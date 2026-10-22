function weaving = unrankWholeWeavingByEndpoints(monthLengths, rank1)
% EXPERIMENTAL lexicographic exact unrank; does not change production.
% At every position, evaluate the complete legal suffix count of each
% candidate next month using the proven endpoint recurrence. Each legal
% word contributes one rank, including every difficult suffix.
% Native performance on 4244 days is NOT yet established.
if ~(isnumeric(monthLengths) && isvector(monthLengths) && ...
        ~isempty(monthLengths) && all(isfinite(monthLengths)) && ...
        all(monthLengths > 0) && ...
        all(fix(monthLengths) == monthLengths) && ...
        all(monthLengths <= flintmax))
    error('Pastafari:EndpointUnrank:Lengths', ...
        'Positive exact integer month lengths are required.');
end
pastafari.ValidationManager.requireExactIntegerInput(rank1);
rank = pastafari.BigInt.coerce(rank1);
lengths = double(monthLengths(:).');
remaining = lengths;
N = sum(lengths);
if ~isfinite(N) || N > flintmax
    error('Pastafari:EndpointUnrank:TotalDays', ...
        'Total days must be exactly representable.');
end
total = pastafari.countWholeWeavingSuffixByEndpoints( ...
    remaining, 0, 0);
if rank < pastafari.BigInt(1) || rank > total
    error('Pastafari:EndpointUnrank:Rank', ...
        'Rank is outside exact 1-based whole-weave family.');
end

opened = 0;
closed = 0;
weaving = zeros(1, N);
for position = 1:N
    found = false;
    % Iterate month IDs in increasing order: lexicographic block order.
    % With at most one unopened month, no future first-occurrence
    % restriction remains. The same exact all-open child partition
    % applies (and opening the final month remains legal only in order).
    % Avoid recomputing the endpoint-DP for each lexicographic child.
    if opened >= numel(lengths)-1
        allOpenBlocks = pastafari.allOpenedWholeWeaveChildCounts( ...
            remaining, closed, total);
    else
        allOpenBlocks = {};
    end
    for monthId = 1:numel(lengths)
        if remaining(monthId) == 0 || ...
                (remaining(monthId) == lengths(monthId) && ...
                    monthId ~= opened + 1) || ...
                (remaining(monthId) == 1 && monthId ~= closed + 1)
            continue
        end
        childRemaining = remaining;
        childRemaining(monthId) = childRemaining(monthId) - 1;
        childOpened = opened + ...
            double(remaining(monthId) == lengths(monthId));
        childClosed = closed + double(remaining(monthId) == 1);
        if opened >= numel(lengths)-1
            block = allOpenBlocks{monthId};
        else
            block = pastafari.countWholeWeavingSuffixByEndpoints( ...
                childRemaining, childOpened, childClosed);
        end
        if block < pastafari.BigInt(1)
            error('Pastafari:EndpointUnrank:ZeroBlock', ...
                'A legal child must admit at least one completion.');
        end
        if rank > block
            rank = rank - block;
            continue
        end
        weaving(position) = monthId;
        total = block; % selected child count for the next prefix
        remaining = childRemaining;
        opened = childOpened;
        closed = childClosed;
        found = true;
        break
    end
    if ~found
        error('Pastafari:EndpointUnrank:NoChild', ...
            'No exact lexicographic child contains the selected rank.');
    end
end
if any(remaining ~= 0) || opened ~= numel(lengths) || ...
        closed ~= numel(lengths) || rank ~= pastafari.BigInt(1)
    error('Pastafari:EndpointUnrank:Terminal', ...
        'Exact unranking did not finish in the unique terminal state.');
end
end
