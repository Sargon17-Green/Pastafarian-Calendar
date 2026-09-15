function run_stage46_tests()
% DISCOVERY 23: historyczne API próbuje materializować wszystkie bounded
% month-length compositions. Ogrom ma być dowiedziony bez materializacji.
%
% Po PATCH 23 ten sam regression ma zachować blocked legacy scar, ale
% semantic route ma zwrócić month-length row przez VirtualLegacyList.

run_stage45_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

smallCases = [12 2; 15 3; 20 4];

for k = 1:size(smallCases, 1)
    total = smallCases(k, 1);
    months = smallCases(k, 2);

    [actualWays, descriptor] = ...
        pastafari.LegacyAllMonthLengthWaysAPI.listAllWays( ...
            pastafari.BigInt(total), pastafari.BigInt(months));
    expectedWays = bruteWays(total, months);

    assert(~descriptor.preflightTooLarge, ...
        'Mała rodzina nie może przekraczać safe cap.');
    assert(numel(actualWays) == numel(expectedWays), ...
        'Legacy concrete list ma błędny count dla małej rodziny.');

    for r = 1:numel(expectedWays)
        assert(isequal(actualWays{r}, expectedWays{r}), ...
            ['Legacy concrete list ma błędny lexicographic row przy rank ', ...
             num2str(r), '.']);
    end
end

[minWays, ~] = pastafari.LegacyAllMonthLengthWaysAPI.listAllWays( ...
    pastafari.BigInt(12), pastafari.BigInt(2));
assert(numel(minWays) == 5, ...
    'Rodzina total=12,K=2 powinna mieć 5 wierszy.');
assert(isequal(minWays{1}, [4 8]) && isequal(minWays{5}, [8 4]), ...
    'Minimalna rodzina utraciła lexicographic endpoints.');

witnesses = { ...
    struct('total', 300, 'months', 10, 'width', 13, ...
        'lower', '10604499373', 'exact', '16972992395495488'), ...
    struct('total', 400, 'months', 10, 'width', 14, ...
        'lower', '20661046784', 'exact', '230112572610023588'), ...
    struct('total', 1000, 'months', 20, 'width', 6, ...
        'lower', '609359740010496', ...
        'exact', '219529195724680298522930699726339455920')};

safeCap = pastafari.LegacyAllMonthLengthWaysAPI.safeCap();
assert(safeCap == pastafari.BigInt(100000), ...
    'Historyczny safe cap powinien wynosić dokładnie 100000.');

for k = 1:numel(witnesses)
    w = witnesses{k};

    proof = pastafari.proveLegacyMonthLengthFamilyLowerBound( ...
        pastafari.BigInt(w.total), pastafari.BigInt(w.months));

    assert(proof.width == pastafari.BigInt(w.width), ...
        ['Lower-bound width jest błędny dla witness ', num2str(k), '.']);
    assert(proof.lowerBound == pastafari.BigInt(w.lower), ...
        ['Lower bound jest błędny dla witness ', num2str(k), '.']);
    assert(proof.lowerBound > safeCap, ...
        'Huge witness musi przekraczać safe cap już przez lower bound.');

    exact = exactBoundedCountTestOnly(w.total, w.months);
    assert(exact == pastafari.BigInt(w.exact), ...
        ['Test-only exact count jest błędny dla witness ', num2str(k), '.']);
    assert(exact >= proof.lowerBound, ...
        'Exact count nie może być mniejszy od lower bound.');

    probe = pastafari.LegacyAllMonthLengthWaysAPI.probeAllWays( ...
        pastafari.BigInt(w.total), pastafari.BigInt(w.months));
    assert(probe.preflightTooLarge, ...
        'Huge witness powinien zostać zablokowany przed materializacją.');
end

caughtLegacy = false;
try
    pastafari.LegacyAllMonthLengthWaysAPI.listAllWays( ...
        pastafari.BigInt(300), pastafari.BigInt(10));
catch err
    caughtLegacy = strcmp(err.identifier, ...
        'Pastafari:MonthLengths:LegacyMaterializationTooLarge');
end
assert(caughtLegacy, ...
    'Legacy list_all_ways musi zatrzymać ogromną rodzinę przed OOM.');

adapterCtx = pastafari.MonsterContext(0, 0);
[adapterCtx, blockedWays, blockedDescriptor, blocked] = ...
    pastafari.LegacyMonthLengthMaterializationAdapter.call( ...
        adapterCtx, pastafari.BigInt(300), pastafari.BigInt(10)); %#ok<ASGLU>

assert(blocked, 'Adapter powinien oznaczyć 300/10 jako blocked.');
assert(isempty(blockedWays), ...
    'Blocked legacy adapter nie może zwrócić konkretnej listy.');
assert(adapterCtx.legacyMonthLengthMaterializationAttempted, ...
    'Kontekst utracił historyczną próbę materializacji.');
assert(adapterCtx.legacyMonthLengthMaterializationBlocked, ...
    'Kontekst utracił blocked materialization scar.');
assert(strcmp(adapterCtx.legacyMonthLengthMaterializationError, ...
    'Pastafari:MonthLengths:LegacyMaterializationTooLarge'), ...
    'Kontekst ma błędny legacy materialization error.');
