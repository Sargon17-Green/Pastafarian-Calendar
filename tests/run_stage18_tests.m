function run_stage18_tests()
% DISCOVERY 09: pours czytają stałe bowl IDs 1,2,3 zamiast positions order.
% Surowa blizna ma pozostać po PATCH 09, natomiast publikowane pours
% mają wtedy przejść na GREEN przez bowlAlias[position]=order[position].

run_stage17_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');
counts = referenceWorkCounts(foundation, foundation);
stones = referenceStones();

visible = repmat({pastafari.BigInt(1)}, 1, 46);
visible{1} = pastafari.BigInt(121);

initial = referenceInitialBowls(counts);
order121 = referenceOrderFromDrop(visible{1});
assert(isequal(order121, [2 1 3 4 5 6]), ...
    'Fixture Discovery 09 musi mieć order zaczynający się od [2 1 3].');

legacyPours = pastafari.LegacyFixedBowlPourAdapter.compute( ...
    initial, visible{1}, stones(1, :), 1);
expectedPours = referencePours( ...
    initial, visible{1}, stones(1, :), 1, order121);

assert(legacyPours{1} ~= expectedPours{1}, ...
    'Legacy pour 1 powinien czytać bowl 1 zamiast bowl order(1)=2.');
assert(legacyPours{2} ~= expectedPours{2}, ...
    'Legacy pour 2 powinien czytać bowl 2 zamiast bowl order(2)=1.');
assert(legacyPours{3} == expectedPours{3}, ...
    'Pour 3 powinien przypadkowo pozostać zgodny dla tego fixture.');

ctx = pastafari.MonsterContext(foundation, foundation);
[ctx, actualFinal] = pastafari.BowlPourCompatibilityRoute.call( ...
    ctx, counts, stones, visible);

for position = 1:3
    assert(ctx.legacyFirstRoundPours{position} == legacyPours{position}, ...
        ['Kontekst utracił raw legacy pour ', num2str(position), '.']);
end

expectedFinal = referenceBowlRounds(counts, stones, visible);
divergentPours = false(1, 3);
for position = 1:3
    divergentPours(position) = ...
        ctx.firstRoundPoursCandidate{position} ~= expectedPours{position};

    fprintf(['STAGE18 DISCOVERY09 POUR_POSITION=%d ORDER_BOWL=%d ', ...
        'LEGACY=%s ACTUAL=%s EXPECTED=%s CLASSIFICATION=%s\n'], ...
        position, order121(position), char(legacyPours{position}), ...
        char(ctx.firstRoundPoursCandidate{position}), ...
        char(expectedPours{position}), ...
        classification(divergentPours(position)));
end

assert(isequal(divergentPours, [true true false]) || ...
       ~any(divergentPours), ...
    ['Discovery 09 powinno być RED przed PATCH 09 i GREEN po nim; ', ...
     'inny wzorzec oznacza dodatkową wadę.']);

assert(any(strcmp(ctx.branchTrace, 'DISCOVERY_09_FIXED_BOWL_POURS')), ...
    'Brakuje śladu Discovery 09.');
metricKey = matlab.lang.makeValidName('discovery09.fixedBowlPours.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik fixed-bowl pours jest niepoprawny.');

finalDivergent = false(1, 6);
for id = 1:6
    finalDivergent(id) = actualFinal{id} ~= expectedFinal{id};
end

caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 18.');

if any(divergentPours)
    fprintf('STAGE_18_DISCOVERY_09_EXPECTED_RED\n');
    error('Pastafari:Discovery09:FixedBowlPours', ...
        ['Oczekiwana rozbieżność Discovery 09: pours positions 1..3 ', ...
         'czytają stałe bowl IDs 1..3 zamiast bowlAlias[position].']);
end

for id = 1:6
    assert(~finalDivergent(id), ...
        ['Po naprawie pours końcowa bowl ', num2str(id), ...
         ' musi być zgodna z reference round path.']);
end

fprintf('STAGE_18_DISCOVERY_09_REGRESSION_GREEN\n');
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

function text = classification(isDivergent)
if isDivergent
    text = 'EXPECTED_RED';
else
    text = 'MATCH';
end
end

function cleanupPaths(root)
rmpath(fullfile(root, 'src'));
end
