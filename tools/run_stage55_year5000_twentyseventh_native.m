function run_stage55_year5000_twentyseventh_native()
% Stage55 AFTER26 to AFTER27: bounded MATLAB exact cursor and PATCH25 comparison.
root=fileparts(fileparts(mfilename('fullpath')));
src=fullfile(root,'src'); addpath(src);
cleanupPath=onCleanup(@()rmpath(src)); %#ok<NASGU>
logs=fullfile(root,'logs'); if exist(logs,'dir')~=7, mkdir(logs); end
diary(fullfile(logs,'STAGE55_TWENTYSEVENTH_NATIVE.log'));
cleanupDiary=onCleanup(@()diary('off')); %#ok<NASGU>
f=jsondecode(fileread(fullfile(root,'tests','fixtures','stage55_year5000_appendix_a_metadata.json')));
L=double(f.month_lengths(:).');
assert(f.year==5000 && numel(L)==45 && sum(L)==4244 && f.first_day==-15057702,'Stage55:Fixture');
[original,before]=pastafari.restoreExactWeaveCursorJson(fileread(fullfile(logs,'STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_26.json')));
expected=L; prefix=[1 2 3 4 5 6 7 4 8 9 10 9 11 6 12 13 14 15 16 16 17 7 18 2 19 20]; for k=prefix, expected(k)=expected(k)-1; end; one=pastafari.BigInt(1);
assert(isequal(original,L) && isequal(before.remaining,expected) && before.stepsComputed==26 && ...
 before.openedUpTo==20 && before.closedUpTo==0 && ~before.done && sum(before.remaining)==4218 && ...
 before.rank>=one && before.rank<=before.count,'Stage55:After25');
t=tic;
[letter,after]=pastafari.unrankGeneralWeaveSuffixChunkAdjoint(original,before.remaining,20,0,before.rank,1);
selectionSeconds=toc(t);
n=before.remaining(letter); r=before.remaining; r(letter)=r(letter)-1;
assert(isscalar(letter) && letter==19 && n>1 && ...
 after.stepsComputed==1 && after.initialCount==before.count && ...
 isequal(after.remaining,r) && (letter==before.openedUpTo+1)==(n==L(letter)) && ...
 after.openedUpTo==20 && after.closedUpTo==0 && ...
 ~after.done && sum(after.remaining)==4217 && ...
 after.rank>=one && after.rank<=after.count,'Stage55:After25Selection');
t=tic;
recount=pastafari.countWholeWeavingSuffixByFirstEndpoint(after.remaining,after.openedUpTo,after.closedUpTo);
recountSeconds=toc(t);
assert(recount==after.count && after.count<=before.count,'Stage55:After25Recount');
after.stepsComputed=27;
body=pastafari.serializeExactWeaveCursorJson(original,after);
dest=fullfile(logs,'STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_27.json');
[fid,msg]=fopen(dest,'w','n','UTF-8');
assert(fid>=0,'Stage55:After25Write',msg);
closeGuard=onCleanup(@()fclose(fid)); %#ok<NASGU>
assert(fwrite(fid,body,'char')==numel(body),'Stage55:After25Truncated');
clear closeGuard
assert(strcmp(fileread(dest),body),'Stage55:After25Readback');
weave=[prefix letter]; position=27;
day=pastafari.BigInt(f.first_day+position-1);
yearOpen=pastafari.BigInt(f.first_day-1);
ctx=pastafari.MonsterContext(pastafari.BigInt(f.calculation_day),day);
[ctx,monthId,monthDay]=pastafari.MonthDayCompatibilityRoute.call(ctx,weave,yearOpen,day);
occ=sum(weave==letter); names=double(f.month_name_indices(:).');
catalog=pastafari.sourceLanguageCatalog();
fields={pastafari.BigInt(5000),catalog.cutlets(15).text,pastafari.BigInt(27), ...
 catalog.months(names(letter)).text,monthDay};
assert(numel(fields)==5 && names(letter)==27 && fields{1}==pastafari.BigInt(5000) && strcmp(fields{2},'Akad') && ...
 fields{3}==pastafari.BigInt(27) && strcmp(fields{4},catalog.months(names(letter)).text) && ...
 fields{5}==pastafari.BigInt(occ) && monthId==letter && ...
 any(strcmp(ctx.branchTrace,'PATCH_25_OCCURRENCE_COUNT')),'Stage55:FiveFields');
assert(position==after.stepsComputed && position==27,'Stage55:RowPosition');
fprintf('STAGE55_TWENTYSEVENTH_ROW POSITION=%d YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=%d MONTH_INDEX=%d MONTH_DAY=%d\n',position,position,names(letter),occ);
for bad=[0 28]
 target=pastafari.BigInt(f.first_day+bad-1);
 invalid=pastafari.MonsterContext(pastafari.BigInt(f.calculation_day),target);
 rejected=false;
 try
  pastafari.MonthDayCompatibilityRoute.call(invalid,weave,yearOpen,target);
 catch err
  rejected=strcmp(err.identifier,'Pastafari:MonthDay:TargetOutsideYear');
 end
 assert(rejected,'Stage55:InvalidPosition');
end
fprintf('STAGE55_TWENTYSEVENTH_NATIVE_PASS STEPS=27 REMAINING=4217 LETTER=%d SELECT_SEC=%.3f RECOUNT_SEC=%.3f REJECTED=2\n',letter,selectionSeconds,recountSeconds);
fprintf('STAGE55_FULL_YEAR_CANONICAL_ORACLE_NOT_VERIFIED\n');
fprintf('STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED\n');
fprintf('STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED\n');
end
