function run_stage28_tests()
% DISCOVERY 14: general selector zakłada, że każdy wybór jest short.
% Surowy unsupported scar ma pozostać po PATCH 14, natomiast publikowany
% wide rank ma wtedy przejść na GREEN przez wide detour.

run_stage27_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

M = pastafari.BigInt('170141183460469231731687303715884105727');
stream = struct('first', pastafari.BigInt(1), 'directionStep', 1);

witnesses = { ...
    M + pastafari.BigInt(1), ...
    M * M, ...
    M * M * M};
labels = {'M_PLUS_1', 'M_SQUARED', 'M_CUBED'};

expectedKnown = { ...
    M + pastafari.BigInt(1), ...
    M + pastafari.BigInt(1), ...
    pastafari.BigInt(1) + M + pastafari.BigInt(2) * M * M};

divergent = false(1, numel(witnesses));

for k = 1:numel(witnesses)
    N = witnesses{k};
    expected = normative_oracle('chooseRank', stream, N);

    assert(expected == expectedKnown{k}, ...
        ['Wide oracle fixture jest nieoczekiwany dla ', labels{k}, '.']);

    ctx = pastafari.MonsterContext(0, 0);
    [ctx, actual] = ...
        pastafari.GeneralSelectionCompatibilityRoute.call( ...
            ctx, stream, N);

    assert(ctx.legacyShortOnlyAssumed, ...
        'Legacy dispatcher musi zakładać short-only selection.');
    assert(ctx.legacyGeneralSelectionRequestedSize == N, ...
        'Kontekst utracił requested N.');
    assert(ctx.legacyWideSelectionUnsupported, ...
        'Legacy dispatcher musi oznaczyć N>M jako unsupported.');
    assert(strcmp(ctx.legacyWideSelectionError, ...
        'Pastafari:Selection:LegacyShortAssumption'), ...
        'Legacy dispatcher zachował nieoczekiwany identyfikator błędu.');
    assert(isempty(ctx.legacyGeneralSelectionResult), ...
        'Raw legacy result dla N>M musi pozostać pusty.');

    assert(any(strcmp(ctx.branchTrace, ...
        'DISCOVERY_14_SHORT_ONLY_SELECTOR')), ...
        'Brakuje śladu Discovery 14.');
    metricKey = matlab.lang.makeValidName( ...
        'discovery14.shortOnlySelector.calls');
    assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
        'Licznik short-only selector jest niepoprawny.');

    if isempty(actual)
        divergent(k) = true;
        actualText = 'EMPTY';
    else
        divergent(k) = actual ~= expected;
        actualText = char(actual);
    end

    fprintf(['STAGE28 DISCOVERY14 CASE=%s N=%s RAW_UNSUPPORTED=%d ', ...
        'ACTUAL=%s EXPECTED=%s CLASSIFICATION=%s\n'], ...
        labels{k}, char(N), ctx.legacyWideSelectionUnsupported, ...
        actualText, char(expected), classification(divergent(k)));
end

assert(all(divergent) || ~any(divergent), ...
    ['Stage 28 ma być w pełni RED przed PATCH 14 albo w pełni GREEN ', ...
     'po wide detour; mieszany wynik oznacza dodatkową wadę.']);

shortN = pastafari.BigInt(922);
shortExpected = normative_oracle('chooseRank', stream, shortN);
shortCtx = pastafari.MonsterContext(0, 0);
[shortCtx, shortActual] = ...
    pastafari.GeneralSelectionCompatibilityRoute.call( ...
        shortCtx, stream, shortN);

assert(~shortCtx.legacyWideSelectionUnsupported, ...
    'Short control nie może być oznaczony jako wide unsupported.');
assert(~isempty(shortCtx.legacyGeneralSelectionResult), ...
    'Short control musi zachować wynik legacy dispatcher.');
assert(shortActual == shortExpected, ...
    'Discovery 14 nie może uszkodzić ścieżki N<=M.');
assert(any(strcmp(shortCtx.branchTrace, ...
    'PATCH_13_REJECTION_ON_ANSWER_RING')), ...
    'Short control nie przeszedł przez PATCH 13.');

foundation = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 28.');

if any(divergent)
    assert(all(divergent), ...
        'Discovery 14 powinno odrzucać wszystkie trzy wide witnesses.');
    fprintf('STAGE_28_DISCOVERY_14_EXPECTED_RED\n');
    error('Pastafari:Discovery14:ShortOnlySelector', ...
        ['Oczekiwana rozbieżność Discovery 14: general selector kieruje ', ...
         'N>M do short-only PATCH 13 i nie ma jeszcze wide detour.']);
end

fprintf('STAGE_28_DISCOVERY_14_REGRESSION_GREEN\n');
end

function text = classification(isDivergent)
if isDivergent
    text = 'EXPECTED_RED';
else
    text = 'MATCH';
end
end

function cleanupPaths(root, here)
rmpath(fullfile(root, 'src'));
rmpath(fullfile(here, 'oracle'));
end
