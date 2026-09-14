function run_stage05_tests()
% PATCH 02: Foundation scar nad historycznym oldDayTag.

% Niezmieniony regression Discovery 02 musi po nałożeniu patcha stać się zielony.
run_stage04_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');
days = {foundation - 2, foundation - 1, foundation, foundation + 1, foundation + 2};
legacyExpected = { ...
    pastafari.BigInt(4), ...
    pastafari.BigInt(2), ...
    pastafari.BigInt(0), ...
    pastafari.BigInt(2), ...
    pastafari.BigInt(4)};
labels = {'FOUNDATION-2', 'FOUNDATION-1', 'FOUNDATION', 'FOUNDATION+1', 'FOUNDATION+2'};

for k = 1:numel(days)
    rawLegacy = pastafari.LegacyDayTagAdapter.oldDayTag(days{k});
    assert(rawLegacy == legacyExpected{k}, ...
        ['Historyczna blizna oldDayTag została zmieniona dla przypadku ', labels{k}, '.']);

    patchedDirect = pastafari.FoundationScarPatch.apply(days{k}, rawLegacy);
    normative = normative_oracle('dayCount', days{k});
    assert(patchedDirect == normative, ...
        ['FoundationScarPatch nie odtworzył dayCount dla przypadku ', labels{k}, '.']);

    ctx = pastafari.MonsterContext(days{k}, days{k});
    [ctx, actual] = pastafari.DayTagCompatibilityRoute.call(ctx, days{k});

    assert(ctx.legacyDayTagValue == rawLegacy, ...
        ['Trasa utraciła surowy oldDayTag dla przypadku ', labels{k}, '.']);
    assert(actual == normative, ...
        ['Trasa licznika dnia po PATCH 02 jest błędna dla przypadku ', labels{k}, '.']);
    assert(ctx.dayTagCandidate == actual, ...
        ['Kontekst nie zachował wyniku po Foundation scar dla przypadku ', labels{k}, '.']);
    assert(any(strcmp(ctx.branchTrace, 'DISCOVERY_02_OLD_DAY_TAG')), ...
        ['Brakuje śladu historycznego oldDayTag dla przypadku ', labels{k}, '.']);
    assert(any(strcmp(ctx.branchTrace, 'PATCH_02_FOUNDATION_SCAR')), ...
        ['Brakuje śladu PATCH 02 dla przypadku ', labels{k}, '.']);

    legacyKey = matlab.lang.makeValidName('discovery02.oldDayTag.calls');
    patchKey = matlab.lang.makeValidName('patch02.foundationScar.calls');
    assert(isfield(ctx.metrics, legacyKey) && ctx.metrics.(legacyKey) == 1, ...
        ['Licznik oldDayTag jest niepoprawny dla przypadku ', labels{k}, '.']);
    assert(isfield(ctx.metrics, patchKey) && ctx.metrics.(patchKey) == 1, ...
        ['Licznik Foundation scar jest niepoprawny dla przypadku ', labels{k}, '.']);
end

% Kontrole graniczne dokładnie według historycznej łaty.
assert(pastafari.FoundationScarPatch.apply(foundation - 1, pastafari.BigInt(2)) == pastafari.BigInt(2), ...
    'PATCH 02 nie może zmieniać strony wcześniejszej.');
assert(pastafari.FoundationScarPatch.apply(foundation, pastafari.BigInt(0)) == pastafari.BigInt(1), ...
    'PATCH 02 musi mapować Foundation na 1.');
assert(pastafari.FoundationScarPatch.apply(foundation + 1, pastafari.BigInt(2)) == pastafari.BigInt(3), ...
    'PATCH 02 musi dodawać +1 po stronie późniejszej.');

fprintf('STAGE_05_PATCH_02_GREEN\n');
end

function cleanupPaths(root, here)
rmpath(fullfile(root, 'src'));
rmpath(fullfile(here, 'oracle'));
end
