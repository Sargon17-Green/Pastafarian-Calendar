function run_stage25_tests()
% PATCH 12: successor według pozycji queried ID w orderAt46Latch.

% Niezmieniony regression Discovery 12 ma po PATCH 12 przejść na GREEN.
run_stage24_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

foundationOrder = [4 5 2 3 6 1];
expectedById = [4 3 6 5 2 1];
legacyById = [2 3 4 5 6 1];

for queriedId = 1:6
    expected = expectedById(queriedId);
    actual = pastafari.LatchedSuccessorPatch.apply( ...
        foundationOrder, queriedId);
    assert(actual == expected, ...
        ['PATCH 12 zwrócił błędny successor dla Foundation ID ', ...
         num2str(queriedId), '.']);

    ctx = pastafari.MonsterContext(0, 0);
    [ctx, published] = pastafari.NextBowlCompatibilityRoute.call( ...
        ctx, foundationOrder, queriedId);

    assert(published == expected, ...
        ['Route PATCH 12 zwróciła błędny successor dla ID ', ...
         num2str(queriedId), '.']);
    assert(ctx.nextBowlCandidate == expected, ...
        'Kontekst utracił publikowany successor.');
    assert(ctx.legacyFixedNameSuccessor == legacyById(queriedId), ...
        'PATCH 12 zmienił surowy fixed-name successor.');

    assert(any(strcmp(ctx.branchTrace, ...
        'DISCOVERY_12_FIXED_NAME_SUCCESSOR')), ...
        'Brakuje śladu historycznego Discovery 12.');
    assert(any(strcmp(ctx.branchTrace, ...
        'PATCH_12_LATCHED_SUCCESSOR')), ...
        'Brakuje śladu PATCH 12.');

    legacyKey = matlab.lang.makeValidName( ...
        'discovery12.fixedNameSuccessor.calls');
    patchKey = matlab.lang.makeValidName( ...
        'patch12.latchedSuccessor.calls');
    assert(isfield(ctx.metrics, legacyKey) && ctx.metrics.(legacyKey) == 1, ...
        'Licznik historycznego successor jest niepoprawny.');
    assert(isfield(ctx.metrics, patchKey) && ctx.metrics.(patchKey) == 1, ...
        'Licznik PATCH 12 jest niepoprawny.');
end

% Wrap na końcu latcha: ostatni element musi przejść do pierwszego.
assert(pastafari.LatchedSuccessorPatch.apply( ...
    foundationOrder, foundationOrder(end)) == foundationOrder(1), ...
    'PATCH 12 nie zawija ostatniej pozycji do początku latcha.');

% Sprawdź wszystkie 720 możliwych order oraz wszystkie 6 queried IDs.
allOrders = perms(1:6);
for row = 1:size(allOrders, 1)
    orderAt46 = allOrders(row, :);
    for position = 1:6
        queriedId = orderAt46(position);
        expected = orderAt46(mod(position, 6) + 1);
        actual = pastafari.LatchedSuccessorPatch.apply( ...
            orderAt46, queriedId);
        assert(actual == expected, ...
            ['PATCH 12 nie zachowuje pozycyjnego successor dla order row ', ...
             num2str(row), ', position ', num2str(position), '.']);
    end
end

% Surowa blizna musi pozostać dokładnie fixed-name ring.
for queriedId = 1:6
    assert(pastafari.LegacyFixedNameSuccessor.next(queriedId) == ...
        mod(queriedId, 6) + 1, ...
        'LegacyFixedNameSuccessor został zmieniony.');
end

fprintf('STAGE_25_PATCH_12_GREEN\n');
end

function cleanupPaths(root)
rmpath(fullfile(root, 'src'));
end
