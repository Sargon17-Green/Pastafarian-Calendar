function run_stage55_final_audit()
% Etap 55: końcowy audyt i natywna weryfikacja całej linii MATLAB + polski.
%
% Ten etap nie naprawia produkcji "na zapas". Najpierw wymusza pełny ciężki
% Stage 54 differential, który rekurencyjnie uruchamia wcześniejsze regresje,
% a następnie wykonuje końcowe kontrole integralności repozytorium.
%
% PASS tego pliku jest warunkiem zamknięcia LAST_COMPLETED_STAGE=55.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);

addpath(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'tests', 'oracle'));
pathCleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

oldHeavy = getenv('PASTAFARI_STAGE54_HEAVY');
setenv('PASTAFARI_STAGE54_HEAVY', '1');
envCleanup = onCleanup(@() setenv('PASTAFARI_STAGE54_HEAVY', oldHeavy)); %#ok<NASGU>

logDir = fullfile(root, 'logs');
if exist(logDir, 'dir') ~= 7
    mkdir(logDir);
end
logPath = fullfile(logDir, 'STAGE_55_MATLAB_RUN.log');

% Every stage prints immediately. evalc previously held 49 minutes of output
% in memory; a runner shutdown discarded the test history entirely.
% diary additionally records the same output for artifacts, if available.
if exist(logPath, 'file') == 2
    delete(logPath);
end
diary(logPath);
diary('on');
diaryCleanup = onCleanup(@() diary('off')); %#ok<NASGU>

try
    header = sprintf([ ...
        'STAGE_55_FINAL_AUDIT_BEGIN\n', ...
        'MATLAB_VERSION=%s\n', ...
        'MATLAB_RELEASE=%s\n', ...
        'PASTAFARI_STAGE54_HEAVY=1\n'], ...
        version, version('-release'));
    fprintf('%s', header);

    % 0. Szybki preflight: brak starych oczekiwań NotImplementedYet.
    fprintf('%s', verifyPublicEntryRegressions(root));

    % 0a. MATLAB parses all src/tests before the recursive heavy run.
    fprintf('%s', run_stage55_code_analysis(root));

    % Independent exact endpoint recurrence: exhaustive small frontiers.
    % This is experimental and does not replace production weaving.
    run_stage55_endpoint_counter_tests();

    % 1. Pełna ścieżka regresji 1..54 + ciężki production/oracle differential.
    fprintf('STAGE_55_RECURSIVE_REGRESSIONS_BEGIN\n');
    run_stage54_tests();
    fprintf('STAGE_55_RECURSIVE_REGRESSIONS_PASS\n');

    % 2. Końcowa kontrola kompletności plików etapów.
    fprintf('%s', verifyStageInventory(root));

    % 3. Produkcja nie może zależeć od testowego oracle.
    fprintf('%s', verifyProductionIsolation(root));

    % 4. Reprezentatywny artefakt każdego PATCH 01..26 musi fizycznie istnieć.
    fprintf('%s', verifyPatchInventory(root));

    % 5. Stage 55 jest kandydatem do zamknięcia, nie fałszywym wcześniejszym PASS.
    fprintf('%s', verifyStage55Metadata(root));

    % 6. README nie może nadal twierdzić, że bieżący stan to Stage 1.
    fprintf('%s', verifyReadme(root));

    footer = sprintf([ ...
        'STAGE_55_REPOSITORY_AUDIT_PASS\n', ...
        'STAGE_55_NATIVE_VERIFICATION_PASS\n', ...
        'STAGE_55_FINAL_AUDIT_PASS\n']);
    fprintf('%s', footer);

    % The diary has already recorded header, stages and audit verdict.
catch err
    report = getReport(err, 'extended', 'hyperlinks', 'off');
    failure = sprintf([ ...
        'STAGE_55_FINAL_AUDIT_FAIL\n', ...
        'ERROR_IDENTIFIER=%s\n', ...
        '%s\n'], err.identifier, report);
    fprintf('%s', failure);
    % Failure evidence is streamed to stdout and captured by the diary.
    rethrow(err)
end
end

function out = verifyStageInventory(root)
for stage = 1:55
    path = fullfile(root, 'tests', sprintf('run_stage%02d_tests.m', stage));
    if stage == 55
        path = fullfile(root, 'tests', 'run_stage55_final_audit.m');
    end
    assert(exist(path, 'file') == 2, ...
        'Brakuje pliku testowego dla etapu %d: %s', stage, path);
end
out = sprintf('STAGE_55_STAGE_INVENTORY_PASS\n');
end

function out = verifyProductionIsolation(root)
files = dir(fullfile(root, 'src', '**', '*.m'));
assert(~isempty(files), 'Nie znaleziono plików produkcyjnych MATLAB.');

for k = 1:numel(files)
    path = fullfile(files(k).folder, files(k).name);
    txt = fileread(path);
    assert(~contains(txt, 'normative_oracle('), ...
        'Produkcja odwołuje się do normative_oracle: %s', path);
    assert(~contains(txt, 'tests/oracle'), ...
        'Produkcja odwołuje się do tests/oracle: %s', path);
    assert(~contains(txt, ['tests', filesep, 'oracle']), ...
        'Produkcja odwołuje się do tests/oracle: %s', path);
end

