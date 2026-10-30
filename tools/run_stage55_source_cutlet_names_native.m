function run_stage55_source_cutlet_names_native()
% Bounded Year-5000 source provenance: cutlet partition and both name maps.
root=fileparts(fileparts(mfilename('fullpath')));
srcDir=fullfile(root,'src'); addpath(srcDir);
pathGuard=onCleanup(@() rmpath(srcDir)); %#ok<NASGU>
logDir=fullfile(root,'logs');
if exist(logDir,'dir')~=7, mkdir(logDir); end
diary(fullfile(logDir,'STAGE55_SOURCE_CUTLET_NAMES_NATIVE.log'));
diaryGuard=onCleanup(@() diary('off')); %#ok<NASGU>
fprintf('STAGE55_SOURCE_CUTLET_NAMES_BEGIN\n');
f=jsondecode(fileread(fullfile(root,'tests','fixtures', ...
    'stage55_year5000_appendix_a_metadata.json')));
assert(f.year==5000 && f.calculation_day==-15055671 && ...
    f.first_day==-15057702 && f.last_day==-15053459 && ...
    f.cutlet_count==6 && f.months==45 && ...
    f.open_gate_index==-4 && f.close_gate_index==4, ...
    'Stage55:MetadataShape');
c=pastafari.BigInt(f.calculation_day);
t=pastafari.BigInt(f.first_day);
sauce=pastafari.sauceWithCurrentScars(c,t);
catalog=pastafari.sourceLanguageCatalog();
assert(numel(catalog.cutlets)==17 && numel(catalog.months)==47, ...
    'Stage55:CatalogShape');
G=f.close_gate_index-f.open_gate_index;
candidateCounts=6:min(17,G);
r=rankFromSauce(sauce,2,20,pastafari.BigInt(numel(candidateCounts)));
K=candidateCounts(r.toDoubleExact());
assert(K==6,'Stage55:CutletCountMismatch');
ctx=pastafari.MonsterContext(c,t);
next=pastafari.LatchedSuccessorPatch.apply(sauce.orderAt46Latch,2);
stream=pastafari.AnswerRingStreamFactory.fromSauce( ...
    sauce.bowls,2,next,21);
[ctx,partition]=pastafari.CutletPartitionCompatibilityRoute.call( ...
    ctx,stream,pastafari.BigInt(G),pastafari.BigInt(K), ...
    pastafari.BigInt(-f.open_gate_index));
