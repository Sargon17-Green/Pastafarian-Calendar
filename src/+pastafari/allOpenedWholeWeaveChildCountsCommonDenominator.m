function blocks = allOpenedWholeWeaveChildCountsCommonDenominator( ...
        remaining, closedUpTo, totalCount)
% Experimental exact common-denominator all-open rank blocks.
% Never uses floating-point counting, truncated state spaces, or
% approximate division. No production route calls this helper.
%
% Let r(1)..r(m) be positive counts of already-open, not-yet-closed
% months, and S(j)=r(1)+...+r(j). The parent family count is F.
% D=PROD_{j=2..m}(S(j)-1).
% Numerators are
%   N(1)=PROD_{j=2..m} S(j-1);
%   N(i)=(r(i)-1) * PROD_{j=2..i-1}(S(j)-1)
%                   * PROD_{j=i+1..m} S(j-1), i>1.
% Every legal child count equals F*N(i)/D. All numerators and the
% denominator are small relative to the huge exact parent F.
% Let g=gcd(F,D), F'=F/g, D'=D/g. Since gcd(F',D')=1 and each block is
% an integer, D' divides each N(i). We perform ONE large-input exact
% division by g, then only short N(i)/D' divisions, followed by exact
% multiplication F'*(N(i)/D').
%
% If r(i)=1 for i>1, selecting it would close out of order, so N(i)=0
% and the corresponding child block is intentionally absent.

if ~(isnumeric(remaining) && isvector(remaining) && ...
        ~isempty(remaining) && all(isfinite(remaining)) && ...
        all(remaining>=0) && all(fix(remaining)==remaining) && ...
        all(remaining<=flintmax))
    error('Pastafari:AllOpenCommon:Remaining', ...
        'Expected an exact nonnegative remaining-length vector.');
end
remaining=double(remaining(:).');
K=numel(remaining);
if ~(isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isfinite(closedUpTo) && fix(closedUpTo)==closedUpTo && ...
        closedUpTo>=0 && closedUpTo<K) || ...
        any(remaining(1:closedUpTo)~=0) || ...
        any(remaining(closedUpTo+1:end)<=0)
    error('Pastafari:AllOpenCommon:Frontier', ...
        'Invalid all-open suffix closure frontier.');
end
pastafari.ValidationManager.requireExactIntegerInput(totalCount);
F=pastafari.BigInt.coerce(totalCount);
if F<pastafari.BigInt(1)
    error('Pastafari:AllOpenCommon:Count', ...
        'Exact parent count must be positive.');
end
r=remaining(closedUpTo+1:end);
m=numel(r);
blocks=cell(1,K);
if m==1
    if F~=pastafari.BigInt(1)
        error('Pastafari:AllOpenCommon:Count', ...
            'Single remaining month must have exactly one completion.');
    end
    blocks{closedUpTo+1}=F;
    return
end

S=cumsum(r);
prefixD=cell(1,m);
suffixN=cell(1,m+1);
prefixD{1}=pastafari.BigInt(1);
suffixN{m+1}=pastafari.BigInt(1);
for i=2:m
    prefixD{i}=prefixD{i-1}*pastafari.BigInt(S(i)-1);
end
for i=m:-1:2
    suffixN{i}=suffixN{i+1}*pastafari.BigInt(S(i-1));
end
D=prefixD{m};

% The only division of a multi-thousand-digit parent count.
g=gcdBig(F,D);
[parentQuotient,remF]=F.floorDivMod(g);
[denominatorReduced,remD]=D.floorDivMod(g);
if ~remF.iszero() || ~remD.iszero()
    error('Pastafari:AllOpenCommon:GcdDivision', ...
        'GCD must divide exact parent and common denominator.');
end

sumBlocks=pastafari.BigInt(0);
for i=1:m
    if i==1
        numerator=suffixN{2};
    elseif r(i)>1
        numerator=pastafari.BigInt(r(i)-1)*prefixD{i-1};
        numerator=numerator*suffixN{i+1};
    else
        continue
    end
    [smallQuotient,remN]=numerator.floorDivMod(denominatorReduced);
    if ~remN.iszero() || smallQuotient<pastafari.BigInt(1)
        error('Pastafari:AllOpenCommon:NonIntegral', ...
            'Reduced common denominator must divide legal numerator.');
    end
    block=parentQuotient*smallQuotient;
    blocks{closedUpTo+i}=block;
    sumBlocks=sumBlocks+block;
end
if sumBlocks~=F
    error('Pastafari:AllOpenCommon:Partition', ...
        'All exact child blocks must sum to the parent count.');
end
end

function g=gcdBig(a,b)
% Euclid via the existing pure MATLAB exact arbitrary-precision kernel.
while ~b.iszero()
    [~,rem]=a.floorDivMod(b);
    a=b;
    b=rem;
end
g=a;
end
