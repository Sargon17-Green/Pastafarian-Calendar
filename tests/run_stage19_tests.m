function run_stage19_tests()
% PATCH 09: bowlAlias[position] = order[position] dla wszystkich pours.

% Niezmieniony regression Discovery 09 ma po PATCH 09 przejść na GREEN.
run_stage18_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');
counts = referenceWorkCounts(foundation, foundation);
stones = referenceStones();

% Kontrolowany pierwszy drop gwarantuje nieidentyczny alias dla positions 1 i 2.
visible = repmat({pastafari.BigInt(1)}, 1, 46);
visible{1} = pastafari.BigInt(121);

initial = referenceInitialBowls(counts);
order = referenceOrderFromDrop(visible{1});
assert(isequal(order, [2 1 3 4 5 6]), ...
    'Fixture PATCH 09 musi mieć order [2 1 3 4 5 6].');

alias = pastafari.BowlAliasPatch.fromOrder(order);
assert(isequal(alias, order), ...
    'bowlAlias musi być dokładnie równy bieżącemu order.');

legacyPours = pastafari.LegacyFixedBowlPourAdapter.compute( ...
    initial, visible{1}, stones(1, :), 1);
patchedPours = pastafari.BowlAliasPatch.computePours( ...
    initial, visible{1}, stones(1, :), 1, order);
expectedPours = referencePours( ...
    initial, visible{1}, stones(1, :), 1, order);

for position = 1:3
    assert(patchedPours{position} == expectedPours{position}, ...
        ['PATCH 09 zwrócił błędny pour dla position ', ...
         num2str(position), '.']);
end
assert(legacyPours{1} ~= expectedPours{1}, ...
    'Historyczna blizna fixed-bowl pour 1 zniknęła.');
assert(legacyPours{2} ~= expectedPours{2}, ...
    'Historyczna blizna fixed-bowl pour 2 zniknęła.');

ctx = pastafari.MonsterContext(foundation, foundation);
[ctx, actualFinal] = pastafari.BowlPourCompatibilityRoute.call( ...
    ctx, counts, stones, visible);
expectedFinal = referenceBowlRounds(counts, stones, visible);

for position = 1:3
    assert(ctx.legacyFirstRoundPours{position} == legacyPours{position}, ...
        ['Kontekst utracił legacy pour ', num2str(position), '.']);
    assert(ctx.firstRoundPoursCandidate{position} == expectedPours{position}, ...
        ['Kontekst utracił alias pour ', num2str(position), '.']);
end

for id = 1:6
    assert(actualFinal{id} == expectedFinal{id}, ...
        ['PATCH 09 rozchodzi się z reference dla bowl ', num2str(id), '.']);
    assert(ctx.bowlsCandidate{id} == expectedFinal{id}, ...
        ['Kontekst utracił publikowaną bowl ', num2str(id), '.']);
end

% Pełna surowa ścieżka legacy nadal musi być rozbieżna.
legacyDiff = false(1, 6);
for id = 1:6
    legacyDiff(id) = ctx.legacyFixedBowlFinalBowls{id} ~= expectedFinal{id};
end
assert(any(legacyDiff), ...
    'Pełna historyczna ścieżka fixed-bowl pours nie może zniknąć.');

assert(any(strcmp(ctx.branchTrace, 'DISCOVERY_09_FIXED_BOWL_POURS')), ...
    'Brakuje śladu historycznych fixed-bowl pours.');
assert(any(strcmp(ctx.branchTrace, 'PATCH_09_BOWL_ALIASES')), ...
    'Brakuje śladu PATCH 09.');

legacyKey = matlab.lang.makeValidName('discovery09.fixedBowlPours.calls');
patchKey = matlab.lang.makeValidName('patch09.bowlAliases.calls');
assert(isfield(ctx.metrics, legacyKey) && ctx.metrics.(legacyKey) == 1, ...
    'Licznik fixed-bowl pours jest niepoprawny.');
assert(isfield(ctx.metrics, patchKey) && ctx.metrics.(patchKey) == 1, ...
    'Licznik bowl aliases jest niepoprawny.');

% Sprawdź kilka odmiennych permutacji, nie tylko kontrolowany [2 1 3 ...].
for rank1 = [1 2 120 121 360 720]
    drop = pastafari.BigInt(rank1);
    order = referenceOrderFromDrop(drop);
    alias = pastafari.BowlAliasPatch.fromOrder(order);
    assert(isequal(alias, order), ...
        ['Alias nie odpowiada order dla rank ', num2str(rank1), '.']);

    actual = pastafari.BowlAliasPatch.computePours( ...
        initial, drop, stones(1, :), 1, order);
    expected = referencePours(initial, drop, stones(1, :), 1, order);
    for position = 1:3
        assert(actual{position} == expected{position}, ...
            ['Alias pour jest błędny dla rank ', num2str(rank1), ...
             ', position ', num2str(position), '.']);
    end