assert(isequal(double(partition(:).'), ...
    double(f.cutlet_gate_partition(:).')) && ...
    any(strcmp(ctx.branchTrace,'PATCH_21_FILTERED_PARTITION_FAMILY')), ...
    'Stage55:SourceCutletPartitionMismatch');
fprintf('STAGE55_SOURCE_CUTLET_PARTITION_PASS GAPS=%d CUTLETS=%d\n',G,K);
cutletN=permutationCount(17,K);
monthN=permutationCount(47,f.months);
cr=rankFromSauce(sauce,5,22,cutletN);
mr=rankFromSauce(sauce,5,33,monthN);
indCutlets=independentUnrank(17,K,cr);
indMonths=independentUnrank(47,f.months,mr);
assert(isequal(indCutlets,double(f.cutlet_name_indices(:).')) && ...
    isequal(indMonths,double(f.month_name_indices(:).')), ...
    'Stage55:SourceNameFixtureMismatch');
[ctx,productionCutlets]=pastafari.CutletNameCompatibilityRoute.call( ...
    ctx,sauce,pastafari.BigInt(K));
[ctx,productionMonths]=pastafari.MonthNameCompatibilityRoute.call( ...
    ctx,sauce,pastafari.BigInt(f.months));
assert(isequal(productionCutlets,indCutlets) && ...
    isequal(productionMonths,indMonths) && ...
    sum(strcmp(ctx.branchTrace,'PATCH_22_DISTINCT_NAME_DETOUR'))==2, ...
    'Stage55:ProductionNamesMismatch');
fprintf('STAGE55_SOURCE_NAMES_PASS CUTLETS=6 MONTHS=45 INDICES=51 CUTLET_RANK=%s MONTH_RANK=%s\n', ...
    char(cr),char(mr));
for i=1:60
    k=pastafari.BigInt(i);
    assert(isequal(independentUnrank(5,3,k), ...
        pastafari.partialPermutationNameRowUnrank( ...
        pastafari.BigInt(5),pastafari.BigInt(3),k)), ...
        'Stage55:SmallNameUnrankMismatch');
end
fprintf('STAGE55_SOURCE_CUTLET_NAMES_NATIVE_PASS YEAR=5000 CUTLETS=6 MONTHS=45 NAME_INDICES=51 SMALL_CASES=60\n');
fprintf('STAGE55_INDEPENDENT_CUTLET_DAY_LENGTHS_NOT_VERIFIED\n');
fprintf('STAGE55_MIDDLE_WEAVE_FIVE_FIELD_ORACLE_NOT_VERIFIED\n');
fprintf('STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED\n');
fprintf('STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED\n');
end

function N=permutationCount(master,k)
N=pastafari.BigInt(1);
for i=0:k-1, N=N*pastafari.BigInt(master-i); end
end

function rank=rankFromSauce(sauce,bowl,seal,N)
one=pastafari.BigInt(1); zero=pastafari.BigInt(0);
M=pastafari.BigInt('170141183460469231731687303715884105727');
next=pastafari.LatchedSuccessorPatch.apply(sauce.orderAt46Latch,bowl);
stream=pastafari.AnswerRingStreamFactory.fromSauce( ...
    sauce.bowls,bowl,next,seal);
base=sauce.bowls{bowl}+pastafari.BigInt(seal+181);
raw=base.square()+pastafari.BigInt(179)*sauce.bowls{next}+ ...
    pastafari.BigInt(seal);
first=raw.regularMod(M);
if first==zero, first=M; end
directionBase=first+pastafari.BigInt(seal+194);
directionRaw=directionBase.square()+pastafari.BigInt(193)*first+ ...
    pastafari.BigInt(197)*sauce.bowls{6};
d=directionRaw.regularMod(M);
if d==zero, d=M; end
if d.regularMod(pastafari.BigInt(2))==one, step=1; else, step=-1; end
assert(stream.first==first && stream.directionStep==step, ...
    'Stage55:SourceRingMismatch');
space=one; places=0;
while space<N
    space=space*M; places=places+1;
    assert(places<=4,'Stage55:SelectionWidth');
end
wide=one; weight=one;
for j=0:places-1
    delta=first-one+pastafari.BigInt(step)*pastafari.BigInt(j);
    digit=delta.regularMod(M);
    assert(pastafari.AnswerRingStreamFactory.answerAt( ...
        stream,pastafari.BigInt(j))==digit+one, ...
        'Stage55:RingDigitMismatch');
    wide=wide+digit*weight; weight=weight*M;
end
limit=space.floorDiv(N)*N;
if wide<=limit
    accepted=wide;
elseif step==1
    accepted=one;
else
    accepted=limit;
end
offset=accepted-one;
rank=offset.regularMod(N)+one;
assert(rank>=one && rank<=N,'Stage55:SourceRankBound');
end

function out=independentUnrank(master,k,rank)
one=pastafari.BigInt(1); zero=pastafari.BigInt(0);
r=rank-one; left=1:master; out=zeros(1,k);
for p=1:k
    block=one;
    for j=0:k-p-1, block=block*pastafari.BigInt(numel(left)-1-j); end
    quotient=r.floorDiv(block);
    pos=quotient.toDoubleExact()+1;
    assert(pos>=1 && pos<=numel(left),'Stage55:NamePosition');
    out(p)=left(pos);
    left(pos)=[];
    r=r.regularMod(block);
end
assert(r==zero,'Stage55:NameRemainder');
end
