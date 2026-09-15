function run_stage50_tests()
% DISCOVERY 25: dayInMonth z różnicy dni zakłada contiguous month block.
%
% Po PATCH 25 ten sam regression ma zachować ghost, lecz publikować liczbę
% wystąpień wybranego month id do target position włącznie.

run_stage49_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

lengths = [4 4 4];
family = pastafari.WholeMonthWeavingFamily(lengths);
weaving = family.itemAt1(pastafari.BigInt(396));
expectedWeaving = [1 1 2 3 2 1 3 2 1 2 3 3];

assert(isequal(weaving, expectedWeaving), ...
    'Stage 50 witness musi używać exact Stage 49 whole weave.');

yearOpenDay = pastafari.BigInt(1000);

% 1. W pierwszym contiguous fragmencie historyczna różnica jeszcze się zgadza.
controlTargets = [1 2 3 4];
for position = controlTargets
    ghost = pastafari.LegacyContiguousMonthDay.compute( ...
        weaving, yearOpenDay, yearOpenDay + pastafari.BigInt(position));

    expectedOccurrence = occurrenceCount( ...
        weaving, position, ghost.monthId);

    assert(ghost.dayInMonth == pastafari.BigInt(expectedOccurrence), ...
        ['W control prefix historyczny ghost powinien zgadzać się przy ', ...
         'position ', num2str(position), '.']);
end

% 2. Rozdzielone wystąpienia: różnica dni jest większa od occurrence count.
positions = [5 6 7 8 9 10 11 12];
expectedLegacy = [3 6 4 6 9 8 8 9];
expectedOccurrence = [2 3 2 3 4 4 3 4];

for k = 1:numel(positions)
    position = positions(k);
    ghost = pastafari.LegacyContiguousMonthDay.compute( ...
        weaving, yearOpenDay, yearOpenDay + pastafari.BigInt(position));

    assert(ghost.dayInMonth == pastafari.BigInt(expectedLegacy(k)), ...
        ['Legacy contiguous result jest błędny dla position ', ...
         num2str(position), '.']);
    assert(occurrenceCount(weaving, position, ghost.monthId) == ...
        expectedOccurrence(k), ...
        ['Test-only occurrence reference jest błędny dla position ', ...
         num2str(position), '.']);
    assert(expectedLegacy(k) ~= expectedOccurrence(k), ...
        'Separated-occurrence witness musi wykazać rozbieżność.');
end

% 3. Główny witness: target position 9, month 1.
targetDay = pastafari.BigInt(1009);
ghost = pastafari.LegacyContiguousMonthDay.compute( ...
    weaving, yearOpenDay, targetDay);

assert(ghost.monthId == 1, ...
    'Target position 9 powinno należeć do month 1.');
assert(ghost.targetPosition1 == pastafari.BigInt(9), ...
    'Ghost utracił target position 9.');
assert(ghost.firstPosition1 == pastafari.BigInt(1), ...
    'Pierwsze wystąpienie month 1 powinno być na position 1.');
assert(ghost.firstDay == pastafari.BigInt(1001), ...
    'Pierwszy absolutny dzień month 1 powinien wynosić 1001.');
assert(ghost.dayInMonth == pastafari.BigInt(9), ...
    'Historyczny contiguous dayInMonth powinien wynosić 9.');

normativeOccurrence = occurrenceCount(weaving, 9, 1);
assert(normativeOccurrence == 4, ...
    'Month 1 powinien wystąpić dokładnie cztery razy do position 9.');

% 4. Produkcyjna route: Stage 50 publikuje 9; Stage 51 ma publikować 4.
ctx = pastafari.MonsterContext(0, 0);
[ctx, monthId, actual] = ...
    pastafari.MonthDayCompatibilityRoute.call( ...
        ctx, weaving, yearOpenDay, targetDay);

assert(monthId == 1, ...
    'Route powinna publikować month id 1.');
assert(ctx.monthDayYearOpenDay == pastafari.BigInt(1000), ...
    'Kontekst utracił yearOpenDay.');
assert(ctx.monthDayTargetDay == pastafari.BigInt(1009), ...
    'Kontekst utracił targetDay.');
assert(ctx.monthDayTargetPosition1 == pastafari.BigInt(9), ...
    'Kontekst utracił target position.');
assert(ctx.legacyContiguousMonthId == 1, ...
    'Kontekst utracił legacy month id.');
assert(ctx.legacyContiguousMonthFirstPosition1 == pastafari.BigInt(1), ...
    'Kontekst utracił legacy first position.');
assert(ctx.legacyContiguousMonthFirstDay == pastafari.BigInt(1001), ...
    'Kontekst utracił legacy first day.');
assert(ctx.legacyContiguousDayInMonth == pastafari.BigInt(9), ...
    'Kontekst utracił historyczny dayInMonth=9.');

rawPattern = actual == pastafari.BigInt(9);
greenPattern = actual == pastafari.BigInt(4);
assert(rawPattern || greenPattern, ...
    ['Stage 50 powinno publikować contiguous difference przed PATCH 25 ', ...
     'albo exact occurrence count po PATCH 25.']);

assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_25_CONTIGUOUS_MONTH_DAY')), ...
    'Brakuje śladu Discovery 25.');
metricKey = matlab.lang.makeValidName( ...
    'discovery25.contiguousMonthDay.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik contiguous-month-day jest niepoprawny.');

fprintf(['STAGE50 DISCOVERY25 POSITION=9 MONTH=1 FIRST=1 ', ...
    'LEGACY=9 OCCURRENCE=4 ACTUAL=%s CLASSIFICATION=%s\n'], ...
    char(actual), classification(rawPattern));

% 5. Public route nadal kończy się na kontrolowanej granicy.
pastafari.LegacyYearNumberStructureCache.clear();
foundation = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, ...
        'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 50.');

if rawPattern
    fprintf('STAGE_50_DISCOVERY_25_EXPECTED_RED\n');
    error('Pastafari:Discovery25:ContiguousMonthDay', ...
        ['Oczekiwana rozbieżność Discovery 25: dayInMonth z różnicy dni ', ...
         'jest błędny dla rozdzielonych wystąpień miesiąca.']);
end

fprintf('STAGE_50_DISCOVERY_25_REGRESSION_GREEN\n');
end

function count = occurrenceCount(weaving, targetPosition, monthId)
count = sum(weaving(1:targetPosition) == monthId);
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
