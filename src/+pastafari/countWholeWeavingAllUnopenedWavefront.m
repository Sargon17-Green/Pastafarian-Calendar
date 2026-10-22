function total = countWholeWeavingAllUnopenedWavefront(lengths)
% Experimental exact full-initial-frontier counter: EVERY month unopened.
% Neither the canonical production route nor the independent oracle
% imports this code.
%
% Prefix_i(p,q) counts legal words for months 1..i whose LARGEST
% month's first position <=p and last position <=q (all first and last
% appearances are ordered, respectively).
%
% For m=lengths(i)>1 and i>1:
% DP_i(p,q) = C(q-p-1,m-2) * Prefix_(i-1)(p-1,q-m).
% The m=1 case instead has DP_i(p,p)=Prefix_(i-1)(p-1,p-1).
% Prefix_i(p,q)=Prefix_i(p-1,q)+SUM_{v<=q} DP_i(p,v).
% Month 1 is a single word, with its first at 1 and last at lengths(1).
%
% Iterate p in increasing order and preserve only the immediately
% preceding Prefix_i(p-1,:) ROW for each month i. Thus all cross-layer
% queries are served from the old row, not a full p-by-q matrix.
% Working memory is O(SUM_i N_i) BigInt cells rather than
% O(SUM_i N_i^2), with N_i=SUM_{j<=i} lengths(j).
% All exact counts, every legal first/last ordering, and every distinct
% weaving are retained. CPU cost remains quadratic in prefix length per
% layer and MUST be measured natively before large-year deployment.
%
% This implementation currently covers the fully unopened initial
% frontier only. Partial first-opened prefixes have a different base
% condition and require a separate proof and implementation.

if ~(isnumeric(lengths) && isvector(lengths) && ...
        ~isempty(lengths) && all(isfinite(lengths)) && ...
        all(lengths > 0) && all(fix(lengths)==lengths) && ...
        all(lengths <= flintmax))
    error('Pastafari:PreopenWavefront:Lengths', ...
        'Lengths must be a nonempty exact positive integer vector.');
end
lengths=double(lengths(:).');
K=numel(lengths);
N=cumsum(lengths);
if ~isfinite(N(end)) || N(end)>flintmax
    error('Pastafari:PreopenWavefront:TotalDays', ...
        'Total days must be an exactly representable integer.');
end
if K==1
    total=pastafari.BigInt(1);
    return
end

% Prefix arrays use MATLAB column index q+1 for zero-based q=0..N_i.
% An empty cell means EXACT ZERO, never an unknown/truncated count.
rows=cell(1,K);
coeff=cell(1,K);
for i=1:K
    rows{i}=cell(1,N(i)+1);
    if i==1
        continue
    end
    m=lengths(i);
    if m==1
        continue
    end
    b=cell(1,N(i)+1);
    factor=pastafari.BigInt(1);
    for d=m-1:N(i)
        % b{d+1} = C(d-1,m-2), initially C(m-2,m-2)=1.
        b{d+1}=factor;
        if d<N(i)
            numerator=factor*pastafari.BigInt(d);
            [factor,rem]=numerator.floorDivMod( ...
                pastafari.BigInt(d-m+2));
            if ~rem.iszero()
                error('Pastafari:PreopenWavefront:Binomial', ...
                    'Binomial update must divide exactly.');
            end
        end
    end
    coeff{i}=b;
end

pMax=N(K-1)+1;
traceEnabled=strcmp(getenv('PASTAFARI_PREOPEN_WAVEFRONT_TRACE'),'1');
if traceEnabled
    traceClock=tic;
    fprintf('STAGE_55_PREOPEN_WAVEFRONT_TRACE_BEGIN MONTHS=%d DAYS=%d ROWS=%d\n', ...
        K,N(end),pMax);
end
for p=1:pMax
    old=rows;
    current=rows;
    if p==1
        % Month 1 has one legal word: copies of month 1 only.
        base=current{1};
        for q=lengths(1):N(1)
            base{q+1}=pastafari.BigInt(1);
        end
        current{1}=base;
    end
    for i=2:K
        m=lengths(i);
        qStart=p+m-1;
        if m==1
            qStart=p;
        end
        if qStart>N(i)
            continue
        end
        oldOwn=old{i};
        oldPrior=old{i-1};
        newOwn=oldOwn;
        rowSum=pastafari.BigInt(0);
        for q=qStart:N(i)
            if m==1
                % The sole copy occurs at q=p, but its cumulative
                % contribution persists for every later q in this row.
                if q==p
                    prior=oldPrior{p}; % index p -> p-1
                    if ~isempty(prior)
                        rowSum=rowSum+prior;
                    end
                end
            else
                prior=oldPrior{q-m+1};
                if ~isempty(prior)
                    rowSum=rowSum+prior*coeff{i}{q-p+1};
                end
            end
            if rowSum.iszero()
                continue
            end
            previous=oldOwn{q+1};
            if isempty(previous)
                newOwn{q+1}=rowSum;
            else
                newOwn{q+1}=previous+rowSum;
            end
        end
        current{i}=newOwn;
    end
    rows=current;
    if traceEnabled && (p==1 || mod(p,128)==0 || p==pMax)
        filled=0;
        for i=1:K
            filled=filled+nnz(~cellfun(@isempty,rows{i}));
        end
        fprintf(['STAGE_55_PREOPEN_WAVEFRONT_TRACE_ROW ', ...
            'P=%d OF=%d STORED_NONZERO=%d SECONDS=%.3f\n'], ...
            p,pMax,filled,toc(traceClock));
    end
end

total=rows{K}{N(K)+1};
if isempty(total) || total<pastafari.BigInt(1)
    error('Pastafari:PreopenWavefront:Final', ...
        'Complete exact fully unopened count must be positive.');
end
end
