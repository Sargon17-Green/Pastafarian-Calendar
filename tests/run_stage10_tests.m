function run_stage10_tests()
% DISCOVERY 05: hidden są fizycznie zapisane w kolejności 7..1.
% Regresja zachowuje fizyczną bliznę, ale klasyfikuje stan według
% logicznego wyniku publikowanego przez HiddenCompatibilityRoute.
% Po PATCH 05 ten sam test ma przejść na GREEN bez odwracania magazynu.

run_stage09_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

foundation = pastafari.BigInt('-15055671');
cases = { ...
    foundation, foundation; ...
    foundation - 3, foundation + 4};
labels = {'FOUNDATION_SAME', 'CROSS_FOUNDATION'};

anyDivergence = false;

for caseIndex = 1:size(cases, 1)
    c = cases{caseIndex, 1};
    t = cases{caseIndex, 2};

    counts = normative_oracle('workCounts', c, t);
    stones = normative_oracle('stones');
    expected = referenceHiddenDrops(counts, stones);

    storage = pastafari.LegacyBackwardHiddenStore.build(counts, stones);

    % Historyczna forma pamięci musi pozostać dokładnie 7,6,...,1.
    for k = 1:7
        assert(storage{k} == expected{8 - k}, ...
            ['Magazyn legacy nie jest dokładnym odwróceniem hidden dla ', ...
             labels{caseIndex}, ', slot ', num2str(k), '.']);
    end

    ctx = pastafari.MonsterContext(c, t);
    [ctx, actual] = pastafari.HiddenCompatibilityRoute.call(ctx, counts, stones);

    % Niezależnie od obecności PATCH 05 kontekst ma zachować naiwny
    % historyczny odczyt slot-k jako obserwowalną bliznę.
    assert(numel(ctx.legacyHiddenLogicalCandidate) == 7, ...
        'Kontekst nie zachował siedmiu naiwnych odczytów legacy.');
    for k = 1:7
        assert(ctx.legacyHiddenLogicalCandidate{k} == storage{k}, ...
            ['Kontekst utracił naiwny odczyt legacy dla ', ...
             labels{caseIndex}, ', hidden ', num2str(k), '.']);
    end

    assert(isequal(ctx.hiddenBackward, storage), ...
        ['Kontekst nie zachował fizycznego magazynu backward dla ', ...
         labels{caseIndex}, '.']);
    assert(any(strcmp(ctx.branchTrace, ...
        'DISCOVERY_05_BACKWARD_HIDDEN_STORAGE')), ...
        'Brakuje śladu Discovery 05.');

    metricKey = matlab.lang.makeValidName( ...
        'discovery05.backwardHiddenStorage.calls');
    assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
        'Licznik backward hidden storage jest niepoprawny.');

    divergent = false(1, 7);
    for k = 1:7
        divergent(k) = actual{k} ~= expected{k};
        fprintf(['STAGE10 DISCOVERY05 CASE=%s HIDDEN=%d ACTUAL=%s ', ...
            'EXPECTED=%s CLASSIFICATION=%s\n'], ...
            labels{caseIndex}, k, char(actual{k}), char(expected{k}), ...
            classification(divergent(k)));
    end

    anyDivergence = anyDivergence || any(divergent);
end

caught = false;
try
    calendarDateSpaghetti(foundation - 3, foundation + 4);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 10.');

if anyDivergence
    fprintf('STAGE_10_DISCOVERY_05_EXPECTED_RED\n');
    error('Pastafari:Discovery05:BackwardHiddenStorage', ...
        ['Oczekiwana rozbieżność Discovery 05: fizyczny magazyn hidden ma ', ...
         'kolejność 7..1, a bieżąca trasa nie tłumaczy jeszcze logicznego indeksu.']);
end

fprintf('STAGE_10_DISCOVERY_05_REGRESSION_GREEN\n');
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
