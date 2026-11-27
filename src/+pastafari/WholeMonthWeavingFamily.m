classdef WholeMonthWeavingFamily < handle
    % PATCH 24: exact reverse-suffix whole-month weaving family.
    % Preserves lexicographic one-based rank, first/last label order,
    % multiplicities, and the existing production selection route.
    % No global cache, fixture, oracle, or change to BigInt.
    properties (SetAccess = private)
        monthLengths
        monthCount
        totalDays
    end
    properties (Access = private)
        suffixWeights
        suffixTotals
        exactCount
    end
    methods
        function obj=WholeMonthWeavingFamily(monthLengths)
            if ~(isnumeric(monthLengths) && isvector(monthLengths) && ...
                    ~isempty(monthLengths) && isreal(monthLengths) && ...
                    all(isfinite(monthLengths(:))) && ...
                    all(fix(monthLengths(:))==monthLengths(:)) && ...
                    all(monthLengths(:)>0) && all(monthLengths(:)<=flintmax))
                error('Pastafari:MonthWeaving:WholeFamilyLengths', ...
                    'monthLengths musi być niepustym dodatnim wektorem całkowitym.');
            end
            obj.monthLengths=double(monthLengths(:).');
            obj.monthCount=numel(obj.monthLengths);
            obj.totalDays=sum(obj.monthLengths);
            if ~isfinite(obj.totalDays) || obj.totalDays>flintmax
                error('Pastafari:MonthWeaving:WholeFamilyLengths','Total days must be exact.');
            end
            [obj.suffixWeights,obj.suffixTotals]=buildReverseSuffixes(obj.monthLengths);
            obj.exactCount=obj.suffixTotals{1};
        end
        function total=count(obj)
            total=obj.exactCount;
        end
        function weaving=itemAt1(obj,rank1)
            pastafari.ValidationManager.requireExactIntegerInput(rank1);
            rank=pastafari.BigInt.coerce(rank1);
            one=pastafari.BigInt(1);
            if rank<one || rank>obj.exactCount
                error('Pastafari:MonthWeaving:WholeFamilyRank', ...
                    'Rank musi należeć do 1..count whole-weave family.');
            end
            % Cache is instance-scoped. Consume it for a full traversal;
            % repeat calls rebuild it deterministically, with the same count.
            if isempty(obj.suffixWeights)
                [obj.suffixWeights,obj.suffixTotals]=buildReverseSuffixes(obj.monthLengths);
                assert(obj.suffixTotals{1}==obj.exactCount,'Reverse:RebuildCount');
            end
            W=obj.suffixWeights; T=obj.suffixTotals;
            obj.suffixWeights={}; obj.suffixTotals={};
            L=obj.monthLengths; R=L; K=obj.monthCount; k=0; c=0;
            parent=obj.exactCount; weaving=zeros(1,obj.totalDays);
            trace=strcmp(getenv('PASTAFARI_STAGE54_DIAGNOSTICS'),'1');
            timer=tic;
            for p=1:obj.totalDays
                choices=[];
                for i=c+1:K
                    if i<=k+1 && (R(i)>1 || i==c+1)
                        choices(end+1)=i; %#ok<AGROW>
                    end
                end
                assert(~isempty(choices),'Reverse:NoChoice');
                blocks=cell(1,K);
                if numel(choices)==1
                    blocks{choices(1)}=parent;
                elseif k==K
                    blocks=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator(R,c,parent);
                else
                    O=R(c+1:k); g=sum(O);
                    E=weightedExternal(g-1,R(k+1:end),W{k+1},T{k+1});
                    A=internal(O);
                    ib=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator(O,0,A);
                    rest=parent;
                    for i=choices(choices<=k)
                        blocks{i}=ib{i-c}*E;
                        rest=rest-blocks{i};
                    end
                    if any(choices==k+1)
                        blocks{k+1}=rest;
                    else
                        assert(rest==pastafari.BigInt(0),'Reverse:Residual');
                    end
                end
                s=pastafari.BigInt(0);
                for i=choices
                    assert(~isempty(blocks{i}) && blocks{i}>=one,'Reverse:Positive');
                    s=s+blocks{i};
                end
                assert(s==parent,'Reverse:Partition');
                selected=0;
                for i=choices
                    if rank>blocks{i}
                        rank=rank-blocks{i};
                    else
                        selected=i; parent=blocks{i}; break
                    end
                end
                assert(selected>0 && rank>=one && rank<=parent,'Reverse:RankBounds');
                if R(selected)==L(selected)
                    k=k+1;
                    % The old unopened suffix is never needed again.
                    W{k}=[]; T{k}=[];
                end
                if R(selected)==1, c=c+1; end
                R(selected)=R(selected)-1;
                weaving(p)=selected;
                if trace && (p<=4 || mod(p,64)==0 || p==obj.totalDays)
                    fprintf('STAGE_54_REVERSE_WEAVE POSITION=%d/%d SECONDS=%.3f\n',p,obj.totalDays,toc(timer));
                end
            end
            if any(R~=0) || k~=K || c~=K || parent~=one || rank~=one
                error('Pastafari:MonthWeaving:WholeFamilyInvariant', ...
                    'Whole-weave unrank did not terminate in a singleton.');
            end
        end
    end
end

function n=weightedExternal(g,U,F,total)
% Same exact reverse-label insertion recurrence as the certified candidate.
assert(g>=0 && fix(g)==g && ~isempty(U),'Reverse:ExternalInput');
if g==0, n=total; return; end
N=sum(U); n=pastafari.BigInt(0); B=pastafari.BigInt(1);
for p=N:-1:1
    if ~isempty(F{p}), n=n+B*F{p}; end
    if p>1
        numerator=B*pastafari.BigInt(g+N-p+1);
        [B,rem]=numerator.floorDivMod(pastafari.BigInt(N-p+1));
        assert(rem.iszero(),'Reverse:Binomial');
    end
end
assert(n>=pastafari.BigInt(1),'Reverse:Nonpositive');
end

function n=internal(O)
n=pastafari.BigInt(1); s=0;
for m=O
    s=s+m; b=pastafari.BigInt(1);
    z=min(m-1,s-m);
    for j=1:z
        numerator=b*pastafari.BigInt(s-z+j-1);
        [b,rem]=numerator.floorDivMod(pastafari.BigInt(j));
        assert(rem.iszero(),'Grouped:Binomial');
    end
    n=n*b;
end
end

function [cache,totals]=buildReverseSuffixes(U)
% Reverse insertion DP: all unopened labels in first AND last order.
K=numel(U); keep=K; N=0; F={}; one=pastafari.BigInt(1); zero=pastafari.BigInt(0);
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
    cache{k+1}=F; totals{k+1}=total;
end
assert(all(~cellfun(@isempty,cache)),'Reverse:MissingCache');
end
