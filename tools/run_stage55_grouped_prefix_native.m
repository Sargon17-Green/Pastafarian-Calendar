function run_stage55_grouped_prefix_native()
% Experimental grouped suffix gate only. Never call production.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
out=fullfile(root,'logs','stage55_grouped_prefix');
if ~exist(out,'dir'), mkdir(out); end
timer=tic;
fprintf('GROUPED_BEGIN SHA=%s MATLAB=%s\n',getenv('GITHUB_SHA'),version);
[nf,ns,ne]=tinyGate();
assert(isequal([nf ns ne],[115 1335 1697]),'Grouped:TinyCoverage');
fprintf('GROUPED_TINY_PASS families=%d states=%d blocks=%d\n',nf,ns,ne);
writeText(fullfile(out,'tiny.json'),jsonencode(struct('families',nf,'states',ns,'blocks',ne)));
m=jsondecode(fileread(fullfile(root,'tests','fixtures','stage55_year5000_appendix_a_metadata.json')));
L=double(m.month_lengths(:).');
W=double(jsondecode(fileread(fullfile(root,'tests','fixtures','stage55_year5000_middle_word.json'))));
W=W(:).';
assert(m.year==5000 && numel(L)==45 && sum(L)==4244 && numel(W)==4244);
R=L; k=0; c=0;
t=tic; count=external(0,L); rootSeconds=toc(t);
rank=count.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1);
writeText(fullfile(out,'root_count.txt'),char(count));
writeText(fullfile(out,'root_rank.txt'),char(rank));
fprintf('GROUPED_ROOT seconds=%.3f digits=%d\n',rootSeconds,numel(char(count)));
% Measure actual arithmetic primitives on this operand size, not a proxy.
a=pastafari.BigInt(123); t=tic; b=count*a; mul=toc(t);
t=tic; [q,rem]=b.floorDivMod(a); div=toc(t);
assert(q==count && rem.iszero());
writeText(fullfile(out,'profile.json'),jsonencode(struct('root_seconds',rootSeconds,'sample_multiply_seconds',mul,'sample_divide_seconds',div,'root_limbs',numel(count.limbs))));
prefix=zeros(1,12);
for p=1:12
    assert(toc(timer)<1800-240,'Grouped:SoftBudget');
    t=tic;
    [choices,blocks,extCalls,externalSeconds]=partition(L,R,k,c,count);
    selected=0;
    for i=choices
        b=blocks{i};
        if rank>b, rank=rank-b; else, selected=i; count=b; break; end
    end
    assert(selected==W(p) && rank>=pastafari.BigInt(1) && rank<=count,'Grouped:PrefixMismatch');
    [R,k,c]=advance(L,R,k,c,selected);
    prefix(p)=selected;
    elapsed=toc(t);
    row=struct('position',p,'symbol',selected,'count',char(count),'local_rank',char(rank),'legal_blocks',numel(choices),'remaining',R,'opened',k,'closed',c,'prefix',{num2cell(prefix(1:p))},'peak_rss_kib',peakRSS(),'seconds',elapsed,'external_calls',extCalls,'external_seconds',externalSeconds,'elapsed',toc(timer),'sha',getenv('GITHUB_SHA'));
    writeText(fullfile(out,sprintf('cursor_%02d.json',p)),jsonencode(row));
    fprintf('GROUPED_POSITION %d/12 SYMBOL=%d BLOCKS=%d EXTERNAL=%d SECONDS=%.3f ELAPSED=%.3f\n',p,selected,numel(choices),extCalls,elapsed,toc(timer));
end
writeText(fullfile(out,'native_complete.json'),jsonencode(struct('positions',12,'sha',getenv('GITHUB_SHA'),'production_used',false,'stage55_accepted',false,'elapsed',toc(timer))));
fprintf('GROUPED_PREFIX_NATIVE_COMPLETE 12/12 STAGE55=OPEN\n');
end

function n=external(g,U)
r=U;
if g>0, r=[g U]; end
if isempty(r), n=pastafari.BigInt(1); else, n=pastafari.countWholeWeavingSuffixByFirstEndpoint(r,double(g>0),0); end
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

