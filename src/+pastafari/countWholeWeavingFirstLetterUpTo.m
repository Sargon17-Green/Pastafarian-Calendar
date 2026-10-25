function total = countWholeWeavingFirstLetterUpTo( ...
        remaining, openedUpTo, closedUpTo, threshold)
% EXPERIMENTAL exact cumulative first-letter count:
% number of legal nonempty suffixes starting with a month <= threshold.
% This is a SINGLE one-dimensional first-position insertion recurrence,
% NOT the O(opened * days) first-label matrix of the joint algorithm.
% It is kept independent from production and normative_oracle.
%
% Insert months in ascending order. The largest inserted month always
% finishes the suffix; if it appears m>=2 times and first occurs at p,
% its other m-2 interior positions contribute C(Nnew-p-1,m-2).
% A newly inserted month j can be the very first letter only when
% j<=openedUpTo+1 and j<=threshold. If j>threshold, p=1 is excluded.
% Existing accepted first letters remain accepted when p>1.
if ~(isnumeric(remaining) && isvector(remaining) && ...
        ~isempty(remaining) && isreal(remaining) && ...
        all(isfinite(remaining(:))) && all(remaining(:)>=0) && ...
        all(fix(remaining(:))==remaining(:)) && ...
        all(remaining(:)<=flintmax))
    error('Pastafari:FirstLetterUpTo:Remaining', ...
        'Expected nonempty exact nonnegative month multiplicities.');
end
R=double(remaining(:).');
K=numel(R);
if ~(isnumeric(openedUpTo) && isscalar(openedUpTo) && ...
        isreal(openedUpTo) && isfinite(openedUpTo) && ...
        fix(openedUpTo)==openedUpTo && ...
        isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isreal(closedUpTo) && isfinite(closedUpTo) && ...
        fix(closedUpTo)==closedUpTo && ...
        0<=closedUpTo && closedUpTo<=openedUpTo && openedUpTo<=K)
    error('Pastafari:FirstLetterUpTo:Frontier', ...
        'Expected exact 0<=closed<=opened<=K frontier.');
end
if ~(isnumeric(threshold) && isscalar(threshold) && ...
        isreal(threshold) && isfinite(threshold) && ...
        fix(threshold)==threshold && threshold>=0 && threshold<=K)
    error('Pastafari:FirstLetterUpTo:Threshold', ...
        'The first-letter threshold must be an integer in 0..K.');
end
if any(R(1:closedUpTo)~=0) || ...
        any(R(closedUpTo+1:end)<=0)
    error('Pastafari:FirstLetterUpTo:SuffixShape', ...
        'Closed months must have zero remaining; the others are positive.');
end
if closedUpTo==K
    error('Pastafari:FirstLetterUpTo:Terminal', ...
        'The empty suffix has no first letter.');
end
days=sum(R);
if ~isfinite(days) || days>flintmax
    error('Pastafari:FirstLetterUpTo:Days', ...
        'Remaining days must be exactly representable.');
end
zero=pastafari.BigInt(0);
one=pastafari.BigInt(1);
first=closedUpTo+1;
if threshold<first
    total=zero;
    return
end
N=R(first);
prefix=cell(1,N+1);
prefix(2:end)=repmat({one},1,N);
total=one;
for j=first+1:K
    m=R(j);
    oldN=N;
    newN=oldN+m;
    requireOpeningOrder=j>openedUpTo+1;
    nextPrefix=cell(1,newN+1);
    if m==1
        % The single largest symbol must occur LAST, so it cannot
        % change the first symbol of this already nonempty suffix.
        nextPrefix{newN+1}=total;
    else
        maxFirst=oldN+1;
        coefficient=one;
        weights=cell(1,maxFirst);
        for p=maxFirst:-1:1
            if p==1 && j>threshold
                % New first letter is j and would violate the bound.
                eligible=[];
            elseif requireOpeningOrder
                % Previous largest month's first position is <p.
                eligible=prefix{p};
            else
                eligible=total;
            end
            if ~isempty(eligible) && ~eligible.iszero()
                weights{p}=eligible*coefficient;
            end
            if p>1
                numerator=coefficient*pastafari.BigInt(newN-p);
                divisor=pastafari.BigInt(oldN-p+2);
                [coefficient,remainder]=numerator.floorDivMod(divisor);
                if ~remainder.iszero()
                    error('Pastafari:FirstLetterUpTo:Binomial', ...
                        'The exact binomial coefficient lost divisibility.');
                end
            end
        end
        running=zero;
        for p=1:maxFirst
            if ~isempty(weights{p})
                running=running+weights{p};
            end
            if ~running.iszero()
                nextPrefix{p+1}=running;
            end
        end
        for p=maxFirst+1:newN
            if ~running.iszero()
                nextPrefix{p+1}=running;
            end
        end
    end
    N=newN;
    prefix=nextPrefix;
    total=prefix{N+1};
    if isempty(total)
        total=zero;
    end
end
end
