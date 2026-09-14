function run_stage20_tests()
% DISCOVERY 10: sześć bowl updates jest wykonywanych sekwencyjnie in-place.
% Surowa blizna ma pozostać po PATCH 10, ale publikowany first-round/final
% ma wtedy przejść na GREEN przez vaultOld + pending + późny commit.

run_stage19_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

% Dokładny, mały witness historycznego zanieczyszczenia.
fixtureBowls = { ...
    pastafari.BigInt(11), pastafari.BigInt(13), ...
    pastafari.BigInt(17), pastafari.BigInt(19), ...
    pastafari.BigInt(23), pastafari.BigInt(29)};
fixtureStoneRow = { ...
    pastafari.BigInt(2), pastafari.BigInt(3), ...
    pastafari.BigInt(5), pastafari.BigInt(7), ...
    pastafari.BigInt(11)};
fixtureDrop = pastafari.BigInt(1);
fixtureIndex = 4;
fixtureOrder = 1:6;

fixturePours = pastafari.BowlAliasPatch.computePours( ...
    fixtureBowls, fixtureDrop, fixtureStoneRow, ...
    fixtureIndex, fixtureOrder);

legacyFixture = pastafari.LegacyInPlaceBowlUpdateWrong.apply( ...
    fixtureBowls, fixtureIndex, fixtureDrop, fixtureStoneRow, ...
    fixtureOrder, fixturePours);
referenceFixture = referenceOneRound( ...
    fixtureBowls, fixtureIndex, fixtureDrop, fixtureStoneRow, ...
    fixtureOrder, fixturePours);

expectedLegacy = { ...
    pastafari.BigInt('23205'), ...
    pastafari.BigInt('2167757877'), ...
    pastafari.BigInt('18796698741299337031'), ...
    pastafari.BigInt('52134066600902479800271676581807921729'), ...
    pastafari.BigInt('49276137518158613509478075707571518903'), ...
    pastafari.BigInt('122328037836810514334452521434516846956')};
expectedReference = { ...
    pastafari.BigInt('23205'), ...
    pastafari.BigInt('23443'), ...
    pastafari.BigInt('49647'), ...
    pastafari.BigInt('18871'), ...
    pastafari.BigInt('28375'), ...
    pastafari.BigInt('13610')};

for id = 1:6
    assert(legacyFixture{id} == expectedLegacy{id}, ...
        ['Historyczny witness ma błędną bowl ', num2str(id), '.']);
    assert(referenceFixture{id} == expectedReference{id}, ...
        ['Reference witness ma błędną bowl ', num2str(id), '.']);
end
assert(legacyFixture{1} == referenceFixture{1}, ...
    'Pierwsza pozycja powinna jeszcze widzieć wyłącznie stare misy.');
for id = 2:6
    assert(legacyFixture{id} ~= referenceFixture{id}, ...
        ['Bowl ', num2str(id), ...
         ' powinna ujawnić zanieczyszczenie po wcześniejszym write.']);
end

% Integracja: PATCH 09 pozostaje zielony, a nowa warstwa Discovery 10
% dostaje ten sam input i dodaje wyłącznie wadę write-in-place.
foundation = pastafari.BigInt('-15055671');
counts = referenceWorkCounts(foundation, foundation);
stones = referenceStones();
visible = repmat({pastafari.BigInt(1)}, 1, 46);

ctxBefore = pastafari.MonsterContext(foundation, foundation);
[ctxBefore, preInPlaceFinal] = ...
    pastafari.BowlPourCompatibilityRoute.call( ...
        ctxBefore, counts, stones, visible);
referenceFinal = referenceRounds(counts, stones, visible);

for id = 1:6
    assert(preInPlaceFinal{id} == referenceFinal{id}, ...
        ['PATCH 09 przestał być zielony przed Discovery 10, bowl ', ...
         num2str(id), '.']);
end

initial = referenceInitialBowls(counts);
firstOrder = referenceOrderFromDrop(visible{1});
firstPours = referencePours( ...
    initial, visible{1}, stones(1, :), 1, firstOrder);
