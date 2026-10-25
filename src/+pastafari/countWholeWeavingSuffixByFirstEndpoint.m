function [total, monthTotals] = countWholeWeavingSuffixByFirstEndpoint( ...
        remaining, openedUpTo, closedUpTo)
% EXPERIMENTAL: exact ONE-ENDPOINT streaming counter for ALL legal suffix
% frontiers (fully unopened, partially opened, or all opened).
% Does not replace production or the independent normative oracle.
%
% Since last occurrences must be in month-ID order, the LAST symbol in
% EVERY legal word on months closedUpTo+1..i is month i. Its final
% position is necessarily N_i = sum(remaining(closedUpTo+1:i)).
% Thus no two-dimensional (first,last) DP is necessary. Let F_i(p)
% count legal words whose largest month FIRST appears at position p.
%
% For new largest month with m>=2 copies, Nnew=Nold+m:
% F_new(p)=C(Nnew-p-1,m-2)*eligibleOld(p).
% eligibleOld(p)=sum_{f<p} F_old(f) when the first-order constraint
% applies (monthID > openedUpTo+1), otherwise eligibleOld(p)=totalOld.
% There are no other constraints on the m-2 interior positions.
% For m=1 the only copy is at p=Nnew, with totalOld completions.
%
% Store only cumulative first-position weights Prefix_i(p). Every
% recurrence reads the previous month's prefix, and keeps only the
% current/previous vectors and temporary integer coefficients:
% O(N_K) BigInt cells, not O(N_K^2) endpoint cells and not an
% exponential DAG. NO counts or difficult states are discarded.

if ~(isnumeric(remaining) && isvector(remaining) && ...
        all(isfinite(remaining)) && all(remaining>=0) && ...
        all(fix(remaining)==remaining) && ...
        all(remaining<=flintmax))
    error('Pastafari:FirstEndpoint:Remaining', ...
        'Remaining counts must be exact nonnegative integers.');
end
remaining=double(remaining(:).');
K=numel(remaining);
monthTotals=cell(1,K); % Optional exact totals at each inserted month.
if ~(isnumeric(openedUpTo) && isscalar(openedUpTo) && ...
        isfinite(openedUpTo) && fix(openedUpTo)==openedUpTo && ...
        isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isfinite(closedUpTo) && fix(closedUpTo)==closedUpTo && ...
        0<=closedUpTo && closedUpTo<=openedUpTo && ...
        openedUpTo<=K)
    error('Pastafari:FirstEndpoint:Frontier', ...
        'Expected 0 <= closed <= opened <= total months.');
end
if any(remaining(1:closedUpTo)~=0) || ...
        any(remaining(closedUpTo+1:end)<=0)
    error('Pastafari:FirstEndpoint:SuffixShape', ...
        'Closed months must be zero, remaining months positive.');
end

r=remaining(closedUpTo+1:end);
if isempty(r)
    total=pastafari.BigInt(1);
    return
end
N=cumsum(r);
if ~isfinite(N(end)) || N(end)>flintmax
    error('Pastafari:FirstEndpoint:Days', ...
        'Total suffix days must be exactly representable.');
end

% For one remaining month its first position is 1, with one word.
one=pastafari.BigInt(1);
prefix=cell(1,N(1)+1);
prefix(2:end)=repmat({one},1,N(1));
total=one;
monthTotals{closedUpTo+1}=one;

trace=strcmp(getenv('PASTAFARI_FIRST_ENDPOINT_TRACE'),'1');
if trace
    timer=tic;
    fprintf('STAGE_55_FIRST_ENDPOINT_BEGIN MONTHS=%d DAYS=%d\n', ...
        numel(r),N(end));
end

for j=2:numel(r)
    m=r(j);
    nOld=N(j-1);
    nNew=N(j);
    monthId=closedUpTo+j;
    requireOpeningOrder=(monthId>openedUpTo+1);
    nextPrefix=cell(1,nNew+1);

    if m==1
        % Exactly one occurrence, both first and last at Nnew.
        nextPrefix{nNew+1}=total;
    else
        maxFirst=nOld+1;
        weights=cell(1,maxFirst);
        coefficient=one; % C(m-2,m-2)=1 at p=maxFirst
        for p=maxFirst:-1:1
            if requireOpeningOrder
                eligible=prefix{p}; % prev first <= p-1
            else
                eligible=total;
            end
            if ~isempty(eligible) && ~eligible.iszero()
                weights{p}=eligible*coefficient;
            end
            if p>1
                numerator=coefficient*pastafari.BigInt(nNew-p);
                divisor=pastafari.BigInt(nOld-p+2);
                [coefficient,remainder]=numerator.floorDivMod(divisor);
                if ~remainder.iszero()
                    error('Pastafari:FirstEndpoint:Binomial', ...
                        'Binomial recurrence lost exact divisibility.');
                end
            end
        end
        running=pastafari.BigInt(0);
        for p=1:maxFirst
            if ~isempty(weights{p})
                running=running+weights{p};
            end
            if ~running.iszero()
                nextPrefix{p+1}=running;
            end
        end
        for p=maxFirst+1:nNew
            nextPrefix{p+1}=running;
        end
    end

    total=nextPrefix{nNew+1};
    if isempty(total) || total<pastafari.BigInt(1)
        error('Pastafari:FirstEndpoint:Nonpositive', ...
            'Every legal nonempty suffix has an exact positive count.');
    end
    prefix=nextPrefix;
    monthTotals{monthId}=total;

    if trace && (j==2 || mod(j,5)==0 || j==numel(r))
        fprintf(['STAGE_55_FIRST_ENDPOINT_PROGRESS MONTH=%d OF=%d ', ...
            'DAYS=%d SECONDS=%.3f\n'], ...
            j,numel(r),nNew,toc(timer));
    end
end
end
