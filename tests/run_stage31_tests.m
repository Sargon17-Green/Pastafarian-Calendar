function run_stage31_tests()
% PATCH 15: signed gate question zachowuje znak kroku bramy.

% Niezmieniony regression Discovery 15 ma po PATCH 15 przejść na GREEN.
run_stage30_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');
steps = [1 2 3];
expectedPositive = [345 818 831];
expectedNegative = [503 441 329];

for k = 1:numel(steps)
    n = steps(k);
    positiveStep = pastafari.BigInt(n);
    negativeStep = -pastafari.BigInt(n);
    positiveDay = foundation + positiveStep;
    negativeDay = foundation + negativeStep;

    [directPositive, patchPositiveDay] = ...
        pastafari.SignedGateQuestionPatch.ask(positiveStep);
    [directNegative, patchNegativeDay] = ...
        pastafari.SignedGateQuestionPatch.ask(negativeStep);

    assert(patchPositiveDay == positiveDay, ...
        'PATCH 15 błędnie zbudował dodatni question day.');
    assert(patchNegativeDay == negativeDay, ...
        'PATCH 15 błędnie zbudował ujemny question day.');
    assert(directPositive == pastafari.BigInt(expectedPositive(k)), ...
        ['PATCH 15 ma błędny dodatni gap dla n=', num2str(n), '.']);
    assert(directNegative == pastafari.BigInt(expectedNegative(k)), ...
        ['PATCH 15 ma błędny ujemny gap dla n=', num2str(n), '.']);

    % Dodatni przypadek: raw legacy i signed semantic path są zgodne.
    posCtx = pastafari.MonsterContext(0, 0);
    [posCtx, posActual] = pastafari.GateGapCompatibilityRoute.call( ...
        posCtx, positiveStep);

    assert(posActual == directPositive, ...
        'Publikowany dodatni gate gap jest błędny.');
    assert(posCtx.legacyPositiveOnlyGateQuestionDay == positiveDay, ...
        'Raw positive question day został zmieniony.');
    assert(posCtx.legacyPositiveOnlyGateGap == directPositive, ...
        'Raw positive gate gap został zmieniony.');
    assert(posCtx.gateQuestionDayCandidate == positiveDay, ...
        'Semantic positive question day jest błędny.');
    assert(posCtx.gateGapCandidate == directPositive, ...
        'Semantic positive gap jest błędny.');

    % Ujemny przypadek: raw scar nadal mirroruje +n, ale published path
    % musi pytać Foundation-n i zwrócić prawdziwy negative gap.
    negCtx = pastafari.MonsterContext(0, 0);
    [negCtx, negActual] = pastafari.GateGapCompatibilityRoute.call( ...
        negCtx, negativeStep);

    assert(negActual == directNegative, ...
        ['Publikowany negative gap jest błędny dla n=', num2str(n), '.']);
    assert(negCtx.legacyPositiveOnlyGateQuestionDay == positiveDay, ...
        ['PATCH 15 usunął mirrored raw question day dla -', ...
         num2str(n), '.']);
    assert(negCtx.legacyPositiveOnlyGateGap == directPositive, ...
        ['PATCH 15 usunął mirrored raw gap dla -', num2str(n), '.']);
    assert(negCtx.gateQuestionDayCandidate == negativeDay, ...
        ['Semantic negative question day jest błędny dla -', ...
         num2str(n), '.']);
    assert(negCtx.gateGapCandidate == directNegative, ...
        ['Semantic negative gap jest błędny dla -', num2str(n), '.']);
    assert(negCtx.legacyPositiveOnlyGateGap ~= negCtx.gateGapCandidate, ...
        'Fixture powinien zachować obserwowalną raw/semantic różnicę.');

    assert(any(strcmp(negCtx.branchTrace, ...
        'DISCOVERY_15_POSITIVE_ONLY_GATE_QUESTION')), ...
        'Brakuje śladu historycznego Discovery 15.');
    assert(any(strcmp(negCtx.branchTrace, ...
        'PATCH_15_SIGNED_GATE_QUESTION')), ...
        'Brakuje śladu PATCH 15.');

    legacyKey = matlab.lang.makeValidName( ...
        'discovery15.positiveOnlyGateQuestion.calls');
    patchKey = matlab.lang.makeValidName( ...
        'patch15.signedGateQuestion.calls');
    assert(isfield(negCtx.metrics, legacyKey) && ...
        negCtx.metrics.(legacyKey) == 1, ...
        'Licznik raw positive-only gate question jest niepoprawny.');
    assert(isfield(negCtx.metrics, patchKey) && ...
        negCtx.metrics.(patchKey) == 1, ...
        'Licznik PATCH 15 jest niepoprawny.');
end

% Zero pozostaje poza domeną zarówno raw, jak i patched path.
caughtZero = false;
try
    pastafari.SignedGateQuestionPatch.ask(pastafari.BigInt(0));
catch err
    caughtZero = strcmp(err.identifier, 'Pastafari:Gates:ZeroStep');
end
assert(caughtZero, ...
    'PATCH 15 powinien odrzucać signedStep=0.');

% Legacy klasa pozostaje fizycznie semantycznie positive-only.
[legacyGap, legacyDay] = ...
    pastafari.LegacyPositiveOnlyGateQuestion.ask(pastafari.BigInt(-1));
assert(legacyDay == foundation + pastafari.BigInt(1), ...
    'LegacyPositiveOnlyGateQuestion został zmieniony przez PATCH 15.');
assert(legacyGap == pastafari.BigInt(345), ...
    'Legacy mirrored gap -1 powinien nadal wynosić dodatnie 345.');

fprintf('STAGE_31_PATCH_15_GREEN\n');
end

function cleanupPaths(root)
rmpath(fullfile(root, 'src'));
end
