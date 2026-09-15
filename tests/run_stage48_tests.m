function run_stage48_tests()
% DISCOVERY 24: historyczny chooser wybiera month id niezależnie dla
% każdego dnia i może naruszyć legalny whole-month weave.
%
% Raw daily ghost ma pozostać obserwowalny po PATCH 24.

run_stage47_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

lengths = [4 4 4];

% 1. Pomocnicze wrap + skip-full behavior.
assert(pastafari.wrapMonth(1, 3) == 1 && ...
       pastafari.wrapMonth(4, 3) == 1 && ...
       pastafari.wrapMonth(0, 3) == 3, ...
    'wrapMonth ma błędną semantykę modulo 1..N.');

skipStream = struct( ...
    'first', pastafari.BigInt(1), ...
    'directionStep', 1);
[skipGhost, skipProposals, skipRemaining] = ...
    pastafari.legacyChooseEachDaySeparately(skipStream, [1 2]);
assert(isequal(skipProposals, [1 2 1]), ...
    'Kontrolowany skip-full witness ma błędne raw proposals.');
assert(isequal(skipGhost, [1 2 2]), ...
    'Pełny miesiąc powinien zostać pominięty przez circular wrap.');
assert(isequal(skipRemaining, [0 0]), ...
    'Daily chooser musi zachować dokładne multiplicities.');

% 2. Trzy wcześniej utrwalone bowl-4/seal-32 stream witnesses.
streamWitnesses = { ...
    struct( ...
        'first', ...
            '156621837332624240885492203280715109403', ...
        'step', 1, ...
        'ghost', [2 3 1 2 3 1 2 3 1 2 3 1]), ...
    struct( ...
        'first', ...
            '80803525669999255172801708465153447025', ...
        'step', -1, ...
        'ghost', [3 2 1 3 2 1 3 2 1 3 2 1]), ...
    struct( ...
        'first', ...
            '38196695267841223610584811766559928411', ...
        'step', 1, ...
        'ghost', [2 3 1 2 3 1 2 3 1 2 3 1])};

for k = 1:numel(streamWitnesses)
    w = streamWitnesses{k};
    stream = struct( ...
        'first', pastafari.BigInt(w.first), ...
        'directionStep', w.step);
    [ghost, ~, remaining] = ...
        pastafari.legacyChooseEachDaySeparately(stream, lengths);

    assert(isequal(ghost, w.ghost), ...
        ['Historyczny daily ghost witness ', num2str(k), ' jest błędny.']);
    assert(isequal(remaining, [0 0 0]), ...
        'Historyczny ghost musi zużyć dokładnie 4+4+4 dni.');
    assert(~isLegalWeaving(ghost, lengths), ...
        'Każdy utrwalony Discovery 24 ghost musi naruszać legalny splot.');
end

% 3. Realne wiring bowl 4 / seal 32 na syntetycznym structure sauce.
structureSauce = syntheticSauce();
stream = pastafari.buildMonthWeavingAnswerRing(structureSauce);
assert(stream.first == pastafari.BigInt(64145), ...
    'Synthetic bowl-4/seal-32 first powinien wynosić 64145.');
assert(stream.directionStep == 1, ...
    'Synthetic bowl-4/seal-32 direction powinien wynosić +1.');

[directGhost, directProposals, directRemaining] = ...
    pastafari.legacyChooseEachDaySeparately(stream, lengths);

expectedGhost = [2 3 1 2 3 1 2 3 1 2 3 1];
assert(isequal(directProposals, expectedGhost), ...
    'Synthetic raw proposals mają nieoczekiwany wzorzec.');
assert(isequal(directGhost, expectedGhost), ...
    'Synthetic daily chooser ma nieoczekiwany ghost.');
assert(isequal(directRemaining, [0 0 0]), ...
    'Synthetic daily chooser utracił multiplicities.');
assert(~isLegalWeaving(expectedGhost, lengths), ...
    'Synthetic ghost ma być nielegalnym whole-month weave.');

% 4. Normatywna whole-weave family dla [4,4,4] ma 1301 elementów.
% Test-only reference wynikający z reguł first/last occurrence ordering.
expectedWholeCount = pastafari.BigInt(1301);
selectionCtx = pastafari.MonsterContext(0, 0);
[selectionCtx, expectedRank] = ...
    pastafari.GeneralSelectionCompatibilityRoute.call( ...
        selectionCtx, stream, expectedWholeCount); %#ok<ASGLU>

expectedLegal = [1 1 2 3 2 1 3 2 1 2 3 3];
assert(expectedRank == pastafari.BigInt(396), ...
    'Whole-weave witness powinien wybrać rank 396 z count 1301.');