out = sprintf('STAGE_55_PRODUCTION_ORACLE_ISOLATION_PASS\n');
end

function out = verifyPatchInventory(root)
patchFiles = { ...
    'SavePatch.m', ...
    'FoundationScarPatch.m', ...
    'ChronologicalDistancePatch.m', ...
    'StoneSnapshotPatch.m', ...
    'HiddenIndexTranslator.m', ...
    'PriorPatch.m', ...
    'SentinelGrindRowPatch.m', ...
    'OneBasedRankDetourPatch.m', ...
    'BowlAliasPatch.m', ...
    'VaultOldPendingPatch.m', ...
    'OrderAt46LatchPatch.m', ...
    'LatchedSuccessorPatch.m', ...
    'AnswerRingRejectionPatch.m', ...
    'WideSelectionDetourPatch.m', ...
    'SignedGateQuestionPatch.m', ...
    'YearMax5778LateFilter.m', ...
    'Year5000TieRunSortPatch.m', ...
    'SequentialYearWalkPatch.m', ...
    'GuardedYearCachePatch.m', ...
    'StructureSauceDetourPatch.m', ...
    'CutletPartitionGatePatchWrapper.m', ...
    'RepeatedNamePatchWrapper.m', ...
    'VirtualLegacyList.m', ...
    'MonthWeavingDPPatchWrapper.m', ...
    'MonthDayOccurrencePatchWrapper.m', ...
    'OpenClosedYearIntervalPatch.m'};

for k = 1:numel(patchFiles)
    path = fullfile(root, 'src', '+pastafari', patchFiles{k});
    assert(exist(path, 'file') == 2, ...
        'Brakuje reprezentatywnego artefaktu PATCH %02d: %s', k, patchFiles{k});
end

out = sprintf('STAGE_55_PATCH_01_26_INVENTORY_PASS\n');
end

function out = verifyPublicEntryRegressions(root)
% Stage 54 retired the public bootstrap error. The historical Discovery
% tests still exercise their raw legacy paths, but the public entry
% checks must now use the modern, lightweight contract assertion.
helper = fullfile(root, 'tests', 'assert_public_calendar_entry_contract.m');
assert(exist(helper, 'file') == 2, ...
    'Brakuje testowego kontraktu publicznego wejścia.');

stages = [1, 2:2:52];
totalChecks = 0;
for k = 1:numel(stages)
    stage = stages(k);
    path = fullfile(root, 'tests', sprintf('run_stage%02d_tests.m', stage));
    txt = fileread(path);
    assert(~contains(txt, 'Pastafari:Bootstrap:NotImplementedYet'), ...
        'Historyczny błąd bootstrapu pozostaje w teście %s.', path);

    checks = count(txt, 'assert_public_calendar_entry_contract(');
    expected = 1;
    if stage == 1
        expected = 2;
    end
    assert(checks == expected, ...
        'Nieprawidłowa liczba kontroli publicznego wejścia w %s.', path);
    totalChecks = totalChecks + checks;
end

assert(totalChecks == 28, ...
    'Oczekiwano dokładnie 28 odnowionych kontroli publicznego wejścia.');
out = sprintf('STAGE_55_PUBLIC_ENTRY_REGRESSION_AUDIT_PASS\n');
end

function out = verifyStage55Metadata(root)
path = fullfile(root, 'DEVELOPMENT_STAGE.md');
txt = fileread(path);

required = { ...
    'TOTAL_STAGES=55', ...
    'CURRENT_STAGE=55', ...
    'CURRENT_KIND=FINAL_AUDIT_CANDIDATE', ...
    'LAST_COMPLETED_STAGE=54', ...
    'STAGE_55_COMPLETE=NO_AWAITING_NATIVE_FINAL_AUDIT', ...
    'MATLAB_RERUN_REQUIRED=YES', ...
    'FINAL_AUDIT_EXPECTED_MARKER=STAGE_55_FINAL_AUDIT_PASS'};

for k = 1:numel(required)
    assert(contains(txt, required{k}), ...
        'DEVELOPMENT_STAGE.md nie zawiera wymaganego wpisu: %s', required{k});
end

assert(~contains(txt, 'LAST_COMPLETED_STAGE=55'), ...
    'Stage 55 nie może być zamknięty przed rzeczywistym natywnym PASS.');

out = sprintf('STAGE_55_METADATA_CANDIDATE_PASS\n');
end

function out = verifyReadme(root)
path = fullfile(root, 'README.md');
txt = fileread(path);

assert(contains(txt, 'Etap 55'), ...
    'README nie opisuje bieżącego Stage 55 final audit candidate.');
assert(~contains(txt, 'Etap 1 z 55, czyli rozruch, jest zakończony'), ...
    'README nadal przedstawia Stage 1 jako bieżący stan gałęzi.');
assert(contains(txt, 'finalMonsterIntegration'), ...
    'README nie dokumentuje finalnej integracji Stage 54.');

out = sprintf('STAGE_55_README_STATE_PASS\n');
end

function cleanupPaths(root, here)
pastafari.LegacyYearNumberStructureCache.clear();

try
    rmpath(fullfile(root, 'tests', 'oracle'));
catch
end
try
    rmpath(fullfile(root, 'src'));
catch
end
try
    rmpath(here);
catch
end
end
