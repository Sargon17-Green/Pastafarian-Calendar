function total = countWholeWeavingSuffixByEndpoints(remaining, openedUpTo, closedUpTo)
% Experimental EXACT polynomial-state suffix counter, not the published route.
% Each suffix begins after an already verified legal prefix.
% Month IDs 1..closedUpTo have no occurrences left; IDs
% closedUpTo+1..openedUpTo have already opened; remaining IDs are unopened.
% First occurrence order is required only for months > openedUpTo+1.
% Last occurrence order is required for ALL remaining months.
%
% Inserting m indistinguishable copies of new largest month into an old
% legal suffix of N days, with old last month's first/last positions f,l:
%   new first = p, new last = q, q >= l+m,
%   p > f ONLY when both months are as-yet unopened.
% For m>=2 the exact number of choices for the interior copies is
% C(q-p-1,m-2). For m=1, necessarily p=q.
% Therefore newDP(p,q) = C(...)*sum_{f<p if needed, l<=q-m} oldDP(f,l).
% 2D prefix sums compute the aggregate without enumerating a state
% for every vector of remaining monthly multiplicities.
%
% This implementation is an independently testable candidate. It uses
% exact pastafari.BigInt only, never rounded floating-point counts.
% O(monthCount * totalDays^2) cells, up to arithmetic costs.
% Its performance on 4244 days has NOT been established; do not wire
% it into WholeMonthWeavingFamily until native tests and benchmarks pass.

if ~(isnumeric(remaining) && isvector(remaining) && ...
        all(isfinite(remaining)) && all(remaining >= 0) && ...
        all(fix(remaining) == remaining))
    error('Pastafari:EndpointCount:Remaining', ...
        'Remaining must be a vector of nonnegative exact integers.');
end
remaining = double(remaining(:).');
K = numel(remaining);
if ~(isnumeric(openedUpTo) && isscalar(openedUpTo) && ...
        isfinite(openedUpTo) && openedUpTo == fix(openedUpTo) && ...
        isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isfinite(closedUpTo) && closedUpTo == fix(closedUpTo) && ...
        0 <= closedUpTo && closedUpTo <= openedUpTo && openedUpTo <= K)
    error('Pastafari:EndpointCount:Frontier', ...
        'Expected 0 <= closedUpTo <= openedUpTo <= monthCount.');
end
if any(remaining(1:closedUpTo) ~= 0) || ...
        any(remaining(closedUpTo+1:end) <= 0)
    error('Pastafari:EndpointCount:SuffixShape', ...
        'Closed months must be zero and all future months positive.');
end

suffix = remaining(closedUpTo+1:end);
if isempty(suffix)
    total = pastafari.BigInt(1);
    return
end

% The first remaining month has exactly one suffix word, consisting only
% of its own copies. Its first/last positions are 1 and m.
N = suffix(1);
dp = cell(N, N);
dp{1, N} = pastafari.BigInt(1);

for j = 2:numel(suffix)
    m = suffix(j);
    newN = N + m;
    % Month index in the original full year, NOT an array-local index.
    monthId = closedUpTo + j;
    requireFirstOrder = monthId > openedUpTo + 1;

    % prefix(f,l) counts all previous legal words whose last added
    % month's first position <=f and last position <=l.
    prefix = cell(N, N);
    for f = 1:N
        rowTotal = pastafari.BigInt(0);
        for l = 1:N
            if ~isempty(dp{f,l})
                rowTotal = rowTotal + dp{f,l};
            end
            if f == 1
                prefix{f,l} = rowTotal;
            else
                prefix{f,l} = rowTotal + prefix{f-1,l};
            end
        end
    end

    next = cell(newN, newN);
    for p = 1:newN
        if requireFirstOrder
            fMax = min(N, p-1);
        else
            fMax = N;
        end
        if fMax < 1
            continue
        end

        if m == 1
            % One inserted occurrence serves as both first and last.
            lMax = min(N, p-1);
            if lMax >= 1
                count = prefix{fMax,lMax};
                if ~count.iszero()
                    next{p,p} = count;
                end
            end
            continue
        end

        % m >= 2: first and last positions leave m-2 indistinguishable
        % copies to choose freely from the q-p-1 interior positions.
        coefficient = pastafari.BigInt(1);
        for q = p+m-1:newN
            lMax = min(N, q-m);
            if lMax >= 1
                previous = prefix{fMax,lMax};
                if ~previous.iszero()
                    next{p,q} = previous * coefficient;
                end
            end
            if q < newN
                n = q-p-1; % previous C(n,m-2)
                numerator = coefficient * pastafari.BigInt(n+1);
                divisor = pastafari.BigInt(n-m+3);
                [coefficient, remainder] = numerator.floorDivMod(divisor);
                if ~remainder.iszero()
                    error('Pastafari:EndpointCount:BinomialNonintegral', ...
                        'Exact binomial recurrence had nonzero remainder.');
                end
            end
        end
    end
    dp = next;
    N = newN;
end

total = pastafari.BigInt(0);
for p = 1:N
    for q = p:N
        if ~isempty(dp{p,q})
            total = total + dp{p,q};
        end
    end
end
end
