function run_stage21_tests()
% PATCH 10: vaultOld + pending + commit dopiero po sześciu positions.

% Niezmieniony regression Discovery 10 musi po PATCH 10 stać się zielony.
run_stage20_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

% Dokładny witness z Discovery 10: legacy pozostaje skażone,
% a PATCH 10 musi być równy simultaneous reference.
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
patchedFixture = pastafari.VaultOldPendingPatch.apply( ...
    fixtureBowls, fixtureIndex, fixtureDrop, fixtureStoneRow, ...
    fixtureOrder, fixturePours);
referenceFixture = referenceOneRound( ...
    fixtureBowls, fixtureIndex, fixtureDrop, fixtureStoneRow, ...
    fixtureOrder, fixturePours);

for id = 1:6
    assert(patchedFixture{id} == referenceFixture{id}, ...
        ['PATCH 10 witness jest błędny dla bowl ', num2str(id), '.']);
end
assert(legacyFixture{1} == referenceFixture{1}, ...
    'Surowa blizna position 1 powinna pozostać zgodna.');
for id = 2:6
    assert(legacyFixture{id} ~= referenceFixture{id}, ...
        ['Surowa blizna bowl ', num2str(id), ' niespodziewanie zniknęła.']);
end

foundation = pastafari.BigInt('-15055671');
counts = referenceWorkCounts(foundation, foundation);
stones = referenceStones();

visibleSets = cell(1, 3);
visibleSets{1} = repmat({pastafari.BigInt(1)}, 1, 46);

visibleSets{2} = repmat({pastafari.BigInt(1)}, 1, 46);
visibleSets{2}{1} = pastafari.BigInt(121);
visibleSets{2}{2} = pastafari.BigInt(720);
visibleSets{2}{3} = pastafari.BigInt(2);

cycle = [1 121 720 2 360 17];
visibleSets{3} = cell(1, 46);
for i = 1:46
    visibleSets{3}{i} = pastafari.BigInt(cycle(mod(i - 1, numel(cycle)) + 1));
end

for caseIndex = 1:numel(visibleSets)
    visible = visibleSets{caseIndex};

    preCtx = pastafari.MonsterContext(foundation, foundation);
    [preCtx, preInPlaceFinal] = ...
        pastafari.BowlPourCompatibilityRoute.call( ...
            preCtx, counts, stones, visible);

    expectedFinal = referenceRounds(counts, stones, visible);
    for id = 1:6
        assert(preInPlaceFinal{id} == expectedFinal{id}, ...
            ['PATCH 09 nie jest zielony w case ', num2str(caseIndex), ...
             ', bowl ', num2str(id), '.']);
    end

    ctx = pastafari.MonsterContext(foundation, foundation);
    [ctx, actualFinal] = pastafari.BowlStirCompatibilityRoute.call( ...
        ctx, counts, stones, visible, preInPlaceFinal);

    for id = 1:6
        assert(actualFinal{id} == expectedFinal{id}, ...
            ['PATCH 10 rozchodzi się z reference w case ', ...
             num2str(caseIndex), ', bowl ', num2str(id), '.']);
        assert(ctx.stirBowlsCandidate{id} == expectedFinal{id}, ...
            ['Kontekst utracił patched bowl w case ', ...
             num2str(caseIndex), ', bowl ', num2str(id), '.']);
        assert(ctx.bowlsCandidate{id} == expectedFinal{id}, ...
            ['Publikowana bowlCandidate jest błędna w case ', ...
             num2str(caseIndex), ', bowl ', num2str(id), '.']);
    end

    assert(isequal(ctx.preInPlaceBowlsCandidate, preInPlaceFinal), ...
        'Kontekst utracił zielony stan PATCH 09 sprzed PATCH 10.');

    legacyDiff = false(1, 6);
    for id = 1:6
        legacyDiff(id) = ...
            ctx.legacyInPlaceFinalBowls{id} ~= expectedFinal{id};
    end
    assert(any(legacyDiff), ...
        ['Historyczna ścieżka in-place powinna pozostać rozbieżna w case ', ...
         num2str(caseIndex), '.']);

    assert(any(strcmp(ctx.branchTrace, ...
        'DISCOVERY_10_IN_PLACE_BOWL_CONTAMINATION')), ...
        'Brakuje śladu historycznego Discovery 10.');
    assert(any(strcmp(ctx.branchTrace, ...
        'PATCH_10_VAULT_OLD_PENDING')), ...
        'Brakuje śladu PATCH 10.');

    legacyKey = matlab.lang.makeValidName( ...
        'discovery10.inPlaceBowlContamination.calls');
    patchKey = matlab.lang.makeValidName( ...
        'patch10.vaultOldPending.calls');
    assert(isfield(ctx.metrics, legacyKey) && ctx.metrics.(legacyKey) == 1, ...
        'Licznik historycznej ścieżki in-place jest niepoprawny.');
    assert(isfield(ctx.metrics, patchKey) && ctx.metrics.(patchKey) == 1, ...
        'Licznik PATCH 10 jest niepoprawny.');
end

fprintf('STAGE_21_PATCH_10_GREEN\n');
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

function cleanupPaths(root)
rmpath(fullfile(root, 'src'));
end
