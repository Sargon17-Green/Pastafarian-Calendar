function run_stage55_production_reverse_gate()
% Native differential for the actual production family, independent tiny
% lexical enumeration and previously independently certified real-year word.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
out=fullfile(root,'logs','stage55_production_reverse');
if ~isfolder(out), mkdir(out); end
timer=tic; families=0; words=0;
for K=1:4
    for code=0:3^K-1
        L=1+mod(floor(code./(3.^(0:K-1))),3);
        if sum(L)>10, continue; end
        expected=enumerate(L,L,[]);
        f=pastafari.WholeMonthWeavingFamily(L(:));
        assert(f.count()==pastafari.BigInt(size(expected,1)),'Production:Count');
        for r=1:size(expected,1)
            assert(isequal(f.itemAt1(pastafari.BigInt(r)),expected(r,:)),'Production:Word');
            words=words+1;
        end
        assert(isequal(f.itemAt1(pastafari.BigInt(1)),expected(1,:)),'Production:Repeat');
        reject(@() f.itemAt1(pastafari.BigInt(0)));
        reject(@() f.itemAt1(f.count()+pastafari.BigInt(1)));
        families=families+1;
    end
end
assert(families==115 && words==1408,'Production:TinyCoverage');
fprintf('PRODUCTION_TINY_PASS families=%d words=%d\n',families,words);
m=jsondecode(fileread(fullfile(root,'tests','fixtures','stage55_year5000_appendix_a_metadata.json')));
L=double(m.month_lengths(:).');
assert(numel(L)==45 && sum(L)==4244);
f=pastafari.WholeMonthWeavingFamily(L);
count=f.count(); rank=count.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1);
write(fullfile(out,'count.txt'),char(count));
write(fullfile(out,'rank.txt'),char(rank));
actual=f.itemAt1(rank);
% Expected word is read only AFTER production returns.
expected=jsondecode(fileread(fullfile(root,'tests','fixtures','stage55_year5000_middle_word.json')));
assert(isequal(actual,double(expected(:).')),'Production:MiddleWord');
write(fullfile(out,'word.json'),[jsonencode(actual) newline]);
t=regexp(fileread('/proc/self/status'),'VmHWM:\s+(\d+)\s+kB','tokens','once');
assert(~isempty(t),'Production:RSSMissing');
rss=str2double(t{1}); elapsed=toc(timer);
assert(rss>0 && rss<3*1024*1024 && elapsed<9600,'Production:Resource');
write(fullfile(out,'report.json'),jsonencode(struct('sha',getenv('GITHUB_SHA'),'families',families,'words',words,'positions',numel(actual),'rss_kib',rss,'elapsed',elapsed,'production_used',true)));
fprintf('PRODUCTION_REVERSE_NATIVE_PASS 4244/4244\n');
end

function W=enumerate(L,R,prefix)
if all(R==0), W=prefix; return; end
W=zeros(0,sum(L));
for i=1:numel(L)
    if R(i)==0, continue; end
    if R(i)==L(i) && any(R(1:i-1)==L(1:i-1)), continue; end
    if R(i)==1 && any(R(1:i-1)>0), continue; end
    next=R; next(i)=next(i)-1;
    W=[W;enumerate(L,next,[prefix i])]; %#ok<AGROW>
end
end
function reject(fn)
try
    fn();
catch ME
    assert(strcmp(ME.identifier,'Pastafari:MonthWeaving:WholeFamilyRank'));
    return
end
error('Production:MissingRankRejection','Invalid rank accepted.');
end
function write(path,s)
[f,msg]=fopen(path,'w','n','UTF-8'); assert(f>=0,msg);
guard=onCleanup(@() fclose(f)); %#ok<NASGU>
assert(fwrite(f,s,'char')==numel(s));
end
