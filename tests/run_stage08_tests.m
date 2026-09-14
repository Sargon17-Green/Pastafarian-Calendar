function run_stage08_tests()
% DISCOVERY 04: pięć kamieni jest mutowanych sekwencyjnie w miejscu.
% Ten sam regression ma stać się zielony po PATCH 04 w etapie 9.

run_stage07_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

legacy = pastafari.LegacyStoneMutationAdapter.buildTable();
oracle = normative_oracle('stones');

legacySecondExpected = { ...
    pastafari.BigInt(378), ...
    pastafari.BigInt(1434), ...
    pastafari.BigInt(3780), ...
    pastafari.BigInt(9932), ...
    pastafari.BigInt(25047)};

oracleSecondExpected = { ...
    pastafari.BigInt(378), ...
    pastafari.BigInt(1073), ...
    pastafari.BigInt(2375), ...
    pastafari.BigInt(6195), ...
    pastafari.BigInt(10493)};

for k = 1:5
    assert(legacy{2, k} == legacySecondExpected{k}, ...
        ['Historyczna wartość legacy w wierszu 2, kamień ', num2str(k), ...
         ' nie odpowiada sekwencyjnej mutacji.']);
    assert(oracle{2, k} == oracleSecondExpected{k}, ...
        ['Snapshot oracle w wierszu 2, kamień ', num2str(k), ' jest nieoczekiwany.']);
end

rawDivergent = false(1, 5);
for k = 1:5
    rawDivergent(k) = legacy{2, k} ~= oracle{2, k};
end
assert(isequal(rawDivergent, [false, true, true, true, true]), ...
    ['Discovery 04 musi zachować pierwszy kamień zgodny, a kamienie 2-5 ', ...
     'muszą rozchodzić się wskutek mutacji sekwencyjnej.']);

ctx = pastafari.MonsterContext(pastafari.BigInt(0), pastafari.BigInt(0));
[ctx, actual] = pastafari.StoneTableCompatibilityRoute.call(ctx);

assert(isequal(size(actual), [46, 5]), ...
    'Produkcyjna tabela kamieni musi mieć rozmiar 46x5.');
assert(isequal(size(ctx.legacyStoneTable), [46, 5]), ...
    'Kontekst nie zachował pełnej tabeli legacy.');
assert(any(strcmp(ctx.branchTrace, 'DISCOVERY_04_SEQUENTIAL_STONES')), ...
    'Brakuje śladu Discovery 04.');
metricKey = matlab.lang.makeValidName('discovery04.sequentialStoneMutation.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik sekwencyjnej mutacji kamieni jest niepoprawny.');

divergent = false(1, 5);
for k = 1:5
    divergent(k) = actual{2, k} ~= oracle{2, k};
    fprintf(['STAGE08 DISCOVERY04 STONE=%d LEGACY=%s ROUTE=%s EXPECTED=%s ', ...
        'CLASSIFICATION=%s\n'], ...
        k, char(legacy{2, k}), char(actual{2, k}), char(oracle{2, k}), ...
        classification(divergent(k)));
end

if any(divergent)
    assert(isequal(divergent, [false, true, true, true, true]), ...
        'Produkcyjny wzorzec rozbieżności wiersza 2 jest nieoczekiwany.');
end

caught = false;
try
    calendarDateSpaghetti(pastafari.BigInt(0), pastafari.BigInt(0));
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, 'Publiczna trasa nie zachowała kontrolowanej granicy etapu 8.');

if any(divergent)
    fprintf('STAGE_08_DISCOVERY_04_EXPECTED_RED\n');
    error('Pastafari:Discovery04:SequentialStoneMutation', ...
        ['Oczekiwana rozbieżność Discovery 04: kamienie 2-5 w drugim ', ...
         'wierszu widzą wcześniejsze mutacje tego samego wiersza.']);
end

fprintf('STAGE_08_DISCOVERY_04_REGRESSION_GREEN\n');
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
