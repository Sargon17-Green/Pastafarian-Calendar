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

stage54Output = '';
auditOutput = '';

try
    header = sprintf([ ...
        'STAGE_55_FINAL_AUDIT_BEGIN\n', ...
        'MATLAB_VERSION=%s\n', ...
        'MATLAB_RELEASE=%s\n', ...
        'PASTAFARI_STAGE54_HEAVY=1\n'], ...
        version, version('-release'));
    fprintf('%s', header);

    % 1. Pełna ścieżka regresji 1..54 + ciężki production/oracle differential.
    stage54Output = evalc('run_stage54_tests();');
    fprintf('%s', stage54Output);

    % 2. Końcowa kontrola kompletności plików etapów.
    auditOutput = [auditOutput, verifyStageInventory(root)]; %#ok<AGROW>

    % 3. Produkcja nie może zależeć od testowego oracle.
    auditOutput = [auditOutput, verifyProductionIsolation(root)]; %#ok<AGROW>

    % 4. Reprezentatywny artefakt każdego PATCH 01..26 musi fizycznie istnieć.
    auditOutput = [auditOutput, verifyPatchInventory(root)]; %#ok<AGROW>

    % 5. Stage 55 jest kandydatem do zamknięcia, nie fałszywym wcześniejszym PASS.
    auditOutput = [auditOutput, verifyStage55Metadata(root)]; %#ok<AGROW>

    % 6. README nie może nadal twierdzić, że bieżący stan to Stage 1.
    auditOutput = [auditOutput, verifyReadme(root)]; %#ok<AGROW>

    fprintf('%s', auditOutput);
    footer = sprintf([ ...
        'STAGE_55_REPOSITORY_AUDIT_PASS\n', ...
        'STAGE_55_NATIVE_VERIFICATION_PASS\n', ...
        'STAGE_55_FINAL_AUDIT_PASS\n']);
    fprintf('%s', footer);

    writeLog(logPath, [header, stage54Output, auditOutput, footer]);
catch err
    report = getReport(err, 'extended', 'hyperlinks', 'off');
    failure = sprintf([ ...
        'STAGE_55_FINAL_AUDIT_FAIL\n', ...
        'ERROR_IDENTIFIER=%s\n', ...
        '%s\n'], err.identifier, report);
    fprintf('%s', failure);
    writeLog(logPath, [ ...
        sprintf('STAGE_55_FINAL_AUDIT_BEGIN\nMATLAB_VERSION=%s\nMATLAB_RELEASE=%s\n', ...
            version, version('-release')), ...
        stage54Output, auditOutput, failure]);
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

function writeLog(path, text)
fid = fopen(path, 'w', 'n', 'UTF-8');
if fid < 0
    error('Pastafari:Stage55:LogOpen', ...
        'Nie można otworzyć końcowego logu: %s', path);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', text);
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
