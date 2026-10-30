function run_stage55_source_month_rank_native()
% Stage 55: bounded source-language selection provenance for Year 5000.
% This does NOT certify cutlet/name provenance, a middle weaving, the
% five-field full-year oracle, or cross-engine Soak.
root=fileparts(fileparts(mfilename('fullpath')));
srcDir=fullfile(root,'src');
addpath(srcDir);
pathGuard=onCleanup(@() rmpath(srcDir)); %#ok<NASGU>
logDir=fullfile(root,'logs');
if exist(logDir,'dir')~=7, mkdir(logDir); end
diary(fullfile(logDir,'STAGE55_SOURCE_MONTH_RANK_NATIVE.log'));
diaryGuard=onCleanup(@() diary('off')); %#ok<NASGU>
fprintf('STAGE55_SOURCE_MONTH_RANK_PROBE_STARTED\n');

f=jsondecode(fileread(fullfile(root,'tests','fixtures', ...
    'stage55_year5000_appendix_a_metadata.json')));
assert(f.year==5000 && f.calculation_day==-15055671 && ...
    f.first_day==-15057702 && f.last_day==-15053459 && ...
    f.months==45 && sum(double(f.month_lengths))==4244, ...
    'Stage55:YearFixtureShape');
one=pastafari.BigInt(1);
M=pastafari.BigInt('170141183460469231731687303715884105727');
N=pastafari.BigInt( ...
    '28267369127220710176329716843724118975520840014877906533654334421021017631241800900');
certifiedRank=pastafari.BigInt( ...
    '21706039149316943527912320903423885398156086660670683714452395033170314294340946533');
cDay=pastafari.BigInt(f.calculation_day);
firstDay=pastafari.BigInt(f.first_day);

% Production source-language structure sauce: PATCH20 uses first day.
sauce=pastafari.sauceWithCurrentScars(cDay,firstDay);
assert(sauce.calculationDay==cDay && sauce.targetDay==firstDay && ...
    iscell(sauce.bowls) && numel(sauce.bowls)==6, ...
    'Stage55:SourceSauceProvenance');
order=double(sauce.orderAt46Latch(:).');
assert(isequal(sort(order),1:6),'Stage55:SourceLatchInvalid');
i=find(order==3,1,'first');
nextBowl=order(mod(i,6)+1);
assert(nextBowl==pastafari.LatchedSuccessorPatch.apply(order,3), ...
    'Stage55:SourceSuccessorMismatch');
stream=pastafari.AnswerRingStreamFactory.fromSauce( ...
    sauce.bowls,3,nextBowl,31);

% Independent arithmetic derivation from the six authoritative bowls.
firstBase=sauce.bowls{3}+pastafari.BigInt(212); % 31+181
firstRaw=firstBase.square()+pastafari.BigInt(179)* ...
    sauce.bowls{nextBowl}+pastafari.BigInt(31);
first=firstRaw.regularMod(M);
if first.iszero(), first=M; end
directionBase=first+pastafari.BigInt(225); % 31+1+193
directionRaw=directionBase.square()+pastafari.BigInt(193)*first+ ...
    pastafari.BigInt(197)*sauce.bowls{6};
directionNumber=directionRaw.regularMod(M);
if directionNumber.iszero(), directionNumber=M; end
if directionNumber.regularMod(pastafari.BigInt(2))==one
    direction=1;
else
    direction=-1;
end
assert(stream.first==first && stream.directionStep==direction, ...
    'Stage55:SourceAnswerRingMismatch');
fprintf('STAGE55_SOURCE_MONTH_RANK_SAUCE_AND_RING_VERIFIED NEXT_BOWL=%d DIRECTION=%d\n', ...
    nextBowl,direction);

% Derive the exact wide-selector rank without enumerating any compositions.
space=one;
places=0;
while space<N
    space=space*M;
    places=places+1;
    assert(places<=4,'Stage55:SelectorPlaceBound');
end
assert(places==3,'Stage55:UnexpectedYear5000SelectorWidth');
wide=one;
weight=one;
for j=0:places-1
    offset=first-one+pastafari.BigInt(direction)*pastafari.BigInt(j);
    digit=offset.regularMod(M);
    answer=pastafari.AnswerRingStreamFactory.answerAt( ...
        stream,pastafari.BigInt(j));
    assert(answer==digit+one,'Stage55:AnswerDigitMismatch');
    wide=wide+digit*weight;
    weight=weight*M;
end
assert(wide>=one && wide<=space,'Stage55:WideValueOutOfRange');
limit=space.floorDiv(N)*N;
% Exact O(1) ring rejection resolution: no unbounded stepping.
if wide<=limit
    accepted=wide;
    rejectionSteps=pastafari.BigInt(0);
else
    if direction==1
        accepted=one;
        rejectionSteps=space-wide+one;
    else
        accepted=limit;
        rejectionSteps=wide-limit;
    end
end
rank=(accepted-one).regularMod(N)+one;
assert(rank>=one && rank<=N,'Stage55:SelectedRankOutOfRange');

% Compare with production Patch14, but only on the non-reject path;
% no potentially huge rejection loop is permitted in this bounded test.
if wide<=limit
    [productionRank,productionWide,productionAccepted, ...
        productionPlaces,productionSpace,productionLimit,productionSteps]= ...
        pastafari.WideSelectionDetourPatch.apply(stream,N);
    assert(productionRank==rank && productionWide==wide && ...
        productionAccepted==accepted && productionPlaces==places && ...
        productionSpace==space && productionLimit==limit && ...
        productionSteps==rejectionSteps, ...
        'Stage55:ProductionSelectionMismatch');
    fprintf('STAGE55_SOURCE_MONTH_RANK_PRODUCTION_PATCH14_AGREES\n');
else
    fprintf('STAGE55_SOURCE_MONTH_RANK_REJECTION_WEDGE_BOUNDED_STEPS=%s\n', ...
        char(rejectionSteps));
end
fprintf('STAGE55_SOURCE_MONTH_RANK_ACTUAL=%s\n',char(rank));
fprintf('STAGE55_SOURCE_MONTH_RANK_CERTIFIED=%s\n',char(certifiedRank));
fprintf('STAGE55_SOURCE_MONTH_RANK_REJECTION_STEPS=%s\n', ...
    char(rejectionSteps));
if rank~=certifiedRank
    error('Pastafari:Stage55:MonthRankFixtureMismatch', ...
        'Source stream selects a different rank than certified fixture.');
end
fprintf(['STAGE55_SOURCE_MONTH_SELECTION_RANK_NATIVE_PASS ', ...
    'YEAR=5000 MONTHS=45 DAYS=4244 BOWLS=6 PLACES=%d\n'],places);
fprintf('STAGE55_CUTLET_NAME_MIDDLE_WEAVE_FIVE_FIELD_ORACLE_NOT_VERIFIED\n');
fprintf('STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED\n');
fprintf('STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED\n');
end