referenceFirst = referenceOneRound( ...
    initial, 1, visible{1}, stones(1, :), firstOrder, firstPours);

ctx = pastafari.MonsterContext(foundation, foundation);
[ctx, actualFinal] = pastafari.BowlStirCompatibilityRoute.call( ...
    ctx, counts, stones, visible, preInPlaceFinal);

assert(isequal(firstOrder, 1:6), ...
    'Kontrolowany drop 1 musi dawać identity order.');

rawFirstDivergence = false(1, 6);
publishedFirstDivergence = false(1, 6);
for id = 1:6
    rawFirstDivergence(id) = ...
        ctx.legacyInPlaceFirstRoundBowls{id} ~= referenceFirst{id};
    publishedFirstDivergence(id) = ...
        ctx.firstRoundStirCandidate{id} ~= referenceFirst{id};

    fprintf(['STAGE20 DISCOVERY10 BOWL=%d RAW=%s ACTUAL=%s ', ...
        'EXPECTED=%s CLASSIFICATION=%s\n'], ...
        id, char(ctx.legacyInPlaceFirstRoundBowls{id}), ...
        char(ctx.firstRoundStirCandidate{id}), char(referenceFirst{id}), ...
        classification(publishedFirstDivergence(id)));
end

% Blizna historyczna musi pozostać dokładnie: pierwsza pozycja zgodna,
% pozostałe pięć skażone.
assert(isequal(rawFirstDivergence, ...
    [false true true true true true]), ...
    'Surowa blizna in-place ma nieoczekiwany wzorzec divergence.');

assert(isequal(ctx.preInPlaceBowlsCandidate, preInPlaceFinal), ...
    'Kontekst nie zachował zielonego wyniku PATCH 09 sprzed nowej wady.');
assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_10_IN_PLACE_BOWL_CONTAMINATION')), ...
    'Brakuje śladu Discovery 10.');

metricKey = matlab.lang.makeValidName( ...
    'discovery10.inPlaceBowlContamination.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik in-place bowl contamination jest niepoprawny.');

caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 20.');

if any(publishedFirstDivergence)
    assert(isequal(publishedFirstDivergence, ...
        [false true true true true true]), ...
        ['Discovery 10 powinno izolować wyłącznie sekwencyjne ', ...
         'zanieczyszczenie bowl writes.']);
    fprintf('STAGE_20_DISCOVERY_10_EXPECTED_RED\n');
    error('Pastafari:Discovery10:InPlaceBowlContamination', ...
        ['Oczekiwana rozbieżność Discovery 10: późniejsze positions ', ...
         'czytają bowls zmienione wcześniej w tym samym round.']);
end

for id = 1:6
    assert(actualFinal{id} == referenceFinal{id}, ...
        ['Po PATCH 10 końcowa bowl ', num2str(id), ...
         ' musi wrócić do ścieżki transakcyjnej.']);
end

fprintf('STAGE_20_DISCOVERY_10_REGRESSION_GREEN\n');
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

function nextBowls = referenceOneRound( ...
        old, i, drop, stoneRow, order, pours)
stoneByPosition = [1 2 3 4 5 1];
nextBowls = cell(1, 6);

for position = 1:6
    id = order(position);
    previousId = order(wrap1(position - 1, 6));
    nextId = order(wrap1(position + 1, 6));

    s = old{id} + pastafari.BigInt(2) * old{previousId} + ...
        pastafari.BigInt(3) * old{nextId} + pours{position} + ...
        drop + stoneRow{stoneByPosition(position)};

    nextBowls{id} = saveReference( ...
        s.square() + pastafari.BigInt(5) * ...
        old{previousId} * old{nextId} + ...
        pastafari.BigInt(i * position));
end
end

function bowls = referenceRounds(counts, stones, visible)
bowls = referenceInitialBowls(counts);
for i = 1:46
    drop = visible{i};
    order = referenceOrderFromDrop(drop);
    pours = referencePours(bowls, drop, stones(i, :), i, order);
    bowls = referenceOneRound(bowls, i, drop, stones(i, :), order, pours);
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
