function blocks = allOpenedWholeWeaveChildCountsByFactors( ...
        remaining, closedUpTo, totalCount)
% Experimental exact factorized child-block computation.
% Unlike rational ratios, no long BigInt is multiplied by a large
% rational numerator and then divided by a multi-limb denominator.
% The factors below are integers from the outset.
%
% For active months r(1)..r(m), let S(j)=sum_{h<=j}r(h).
% All months are already open. Last occurrences must be in ID order.
% F=PROD_{j=2..m} C(S(j)-1,r(j)-1).
% For choice of first active month:
%   B(1)=PROD_{j=2..m} C(S(j)-2,r(j)-1)
% For choice of any later active month i with r(i)>1:
%   B(i)=PROD_{j=2..i-1} C(S(j)-1,r(j)-1)
%        * C(S(i)-2,r(i)-2)
%        * PROD_{j=i+1..m} C(S(j)-2,r(j)-1).
% These are exactly the binomial completion counts of the child
% states; choosing a later month with one copy left would close it
% out of order, so its block is absent.
%
% The proof is to remove the selected first letter, apply the exact
% all-opened count formula, and update the relevant prefix sums.
% Every child contributes precisely one lexicographic rank interval.

if ~(isnumeric(remaining) && isvector(remaining) && ...
        ~isempty(remaining) && all(isfinite(remaining)) && ...
        all(remaining >= 0) && all(fix(remaining)==remaining) && ...
        all(remaining<=flintmax))
    error('Pastafari:AllOpenFactors:Remaining', ...
        'Expected exact nonnegative integer remaining lengths.');
end
remaining = double(remaining(:).');
K = numel(remaining);
if ~(isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isfinite(closedUpTo) && closedUpTo==fix(closedUpTo) && ...
        closedUpTo>=0 && closedUpTo<K) || ...
        any(remaining(1:closedUpTo)~=0) || ...
        any(remaining(closedUpTo+1:end)<=0)
    error('Pastafari:AllOpenFactors:Frontier', ...
        'Invalid already-opened suffix closure frontier.');
end
pastafari.ValidationManager.requireExactIntegerInput(totalCount);
F = pastafari.BigInt.coerce(totalCount);
if F < pastafari.BigInt(1)
    error('Pastafari:AllOpenFactors:Count', ...
        'Exact parent completion count must be positive.');
end

r = remaining(closedUpTo+1:end);
m = numel(r);
blocks = cell(1,K);
if m==1
    if F~=pastafari.BigInt(1)
        error('Pastafari:AllOpenFactors:Count', ...
            'One active month has exactly one legal completion.');
    end
    blocks{closedUpTo+1}=F;
    return
end

S = cumsum(r);
prefix=cell(1,m);
suffix=cell(1,m+1);
prefix{1}=pastafari.BigInt(1);
suffix{m+1}=pastafari.BigInt(1);

for j=2:m
    factor=chooseExact(S(j)-1,r(j)-1);
    prefix{j}=prefix{j-1}*factor;
end
for j=m:-1:2
    factor=chooseExact(S(j)-2,r(j)-1);
    suffix{j}=factor*suffix{j+1};
end

% Verify input count rather than trusting the caller's checkpoint.
if prefix{m}~=F
    error('Pastafari:AllOpenFactors:Count', ...
        'Parent count does not match the exact binomial family.');
end

blocks{closedUpTo+1}=suffix{2};
sumBlocks=blocks{closedUpTo+1};
for j=2:m
    if r(j)==1
        continue
    end
    midpoint=chooseExact(S(j)-2,r(j)-2);
    left=prefix{j-1}*midpoint;
    block=left*suffix{j+1};
    if block<pastafari.BigInt(1)
        error('Pastafari:AllOpenFactors:ZeroBlock', ...
            'Legal next-letter block must have positive count.');
    end
    blocks{closedUpTo+j}=block;
    sumBlocks=sumBlocks+block;
end
if sumBlocks~=F
    error('Pastafari:AllOpenFactors:Partition', ...
        'Exact child block sum did not equal the exact parent count.');
end
end

function c=chooseExact(n,k)
% Integer C(n,k), with exact division checked at every recurrence step.
if ~isfinite(n) || ~isfinite(k) || ...
        n<0 || k<0 || k>n || n>flintmax
    error('Pastafari:AllOpenFactors:Binomial', ...
        'Invalid exact binomial arguments.');
end
k=min(k,n-k);
c=pastafari.BigInt(1);
for i=1:k
    numerator=c*pastafari.BigInt(n-k+i);
    [c,remainder]=numerator.floorDivMod(pastafari.BigInt(i));
    if ~remainder.iszero()
        error('Pastafari:AllOpenFactors:NonIntegral', ...
            'Binomial recurrence must have zero exact remainder.');
    end
end
end
