function run_stage55_checkpoint_json_tests()
% Native portable checkpoint correctness, BigInt-decimal roundtrips and
% tamper rejection; no format-specific trusted binary or double rank.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families={[1],[2 2],[2 3 2],[3 2 3],[3 3 3],[4 4 4]};
roundtrips=0;
for f=1:numel(families)
    L=families{f};
    legacy=pastafari.WholeMonthWeavingFamily(L);
    total=legacy.count();
    ranks={pastafari.BigInt(1), ...
        total.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1), ...
        total};
    for j=1:numel(ranks)
        initialRank=ranks{j};
        expected=legacy.itemAt1(initialRank);
        [part,c]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
            L,L,0,0,initialRank,2);
        json=pastafari.serializeExactWeaveCursorJson(L,c);
        [restoredL,rc]=pastafari.restoreExactWeaveCursorJson(json);
        assert(isequal(restoredL,L) && ...
            isequal(rc.remaining,c.remaining) && ...
            rc.openedUpTo==c.openedUpTo && ...
            rc.closedUpTo==c.closedUpTo && ...
            rc.rank==c.rank && rc.count==c.count && ...
            rc.done==c.done && ...
            rc.stepsComputed==c.stepsComputed && ...
            rc.initialCount==c.count, ...
            'Persisted checkpoint did not preserve exact cursor.');
        assembled=part;
        while ~rc.done
            [fragment,rc]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
                restoredL,rc.remaining,rc.openedUpTo, ...
                rc.closedUpTo,rc.rank,3);
            assembled=[assembled fragment]; %#ok<AGROW>
        end
        assert(isequal(assembled,expected), ...
            'Resumed weaving differs from independent production rank.');
        roundtrips=roundtrips+1;
    end
end
% JSON arrays may decode as columns, whereas fresh MATLAB cursor
% arrays are rows. Both orientations must round-trip identically.
L=[3 2 2 2];
[~,c]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
    L,L,0,0,pastafari.BigInt(1),3);
columnCursor=c;
columnCursor.remaining=c.remaining(:);
json=pastafari.serializeExactWeaveCursorJson(L(:),columnCursor);
[restoredL,restored]=pastafari.restoreExactWeaveCursorJson(json);
assert(isequal(restoredL,L) && ...
    isequal(restored.remaining,c.remaining) && ...
    restored.count==c.count && restored.rank==c.rank, ...
    'Column-vector JSON cursor changed exact BigInt or shape.');
fprintf('STAGE_55_CHECKPOINT_JSON_COLUMN_ORIENTATION_PASS\n');

fprintf(['STAGE_55_CHECKPOINT_JSON_RESUME_PASS ', ...
    'FAMILIES=%d ROUNDS=%d\n'],numel(families),roundtrips);

L=[3 3 3];
legacy=pastafari.WholeMonthWeavingFamily(L);
[cpart,cursor]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
    L,L,0,0,legacy.count(),3); %#ok<ASGLU>
text=pastafari.serializeExactWeaveCursorJson(L,cursor);
obj=jsondecode(text);
assert(ischar(obj.rankDecimal) && ischar(obj.countDecimal), ...
    'Exact rank/count must be JSON decimal STRINGS.');

changed=obj; changed.countDecimal=[obj.countDecimal '7'];
reject(jsonencode(changed),'Pastafari:WeaveCheckpoint:CountMismatch');
changed=obj; changed.rankDecimal='0001';
reject(jsonencode(changed),'Pastafari:WeaveCheckpoint:Decimal');
changed=obj; changed.rankDecimal='0';
reject(jsonencode(changed),'Pastafari:WeaveCheckpoint:Decimal');
changed=obj; changed.schema='unknown-v9';
reject(jsonencode(changed),'Pastafari:WeaveCheckpoint:Schema');
changed=obj; changed.done=~obj.done;
reject(jsonencode(changed),'Pastafari:WeaveCheckpoint:Done');
changed=obj; changed.remaining(1)=changed.remaining(1)+1;
rejectAny(jsonencode(changed));
reject('not a json object','Pastafari:WeaveCheckpoint:JSON');

% A decimal representation much larger than double's exact integer
% capacity MUST be retained as text, never silently rounded.
large=char(pastafari.BigInt(['1' repmat('0',1,100)]));
assert(numel(large)==101);
changed=obj;
changed.rankDecimal=large;
rejectAny(jsonencode(changed));
% True year-5000 month lengths, with all 45 months already opened
% exactly once. The reachable remainder is 4199 days and its full
% exact completion count/rank have thousands of decimal digits.
% The binomial all-open formula permits an independent fast BigInt
% recount at import without using the exponential production DAG.
L=[115 108 119 109 106 81 115 114 117 120 98 52 81 97 121 ...
   97 115 96 107 61 106 115 119 39 84 103 115 107 55 119 ...
   97 50 122 110 81 54 101 83 88 40 25 77 98 122 105];
R=L-1;
assert(numel(L)==45 && sum(L)==4244 && sum(R)==4199);
started=tic;
bigCount=pastafari.countWholeWeavingSuffixByEndpoints(R,45,0);
bigRank=bigCount.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1);
bigCursor=struct('remaining',R,'openedUpTo',45, ...
    'closedUpTo',0,'rank',bigRank,'count',bigCount, ...
    'done',false,'stepsComputed',45);
portable=pastafari.serializeExactWeaveCursorJson(L,bigCursor);
obj=jsondecode(portable);
assert(ischar(obj.rankDecimal) && ischar(obj.countDecimal) && ...
    numel(obj.countDecimal)>6000 && ...
    strcmp(obj.rankDecimal,char(bigRank)) && ...
    strcmp(obj.countDecimal,char(bigCount)), ...
    'Many-thousand-digit BigInt was not preserved as decimal JSON.');
[original,verified]=pastafari.restoreExactWeaveCursorJson(portable);
assert(isequal(original,L) && isequal(verified.remaining,R) && ...
    verified.count==bigCount && verified.rank==bigRank && ...
    verified.initialCount==bigCount && ~verified.done, ...
    'Full-scale exact BigInt JSON resume lost digits or frontier.');
[letters,nextCursor]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
    original,verified.remaining,verified.openedUpTo, ...
    verified.closedUpTo,verified.rank,3);
assert(numel(letters)==3 && sum(nextCursor.remaining)==4196 && ...
    nextCursor.rank>=pastafari.BigInt(1) && ...
    nextCursor.rank<=nextCursor.count, ...
    'Resumed real-year 4199-day exact rank lost a legal suffix.');
fprintf(['STAGE_55_CHECKPOINT_REAL_YEAR_BIGINT_PASS MONTHS=45 ', ...
    'DAYS=4199 DIGITS=%d RESUMED=3 SECONDS=%.3f\n'], ...
    numel(obj.countDecimal),toc(started));

fprintf('STAGE_55_CHECKPOINT_JSON_TAMPER_REJECT_PASS\n');
fprintf('STAGE_55_CHECKPOINT_JSON_EXPERIMENTAL_PASS\n');
end

function reject(s,id)
caught=false;
try
    pastafari.restoreExactWeaveCursorJson(s);
catch err
    caught=strcmp(err.identifier,id);
end
assert(caught,'Expected exact checkpoint rejection identifier %s',id);
end

function rejectAny(s)
caught=false;
try
    pastafari.restoreExactWeaveCursorJson(s);
catch
    caught=true;
end
assert(caught,'Invalid checkpoint must never be restored.');
end