assert(adapterCtx.legacyMonthLengthSafeCap == pastafari.BigInt(100000), ...
    'Kontekst utracił safe cap.');
assert(adapterCtx.legacyMonthLengthLowerBound == ...
    pastafari.BigInt('10604499373'), ...
    'Kontekst utracił lower bound 13^9.');
assert(adapterCtx.legacyMonthLengthProofWidth == pastafari.BigInt(13), ...
    'Kontekst utracił Cartesian proof width 13.');
assert(isempty(adapterCtx.legacyMonthLengthConcreteWays), ...
    'Blocked scar nie może materializować concrete ways.');

structureSauce = syntheticSauce();
routeCtx = pastafari.MonsterContext(0, 0);
redPattern = false;
greenPattern = false;
actual = [];

try
    [routeCtx, actual] = ...
        pastafari.MonthLengthCompatibilityRoute.call( ...
            routeCtx, structureSauce, ...
            pastafari.BigInt(300), pastafari.BigInt(10));
    greenPattern = true;
catch err
    if strcmp(err.identifier, ...
            'Pastafari:Discovery23:MaterializedMonthLengths')
        redPattern = true;
    else
        rethrow(err)
    end
end

assert(xor(redPattern, greenPattern), ...
    'Stage 46 powinno być dokładnie RED przed patchem albo GREEN po nim.');
assert(routeCtx.legacyMonthLengthMaterializationAttempted, ...
    'Route utracił legacy materialization attempt.');
assert(routeCtx.legacyMonthLengthMaterializationBlocked, ...
    'Route utracił blocked legacy scar.');
assert(routeCtx.legacyMonthLengthLowerBound == ...
    pastafari.BigInt('10604499373'), ...
    'Route utracił ogromny lower bound.');
assert(any(strcmp(routeCtx.branchTrace, ...
    'DISCOVERY_23_MATERIALIZED_MONTH_LENGTHS')), ...
    'Brakuje śladu Discovery 23.');

metricKey = matlab.lang.makeValidName( ...
    'discovery23.materializedMonthLengths.calls');
assert(isfield(routeCtx.metrics, metricKey) && ...
       routeCtx.metrics.(metricKey) == 1, ...
    'Licznik materialized-month-lengths jest niepoprawny.');

if greenPattern
    assert(isnumeric(actual) && isvector(actual) && numel(actual) == 10, ...
        'Po PATCH 23 semantic route powinien zwrócić 10 długości.');
    assert(all(actual >= 4) && all(actual <= 123), ...
        'Po PATCH 23 każda długość musi należeć do 4..123.');
    assert(sum(actual) == 300, ...
        'Po PATCH 23 month lengths muszą sumować się do 300.');
end

pastafari.LegacyYearNumberStructureCache.clear();
foundation = pastafari.BigInt('-15055671');
caughtBootstrap = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caughtBootstrap = strcmp(err.identifier, ...
        'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caughtBootstrap, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 46.');

if redPattern
    fprintf('STAGE_46_DISCOVERY_23_EXPECTED_RED\n');
    error('Pastafari:Discovery23:MaterializedMonthLengthsRegression', ...
        ['Oczekiwana rozbieżność Discovery 23: legacy API wymaga ', ...
         'konkretnej listy rodziny znacznie większej od safe cap.']);
end

fprintf('STAGE_46_DISCOVERY_23_REGRESSION_GREEN\n');
end

function sauce = syntheticSauce()
sauce = struct( ...
    'bowls', {{ ...
        pastafari.BigInt(17), pastafari.BigInt(19), ...
        pastafari.BigInt(23), pastafari.BigInt(29), ...
        pastafari.BigInt(31), pastafari.BigInt(37)}}, ...
    'orderAt46Latch', [1 2 3 4 5 6]);
end

function ways = bruteWays(total, slots)
ways = {};
if slots == 1
    if total >= 4 && total <= 123
        ways = {[total]};
    end
    return
end

minFirst = max(4, total - 123 * (slots - 1));
maxFirst = min(123, total - 4 * (slots - 1));

for first = minFirst:maxFirst
    suffixes = bruteWays(total - first, slots - 1);
    for k = 1:numel(suffixes)
        ways{end + 1} = [first suffixes{k}]; %#ok<AGROW>
    end
end
end

function count = exactBoundedCountTestOnly(total, slots)
dp = cell(1, total + 1);
for s = 0:total
    dp{s + 1} = pastafari.BigInt(0);
end
dp{1} = pastafari.BigInt(1);

for slot = 1:slots
    next = cell(1, total + 1);
    for s = 0:total
        next{s + 1} = pastafari.BigInt(0);
    end

    window = pastafari.BigInt(0);
    for s = 0:total
        addIndex = s - 4;
        removeIndex = s - 124;

        if addIndex >= 0
            window = window + dp{addIndex + 1};
        end
        if removeIndex >= 0
            window = window - dp{removeIndex + 1};
        end

        next{s + 1} = window;
    end

    dp = next;
end

count = dp{total + 1};
end

function cleanupPaths(root)
pastafari.LegacyYearNumberStructureCache.clear();
rmpath(fullfile(root, 'src'));
end
