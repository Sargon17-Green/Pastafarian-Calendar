function run_stage02_tests()
% Discovery 01: ujawnienie błędnego SAVE opartego na zwykłym modulo.
% Oczekiwany wynik całego pliku w etapie 2 to EXPECTED_RED.

% Najpierw wszystkie regresje poprzedniego etapu muszą pozostać zielone.
run_stage01_tests();

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
divergent = false(1, numel(inputs));

for k = 1:numel(inputs)
    rawLegacy = pastafari.LegacyRemainderAdapter.oldRemainder(inputs{k});
    assert(rawLegacy == legacyExpected{k}, ...
        ['Historyczny oldRemainder ma nieoczekiwany wynik dla przypadku ', labels{k}, '.']);

    ctx = pastafari.MonsterContext(inputs{k}, inputs{k});
    [ctx, actual] = pastafari.SaveCompatibilityRoute.call(ctx, inputs{k});

    assert(ctx.legacyRemainderInput == inputs{k}, ...
        ['Kontekst nie zachował wejścia legacy dla przypadku ', labels{k}, '.']);
    assert(ctx.legacyRemainderValue == rawLegacy, ...
        ['Kontekst nie zachował surowego wyniku legacy dla przypadku ', labels{k}, '.']);
    assert(any(strcmp(ctx.branchTrace, 'DISCOVERY_01_OLD_REMAINDER')), ...
        ['Brakuje śladu trasy Discovery 01 dla przypadku ', labels{k}, '.']);

    metricKey = matlab.lang.makeValidName('discovery01.oldRemainder.calls');
    assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
        ['Licznik wywołań oldRemainder jest niepoprawny dla przypadku ', labels{k}, '.']);

    normative = normative_oracle('SAVE', inputs{k});
    divergent(k) = actual ~= normative;

    fprintf(['STAGE02 DISCOVERY01 CASE=%s LEGACY=%s ROUTE=%s EXPECTED=%s ', ...
        'CLASSIFICATION=%s\n'], ...
        labels{k}, char(rawLegacy), char(actual), char(normative), ...
        classification(divergent(k)));
end

if any(divergent)
    assert(isequal(divergent, [true, true, true, false]), ...
        ['Discovery 01 wykazało nieoczekiwany wzorzec rozbieżności; ', ...
         'oczekiwano rozbieżności tylko dla M, 2M i 3M.']);
end

% Publiczna trasa produkcyjna nadal kończy się na kontrolowanej granicy
% niezaimplementowanego kalendarza, ale przechodzi już przez Discovery 01.
caught = false;
try
    calendarDateSpaghetti(M, M);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa produkcyjna nie zachowała kontrolowanej granicy etapu 2.');

if any(divergent)
    fprintf('STAGE_02_DISCOVERY_01_EXPECTED_RED\n');
    error('Pastafari:Discovery01:LegacyRemainderDivergence', ...
        ['Oczekiwana rozbieżność Discovery 01: bieżąca trasa SAVE nadal ', ...
         'dziedziczy zero z oldRemainder dla dodatnich wielokrotności M.']);
end

fprintf('STAGE_02_DISCOVERY_01_REGRESSION_GREEN\n');
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
