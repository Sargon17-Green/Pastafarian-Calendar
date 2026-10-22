function [piece, cursor] = unrankGeneralWeaveSuffixChunk( ...
        originalLengths, remaining, openedUpTo, closedUpTo, rank1, maxSteps)
% EXPERIMENTAL: exact lexicographic chunk unranking for EVERY legal
% opening/closing frontier. Does not alter the production DAG or oracle.
% Computes ALL legally allowed child block sizes with an independently
% native-tested first-endpoint BigInt suffix counter.
% This reference route is NOT yet efficient for a 4244-day initial state.
%
% A cursor is resumed by passing the SAME originalLengths and the
% returned remaining/openedUpTo/closedUpTo/rank. A partial cursor cannot
% be confused with a completed weaving; no proof of durable persistence
% or an authenticated checkpoint is implied.

if ~(isnumeric(originalLengths) && isvector(originalLengths) && ...
        ~isempty(originalLengths) && all(isfinite(originalLengths)) && ...
        all(fix(originalLengths)==originalLengths) && ...
        all(originalLengths>0) && all(originalLengths<=flintmax))
    error('Pastafari:GeneralChunk:Lengths', ...
        'Original lengths must be positive exact integers.');
end
L=double(originalLengths(:).');
K=numel(L);
if ~(isnumeric(remaining) && isvector(remaining) && ...
        numel(remaining)==K && all(isfinite(remaining)) && ...
        all(fix(remaining)==remaining) && all(remaining>=0) && ...
        all(remaining<=L))
    error('Pastafari:GeneralChunk:Remaining', ...
        'Remaining lengths must be exact and bounded by original lengths.');
end
R=double(remaining(:).');
if ~(isnumeric(openedUpTo) && isscalar(openedUpTo) && ...
        isfinite(openedUpTo) && fix(openedUpTo)==openedUpTo && ...
        isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isfinite(closedUpTo) && fix(closedUpTo)==closedUpTo && ...
        0<=closedUpTo && closedUpTo<=openedUpTo && openedUpTo<=K)
    error('Pastafari:GeneralChunk:Frontier', ...
        'Expected an ordered exact 0<=closed<=opened<=K frontier.');
end
if any(R(1:closedUpTo)~=0) || ...
        any(R(closedUpTo+1:openedUpTo)<=0) || ...
        any(R(closedUpTo+1:openedUpTo)>=L(closedUpTo+1:openedUpTo)) || ...
        any(R(openedUpTo+1:end)~=L(openedUpTo+1:end))
    error('Pastafari:GeneralChunk:Reachability', ...
        'Remaining counts contradict opened/closed prefix history.');
end
pastafari.ValidationManager.requireExactIntegerInput(rank1);
rank=pastafari.BigInt.coerce(rank1);
if ~(isnumeric(maxSteps) && isscalar(maxSteps) && ...
        isreal(maxSteps) && isfinite(maxSteps) && ...
        maxSteps>=0 && fix(maxSteps)==maxSteps && ...
        maxSteps<=flintmax)
    error('Pastafari:GeneralChunk:StepLimit', ...
        'The chunk limit must be a nonnegative exact integer.');
end

parent=pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
    R,openedUpTo,closedUpTo);
if rank<pastafari.BigInt(1) || rank>parent
    error('Pastafari:GeneralChunk:Rank', ...
        'Rank lies outside the full exact legal suffix family.');
end
days=sum(R);
if ~isfinite(days) || days>flintmax
    error('Pastafari:GeneralChunk:Days', ...
        'Remaining day count exceeds exact integer range.');
end
steps=min(maxSteps,days);
piece=zeros(1,steps);
for position=1:steps
    % When precisely one legal next letter exists, prepend it to EVERY
    % completion: the child language is in exact bijection with the
    % parent language. Reuse the already verified parent BigInt count,
    % rather than running another exact suffix DP. This is a semantic
    % identity, not a cap, approximation, or case omission.
    legalChoices=0;
    for probe=closedUpTo+1:K
        n=R(probe);
        if n~=0 && ...
                ~(n==L(probe) && probe~=openedUpTo+1) && ...
                ~(n==1 && probe~=closedUpTo+1)
            legalChoices=legalChoices+1;
        end
    end
    if legalChoices<1
        error('Pastafari:GeneralChunk:NoLegalNext', ...
            'Nonterminal suffix has no legal next month.');
    end
    if legalChoices==1
        blocks={};
    elseif openedUpTo==K
        % Every already-open month may be chosen unless this would
        % close it out of the required order. One exact block partition.
        blocks=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator( ...
            R,closedUpTo,parent);
    else
        blocks={};
    end
    found=false;
    for i=closedUpTo+1:K
        n=R(i);
        if n==0 || (n==L(i) && i~=openedUpTo+1) || ...
                (n==1 && i~=closedUpTo+1)
            continue
        end
        childR=R;
        childR(i)=n-1;
        childOpened=openedUpTo+double(n==L(i));
        childClosed=closedUpTo+double(n==1);
        if legalChoices==1
            block=parent;
        elseif openedUpTo==K
            block=blocks{i};
        else
            block=pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
                childR,childOpened,childClosed);
        end
        if isempty(block) || block<pastafari.BigInt(1)
            error('Pastafari:GeneralChunk:ZeroBlock', ...
                'Every legal child must admit a positive exact count.');
        end
        if rank>block
            rank=rank-block;
            continue
        end
        piece(position)=i;
        R=childR;
        openedUpTo=childOpened;
        closedUpTo=childClosed;
        parent=block;
        found=true;
        break
    end
    if ~found
        error('Pastafari:GeneralChunk:Unrank', ...
            'No exact child block contains the requested rank.');
    end
end
done=all(R==0);
if done && (openedUpTo~=K || closedUpTo~=K || ...
        rank~=pastafari.BigInt(1) || parent~=pastafari.BigInt(1))
    error('Pastafari:GeneralChunk:Terminal', ...
        'Terminal suffix must have a unique exact rank/count.');
end
cursor=struct('remaining',R,'openedUpTo',openedUpTo, ...
    'closedUpTo',closedUpTo,'rank',rank, ...
    'count',parent,'done',done,'stepsComputed',steps);
end