function [choices,blocks,calls,seconds]=partition(L,R,k,c,parent)
K=numel(L); choices=[];
for i=c+1:K
    if (i<=k || i==k+1) && (R(i)>1 || i==c+1)
        choices(end+1)=i; %#ok<AGROW>
    end
end
one=pastafari.BigInt(1); zero=pastafari.BigInt(0);
assert(parent>=one);
blocks=cell(1,K); calls=0; seconds=0;
if isempty(choices), assert(all(R==0) && parent==one); return; end
if numel(choices)==1, blocks{choices(1)}=parent; return; end
if k==K
    blocks=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator(R,c,parent);
else
    O=R(c+1:k); g=sum(O); U=R(k+1:end);
    t=tic; E=external(g-1,U); seconds=toc(t); calls=1;
    A=internal(O);
    ib=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator(O,0,A);
    rest=parent;
    for i=choices(choices<=k)
        blocks{i}=ib{i-c}*E;
        rest=rest-blocks{i};
    end
    if any(choices==k+1), blocks{k+1}=rest; else, assert(rest==zero); end
end
s=zero;
for i=choices
    assert(~isempty(blocks{i}) && blocks{i}>=one,'Grouped:Positive');
    s=s+blocks{i};
end
assert(s==parent,'Grouped:Partition');
end

function [R,k,c]=advance(L,R,k,c,i)
if R(i)==L(i), k=k+1; end
if R(i)==1, c=c+1; end
R(i)=R(i)-1;
end

function [families,states,edges]=tinyGate()
families=0; states=0; edges=0;
for K=1:4
    for code=0:3^K-1
        L=1+mod(floor(code./(3.^(0:K-1))),3);
        if sum(L)>10, continue; end
        memo=containers.Map('KeyType','char','ValueType','double');
        direct(L,L,memo);
        keysNow=keys(memo);
        families=families+1;
        for z=1:numel(keysNow)
            R=sscanf(keysNow{z},'%d,').';
            k=find(R<L,1,'last'); if isempty(k), k=0; end
            c=find(R>0,1,'first'); if isempty(c), c=K+1; end; c=c-1;
            truth=memo(keysNow{z});
            assert(internal(R(c+1:k))*external(sum(R(c+1:k)),R(k+1:end))==pastafari.BigInt(truth),'Grouped:TinyCount');
            [C,B]=partition(L,R,k,c,pastafari.BigInt(truth));
            D=directChoices(L,R);
            assert(isequal(C,D),'Grouped:TinyChoices');
            for i=D
                child=R; child(i)=child(i)-1;
                assert(B{i}==pastafari.BigInt(direct(L,child,memo)),'Grouped:TinyChild');
                edges=edges+1;
            end
            states=states+1;
        end
    end
end
end

function C=directChoices(L,R)
% Independent remaining-vector recursion, no factorization.
C=[];
for i=1:numel(L)
    if R(i)==0, continue; end
    if R(i)==L(i) && any(R(1:i-1)==L(1:i-1)), continue; end
    if R(i)==1 && any(R(1:i-1)>0), continue; end
    C(end+1)=i; %#ok<AGROW>
end
end

function n=direct(L,R,memo)
key=sprintf('%d,',R);
if isKey(memo,key), n=memo(key); return; end
if all(R==0), n=1; else
    n=0;
    for i=directChoices(L,R)
        child=R; child(i)=child(i)-1;
        n=n+direct(L,child,memo);
    end
end
memo(key)=n;
end

function kib=peakRSS()
% Linux Native process high-water RSS, not total runner memory.
kib=-1;
if isfile('/proc/self/status')
    token=regexp(fileread('/proc/self/status'),'VmHWM:\s+(\d+)\s+kB','tokens','once');
    if ~isempty(token), kib=str2double(token{1}); end
end
end

function writeText(path,s)
tmp=[path '.tmp']; [f,msg]=fopen(tmp,'w','n','UTF-8'); assert(f>=0,msg);
guard=onCleanup(@() fclose(f));
assert(fwrite(f,s,'char')==numel(s));
clear guard
[ok,msg]=movefile(tmp,path,'f'); assert(ok,msg);
end
