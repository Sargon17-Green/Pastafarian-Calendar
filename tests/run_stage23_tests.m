function run_stage23_tests()
% PATCH 11: jednokrotny orderAt46Latch, niezależny od legacy memory.

% Niezmieniony regression Discovery 11 ma po PATCH 11 przejść na GREEN.
run_stage22_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

% Zachowanie samego latcha: przed capture brak wartości, potem dokładnie
% jeden snapshot, a druga próba zapisu musi zostać odrzucona.
latch = pastafari.OrderAt46LatchPatch();

caughtEmpty = false;
try
    latch.queryOrder();
catch err
    caughtEmpty = strcmp(err.identifier, 'Pastafari:OrderLatch:Empty');
end
assert(caughtEmpty, ...
    'orderAt46Latch powinien odrzucać query przed capture.');

source = [4 5 2 3 6 1];
latch.captureOnce(source);
assert(latch.captureCount == 1, ...
    'orderAt46Latch musi mieć dokładnie jeden capture.');
assert(isequal(latch.queryOrder(), source), ...
    'orderAt46Latch nie zachował order z pierwszego capture.');

% Zmiana zmiennej źródłowej nie może zmieniać snapshotu latcha.
source = [1 2 3 4 5 6]; %#ok<NASGU>
assert(isequal(latch.queryOrder(), [4 5 2 3 6 1]), ...
    'orderAt46Latch nie zachowuje niezależnego snapshotu.');

caughtSecond = false;
try
    latch.captureOnce([1 2 3 4 5 6]);
catch err
    caughtSecond = strcmp( ...
        err.identifier, 'Pastafari:OrderLatch:AlreadyCaptured');
end
assert(caughtSecond, ...
    'orderAt46Latch musi odrzucać drugi capture.');
assert(latch.captureCount == 1, ...
    'Druga próba zapisu nie może zwiększyć captureCount.');

% Integracja na Foundation: queryOrder ma zwrócić order 46, podczas gdy
% surowa legacy memory nadal kończy się na post-stir 12 po 58 writes.
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

assert(isequal(queriedOrder, oracleSauce.orderAtDrop46), ...
    'PATCH 11 nie publikuje order z drop 46.');
assert(isequal(ctx.queriedOrderCandidate, oracleSauce.orderAtDrop46), ...
    'Kontekst utracił publikowany orderAt46Latch.');

assert(ctx.legacyOrderMemoryWriteCount == 58, ...
    'PATCH 11 nie może zmieniać liczby historycznych writes.');
assert(strcmp(ctx.legacyOrderMemoryLastSource, 'post-stir 12'), ...
    'PATCH 11 nie może zmieniać ostatniego źródła legacy memory.');
assert(isequal( ...
    ctx.legacyOverwritableOrderMemoryFinal, [1 6 5 2 4 3]), ...
    'PATCH 11 nie może zmieniać końcowego raw legacy order.');
assert(~isequal( ...
    ctx.legacyOverwritableOrderMemoryFinal, queriedOrder), ...
    'Raw legacy memory i latch nie powinny zostać przypadkowo scalone.');

for id = 1:6
    assert(finalBowls{id} == oracleSauce.bowls{id}, ...
        ['PATCH 11 zmienił final bowl ', num2str(id), '.']);
end

assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_11_LOST_ORDER_AT_DROP_46')), ...
    'Brakuje śladu historycznego Discovery 11.');
assert(any(strcmp(ctx.branchTrace, ...
    'PATCH_11_ORDER_AT_46_LATCH')), ...
    'Brakuje śladu PATCH 11.');

legacyKey = matlab.lang.makeValidName( ...
    'discovery11.lostOrderAtDrop46.calls');
patchKey = matlab.lang.makeValidName( ...
    'patch11.orderAt46Latch.calls');
assert(isfield(ctx.metrics, legacyKey) && ctx.metrics.(legacyKey) == 1, ...
    'Licznik historycznego lost-order jest niepoprawny.');
assert(isfield(ctx.metrics, patchKey) && ctx.metrics.(patchKey) == 1, ...
    'Licznik PATCH 11 jest niepoprawny.');

fprintf('STAGE_23_PATCH_11_GREEN\n');
end

function cleanupPaths(root, here)
rmpath(fullfile(root, 'src'));
rmpath(fullfile(here, 'oracle'));
end
