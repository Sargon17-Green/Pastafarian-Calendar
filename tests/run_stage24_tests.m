function run_stage24_tests()
% DISCOVERY 12: successor używa stałego pierścienia nazw zamiast orderAt46.
% Surowa blizna ma pozostać po PATCH 12, natomiast publikowany successor
% ma wtedy wynikać z pozycji queried ID w latched order.

run_stage23_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');

% Zbuduj prawdziwy latched order z aktualnej zielonej ścieżki.
ctx = pastafari.MonsterContext(foundation, foundation);
[ctx, counts] = pastafari.WorkCountsCompatibilityRoute.call( ...
    ctx, foundation, foundation);
[ctx, stones] = pastafari.StoneTableCompatibilityRoute.call(ctx);
[ctx, hidden] = pastafari.HiddenCompatibilityRoute.call( ...
    ctx, counts, stones);
[ctx, priorVisible] = pastafari.VisibleDropCompatibilityRoute.call( ...
    ctx, counts, stones, hidden);
[ctx, visible] = pastafari.GrindTableCompatibilityRoute.call( ...
    ctx, counts, stones, hidden, priorVisible);
[ctx, preInPlaceBowls] = pastafari.BowlPourCompatibilityRoute.call( ...
    ctx, counts, stones, visible);
[ctx, bowlsAfterDrop46] = pastafari.BowlStirCompatibilityRoute.call( ...
    ctx, counts, stones, visible, preInPlaceBowls);
[ctx, ~, orderAt46] = pastafari.OrderAt46CompatibilityRoute.call( ...
    ctx, visible, bowlsAfterDrop46);

oracleSauce = normative_oracle('sauce', foundation, foundation);
assert(isequal(orderAt46, oracleSauce.orderAtDrop46), ...
    'PATCH 11 nie dostarczył normatywnego orderAt46.');
assert(isequal(orderAt46, [4 5 2 3 6 1]), ...
    'Fixture Foundation ma nieoczekiwany orderAt46.');

% Wszystkie sześć ID: legacy fixed-name ring jest zgodny tylko tam,
% gdzie przypadkiem następny ID w latchu odpowiada id+1 modulo 6.
expectedById = zeros(1, 6);
legacyById = zeros(1, 6);
publishedById = zeros(1, 6);
rawDivergent = false(1, 6);
publishedDivergent = false(1, 6);

for queriedId = 1:6
    expected = expectedSuccessor(orderAt46, queriedId);
    expectedById(queriedId) = expected;

    raw = pastafari.LegacyFixedNameSuccessor.next(queriedId);
    legacyById(queriedId) = raw;
    rawDivergent(queriedId) = raw ~= expected;

    probeCtx = pastafari.MonsterContext(foundation, foundation);
    [probeCtx, actual] = pastafari.NextBowlCompatibilityRoute.call( ...
        probeCtx, orderAt46, queriedId);

    assert(probeCtx.legacyFixedNameSuccessor == raw, ...
        ['Kontekst utracił raw successor dla ID ', num2str(queriedId), '.']);
    assert(isequal(probeCtx.successorOrderAt46, orderAt46), ...
        'Kontekst utracił latched order użyty przez consumer.');
    assert(probeCtx.successorQueriedBowlId == queriedId, ...
        'Kontekst utracił queried bowl ID.');

    publishedById(queriedId) = actual;
    publishedDivergent(queriedId) = actual ~= expected;
end

assert(isequal(expectedById, [4 3 6 5 2 1]), ...
    'Normatywna mapa successor dla Foundation latch jest nieoczekiwana.');
assert(isequal(legacyById, [2 3 4 5 6 1]), ...
    'Historyczny fixed-name ring został zmieniony.');
assert(isequal(rawDivergent, [true false true false true false]), ...
    'Historyczna blizna ma rozchodzić się dokładnie dla IDs 1,3,5.');

assert(isequal(publishedDivergent, rawDivergent) || ...
       ~any(publishedDivergent), ...
    ['Stage 24 ma być RED przed PATCH 12 i GREEN po nim; ', ...
     'inny wzorzec oznacza dodatkową wadę.']);

% Prawdziwy publiczny consumer używa position 4 latcha.
queriedFromPosition4 = orderAt46(4);
assert(queriedFromPosition4 == 3, ...
    'Foundation position 4 powinno wskazywać bowl ID 3.');

publicCtx = pastafari.MonsterContext(foundation, foundation);
[publicCtx, publicSuccessor] = ...
    pastafari.NextBowlCompatibilityRoute.call( ...
        publicCtx, orderAt46, queriedFromPosition4);
expectedPublic = expectedSuccessor(orderAt46, queriedFromPosition4);

assert(publicCtx.legacyFixedNameSuccessor == 4, ...
    'Legacy successor dla queried bowl 3 powinien wynosić 4.');
assert(expectedPublic == 6, ...
    'Normatywny successor queried bowl 3 powinien wynosić 6.');

assert(any(strcmp(publicCtx.branchTrace, ...
    'DISCOVERY_12_FIXED_NAME_SUCCESSOR')), ...
    'Brakuje śladu Discovery 12.');
metricKey = matlab.lang.makeValidName( ...
    'discovery12.fixedNameSuccessor.calls');
assert(isfield(publicCtx.metrics, metricKey) && ...
    publicCtx.metrics.(metricKey) == 1, ...
    'Licznik fixed-name successor jest niepoprawny.');

divergent = publicSuccessor ~= expectedPublic;

fprintf(['STAGE24 DISCOVERY12 ORDER=[%s] QUERY_ID=%d RAW=%d ', ...
    'ACTUAL=%d EXPECTED=%d CLASSIFICATION=%s\n'], ...
    orderText(orderAt46), queriedFromPosition4, ...
    publicCtx.legacyFixedNameSuccessor, publicSuccessor, expectedPublic, ...
    classification(divergent));

caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 24.');

if divergent
    assert(publicSuccessor == 4, ...
        'Discovery 12 powinno publikować fixed-name successor 4.');
    fprintf('STAGE_24_DISCOVERY_12_EXPECTED_RED\n');
    error('Pastafari:Discovery12:FixedNameSuccessor', ...
        ['Oczekiwana rozbieżność Discovery 12: successor jest liczony ', ...
         'po stałych bowl names zamiast po pozycji queried ID w orderAt46Latch.']);
end

fprintf('STAGE_24_DISCOVERY_12_REGRESSION_GREEN\n');
end

function successor = expectedSuccessor(orderAt46, queriedId)
position = find(orderAt46 == queriedId, 1, 'first');
assert(~isempty(position), 'Queried ID musi istnieć w latchu.');
nextPosition = mod(position, numel(orderAt46)) + 1;
successor = orderAt46(nextPosition);
end

function text = orderText(order)
text = strtrim(sprintf('%d ', order));
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
