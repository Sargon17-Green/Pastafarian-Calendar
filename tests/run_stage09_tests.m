function run_stage09_tests()
% PATCH 04: wszystkie pięć kamieni nowego wiersza musi używać snapshotu.

% Niezmieniony regression Discovery 04 musi po PATCH 04 stać się zielony.
run_stage08_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

oracle = normative_oracle('stones');
[patched, legacyRows] = pastafari.StoneSnapshotPatch.buildTable();

assert(isequal(size(patched), [46, 5]), ...
    'PATCH 04 musi zbudować tabelę 46x5.');
assert(isequal(size(legacyRows), [46, 5]), ...
    'PATCH 04 musi zachować równoległą tabelę wyników legacy.');

legacySecondExpected = { ...
    pastafari.BigInt(378), ...
    pastafari.BigInt(1434), ...
    pastafari.BigInt(3780), ...
    pastafari.BigInt(9932), ...
    pastafari.BigInt(25047)};

snapshotSecondExpected = { ...
    pastafari.BigInt(378), ...
    pastafari.BigInt(1073), ...
    pastafari.BigInt(2375), ...
    pastafari.BigInt(6195), ...
    pastafari.BigInt(10493)};

for k = 1:5
    assert(legacyRows{2, k} == legacySecondExpected{k}, ...
        ['Historyczna blizna w wierszu 2, kamień ', num2str(k), ...
         ' nie została zachowana.']);
    assert(patched{2, k} == snapshotSecondExpected{k}, ...
        ['Snapshot w wierszu 2, kamień ', num2str(k), ' jest niepoprawny.']);
end

% Cała tabela po patchu musi być identyczna z lokalnym oracle, nie tylko wiersz 2.
for rowNumber = 1:46
    for stoneNumber = 1:5
        assert(patched{rowNumber, stoneNumber} == oracle{rowNumber, stoneNumber}, ...
            ['PATCH 04 rozchodzi się z oracle: wiersz ', num2str(rowNumber), ...
             ', kamień ', num2str(stoneNumber), '.']);
    end
end

ctx = pastafari.MonsterContext(pastafari.BigInt(0), pastafari.BigInt(0));
[ctx, actual] = pastafari.StoneTableCompatibilityRoute.call(ctx);

for rowNumber = 1:46
    for stoneNumber = 1:5
        assert(actual{rowNumber, stoneNumber} == oracle{rowNumber, stoneNumber}, ...
            ['Trasa produkcyjna po PATCH 04 rozchodzi się z oracle: wiersz ', ...
             num2str(rowNumber), ', kamień ', num2str(stoneNumber), '.']);
    end
end

assert(ctx.legacySecondStoneRow{1} == pastafari.BigInt(378), ...
    'Kontekst utracił pierwszy wynik legacy wiersza 2.');
assert(ctx.legacySecondStoneRow{2} == pastafari.BigInt(1434), ...
    'Kontekst utracił sekwencyjnie zmutowany drugi kamień legacy.');
assert(ctx.stoneTableCandidate{2, 2} == pastafari.BigInt(1073), ...
    'Kontekst nie zachował poprawionego snapshotu drugiego kamienia.');

assert(any(strcmp(ctx.branchTrace, 'DISCOVERY_04_SEQUENTIAL_STONES')), ...
    'Brakuje śladu historycznej mutacji sekwencyjnej.');
assert(any(strcmp(ctx.branchTrace, 'PATCH_04_STONE_SNAPSHOT')), ...
    'Brakuje śladu PATCH 04.');

legacyKey = matlab.lang.makeValidName('discovery04.sequentialStoneMutation.calls');
patchKey = matlab.lang.makeValidName('patch04.stoneSnapshot.calls');
assert(isfield(ctx.metrics, legacyKey) && ctx.metrics.(legacyKey) == 1, ...
    'Licznik historycznej mutacji kamieni jest niepoprawny.');
assert(isfield(ctx.metrics, patchKey) && ctx.metrics.(patchKey) == 1, ...
    'Licznik PATCH 04 jest niepoprawny.');

fprintf('STAGE_09_PATCH_04_GREEN\n');
end

function cleanupPaths(root, here)
rmpath(fullfile(root, 'src'));
rmpath(fullfile(here, 'oracle'));
end
