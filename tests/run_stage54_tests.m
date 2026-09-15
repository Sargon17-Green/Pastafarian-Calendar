function run_stage54_tests()
% Etap 54: finalna integracja. Lekka część jest obowiązkowa; ciężki
% differential z oracle uruchamia się przez PASTAFARI_STAGE54_HEAVY=1.

run_stage53_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'tests', 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

integrationPath = fullfile(root, 'src', '+pastafari', ...
    'finalMonsterIntegration.m');
calendarPath = fullfile(root, 'src', 'calendarDateSpaghetti.m');

assert(exist(integrationPath, 'file') == 2, ...
    'Brakuje produkcyjnej finalMonsterIntegration.');
calendarText = fileread(calendarPath);
assert(contains(calendarText, 'pastafari.finalMonsterIntegration'), ...
    'calendarDateSpaghetti nie jest podłączony do finalnej integracji.');
assert(~contains(calendarText, 'Pastafari:Bootstrap:NotImplementedYet'), ...
    'Kontrolowany bootstrap error Stage 52 nie został usunięty.');
integrationText = fileread(integrationPath);
assert(~contains(integrationText, 'normative_oracle('), ...
    ['Production finalMonsterIntegration nie może wywoływać testowego ', ...
     'normative_oracle.']);
assert(contains(integrationText, 'YearIntervalCompatibilityRoute.call'), ...
    'Finalna trasa musi przechodzić przez PATCH 26.');
assert(contains(integrationText, 'YearStructureCacheCompatibilityRoute.call'), ...
    'Finalna trasa musi przechodzić przez guarded structure cache.');
assert(contains(integrationText, 'MonthDayCompatibilityRoute.call'), ...
    'Finalna trasa musi kończyć strukturę przez occurrence-count patch.');

fprintf('STAGE_54_STATIC_INTEGRATION_TESTS_PASS\n');

if ~strcmp(getenv('PASTAFARI_STAGE54_HEAVY'), '1')
    fprintf('STAGE_54_HEAVY_DIFFERENTIAL_DEFERRED\n');
    fprintf('STAGE_54_TESTS_PASS_STATIC_ONLY\n');
    return
end

pastafari.LegacyYearNumberStructureCache.clear();
normative_oracle('resetGates');

c = pastafari.BigInt('-15055671');
t = c;
ctx = pastafari.MonsterContext(c, t);
[ctx, actual] = pastafari.finalMonsterIntegration(ctx, c, t);
expected = normative_oracle('calendar', c, t);
assertCalendarEqual(actual, expected);

for defect = 1:26
    discoveryPrefix = sprintf('DISCOVERY_%02d_', defect);
    patchPrefix = sprintf('PATCH_%02d_', defect);
    assert(any(startsWith(ctx.branchTrace, discoveryPrefix)), ...
        'Brakuje blizny %s w finalnym branchTrace.', discoveryPrefix);
    assert(any(startsWith(ctx.branchTrace, patchPrefix)), ...
        'Brakuje %s w finalnym branchTrace.', patchPrefix);
end

assert(strcmp(ctx.status, 'GREEN_CANDIDATE_NATIVE_RERUN_DEFERRED'), ...
    'Finalna integracja nie zakończyła się stanem green candidate.');

fprintf('STAGE_54_HEAVY_DIFFERENTIAL_PASS\n');
fprintf('STAGE_54_TESTS_PASS\n');
end

function assertCalendarEqual(actual, expected)
assert(iscell(actual) && numel(actual) == 5, ...
    'Production musi zwracać pięć pól.');
assert(iscell(expected) && numel(expected) == 5, ...
    'Oracle musi zwracać pięć pól.');

assert(actual{1} == expected{1}, 'Niezgodny numer roku.');
assert(strcmp(actual{2}, expected{2}), 'Niezgodna nazwa kotleta.');
assert(actual{3} == expected{3}, 'Niezgodny dzień kotleta.');
assert(strcmp(actual{4}, expected{4}), 'Niezgodna nazwa miesiąca.');
assert(actual{5} == expected{5}, 'Niezgodny dzień miesiąca.');
end

function cleanupPaths(root)
rmpath(fullfile(root, 'src'));
rmpath(fullfile(root, 'tests', 'oracle'));
end
