function run_stage30_tests()
% DISCOVERY 15: ujemny signed gate step pyta Foundation+n zamiast Foundation-n.
% Surowa lustrzana blizna ma pozostać po PATCH 15, natomiast publikowany
% negative gap ma wtedy przejść na GREEN przez signed gate question.

run_stage29_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');
steps = [1 2 3];
expectedPositive = [345 818 831];
expectedNegative = [503 441 329];

negativeDivergent = false(1, numel(steps));

for k = 1:numel(steps)
    n = steps(k);
    positiveDay = foundation + pastafari.BigInt(n);
    negativeDay = foundation - pastafari.BigInt(n);

    % GateQuestionEngine ma być neutralny wobec znaku i poprawny po podaniu
    % konkretnego dnia pytania.
    directPositive = ...
        pastafari.GateQuestionEngine.gapForQuestionDay(positiveDay);
    directNegative = ...
        pastafari.GateQuestionEngine.gapForQuestionDay(negativeDay);

    assert(directPositive == pastafari.BigInt(expectedPositive(k)), ...
        ['Nieoczekiwany dodatni gate gap dla n=', num2str(n), '.']);
    assert(directNegative == pastafari.BigInt(expectedNegative(k)), ...
        ['Nieoczekiwany ujemny gate gap dla n=', num2str(n), '.']);
    assert(directPositive ~= directNegative, ...
        'Fixture musi odróżniać pytanie dodatnie od ujemnego.');

    % Dodatni krok jest przypadkiem, w którym stara ścieżka była poprawna.
    posCtx = pastafari.MonsterContext(0, 0);
    [posCtx, posActual] = ...
        pastafari.GateGapCompatibilityRoute.call( ...
            posCtx, pastafari.BigInt(n));

    assert(posActual == directPositive, ...
        'Dodatni gate gap nie może zostać uszkodzony przez Discovery 15.');
    assert(posCtx.legacyPositiveOnlyGateQuestionDay == positiveDay, ...
        'Legacy positive question day jest błędny.');
    assert(posCtx.legacyPositiveOnlyGateGap == directPositive, ...
        'Legacy positive gap jest błędny.');

    % Ujemny krok: raw legacy nadal musi pytać ten sam positiveDay.
    negCtx = pastafari.MonsterContext(0, 0);
    [negCtx, negActual] = ...
        pastafari.GateGapCompatibilityRoute.call( ...
            negCtx, -pastafari.BigInt(n));

    assert(negCtx.gateSignedStep == -pastafari.BigInt(n), ...
        'Kontekst utracił signed negative step.');
    assert(negCtx.legacyPositiveOnlyGateQuestionDay == positiveDay, ...
        ['Historyczna blizna dla -', num2str(n), ...
         ' musi pytać Foundation+n.']);
    assert(negCtx.legacyPositiveOnlyGateGap == directPositive, ...
        ['Historyczna blizna dla -', num2str(n), ...
         ' musi zachować dodatni mirrored gap.']);

    assert(any(strcmp(negCtx.branchTrace, ...
        'DISCOVERY_15_POSITIVE_ONLY_GATE_QUESTION')), ...
        'Brakuje śladu Discovery 15.');
    metricKey = matlab.lang.makeValidName( ...
        'discovery15.positiveOnlyGateQuestion.calls');
    assert(isfield(negCtx.metrics, metricKey) && ...
        negCtx.metrics.(metricKey) == 1, ...
        'Licznik positive-only gate question jest niepoprawny.');

    negativeDivergent(k) = negActual ~= directNegative;

    fprintf(['STAGE30 DISCOVERY15 STEP=-%d RAW_DAY=%s ', ...
        'RAW_GAP=%s ACTUAL=%s EXPECTED=%s CLASSIFICATION=%s\n'], ...
        n, char(negCtx.legacyPositiveOnlyGateQuestionDay), ...
        char(negCtx.legacyPositiveOnlyGateGap), char(negActual), ...
        char(directNegative), classification(negativeDivergent(k)));
end

assert(all(negativeDivergent) || ~any(negativeDivergent), ...
    ['Stage 30 ma być RED dla wszystkich negative fixtures przed PATCH 15 ', ...
     'albo GREEN dla wszystkich po signed question.']);

foundationDay = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundationDay, foundationDay);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 30.');

if any(negativeDivergent)
    assert(all(negativeDivergent), ...
        'Discovery 15 powinno lustrzanie mylić wszystkie negative fixtures.');
    fprintf('STAGE_30_DISCOVERY_15_EXPECTED_RED\n');
    error('Pastafari:Discovery15:PositiveOnlyGateQuestion', ...
        ['Oczekiwana rozbieżność Discovery 15: dla signedStep=-n ', ...
         'legacy pyta Foundation+n zamiast Foundation-n.']);
end

fprintf('STAGE_30_DISCOVERY_15_REGRESSION_GREEN\n');
end

function text = classification(isDivergent)
if isDivergent
    text = 'EXPECTED_RED';
else
    text = 'MATCH';
end
end

function cleanupPaths(root)
rmpath(fullfile(root, 'src'));
end
