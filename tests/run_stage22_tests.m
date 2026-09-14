function run_stage22_tests()
% DISCOVERY 11: jeden overwritable order memory gubi order z drop 46.
% Surowa pamięć ma pozostać nadpisywana także po PATCH 11, natomiast
% publikowany queryOrder ma wtedy czytać wyłącznie orderAt46Latch.

run_stage21_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');

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

oracleSauce = normative_oracle('sauce', foundation, foundation);

[ctx, finalBowls, queriedOrder] = ...
    pastafari.OrderAt46CompatibilityRoute.call( ...
        ctx, visible, bowlsAfterDrop46);

expectedDrop46 = [4 5 2 3 6 1];
expectedPostStir12 = [1 6 5 2 4 3];

assert(isequal(oracleSauce.orderAtDrop46, expectedDrop46), ...
    'Fixture Foundation ma nieoczekiwany oracle orderAtDrop46.');
assert(isequal(ctx.legacyOrderAtDrop46Observed, expectedDrop46), ...
    'Discovery 11 nie zaobserwowało poprawnego order po drop 46.');

assert(ctx.legacyOrderMemoryWriteCount == 58, ...
    'Historyczny overwritable order memory musi mieć dokładnie 58 writes.');
assert(strcmp(ctx.legacyOrderMemoryLastSource, 'post-stir 12'), ...
    'Ostatnim źródłem legacy order memory musi być post-stir 12.');
assert(isequal(ctx.legacyOverwritableOrderMemoryFinal, expectedPostStir12), ...
    'Końcowa surowa pamięć legacy musi zawierać order post-stir 12.');

assert(~isequal( ...
    ctx.legacyOverwritableOrderMemoryFinal, oracleSauce.orderAtDrop46), ...
    'Surowa blizna lost-order niespodziewanie zniknęła.');

for id = 1:6
    assert(finalBowls{id} == oracleSauce.bowls{id}, ...
        ['Discovery 11 zmieniło poprawną final bowl ', num2str(id), '.']);
    assert(ctx.postStirBowlsCandidate{id} == oracleSauce.bowls{id}, ...
        ['Kontekst utracił poprawną final bowl ', num2str(id), '.']);
end

assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_11_LOST_ORDER_AT_DROP_46')), ...
    'Brakuje śladu Discovery 11.');
metricKey = matlab.lang.makeValidName( ...
    'discovery11.lostOrderAtDrop46.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik lost-order-at-drop-46 jest niepoprawny.');

divergent = ~isequal(queriedOrder, oracleSauce.orderAtDrop46);

fprintf(['STAGE22 DISCOVERY11 DROP46=[%s] QUERY=[%s] ', ...
    'LAST_SOURCE=%s WRITES=%d CLASSIFICATION=%s\n'], ...
    orderText(oracleSauce.orderAtDrop46), orderText(queriedOrder), ...
    ctx.legacyOrderMemoryLastSource, ctx.legacyOrderMemoryWriteCount, ...
    classification(divergent));

caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 22.');

if divergent
    assert(isequal(queriedOrder, expectedPostStir12), ...
        'Discovery 11 powinno publikować dokładnie order post-stir 12.');
    fprintf('STAGE_22_DISCOVERY_11_EXPECTED_RED\n');
    error('Pastafari:Discovery11:LostOrderAtDrop46', ...
        ['Oczekiwana rozbieżność Discovery 11: queryOrder czyta jedno ', ...
         'nadpisywalne pole po 12 post-stirs zamiast zachowanego order drop 46.']);
end

fprintf('STAGE_22_DISCOVERY_11_REGRESSION_GREEN\n');
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
