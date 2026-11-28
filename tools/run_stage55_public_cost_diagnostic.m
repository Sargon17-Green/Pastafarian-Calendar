function run_stage55_public_cost_diagnostic(root, expectedPath, logPath)
% Adaptation of archived pilot; production checkout remains exact SHA.
% Existing source diagnostics only; no production source change.
oldTrace = getenv('PASTAFARI_STAGE54_DIAGNOSTICS');
traceCleanup = onCleanup(@() setenv('PASTAFARI_STAGE54_DIAGNOSTICS',oldTrace)); %#ok<NASGU>
setenv('PASTAFARI_STAGE54_DIAGNOSTICS','1');
originalPath = path;
pathCleanup = onCleanup(@() path(originalPath)); %#ok<NASGU>
addpath(fullfile(root,'src'));
addpath(fullfile(root,'tests','oracle'));
assert(strcmp(which('calendarDateSpaghetti'),fullfile(root,'src','calendarDateSpaghetti.m')));
expected = jsondecode(fileread(expectedPath));
assert(numel(expected.rows)==4244);
assert(expected.calculation_day==-15055671);
assert(expected.first_day==-15057702 && expected.last_day==-15053459);
pastafari.LegacyYearNumberStructureCache.clear();
normative_oracle('resetGates');
catalog = pastafari.sourceLanguageCatalog();
c = pastafari.BigInt(expected.calculation_day);
lo = expected.first_day; hi = expected.last_day;
targets = [lo,lo,lo+2121,hi,lo+2121,lo];
fid = fopen(logPath,'w','n','UTF-8'); assert(fid>=0); fclose(fid);
for k=1:numel(targets)
    t = targets(k);
    fprintf('PUBLIC_CALL_BEGIN session=1 index=%d target=%d\n',k,t);
    clock = tic;
    actual = calendarDateSpaghetti(c,pastafari.BigInt(t));
    seconds = toc(clock);
    row = expected.rows(t-lo+1);
    want = {pastafari.BigInt(5000),catalog.cutlets(row.cutlet_index).text, ...
        pastafari.BigInt(row.cutlet_day),catalog.months(row.month_index).text, ...
        pastafari.BigInt(row.month_day)};
    got = fields(actual); wantFields = fields(want);
    record = struct('session',1,'index',k,'target',t,'seconds',seconds, ...
        'actual',{got},'expected',{wantFields},'equal',isequal(got,wantFields));
    fid = fopen(logPath,'a','n','UTF-8'); assert(fid>=0);
    rowCleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid,'%s\n',jsonencode(record));
    clear rowCleanup
    fprintf('PUBLIC_CALL_END session=1 index=%d seconds=%.6f equal=%d\n',k,seconds,record.equal);
    assert(record.equal,'Public five-field differential mismatch at target %d',t);
end
fprintf('PUBLIC_SOAK_PASS mode=pilot session=1 calls=6\n');
end
function out = fields(value)
assert(iscell(value) && numel(value)==5);
assert(isa(value{1},'pastafari.BigInt') && isa(value{3},'pastafari.BigInt') && isa(value{5},'pastafari.BigInt'));
assert(ischar(value{2}) && ischar(value{4}));
out = {char(value{1}),value{2},char(value{3}),value{4},char(value{5})};
end
