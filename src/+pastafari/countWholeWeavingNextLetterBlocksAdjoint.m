function [blocks, total] = countWholeWeavingNextLetterBlocksAdjoint( ...
        remaining, openedUpTo, closedUpTo)
% EXPERIMENTAL exact all-next-letter partition in TWO scalar DP sweeps.
%
% A streamed forward first-endpoint recurrence computes the EXACT total
% at each prefix of month IDs. A second, REVERSE-mode (adjoint) sweep
% propagates continuation weights for each first-position of the largest
% inserted month. Only one O(totalDays)-sized BigInt vector is stored
% at a time, regardless of the number of legal first labels.
%
% If month j has m>=2 copies, its first p and final N occurrences leave
% C(N-p-1,m-2) interior placements. Earlier first-label j'<j persists
% only when p>1; with an unopen j, the earlier largest-month first
% must additionally precede p. Backward propagation therefore is
% W_old(f) = sum_{p>=2, p>f when order required}
%                 C(N-p-1,m-2) W_new(p).
% An already-open (or next-allowed) j can itself become first only
% at p=1; its exact block is oldTotal*C(N-2,m-2)*W_new(1).
% With m=1 the unique final copy cannot become the first label and
% W_old(f)=W_new(N). Base first label is closedUpTo+1 with one
% initial word and first position 1.
%
% All paths, including 1-copy months and partial opening frontiers, are
% exact. This does not change production or normative_oracle.
[total,monthTotals]=pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
    remaining,openedUpTo,closedUpTo);
R=double(remaining(:).');
K=numel(R);
blocks=cell(1,K);
one=pastafari.BigInt(1);
zero=pastafari.BigInt(0);
if closedUpTo==K
    if total~=one
        error('Pastafari:AdjointNext:Terminal', ...
            'Empty suffix must have one exact completion.');
    end
    return
end
first=closedUpTo+1;
N=sum(R);
% A final word contributes exactly one regardless of its largest
% month's first occurrence position. These are the adjoint seeds.
weights=repmat({one},1,N);
for j=K:-1:first+1
    m=R(j);
    oldN=N-m;
    if m==1
        weights=repmat({weights{N}},1,oldN);
        N=oldN;
        continue
    end
    mustOpenInOrder=j>openedUpTo+1;
    maxFirst=oldN+1;
    coefficient=one; % C(N-maxFirst-1,m-2)=1.
    running=zero;
    if mustOpenInOrder
        prevWeights=cell(1,oldN);
    end
    for p=maxFirst:-1:2
        right=weights{p};
        if ~isempty(right) && ~right.iszero()
            running=running+right*coefficient;
        end
        if mustOpenInOrder
            % All legal p>f contributions already accumulated.
            prevWeights{p-1}=running;
        end
        numerator=coefficient*pastafari.BigInt(N-p);
        divisor=pastafari.BigInt(oldN-p+2);
        [coefficient,remainder]=numerator.floorDivMod(divisor);
        if ~remainder.iszero()
            error('Pastafari:AdjointNext:Binomial', ...
                'Exact binomial recurrence had a nonzero remainder.');
        end
    end
    if ~mustOpenInOrder
        % p=1 makes j the first month, not any previous first label.
        % The computed coefficient is now C(N-2,m-2).
        previousTotal=monthTotals{j-1};
        firstBlock=previousTotal*coefficient;
        firstBlock=firstBlock*weights{1};
        if firstBlock<one
            error('Pastafari:AdjointNext:FirstBlock', ...
                'A legal new first-letter block must be positive.');
        end
        blocks{j}=firstBlock;
        prevWeights=repmat({running},1,oldN);
    end
    weights=prevWeights;
    N=oldN;
end
if N~=R(first)
    error('Pastafari:AdjointNext:Length', ...
        'Adjoint recurrence did not return to first month.');
end
blocks{first}=weights{1};
sumBlocks=zero;
for j=first:K
    if ~isempty(blocks{j})
        if blocks{j}<one
            error('Pastafari:AdjointNext:NonpositiveBlock', ...
                'All nonempty first-letter blocks must be positive.');
        end
        sumBlocks=sumBlocks+blocks{j};
    end
end
if sumBlocks~=total
    error('Pastafari:AdjointNext:Partition', ...
        'Adjoint first-letter blocks do not sum to the exact parent.');
end
end
