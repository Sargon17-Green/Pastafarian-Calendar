function run_stage03_tests()
% PATCH 01: ten sam przypadek Discovery 01 ma po nałożeniu savePatch stać się zielony.

% Niezmieniony regression z etapu 2 musi teraz przejść bez EXPECTED_RED.
run_stage02_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

M = pastafari.BigInt(2).powNonnegative(127) - pastafari.BigInt(1);
inputs = {M, M * 2, M * 3, M + 1};
legacyExpected = { ...
    pastafari.BigInt(0), ...
    pastafari.BigInt(0), ...
    pastafari.BigInt(0), ...
    pastafari.BigInt(1)};
labels = {'M', '2M', '3M', 'M+1'};

for k = 1:numel(inputs)
    rawLegacy = pastafari.LegacyRemainderAdapter.oldRemainder(inputs{k});
    assert(rawLegacy == legacyExpected{k}, ...
        ['Historyczna blizna oldRemainder została zmieniona dla przypadku ', labels{k}, '.']);

    patchedDirect = pastafari.SavePatch.apply(rawLegacy);
    normative = normative_oracle('SAVE', inputs{k});
    assert(patchedDirect == normative, ...
        ['savePatch nie odtworzył normatywnego SAVE dla przypadku ', labels{k}, '.']);

    ctx = pastafari.MonsterContext(inputs{k}, inputs{k});
    [ctx, actual] = pastafari.SaveCompatibilityRoute.call(ctx, inputs{k});

    assert(ctx.legacyRemainderValue == rawLegacy, ...
        ['Trasa utraciła surowy wynik legacy dla przypadku ', labels{k}, '.']);
    assert(actual == normative, ...
        ['Trasa SAVE po PATCH 01 jest niepoprawna dla przypadku ', labels{k}, '.']);
    assert(ctx.saveCandidate == actual, ...
        ['Kontekst nie zachował wyniku po savePatch dla przypadku ', labels{k}, '.']);
    assert(any(strcmp(ctx.branchTrace, 'DISCOVERY_01_OLD_REMAINDER')), ...
        ['Brakuje śladu historycznej wady dla przypadku ', labels{k}, '.']);
    assert(any(strcmp(ctx.branchTrace, 'PATCH_01_SAVE_PATCH')), ...
        ['Brakuje śladu savePatch dla przypadku ', labels{k}, '.']);

    legacyKey = matlab.lang.makeValidName('discovery01.oldRemainder.calls');
    patchKey = matlab.lang.makeValidName('patch01.savePatch.calls');
    assert(isfield(ctx.metrics, legacyKey) && ctx.metrics.(legacyKey) == 1, ...
        ['Licznik oldRemainder jest niepoprawny dla przypadku ', labels{k}, '.']);
    assert(isfield(ctx.metrics, patchKey) && ctx.metrics.(patchKey) == 1, ...
        ['Licznik savePatch jest niepoprawny dla przypadku ', labels{k}, '.']);
end

assert(pastafari.SavePatch.apply(pastafari.BigInt(0)) == M, ...
    'savePatch musi zamieniać zero dokładnie na M.');
assert(pastafari.SavePatch.apply(pastafari.BigInt(1)) == pastafari.BigInt(1), ...
    'savePatch nie może zmieniać niezerowej wartości legacy.');

fprintf('STAGE_03_PATCH_01_GREEN\n');
end

function cleanupPaths(root, here)
rmpath(fullfile(root, 'src'));
rmpath(fullfile(here, 'oracle'));
end
