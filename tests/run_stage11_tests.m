function run_stage11_tests()
% PATCH 05: hidden k ma czytać fizyczny slot 8-k bez odwracania magazynu.

% Po PATCH 05 poprawiona regresja Discovery 05 musi przejść na GREEN.
run_stage10_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');
cases = { ...
    foundation, foundation; ...
    foundation - 3, foundation + 4; ...
    foundation + 12, foundation - 5};
labels = {'FOUNDATION_SAME', 'CROSS_FOUNDATION', 'BACKWARD_WIDE'};

for caseIndex = 1:size(cases, 1)
    c = cases{caseIndex, 1};
    t = cases{caseIndex, 2};

    counts = normative_oracle('workCounts', c, t);
    stones = normative_oracle('stones');
    expected = referenceHiddenDrops(counts, stones);
    storage = pastafari.LegacyBackwardHiddenStore.build(counts, stones);

    % Fizyczna blizna nie może zostać zmieniona przez patch.
    for k = 1:7
        assert(storage{k} == expected{8 - k}, ...
            ['PATCH 05 zmienił fizyczny magazyn dla ', labels{caseIndex}, '.']);
        assert(pastafari.HiddenIndexTranslator.physicalSlot(k) == 8 - k, ...
            ['Translator zwrócił zły slot dla hidden ', num2str(k), '.']);
        assert(pastafari.HiddenIndexTranslator.read(storage, k) == expected{k}, ...
            ['Translator nie odtworzył hidden ', num2str(k), ...
             ' dla ', labels{caseIndex}, '.']);
    end

    ctx = pastafari.MonsterContext(c, t);
    [ctx, actual] = pastafari.HiddenCompatibilityRoute.call(ctx, counts, stones);

    for k = 1:7
        assert(actual{k} == expected{k}, ...
            ['Trasa hidden po PATCH 05 jest błędna dla ', ...
             labels{caseIndex}, ', hidden ', num2str(k), '.']);
        assert(ctx.legacyHiddenLogicalCandidate{k} == storage{k}, ...
            ['Nie zachowano naiwnego odczytu legacy dla ', ...
             labels{caseIndex}, ', hidden ', num2str(k), '.']);
        assert(ctx.hiddenLogicalCandidate{k} == expected{k}, ...
            ['Kontekst nie zachował przetłumaczonego hidden ', ...
             num2str(k), ' dla ', labels{caseIndex}, '.']);
    end

    assert(isequal(ctx.hiddenBackward, storage), ...
        ['PATCH 05 przepisał fizyczny magazyn dla ', labels{caseIndex}, '.']);
    assert(any(strcmp(ctx.branchTrace, ...
        'DISCOVERY_05_BACKWARD_HIDDEN_STORAGE')), ...
        'Brakuje śladu historycznego backward storage.');
    assert(any(strcmp(ctx.branchTrace, ...
        'PATCH_05_HIDDEN_INDEX_TRANSLATOR')), ...
        'Brakuje śladu PATCH 05.');

    legacyKey = matlab.lang.makeValidName( ...
        'discovery05.backwardHiddenStorage.calls');
    patchKey = matlab.lang.makeValidName( ...
        'patch05.hiddenIndexTranslator.calls');
    assert(isfield(ctx.metrics, legacyKey) && ctx.metrics.(legacyKey) == 1, ...
        'Licznik historycznego backward storage jest niepoprawny.');
    assert(isfield(ctx.metrics, patchKey) && ctx.metrics.(patchKey) == 1, ...
        'Licznik PATCH 05 jest niepoprawny.');
end

fprintf('STAGE_11_PATCH_05_GREEN\n');
end

function hidden = referenceHiddenDrops(counts, stones)
coeff = [ ...
    3 4 6 8; ...
    5 7 10 12; ...
    7 10 14 16; ...
    9 13 18 20; ...
    11 16 22 24; ...
    13 19 26 28; ...
    15 22 30 32];
grindStone = [1 2 3 4 5 1 2];
hidden = cell(1, 7);

for k = 1:7
    row = coeff(k, :);
    x = counts.action + ...
        pastafari.BigInt(row(1)) * counts.target + ...
        pastafari.BigInt(row(2)) * counts.distance + ...
        pastafari.BigInt(row(3)) * counts.connection + ...
        pastafari.BigInt(row(4)) * pastafari.BigInt(counts.direction);

    for kind = 1:5
        x = x + stones{k, kind};
    end
    x = saveReference(x);

    for grind = 1:7
        oldX = x;
        x = saveReference( ...
            oldX.square() + pastafari.BigInt(3) * oldX + ...
            stones{k, grindStone(grind)} + pastafari.BigInt(grind));
    end
    hidden{k} = x;
end
end

function value = saveReference(x)
M = pastafari.BigInt('170141183460469231731687303715884105727');
value = pastafari.BigInt(1) + ...
    (pastafari.BigInt.coerce(x) - pastafari.BigInt(1)).regularMod(M);
end

function cleanupPaths(root, here)
rmpath(fullfile(root, 'src'));
rmpath(fullfile(here, 'oracle'));
end
