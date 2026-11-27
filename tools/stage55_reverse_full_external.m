function n = stage55_reverse_full_external(g,U,prepare)
% Experimental exact counter. No production changes; pure MATLAB BigInt.
% Reverse the unopened word AND label order; its largest label first
% occurs at p exactly when the original first label closes at N-p+1.
% Insert g identical opened-group symbols in the N-p+1 slots before that
% closing symbol. Weight is binomial(g+N-p,g).
persistent lockedLengths cachedWeights cachedTotals lastK
if nargin<3, prepare=false; end
U=double(U(:).');
assert(isscalar(g) && isfinite(g) && g>=0 && fix(g)==g);
assert(all(isfinite(U)) && all(U>=1) && all(fix(U)==U));
assert(g+sum(U)<=4244 && numel(U)<=45,'Reverse:Bounds');
one=pastafari.BigInt(1);
if isempty(U), n=one; return; end
if prepare
    assert(g==0 && numel(U)==45 && sum(U)==4244,'Reverse:Prepare');
    lockedLengths=U;
    lastK=0;
    [cachedWeights,cachedTotals]=build(U,45);
end
if ~isempty(lockedLengths)
    k=numel(lockedLengths)-numel(U);
    assert(k>=lastK && k<=44 && isequal(U,lockedLengths(k+1:end)),'Reverse:CacheKey');
    if k>lastK
        cachedWeights(lastK+1:k)={[]};
        cachedTotals(lastK+1:k)={[]};
        lastK=k;
    end
    F=cachedWeights{k+1};
    n=cachedTotals{k+1};
else
    [W,T]=build(U,1);
    F=W{1}; n=T{1};
end
if g==0, return; end
N=sum(U);
n=pastafari.BigInt(0); B=one;
for p=N:-1:1
    if ~isempty(F{p}), n=n+B*F{p}; end
    if p>1
        numerator=B*pastafari.BigInt(g+N-p+1);
        [B,rem]=numerator.floorDivMod(pastafari.BigInt(N-p+1));
        assert(rem.iszero(),'Reverse:Binomial');
    end
end
assert(n>=one,'Reverse:Nonpositive');
end

function [cache,totals]=build(U,keep)
% Reverse insertion DP: all unopened labels in first AND last order.
K=numel(U); N=0; F={}; one=pastafari.BigInt(1); zero=pastafari.BigInt(0);
cache=cell(1,keep); totals=cell(1,keep);
for j=1:K
    k=K-j; m=U(k+1);
    next=cell(1,N+m);
    if N==0
        next{1}=one; total=one;
    elseif m==1
        next{N+1}=total;
    else
        pref=cell(1,N+1); running=zero;
        for p=1:N
            if ~isempty(F{p}), running=running+F{p}; end
            if ~running.iszero(), pref{p+1}=running; end
        end
        B=one; total=zero;
        for p=N+1:-1:1
            if ~isempty(pref{p})
                next{p}=B*pref{p}; total=total+next{p};
            end
            if p>1
                numerator=B*pastafari.BigInt(N+m-p);
        [B,rem]=numerator.floorDivMod(pastafari.BigInt(N-p+2));
                assert(rem.iszero(),'Reverse:BuildBinomial');
            end
        end
    end
    N=N+m; F=next;
    assert(total>=one,'Reverse:BuildCount');
    if k<keep, cache{k+1}=F; totals{k+1}=total; end
    if keep>1
        t=regexp(fileread('/proc/self/status'),'VmHWM:\s+(\d+)\s+kB','tokens','once');
        assert(~isempty(t) && str2double(t{1})<3*1024*1024,'Reverse:BuildRSS');
    end
end
assert(all(~cellfun(@isempty,cache)),'Reverse:MissingCache');
end
