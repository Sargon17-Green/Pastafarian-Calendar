function [blocks, total] = countWholeWeavingNextLetterBlocksOnePass( ...
        remaining, openedUpTo, closedUpTo)
% EXPERIMENTAL exact joint first-letter + largest-month-first-position DP.
% Counts EVERY legal next-letter completion block in ONE streamed
% insertion recurrence, without re-counting the suffix independently
% for each candidate month.
%
% The last occurrence of the largest currently inserted month i must be
% the final character. Let G_i(j,p) count legal suffix words on month
% IDs closedUpTo+1..i whose first letter is j and whose first occurrence
% of month i is at p. Store prefix sums in p for each possible j.
% Insert m copies of the new largest month i. Its last is at N_i.
% If m>=2 and first position p:
%   factor = C(N_i-p-1,m-2).
%   p=1: first letter becomes i, allowed only when i<=openedUpTo+1.
%   p>1: first letter remains j of the old word. The eligible old
%        words are either all of G_old(j,*) or those with old-largest
%        first position <p, when first-occurrence order is required.
% If m=1, month i is appended as the last letter, preserving the old
% word's first letter. No valid lexical word is sampled or dropped.
%
% Strict BigInt arithmetic; O(eligibleFirstLetters * remainingDays)
% BigInt prefix cells and O(months * eligibleLetters * days) updates.
% The production calendar engine is deliberately unchanged.

if ~(isnumeric(remaining) && isvector(remaining) && ...
        ~isempty(remaining) && all(isfinite(remaining)) && ...
        all(remaining>=0) && all(fix(remaining)==remaining) && ...
        all(remaining<=flintmax))
    error('Pastafari:JointNext:Remaining', ...
        'Expected an exact nonnegative integer vector.');
end
remaining=double(remaining(:).');
K=numel(remaining);
if ~(isnumeric(openedUpTo) && isscalar(openedUpTo) && ...
        isfinite(openedUpTo) && fix(openedUpTo)==openedUpTo && ...
        isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isfinite(closedUpTo) && fix(closedUpTo)==closedUpTo && ...
        0<=closedUpTo && closedUpTo<=openedUpTo && openedUpTo<=K)
    error('Pastafari:JointNext:Frontier', ...
        'Expected exact 0<=closed<=opened<=K frontier.');
end
if any(remaining(1:closedUpTo)~=0) || ...
        any(remaining(closedUpTo+1:end)<=0)
    error('Pastafari:JointNext:SuffixShape', ...
        'Closed months must be zero and all remaining months positive.');
end
blocks=cell(1,K);
zero=pastafari.BigInt(0);
one=pastafari.BigInt(1);
if closedUpTo==K
    total=one;
    return
end

firstId=closedUpTo+1;
N=remaining(firstId);
if ~isfinite(sum(remaining)) || sum(remaining)>flintmax
    error('Pastafari:JointNext:Days', ...
        'Total remaining days must be exactly representable.');
end

% Base word consists only of the first remaining month repeated N times;
% first letter=firstId, first appearance of largest at position 1.
prefixes=cell(1,K);
prefixes{firstId}=cell(1,N+1);
prefixes{firstId}(2:end)=repmat({one},1,N);
labelTotals=cell(1,K);
labelTotals{firstId}=one;

for monthId=firstId+1:K
    m=remaining(monthId);
    oldN=N;
    N=oldN+m;
    mustOpenInOrder=(monthId>openedUpTo+1);
    oldFirstIds=find(~cellfun(@isempty,labelTotals));
    newPrefixes=cell(1,K);
    newTotals=cell(1,K);

    if m==1
        % Only copy of the new largest month is at the final position.
        for q=oldFirstIds
            row=cell(1,N+1);
            row{N+1}=labelTotals{q};
            newPrefixes{q}=row;
            newTotals{q}=labelTotals{q};
        end
    else
        maxFirst=oldN+1;
        coefficient=cell(1,maxFirst);
        binomial=one;
        for p=maxFirst:-1:1
            coefficient{p}=binomial;
            if p>1
                numerator=binomial*pastafari.BigInt(N-p);
                divisor=pastafari.BigInt(oldN-p+2);
                [binomial,remainder]=numerator.floorDivMod(divisor);
                if ~remainder.iszero()
                    error('Pastafari:JointNext:Binomial', ...
                        'Exact coefficient had nonzero remainder.');
                end
            end
        end

        for q=oldFirstIds
            row=cell(1,N+1);
            running=zero;
            oldPrefix=prefixes{q};
            for p=2:maxFirst
                if mustOpenInOrder
                    eligible=oldPrefix{p}; % old largest first <=p-1
                else
                    eligible=labelTotals{q};
                end
                if ~isempty(eligible) && ~eligible.iszero()
                    running=running+eligible*coefficient{p};
                end
                if ~running.iszero()
                    row{p+1}=running;
                end
            end
            if ~running.iszero()
                row(maxFirst+2:end)=repmat({running},1,N-maxFirst);
            end
            newPrefixes{q}=row;
            if ~running.iszero()
                newTotals{q}=running;
            end
        end

        % A new largest month can be the first letter exactly when it
        % is already opened or is the single next month allowed to open.
        if ~mustOpenInOrder
            oldTotal=zero;
            for q=oldFirstIds
                oldTotal=oldTotal+labelTotals{q};
            end
            newFirstTotal=oldTotal*coefficient{1};
            row=cell(1,N+1);
            row(2:end)=repmat({newFirstTotal},1,N);
            newPrefixes{monthId}=row;
            newTotals{monthId}=newFirstTotal;
        end
    end
    prefixes=newPrefixes;
    labelTotals=newTotals;
end

total=zero;
for q=firstId:K
    if ~isempty(labelTotals{q}) && ~labelTotals{q}.iszero()
        blocks{q}=labelTotals{q};
        total=total+labelTotals{q};
    end
end
if total<one
    error('Pastafari:JointNext:NoWords', ...
        'Nonterminal legal suffix must have positive exact count.');
end
end
