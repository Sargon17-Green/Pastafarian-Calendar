function run_gate_arithmetic_profile_variant(sourceRoot, vectorsPath, outputPath, bigintBlob)
% Diagnostic-only profile. No cache overlay: all nine inner routes run per call.
outputDirectory = fileparts(outputPath);
if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
pidPath = fullfile(outputDirectory, 'matlab.pid');
pidFid = fopen(pidPath, 'w');
assert(pidFid >= 0);
fprintf(pidFid, '%d\n', feature('getpid'));
fclose(pidFid);

originalPath = path;
pathCleanup = onCleanup(@() path(originalPath)); %#ok<NASGU>
addpath(fullfile(sourceRoot, 'src'));

assert(strcmp(which('pastafari.GateQuestionEngine'), ...
    fullfile(sourceRoot, 'src', '+pastafari', 'GateQuestionEngine.m')));
assert(strcmp(which('pastafari.BigInt'), ...
    fullfile(sourceRoot, 'src', '+pastafari', 'BigInt.m')));

vectors = jsondecode(fileread(vectorsPath));
vectorResults = repmat(struct('q', '', 'r', '', 'regular_r', ''), numel(vectors), 1);
for k = 1:numel(vectors)
    a = pastafari.BigInt(vectors(k).a);
    b = pastafari.BigInt(vectors(k).b);
    [q, r] = a.floorDivMod(b);
    regularR = a.regularMod(b);
    vectorResults(k).q = char(q);
    vectorResults(k).r = char(r);
    vectorResults(k).regular_r = char(regularR);
end

foundation = -15055671;
offsets = [-12:-1, 1:12];
targets = foundation + offsets;
repeatCount = 2;
pastafari.GateQuestionEngine.gapForQuestionDay( ...
    pastafari.BigInt(targets(1)));

profile('clear');
profile('on');
callSeconds = zeros(repeatCount, numel(targets));
gapResults = cell(repeatCount, numel(targets));
for repeatIndex = 1:repeatCount
    for targetIndex = 1:numel(targets)
        clock = tic;
        gap = pastafari.GateQuestionEngine.gapForQuestionDay( ...
            pastafari.BigInt(targets(targetIndex)));
        callSeconds(repeatIndex, targetIndex) = toc(clock);
        gapResults{repeatIndex, targetIndex} = char(gap);
    end
end
profile('off');
profileInfo = profile('info');
functionTable = profileInfo.FunctionTable;

routeNames = { ...
    'WorkCountsCompatibilityRoute', ...
    'StoneTableCompatibilityRoute', ...
    'HiddenCompatibilityRoute', ...
    'VisibleDropCompatibilityRoute', ...
    'GrindTableCompatibilityRoute', ...
    'BowlPourCompatibilityRoute', ...
    'BowlStirCompatibilityRoute', ...
    'OrderAt46CompatibilityRoute', ...
    'GeneralSelectionCompatibilityRoute'};
routeCounts = struct();
for k = 1:numel(routeNames)
    mask = contains({functionTable.FunctionName}, routeNames{k});
    routeCounts.(routeNames{k}) = struct( ...
        'calls', sum([functionTable(mask).NumCalls]), ...
        'profile_seconds', sum([functionTable(mask).TotalTime]));
end

gateMask = contains({functionTable.FunctionName}, 'GateQuestionEngine');
gateEngineCalls = sum([functionTable(gateMask).NumCalls]);
divmodMask = contains({functionTable.FunctionName}, 'divmodMagnitude');
divmodProfile = struct( ...
    'calls', sum([functionTable(divmodMask).NumCalls]), ...
    'profile_seconds', sum([functionTable(divmodMask).TotalTime]), ...
    'functions', {{functionTable(divmodMask).FunctionName}});

allTimes = [functionTable.TotalTime];
[~, order] = sort(allTimes, 'descend');
topCount = min(40, numel(order));
topFunctions = repmat(struct( ...
    'name', '', 'calls', 0, 'profile_seconds', 0), topCount, 1);
for k = 1:topCount
    item = functionTable(order(k));
    topFunctions(k).name = item.FunctionName;
    topFunctions(k).calls = item.NumCalls;
    topFunctions(k).profile_seconds = item.TotalTime;
end

report = struct( ...
    'source_sha', '341927541dccc940bfc5e2b4073c21c647261278', ...
    'bigint_blob', bigintBlob, ...
    'gate_engine_blob', '4b774c90f9a2fcdccaa2baac3ef80b0e8e99489e', ...
    'arithmetic_vector_count', numel(vectors), ...
    'arithmetic_results', vectorResults, ...
    'target_offsets', offsets, ...
    'target_days', targets, ...
    'repeat_count', repeatCount, ...
    'gate_engine_profile_calls', gateEngineCalls, ...
    'call_seconds', callSeconds, ...
    'gap_results', {gapResults}, ...
    'total_measured_gate_seconds', sum(callSeconds(:)), ...
    'median_gate_call_seconds', median(callSeconds(:)), ...
    'p95_gate_call_seconds', percentile95(callSeconds(:)), ...
    'route_counts', routeCounts, ...
    'divmod_profile', divmodProfile, ...
    'top_functions', topFunctions);

fid = fopen(outputPath, 'w', 'n', 'UTF-8');
assert(fid >= 0);
fileCleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fwrite(fid, jsonencode(report), 'char');
fwrite(fid, newline, 'char');
end

function value = percentile95(samples)
sorted = sort(samples(:));
index = max(1, ceil(0.95 * numel(sorted)));
value = sorted(index);
end
