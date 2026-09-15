function run_stage44_tests()
% DISCOVERY 22: legacy cutlet-name family ma rozmiar 17^K i pozwala
% wielokrotnie używać tego samego canonicalIndex.
%
% Raw repeated candidate musi pozostać obserwowalny po PATCH 22.

run_stage43_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

masterCount = pastafari.BigInt(17);
cutletCount = pastafari.BigInt(6);
familyCount = ...
    pastafari.LegacyRepeatedNameGenerator.familyCount( ...
        masterCount, cutletCount);

assert(familyCount == pastafari.BigInt(24137569), ...
    'Legacy repeated-name family powinna mieć 17^6 elementów.');

% Trzy niezależne, kontrolowane witness ranks.
witnesses = { ...
    struct('first', 1, ...
           'raw', [1 1 1 1 1 1], ...
           'distinct', [1 2 3 4 5 6]), ...
    struct('first', 2, ...
           'raw', [1 1 1 1 1 2], ...
           'distinct', [1 2 3 4 5 7]), ...
    struct('first', 18, ...
           'raw', [1 1 1 1 2 1], ...
           'distinct', [1 2 3 4 6 11])};

for k = 1:numel(witnesses)
    w = witnesses{k};
    stream = struct( ...
        'first', pastafari.BigInt(w.first), ...
        'directionStep', 1);

    ctx = pastafari.MonsterContext(0, 0);
    [ctx, rank, raw, count, descriptor] = ...
        pastafari.LegacyRepeatedNameGenerator.callWithRing( ...
            ctx, stream, masterCount, cutletCount); %#ok<ASGLU>

    assert(count == familyCount, ...
        'Legacy generator ma błędny family count.');
    assert(rank == pastafari.BigInt(w.first), ...
        'Kontrolowany stream powinien wybrać rank równy first.');
    assert(isequal(raw, w.raw), ...
        'Legacy repeated-name witness ma błędne indices.');
    assert(hasRepeat(raw), ...
        'Każdy Discovery 22 witness musi zawierać powtórzenie.');
    assert(strcmp(descriptor.familyName, ...
        'REPEATED_LEXICOGRAPHIC_CANONICAL_INDICES'), ...
        'Legacy repeated-name descriptor ma błędny typ.');
    assert(descriptor.repeatsAllowed, ...
        'Legacy descriptor musi jawnie dopuszczać repeats.');

    expectedDistinct = distinctReference(17, 6, w.first);
    assert(isequal(expectedDistinct, w.distinct), ...
        'Test-only distinct reference ma nieoczekiwany wynik.');
    assert(~isequal(raw, expectedDistinct), ...
        'Discovery 22 witness musi różnić się od distinct family.');
end

% Realny bowl-5/seal-22 wiring na syntetycznym structure sauce.
structureSauce = struct( ...
    'bowls', {{ ...
        pastafari.BigInt(17), pastafari.BigInt(19), ...
        pastafari.BigInt(23), pastafari.BigInt(29), ...
        pastafari.BigInt(31), pastafari.BigInt(37)}}, ...
    'orderAt46Latch', [1 2 3 4 5 6]);

nextBowlId = pastafari.LatchedSuccessorPatch.apply( ...
    structureSauce.orderAt46Latch, 5);
routeStream = pastafari.AnswerRingStreamFactory.fromSauce( ...
    structureSauce.bowls, 5, nextBowlId, 22);

assert(routeStream.first == pastafari.BigInt(61401), ...
    'Bowl 5 / seal 22 witness powinien dać first=61401.');

routeCtx = pastafari.MonsterContext(0, 0);
[routeCtx, actual] = ...
    pastafari.CutletNameCompatibilityRoute.call( ...
        routeCtx, structureSauce, cutletCount);

expectedRaw = [1 1 13 9 8 14];
expectedDistinct = [1 3 16 4 11 13];

assert(routeCtx.cutletNameStreamFirst == pastafari.BigInt(61401), ...
    'Kontekst utracił bowl-5/seal-22 first.');
assert(routeCtx.legacyCutletNameFamilyCount == familyCount, ...
    'Kontekst utracił 17^6 family count.');
assert(routeCtx.legacyCutletNameRank == pastafari.BigInt(61401), ...
    'Kontekst utracił raw rank 61401.');
assert(isequal(routeCtx.legacyNameCandidateIndices, expectedRaw), ...
    'Kontekst utracił raw repeated-name candidate.');
assert(hasRepeat(routeCtx.legacyNameCandidateIndices), ...
    'Raw route scar musi zawierać co najmniej jedno powtórzenie.');

assert(isequal(distinctReference(17, 6, 61401), expectedDistinct), ...
    'Test-only distinct route reference ma błędny wynik.');

rawPattern = isequal(actual, expectedRaw);
greenPattern = isequal(actual, expectedDistinct);
assert(rawPattern || greenPattern, ...
    ['Stage 44 powinno publikować raw repeated candidate przed PATCH 22 ', ...
     'albo exact partial-permutation candidate po PATCH 22.']);

assert(any(strcmp(routeCtx.branchTrace, ...
    'DISCOVERY_22_REPEATED_NAMES')), ...
    'Brakuje śladu Discovery 22.');
metricKey = matlab.lang.makeValidName( ...
    'discovery22.repeatedNames.calls');
assert(isfield(routeCtx.metrics, metricKey) && ...
       routeCtx.metrics.(metricKey) == 1, ...
    'Licznik repeated-names jest niepoprawny.');

fprintf(['STAGE44 DISCOVERY22 COUNT=%s RANK=%s RAW=[%s] ', ...
    'ACTUAL=[%s] EXPECTED_DISTINCT=[%s] CLASSIFICATION=%s\n'], ...
    char(familyCount), char(routeCtx.legacyCutletNameRank), ...
    rowText(expectedRaw), rowText(actual), rowText(expectedDistinct), ...
    classification(rawPattern));

pastafari.LegacyYearNumberStructureCache.clear();
foundation = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 44.');

if rawPattern
    fprintf('STAGE_44_DISCOVERY_22_EXPECTED_RED\n');
    error('Pastafari:Discovery22:RepeatedNames', ...
        ['Oczekiwana rozbieżność Discovery 22: legacy name family ', ...
         'pozwala powtarzać canonicalIndex w obrębie tego samego roku.']);
end

fprintf('STAGE_44_DISCOVERY_22_REGRESSION_GREEN\n');
end

function tf = hasRepeat(indices)
tf = numel(unique(indices)) < numel(indices);
end

function out = distinctReference(masterCount, k, rank1)
remaining = 1:masterCount;
out = zeros(1, k);
r = rank1 - 1;

for position = 1:k
    suffixLength = k - position;
    block = fallingFactorial(numel(remaining) - 1, suffixLength);
    index0 = floor(r / block);
    r = mod(r, block);
    out(position) = remaining(index0 + 1);
    remaining(index0 + 1) = [];
end
end

function value = fallingFactorial(n, k)
value = 1;
for j = 0:(k - 1)
    value = value * (n - j);
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
