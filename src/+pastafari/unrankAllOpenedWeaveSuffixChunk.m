function [piece, cursor] = unrankAllOpenedWeaveSuffixChunk( ...
        remaining, closedUpTo, rank1, maxSteps, method)
% EXPERIMENTAL, exact and resumable all-open MONTH suffix unranking.
%
% All months (even those already closed) were opened before this suffix.
% IDs 1..closedUpTo have zero remaining occurrences, later IDs >0.
% Only closure order 1..K remains constrained. No partial answer is
% represented as a completed weaving: cursor.done explicitly records it.
%
% For each legal next month, child block sizes are calculated from the
% *exact* current completion count by algebraic identities. No large DAG
% of remaining multiplicity states is constructed.
%
% Resume by passing cursor.remaining, cursor.closedUpTo, cursor.rank
% back to this function. Each call independently recomputes and checks
% the exact parent count, so it does not trust any earlier count. This
% is not yet a persistent/checksummed checkpoint file format.

% Default uses the previously verified rational method. The alternate
% common-denominator method must pass the same independent brute tests.
if nargin < 5
    method = 'rational';
end
if ~(ischar(method) && isrow(method) && ...
        (strcmp(method,'rational') || strcmp(method,'common')))
    error('Pastafari:AllOpenChunk:Method', ...
        'Choose rational or common as an exact child-block algorithm.');
end
pastafari.ValidationManager.requireExactIntegerInput(rank1);
if ~(isnumeric(maxSteps) && isscalar(maxSteps) && ...
        isreal(maxSteps) && isfinite(maxSteps) && ...
        maxSteps >= 0 && maxSteps == fix(maxSteps) && ...
        maxSteps <= flintmax)
    error('Pastafari:AllOpenChunk:StepLimit', ...
        'Step limit must be a nonnegative exact integer.');
end

if ~(isnumeric(remaining) && isvector(remaining) && ...
        ~isempty(remaining) && all(isfinite(remaining)) && ...
        all(remaining >= 0) && all(fix(remaining) == remaining) && ...
        all(remaining <= flintmax))
    error('Pastafari:AllOpenChunk:Remaining', ...
        'Remaining must be a nonempty exact nonnegative vector.');
end
remaining = double(remaining(:).');
K = numel(remaining);
if ~(isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isfinite(closedUpTo) && closedUpTo == fix(closedUpTo) && ...
        0 <= closedUpTo && closedUpTo <= K) || ...
        any(remaining(1:closedUpTo) ~= 0) || ...
        any(remaining(closedUpTo+1:end) <= 0)
    error('Pastafari:AllOpenChunk:Frontier', ...
        'Invalid fully-opened suffix closure frontier.');
end

rank = pastafari.BigInt.coerce(rank1);
totalDays = sum(remaining);
if ~isfinite(totalDays) || totalDays > flintmax
    error('Pastafari:AllOpenChunk:Days', ...
        'Remaining day count must be exactly representable.');
end

if totalDays == 0
    parent = pastafari.BigInt(1);
else
    parent = pastafari.countWholeWeavingSuffixByEndpoints( ...
        remaining, K, closedUpTo);
end
if rank < pastafari.BigInt(1) || rank > parent
    error('Pastafari:AllOpenChunk:Rank', ...
        'Rank lies outside the exact legal suffix count.');
end

steps = min(maxSteps, totalDays);
piece = zeros(1, steps);
for position = 1:steps
    if strcmp(method,'common')
        blocks = pastafari.allOpenedWholeWeaveChildCountsCommonDenominator( ...
            remaining, closedUpTo, parent);
    else
        blocks = pastafari.allOpenedWholeWeaveChildCounts( ...
            remaining, closedUpTo, parent);
    end
    selected = false;
    for monthId = closedUpTo+1:K
        block = blocks{monthId};
        if isempty(block)
            continue
        end
        if rank > block
            rank = rank - block;
            continue
        end
        piece(position) = monthId;
        remaining(monthId) = remaining(monthId)-1;
        if remaining(monthId) == 0
            if monthId ~= closedUpTo+1
                error('Pastafari:AllOpenChunk:PrematureClosure', ...
                    'Cannot close months outside canonical order.');
            end
            closedUpTo = closedUpTo+1;
        end
        parent = block;
        selected = true;
        break
    end
    if ~selected
        error('Pastafari:AllOpenChunk:Child', ...
            'Exact rank cannot select any legal child.');
    end
end

done = closedUpTo == K;
if done && (rank ~= pastafari.BigInt(1) || ...
        parent ~= pastafari.BigInt(1) || any(remaining ~= 0))
    error('Pastafari:AllOpenChunk:Terminal', ...
        'Terminal suffix must have rank=1 and exactly one completion.');
end
cursor = struct( ...
    'remaining', remaining, ...
    'closedUpTo', closedUpTo, ...
    'rank', rank, ...
    'count', parent, ...
    'done', done, ...
    'stepsComputed', steps);
end
