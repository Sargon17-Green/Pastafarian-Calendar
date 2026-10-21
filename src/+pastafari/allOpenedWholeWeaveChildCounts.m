function blocks = allOpenedWholeWeaveChildCounts(remaining, closedUpTo, totalCount)
% EXPERIMENTAL exact all-opened lexicographic child block counts.
% All K months must have appeared in the already verified prefix.
% Month IDs 1..closedUpTo must be closed, and all later IDs remain
% active. All children obey last-occurrence order; their counts are
% computed by an exact rational telescoping identity, without an
% exponential DAG or one new suffix DP run per candidate.
%
% Let r_j>0 be remaining copies of month closedUpTo+j and
% S_j=sum(r_1..r_j). Every legal all-open suffix has count
% F(r)=PRODUCT_{j=2..m} C(S_j-1,r_j-1).
% If the NEXT letter is i:
% - i=1 is always legal (including r_1=1);
% - i>1 is legal only while r_i>1 (cannot close out of order).
% Its exact completion count is
% F(child_i)=F(r) * R_i, where
%   R_1 = PRODUCT_{j=2..m} S_(j-1)/(S_j-1),
%   R_i = (r_i-1)/(S_i-1) *
%         PRODUCT_{j=i+1..m} S_(j-1)/(S_j-1), for i>1.
% The child counts are integer; exactDiv checks that property.
%
% In the single remaining month case, there is one legal child with
% completion count 1. Input totalCount is independently computed
% from the caller's exact known suffix count, and never approximated.

if ~(isnumeric(remaining) && isvector(remaining) && ...
        ~isempty(remaining) && all(isfinite(remaining)) && ...
        all(fix(remaining) == remaining) && ...
        all(remaining >= 0) && all(remaining <= flintmax))
    error('Pastafari:AllOpen:Remaining', ...
        'Remaining must be an exact nonnegative integer vector.');
end
remaining = double(remaining(:).');
K = numel(remaining);
if ~(isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isfinite(closedUpTo) && fix(closedUpTo) == closedUpTo && ...
        closedUpTo >= 0 && closedUpTo < K)
    error('Pastafari:AllOpen:Frontier', ...
        'At least one month must remain unclosed.');
end
if any(remaining(1:closedUpTo) ~= 0) || ...
        any(remaining(closedUpTo+1:end) <= 0)
    error('Pastafari:AllOpen:SuffixShape', ...
        'Expected zero closed prefix and positive opened suffix.');
end
pastafari.ValidationManager.requireExactIntegerInput(totalCount);
F = pastafari.BigInt.coerce(totalCount);
if F < pastafari.BigInt(1)
    error('Pastafari:AllOpen:Count', 'Parent count must be positive.');
end

r = remaining(closedUpTo+1:end);
m = numel(r);
blocks = cell(1,K);
if m == 1
    if F ~= pastafari.BigInt(1)
        error('Pastafari:AllOpen:Count', ...
            'A sole remaining month admits exactly one suffix.');
    end
    blocks{closedUpTo+1} = F;
    return
end
S = cumsum(r);
tailNum = pastafari.BigInt(1);
tailDen = pastafari.BigInt(1);
sumBlocks = pastafari.BigInt(0);
for i = m:-1:1
    if i == 1 || r(i) > 1
        if i == 1
            numerator = tailNum;
            denominator = tailDen;
        else
            numerator = tailNum * pastafari.BigInt(r(i)-1);
            denominator = tailDen * pastafari.BigInt(S(i)-1);
        end
        [block,rem] = (F*numerator).floorDivMod(denominator);
        if ~rem.iszero() || block < pastafari.BigInt(1)
            error('Pastafari:AllOpen:Fraction', ...
                'The exact child count was not a positive integer.');
        end
        blocks{closedUpTo+i} = block;
        sumBlocks = sumBlocks + block;
    end
    if i > 1
        tailNum = tailNum * pastafari.BigInt(S(i-1));
        tailDen = tailDen * pastafari.BigInt(S(i)-1);
    end
end
if sumBlocks ~= F
    error('Pastafari:AllOpen:Partition', ...
        'Exact lexicographic child blocks do not partition the parent.');
end
end
