function run_stage42_tests()
% DISCOVERY 21: legacy family zawiera wszystkie dodatnie kompozycje,
% bez filtrowania przez internal calculation-day gate.
%
% Raw family i raw selection muszą pozostać obserwowalne po PATCH 21.

run_stage41_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

gapCount = pastafari.BigInt(10);
cutletCount = pastafari.BigInt(8);
internalGateOffset = pastafari.BigInt(4);
stream = struct( ...
    'first', pastafari.BigInt(87), ...
    'directionStep', 1);

descriptor = ...
    pastafari.LegacyAllPositiveCutletPartitionFamily.describe( ...
        gapCount, cutletCount);
assert(strcmp(descriptor.familyName, 'ALL_POSITIVE_LEXICOGRAPHIC'), ...
    'Historyczna rodzina ma nieoczekiwany typ.');
assert(descriptor.count == pastafari.BigInt(36), ...
    'Historyczna rodzina powinna mieć dokładnie 36 kompozycji.');

legacyAll = cell(1, 36);
for r = 1:36
    legacyAll{r} = ...
        pastafari.LegacyAllPositiveCutletPartitionFamily.unrank1( ...
            gapCount, cutletCount, pastafari.BigInt(r));
    assert(all(legacyAll{r} >= 1), ...
        'Każda historyczna część musi być dodatnia.');
    assert(sum(legacyAll{r}) == 10, ...
        'Każda historyczna kompozycja musi sumować się do gapCount.');
end

expectedRaw = [1 1 1 3 1 1 1 1];
assert(isequal(legacyAll{15}, expectedRaw), ...
    'Legacy rank 15 ma nieoczekiwaną kompozycję.');

filtered = {};
for r = 1:numel(legacyAll)
    if hasInternalBoundary(legacyAll{r}, 4)
        filtered{end + 1} = legacyAll{r}; %#ok<AGROW>
    end
end
assert(numel(filtered) == 28, ...
    'Filtrowana rodzina referencyjna powinna mieć dokładnie 28 elementów.');

expectedFilteredRank = 3;
expectedFiltered = [1 1 1 1 1 1 3 1];
assert(isequal(filtered{expectedFilteredRank}, expectedFiltered), ...
    'Normatywny filtered rank 3 ma nieoczekiwaną kompozycję.');
assert(~hasInternalBoundary(expectedRaw, 4), ...
    'Raw legacy witness nie może zawierać wymaganej granicy 4.');
assert(hasInternalBoundary(expectedFiltered, 4), ...
    'Filtered witness musi zawierać wymaganą granicę 4.');

adapterCtx = pastafari.MonsterContext(0, 0);
[adapterCtx, rawRank, rawPartition, rawCount, rawDescriptor] = ...
    pastafari.LegacyCutletPartitionAdapter.callWithRing( ...
        adapterCtx, stream, gapCount, cutletCount); %#ok<ASGLU>

assert(rawCount == pastafari.BigInt(36), ...
    'Legacy adapter powinien wybierać z 36 dróg.');
assert(rawRank == pastafari.BigInt(15), ...
    'Legacy adapter powinien wybrać rank 15.');
assert(isequal(rawPartition, expectedRaw), ...
    'Legacy adapter ma błędną raw partition.');
assert(rawDescriptor.count == pastafari.BigInt(36), ...
    'Legacy adapter utracił descriptor rodziny.');

ctx = pastafari.MonsterContext(0, 0);
[ctx, actual] = ...
    pastafari.CutletPartitionCompatibilityRoute.call( ...
        ctx, stream, gapCount, cutletCount, internalGateOffset);

assert(ctx.cutletGapCount == gapCount, ...
    'Kontekst utracił gapCount.');
assert(ctx.cutletCountCandidate == cutletCount, ...
    'Kontekst utracił cutletCount.');
assert(ctx.cutletInternalGateOffset == internalGateOffset, ...
    'Kontekst utracił internalGateOffset.');
assert(ctx.legacyPositiveCompositions.count == pastafari.BigInt(36), ...
    'Kontekst utracił pełną rodzinę legacy.');
assert(ctx.legacyCutletPartitionFamilyCount == pastafari.BigInt(36), ...
    'Kontekst utracił raw family count.');
assert(ctx.legacyCutletPartitionRank == pastafari.BigInt(15), ...
    'Kontekst utracił raw rank 15.');
assert(isequal(ctx.legacyCutletPartition, expectedRaw), ...
    'Kontekst utracił raw legacy partition.');

rawPattern = isequal(actual, expectedRaw);
greenPattern = isequal(actual, expectedFiltered);
assert(rawPattern || greenPattern, ...
    ['Stage 42 powinno publikować raw legacy partition przed PATCH 21 ', ...
     'albo dokładny filtered-family wynik po PATCH 21.']);

assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_21_UNFILTERED_CUTLET_PARTITIONS')), ...
    'Brakuje śladu Discovery 21.');
metricKey = matlab.lang.makeValidName( ...
    'discovery21.unfilteredCutletPartitions.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik unfiltered-cutlet-partitions jest niepoprawny.');

fprintf(['STAGE42 DISCOVERY21 GAP=10 CUTLETS=8 OFFSET=4 ', ...
    'RAW_COUNT=36 RAW_RANK=15 RAW=[%s] ', ...
    'FILTERED_COUNT=28 FILTERED_RANK=3 ACTUAL=[%s] ', ...
    'EXPECTED=[%s] CLASSIFICATION=%s\n'], ...
    rowText(expectedRaw), rowText(actual), rowText(expectedFiltered), ...
    classification(rawPattern));

noGateCtx = pastafari.MonsterContext(0, 0);
[noGateCtx, noGateActual] = ...
    pastafari.CutletPartitionCompatibilityRoute.call( ...
        noGateCtx, stream, gapCount, cutletCount, []);
assert(isempty(noGateCtx.cutletInternalGateOffset), ...
    'Brak gate powinien pozostać pustym offsetem.');
assert(isequal(noGateActual, expectedRaw), ...
    'Bez wewnętrznego gate raw partition ma przejść bez filtrowania.');

pastafari.LegacyYearNumberStructureCache.clear();
foundation = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 42.');

if rawPattern
    fprintf('STAGE_42_DISCOVERY_21_EXPECTED_RED\n');
    error('Pastafari:Discovery21:UnfilteredCutletPartitions', ...
        ['Oczekiwana rozbieżność Discovery 21: selected composition ', ...
         'nie zawiera calculation-day internal gate boundary.']);
end

fprintf('STAGE_42_DISCOVERY_21_REGRESSION_GREEN\n');
end

function tf = hasInternalBoundary(partition, offset)
running = 0;
tf = false;
for k = 1:(numel(partition) - 1)
    running = running + partition(k);
    if running == offset
        tf = true;
        return
    end
end
end

function text = rowText(values)
text = strtrim(sprintf('%d ', values));
end

function text = classification(isRed)
if isRed
    text = 'EXPECTED_RED';
else
    text = 'MATCH';
end
end

function cleanupPaths(root)
pastafari.LegacyYearNumberStructureCache.clear();
rmpath(fullfile(root, 'src'));
end
