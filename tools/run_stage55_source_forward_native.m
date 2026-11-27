function run_stage55_source_forward_native()
% Production selector + family, actual source rank (not middle).
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
out=fullfile(root,'logs','stage55_source_forward');
if ~isfolder(out), mkdir(out); end
timer=tic;
f=jsondecode(fileread(fullfile(root,'tests','fixtures','stage55_year5000_appendix_a_metadata.json')));
L=double(f.month_lengths(:).');
assert(numel(L)==45 && sum(L)==4244 && f.year==5000);
family=pastafari.WholeMonthWeavingFamily(L);
N=family.count();
s=pastafari.sauceWithCurrentScars(pastafari.BigInt(f.calculation_day),pastafari.BigInt(f.first_day));
order=double(s.orderAt46Latch(:).');
assert(isequal(sort(order),1:6));
next=pastafari.LatchedSuccessorPatch.apply(order,4);
stream=pastafari.AnswerRingStreamFactory.fromSauce(s.bowls,4,next,32);
[rank,~,~,places,~,~,steps]=pastafari.WideSelectionDetourPatch.apply(stream,N);
assert(places==177 && stream.directionStep==-1 && steps==pastafari.BigInt(0));
assert(rank~=N.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1));
write(fullfile(out,'native_count.txt'),char(N));
write(fullfile(out,'native_rank.txt'),char(rank));
actual=family.itemAt1(rank);
assert(numel(actual)==4244);
write(fullfile(out,'native_word.json'),[jsonencode(actual) newline]);
t=regexp(fileread('/proc/self/status'),'VmHWM:\s+(\d+)\s+kB','tokens','once');
assert(~isempty(t));
rss=str2double(t{1}); elapsed=toc(timer);
assert(rss>0 && rss<3*1024*1024 && elapsed<9600);
write(fullfile(out,'native_report.json'),jsonencode(struct('sha',getenv('GITHUB_SHA'),'positions',numel(actual),'rss_kib',rss,'elapsed',elapsed,'places',places,'production_used',true)));
fprintf('SOURCE_FORWARD_NATIVE_RETURNED 4244/4244\n');
end
function write(path,s)
[f,msg]=fopen(path,'w','n','UTF-8'); assert(f>=0,msg);
guard=onCleanup(@() fclose(f)); %#ok<NASGU>
assert(fwrite(f,s,'char')==numel(s));
end