end

fprintf('STAGE_19_PATCH_09_GREEN\n');
end

function counts = referenceWorkCounts(cDay, tDay)
action = referenceDayCount(cDay);
target = referenceDayCount(tDay);
counts = struct( ...
    'action', action, ...
    'target', target, ...
    'distance', abs(tDay - cDay) + pastafari.BigInt(1), ...
    'connection', action + target, ...
    'direction', 2);
end

function value = referenceDayCount(day)
foundation = pastafari.BigInt('-15055671');
if day == foundation
    value = pastafari.BigInt(1);
elseif day > foundation
    value = pastafari.BigInt(2) * (day - foundation) + pastafari.BigInt(1);
else
    value = pastafari.BigInt(2) * (foundation - day);
end
end

function stones = referenceStones()
stones = cell(46, 5);
stones(1, :) = { ...
    pastafari.BigInt(17), pastafari.BigInt(29), ...
    pastafari.BigInt(43), pastafari.BigInt(71), ...
    pastafari.BigInt(101)};
for i = 2:46
    old = stones(i - 1, :);
    stones{i, 1} = saveReference(old{1}.square() + ...
        pastafari.BigInt(3) * old{2} + pastafari.BigInt(i));
    stones{i, 2} = saveReference(old{2}.square() + ...
        pastafari.BigInt(5) * old{3} + old{1});
    stones{i, 3} = saveReference(old{3}.square() + ...
        pastafari.BigInt(7) * old{4} + old{2});
    stones{i, 4} = saveReference(old{4}.square() + ...
        pastafari.BigInt(11) * old{5} + old{3});
    stones{i, 5} = saveReference(old{5}.square() + ...
        pastafari.BigInt(13) * old{1} + old{4});
end
end

function bowls = referenceInitialBowls(counts)
primes = [17 19 23 29 31 37];
bowls = cell(1, 6);
for id = 1:6
    s = counts.action + counts.target * pastafari.BigInt(id) + ...
        counts.distance + counts.connection + ...
        pastafari.BigInt(counts.direction) + ...
        pastafari.BigInt(primes(id) * primes(id));
    bowls{id} = saveReference(s.square() + pastafari.BigInt(id));
end
end

function order = referenceOrderFromDrop(drop)
rank1 = (drop - pastafari.BigInt(1)).regularMod( ...
    pastafari.BigInt(720)) + pastafari.BigInt(1);
rank0 = rank1.toDoubleExact() - 1;
remaining = 1:6;
order = zeros(1, 6);
for position = 1:6
    block = factorial(numel(remaining) - 1);
    q = floor(rank0 / block);
    rank0 = mod(rank0, block);
    order(position) = remaining(q + 1);
    remaining(q + 1) = [];
end
end

function pours = referencePours(old, drop, stoneRow, i, order)
pours = { ...
    pastafari.BigInt(0), pastafari.BigInt(0), ...
    pastafari.BigInt(0), pastafari.BigInt(0), ...
    pastafari.BigInt(0), pastafari.BigInt(0)};
pours{1} = saveReference(drop.square() + ...
    stoneRow{1} * old{order(1)} + pastafari.BigInt(3 * i));
pours{2} = saveReference(drop.square() + ...
    stoneRow{2} * old{order(2)} + pastafari.BigInt(5 * i));
pours{3} = saveReference(drop.square() + ...
    stoneRow{3} * old{order(3)} + pastafari.BigInt(7 * i));
end

function bowls = referenceBowlRounds(counts, stones, visible)
bowls = referenceInitialBowls(counts);
stoneByPosition = [1 2 3 4 5 1];

for i = 1:46
    drop = visible{i};
    order = referenceOrderFromDrop(drop);
    old = bowls;
    pours = referencePours(old, drop, stones(i, :), i, order);
    pending = cell(1, 6);

    for position = 1:6
        id = order(position);
        previousId = order(wrap1(position - 1, 6));
        nextId = order(wrap1(position + 1, 6));
        s = old{id} + pastafari.BigInt(2) * old{previousId} + ...
            pastafari.BigInt(3) * old{nextId} + pours{position} + ...
            drop + stones{i, stoneByPosition(position)};
        pending{id} = saveReference(s.square() + pastafari.BigInt(5) * ...
            old{previousId} * old{nextId} + ...
            pastafari.BigInt(i * position));
    end
    bowls = pending;
end
end

function idx = wrap1(position, sizeValue)
idx = mod(position - 1, sizeValue) + 1;
end

function value = saveReference(x)
M = pastafari.BigInt('170141183460469231731687303715884105727');
value = pastafari.BigInt(1) + ...
    (pastafari.BigInt.coerce(x) - pastafari.BigInt(1)).regularMod(M);
end

function cleanupPaths(root)
rmpath(fullfile(root, 'src'));
end
