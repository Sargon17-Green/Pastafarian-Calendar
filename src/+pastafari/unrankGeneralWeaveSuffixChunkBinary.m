function [piece, cursor] = unrankGeneralWeaveSuffixChunkBinary( ...
        originalLengths, remaining, openedUpTo, closedUpTo, rank1, maxSteps)
% EXPERIMENTAL exact lexicographic unrank: choose the next month by
% binary searching cumulative first-letter completion counts.
% One threshold DP is O(months*days) BigInt positions, independent of
% the number of already opened first-letter labels. At most
% ceil(log2(number of choices)) threshold counts per branching day.
% This avoids a first-letter-by-position matrix at broad frontiers.
% No approximation, word omission, or production/oracle dependency.
if ~(isnumeric(originalLengths) && isvector(originalLengths) && ...
        ~isempty(originalLengths) && isreal(originalLengths) && ...
        all(isfinite(originalLengths(:))) && ...
        all(originalLengths(:)>0) && ...
        all(fix(originalLengths(:))==originalLengths(:)) && ...
        all(originalLengths(:)<=flintmax))
    error('Pastafari:BinaryUnrank:Lengths', ...
        'Original month lengths must be positive exact integers.');
end
L=double(originalLengths(:).');
K=numel(L);
if ~(isnumeric(remaining) && isvector(remaining) && ...
        numel(remaining)==K && isreal(remaining) && ...
        all(isfinite(remaining(:))) && ...
        all(fix(remaining(:))==remaining(:)) && ...
        all(remaining(:)>=0))
    error('Pastafari:BinaryUnrank:Remaining', ...
        'Remaining multiplicities must be exact nonnegative integers.');
end
R=double(remaining(:).');
if any(R>L)
    error('Pastafari:BinaryUnrank:Remaining', ...
        'Remaining multiplicity exceeds original month length.');
end
if ~(isnumeric(openedUpTo) && isscalar(openedUpTo) && ...
        isreal(openedUpTo) && isfinite(openedUpTo) && ...
        fix(openedUpTo)==openedUpTo && ...
        isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isreal(closedUpTo) && isfinite(closedUpTo) && ...
        fix(closedUpTo)==closedUpTo && ...
        0<=closedUpTo && closedUpTo<=openedUpTo && openedUpTo<=K)
    error('Pastafari:BinaryUnrank:Frontier', ...
        'Opening/closure indices must be ordered exact integers.');
end
if any(R(1:closedUpTo)~=0) || ...
        any(R(closedUpTo+1:openedUpTo)<=0) || ...
        any(R(closedUpTo+1:openedUpTo)>=L(closedUpTo+1:openedUpTo)) || ...
        any(R(openedUpTo+1:end)~=L(openedUpTo+1:end))
    error('Pastafari:BinaryUnrank:Reachability', ...
        'Remaining counts contradict opening and closure history.');
end
pastafari.ValidationManager.requireExactIntegerInput(rank1);
rank=pastafari.BigInt.coerce(rank1);
if ~(isnumeric(maxSteps) && isscalar(maxSteps) && ...
        isreal(maxSteps) && isfinite(maxSteps) && ...
        fix(maxSteps)==maxSteps && maxSteps>=0 && maxSteps<=flintmax)
    error('Pastafari:BinaryUnrank:StepLimit', ...
        'Step limit must be an exact nonnegative integer.');
end
days=sum(R);
if ~isfinite(days) || days>flintmax
    error('Pastafari:BinaryUnrank:Days', ...
        'Remaining day count exceeds exact integer range.');
end
one=pastafari.BigInt(1);
zero=pastafari.BigInt(0);
if days==0
    parent=one;
elseif openedUpTo>=K-1
    parent=pastafari.countWholeWeavingSuffixByEndpoints( ...
        R,openedUpTo,closedUpTo);
else
    parent=pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
        R,openedUpTo,closedUpTo);
end
if rank<one || rank>parent
    error('Pastafari:BinaryUnrank:Rank', ...
        'Rank outside complete exact legal suffix family.');
end
initialCount=parent;
steps=min(maxSteps,days);
piece=zeros(1,steps);
for position=1:steps
    choices=[];
    for i=closedUpTo+1:K
        n=R(i);
        if n==0 || (n==L(i) && i~=openedUpTo+1) || ...
                (n==1 && i~=closedUpTo+1)
            continue
        end
        choices(end+1)=i; %#ok<AGROW>
    end
    if isempty(choices)
        error('Pastafari:BinaryUnrank:DeadEnd', ...
            'A nonterminal reachable suffix has no legal first letter.');
    end
    if numel(choices)==1
        selected=choices(1);
    else
        % Prefix totals satisfy C(0)=0, C(end)=parent and are
        % monotonically nondecreasing. Search the first C(j)>=rank.
        low=0;
        high=numel(choices);
        lowCount=zero;
        highCount=parent;
        while high-low>1
            middle=floor((low+high)/2);
            middleCount=pastafari.countWholeWeavingFirstLetterUpTo( ...
                R,openedUpTo,closedUpTo,choices(middle));
            if middleCount<lowCount || middleCount>highCount
                error('Pastafari:BinaryUnrank:Cumulative', ...
                    'Cumulative exact child count is not monotone.');
            end
            if rank>middleCount
                low=middle;
                lowCount=middleCount;
            else
                high=middle;
                highCount=middleCount;
            end
        end
        selected=choices(high);
        block=highCount-lowCount;
        if block<one || rank<=lowCount || rank>highCount
            error('Pastafari:BinaryUnrank:Block', ...
                'Selected lexical child has an inconsistent BigInt range.');
        end
        rank=rank-lowCount;
        parent=block;
    end
    n=R(selected);
    R(selected)=n-1;
    openedUpTo=openedUpTo+double(n==L(selected));
    closedUpTo=closedUpTo+double(n==1);
    piece(position)=selected;
end
done=all(R==0);
if done && (openedUpTo~=K || closedUpTo~=K || ...
        parent~=one || rank~=one)
    error('Pastafari:BinaryUnrank:Terminal', ...
        'Completed suffix must end at unique rank/count 1.');
end
cursor=struct('remaining',R,'openedUpTo',openedUpTo, ...
    'closedUpTo',closedUpTo,'rank',rank,'count',parent, ...
    'initialCount',initialCount,'done',done,'stepsComputed',steps);
end