assert(isLegalWeaving(expectedLegal, lengths), ...
    'Test-only expected whole weave musi być legalny.');
assert(~isequal(expectedGhost, expectedLegal), ...
    'Discovery 24 witness musi rozróżniać ghost od whole-weave wyniku.');

% 5. Produkcyjna Stage 48 route publikuje ghost; Stage 49 ma zmienić
% tylko semantic candidate, pozostawiając raw ghost.
ctx = pastafari.MonsterContext(0, 0);
[ctx, actual] = ...
    pastafari.MonthWeavingCompatibilityRoute.call( ...
        ctx, structureSauce, lengths);

assert(isequal(ctx.monthWeavingLengthsInput, lengths), ...
    'Kontekst utracił wejściowe month lengths.');
assert(ctx.monthWeavingStreamFirst == pastafari.BigInt(64145), ...
    'Kontekst utracił month-weaving answer-ring first.');
assert(ctx.monthWeavingStreamDirectionStep == 1, ...
    'Kontekst utracił month-weaving direction.');
assert(isequal(ctx.legacyDailyMonthRawProposals, expectedGhost), ...
    'Kontekst utracił raw daily proposals.');
assert(isequal(ctx.legacyDailyMonthWeaving, expectedGhost), ...
    'Kontekst utracił historyczny daily ghost.');
assert(isequal(ctx.legacyDailyMonthRemainingFinal, [0 0 0]), ...
    'Kontekst utracił finalne zero multiplicities.');

rawPattern = isequal(actual, expectedGhost);
greenPattern = isequal(actual, expectedLegal);
assert(rawPattern || greenPattern, ...
    ['Stage 48 powinno publikować daily ghost przed PATCH 24 albo ', ...
     'whole-weave DP unrank po PATCH 24.']);

assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_24_DAILY_MONTH_CHOOSER')), ...
    'Brakuje śladu Discovery 24.');
metricKey = matlab.lang.makeValidName( ...
    'discovery24.dailyMonthChooser.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik daily-month-chooser jest niepoprawny.');

fprintf(['STAGE48 DISCOVERY24 LENGTHS=[4 4 4] FIRST=64145 ', ...
    'WHOLE_COUNT=1301 WHOLE_RANK=396 RAW=[%s] ACTUAL=[%s] ', ...
    'EXPECTED=[%s] CLASSIFICATION=%s\n'], ...
    rowText(expectedGhost), rowText(actual), rowText(expectedLegal), ...
    classification(rawPattern));

% 6. Public route nadal kończy się na kontrolowanej granicy etapu.
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
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 48.');

if rawPattern
    fprintf('STAGE_48_DISCOVERY_24_EXPECTED_RED\n');
    error('Pastafari:Discovery24:DailyMonthChooser', ...
        ['Oczekiwana rozbieżność Discovery 24: daily chooser zachowuje ', ...
         'multiplicities, ale nie wybiera legalnego whole-month weave.']);
end

fprintf('STAGE_48_DISCOVERY_24_REGRESSION_GREEN\n');
end

function tf = isLegalWeaving(weaving, lengths)
lengths = double(lengths(:).');
remaining = lengths;
openedUpTo = 0;
closedUpTo = 0;
tf = true;

if numel(weaving) ~= sum(lengths)
    tf = false;
    return
end

for position = 1:numel(weaving)
    j = weaving(position);
    if ~(isnumeric(j) && isscalar(j) && isfinite(j) && ...
            fix(j) == j && j >= 1 && j <= numel(lengths))
        tf = false;
        return
    end

    if remaining(j) == 0
        tf = false;
        return
    end

    alreadyOpened = remaining(j) < lengths(j);
    if ~alreadyOpened && j ~= openedUpTo + 1
        tf = false;
        return
    end

    willClose = remaining(j) == 1;
    if willClose && j ~= closedUpTo + 1
        tf = false;
        return
    end

    if remaining(j) == lengths(j)
        openedUpTo = j;
    end

    remaining(j) = remaining(j) - 1;

    if remaining(j) == 0
        closedUpTo = j;
    end
end

tf = all(remaining == 0);
end

function sauce = syntheticSauce()
sauce = struct( ...
    'bowls', {{ ...
        pastafari.BigInt(17), pastafari.BigInt(19), ...
        pastafari.BigInt(23), pastafari.BigInt(29), ...
        pastafari.BigInt(31), pastafari.BigInt(37)}}, ...
    'orderAt46Latch', [1 2 3 4 5 6]);
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
