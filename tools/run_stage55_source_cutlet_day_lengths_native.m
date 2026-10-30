function run_stage55_source_cutlet_day_lengths_native()
% Stage55: eight signed gate questions, six true cutlet day lengths.
% This derives day lengths from production gate questions, NOT from
% the fixture vector. It is not independent of the gate engine.
root=fileparts(fileparts(mfilename('fullpath')));
srcDir=fullfile(root,'src');
addpath(srcDir);
pathGuard=onCleanup(@() rmpath(srcDir)); %#ok<NASGU>
logDir=fullfile(root,'logs');
if exist(logDir,'dir')~=7, mkdir(logDir); end
diary(fullfile(logDir,'STAGE55_SOURCE_CUTLET_DAYS_NATIVE.log'));
diaryGuard=onCleanup(@() diary('off')); %#ok<NASGU>
fprintf('STAGE55_SOURCE_CUTLET_DAYS_BEGIN\n');
f=jsondecode(fileread(fullfile(root,'tests','fixtures', ...
    'stage55_year5000_appendix_a_metadata.json')));
assert(f.year==5000 && f.calculation_day==-15055671 && ...
    f.open_gate_index==-4 && f.close_gate_index==4 && ...
    f.first_day==-15057702 && f.last_day==-15053459 && ...
    f.cutlet_count==6,'Stage55:GateFixtureShape');
foundation=pastafari.BigInt('-15055671');
context=pastafari.MonsterContext(foundation,foundation);
zero=pastafari.BigInt(0);
gates=cell(1,9);
gates{5}=foundation;
signedQuestions=0;
% Production chooseYear5000: gate(-n)=gate(-(n-1))-gap(-n).
for step=-1:-1:-4
    [context,gap]=pastafari.GateGapCompatibilityRoute.call( ...
        context,pastafari.BigInt(step));
    qDay=foundation+pastafari.BigInt(step);
    direct=pastafari.GateQuestionEngine.gapForQuestionDay(qDay);
    assert(gap==direct && gap>zero, ...
        'Stage55:NegativeSignedGateDisagreement');
    gates{step+5}=gates{step+6}-gap;
    signedQuestions=signedQuestions+1;
end
% Production chooseYear5000: gate(+n)=gate(+(n-1))+gap(+n).
for step=1:4
    [context,gap]=pastafari.GateGapCompatibilityRoute.call( ...
        context,pastafari.BigInt(step));
    qDay=foundation+pastafari.BigInt(step);
    direct=pastafari.GateQuestionEngine.gapForQuestionDay(qDay);
    assert(gap==direct && gap>zero, ...
        'Stage55:PositiveSignedGateDisagreement');
    gates{step+5}=gates{step+4}+gap;
    signedQuestions=signedQuestions+1;
end
assert(signedQuestions==8 && ...
    sum(strcmp(context.branchTrace, ...
    'PATCH_15_SIGNED_GATE_QUESTION'))==8 && ...
    sum(strcmp(context.branchTrace, ...
    'DISCOVERY_15_POSITIVE_ONLY_GATE_QUESTION'))==8, ...
    'Stage55:SignedGateTraceCount');
assert(gates{1}+pastafari.BigInt(1)==pastafari.BigInt(f.first_day) && ...
    gates{9}==pastafari.BigInt(f.last_day), ...
    'Stage55:YearGateEndpoints');
gaps=zeros(1,8);
for k=1:8
    delta=gates{k+1}-gates{k};
    gaps(k)=delta.toDoubleExact();
    assert(gaps(k)>0 && gaps(k)<=963,'Stage55:GapBounds');
end
partition=double(f.cutlet_gate_partition(:).');
assert(numel(partition)==6 && sum(partition)==8 && ...
    all(partition>0),'Stage55:PartitionShape');
lengths=zeros(1,6);
start=1;
for k=1:6
    last=start+partition(k)-1;
    lengths(k)=sum(gaps(start:last));
    start=last+1;
end
assert(start==9 && sum(lengths)==4244 && ...
    all(lengths>0) && ...
    isequal(lengths,double(f.cutlet_day_lengths(:).')), ...
    'Stage55:SourceCutletDayLengthsMismatch');
assert(gates{9}-gates{1}==pastafari.BigInt(4244), ...
    'Stage55:YearSpan');
fprintf('STAGE55_SIGNED_GATE_NATIVE_PASS QUESTIONS=%d NEGATIVE=4 POSITIVE=4 GAPS=%s\n', ...
    signedQuestions,mat2str(gaps));
fprintf('STAGE55_SOURCE_CUTLET_DAY_LENGTHS_NATIVE_PASS YEAR=5000 CUTLETS=6 DAYS=4244 VALUES=%s\n', ...
    mat2str(lengths));
fprintf('STAGE55_GATE_ENGINE_INDEPENDENT_ORACLE_NOT_VERIFIED\n');
fprintf('STAGE55_MIDDLE_WEAVE_FIVE_FIELD_ORACLE_NOT_VERIFIED\n');
fprintf('STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED\n');
fprintf('STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED\n');
end
