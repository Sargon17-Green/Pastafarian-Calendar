function run_stage04_tests()
% DISCOVERY 02: historyczny oldDayTag używa 2*abs(day-FOUNDATION).
% Ten sam regression ma stać się zielony po PATCH 02 w etapie 5.

% Wszystkie wcześniejsze etapy muszą pozostać zielone.
run_stage03_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');
days = {foundation - 1, foundation, foundation + 1};
legacyExpected = {pastafari.BigInt(2), pastafari.BigInt(0), pastafari.BigInt(2)};
labels = {'FOUNDATION-1', 'FOUNDATION', 'FOUNDATION+1'};
divergent = false(1, numel(days));

for k = 1:numel(days)
    rawLegacy = pastafari.LegacyDayTagAdapter.oldDayTag(days{k});
    assert(rawLegacy == legacyExpected{k}, ...
        ['Historyczny oldDayTag ma nieoczekiwany wynik dla przypadku ', labels{k}, '.']);

    ctx = pastafari.MonsterContext(days{k}, days{k});
    [ctx, actual] = pastafari.DayTagCompatibilityRoute.call(ctx, days{k});

    assert(ctx.dayTagInput == days{k}, ...
        ['Kontekst nie zachował wejścia dayTag dla przypadku ', labels{k}, '.']);
    assert(ctx.legacyDayTagValue == rawLegacy, ...
        ['Kontekst nie zachował surowego oldDayTag dla przypadku ', labels{k}, '.']);
    assert(ctx.dayTagCandidate == actual, ...
        ['Kontekst nie zachował publikowanego dayTag dla przypadku ', labels{k}, '.']);
    assert(any(strcmp(ctx.branchTrace, 'DISCOVERY_02_OLD_DAY_TAG')), ...
        ['Brakuje śladu Discovery 02 dla przypadku ', labels{k}, '.']);

    metricKey = matlab.lang.makeValidName('discovery02.oldDayTag.calls');
    assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
        ['Licznik oldDayTag jest niepoprawny dla przypadku ', labels{k}, '.']);

    normative = normative_oracle('dayCount', days{k});
    divergent(k) = actual ~= normative;

    fprintf(['STAGE04 DISCOVERY02 CASE=%s LEGACY=%s ROUTE=%s EXPECTED=%s ', ...
        'CLASSIFICATION=%s\n'], ...
        labels{k}, char(rawLegacy), char(actual), char(normative), ...
        classification(divergent(k)));
end

if any(divergent)
    assert(isequal(divergent, [false, true, true]), ...
        ['Discovery 02 wykazało nieoczekiwany wzorzec: przed Foundation ', ...
         'ma być zgodnie, a Foundation i strona późniejsza mają się rozchodzić.']);
end

% Publiczna ścieżka nadal dochodzi do kontrolowanej granicy po przejściu
% przez wszystkie dotychczasowe warstwy produkcyjne.
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 4.');

if any(divergent)
    fprintf('STAGE_04_DISCOVERY_02_EXPECTED_RED\n');
    error('Pastafari:Discovery02:OldDayTagDivergence', ...
        ['Oczekiwana rozbieżność Discovery 02: oldDayTag zwraca 0 na Foundation ', ...
         'i brakuje mu przesunięcia +1 po stronie późniejszej.']);
end

fprintf('STAGE_04_DISCOVERY_02_REGRESSION_GREEN\n');
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
