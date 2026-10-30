function run_stage55_normative_micro_native()
% Synthetic Appendix-A micro-year check, NOT the full 4244-day calendar.
% Compare saved hand-checkable five-field cases to MATLAB's bounded rank
% and actual PATCH25 month/day routing, preserving Discovery25 ghost.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
cleanupPath = onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
logDir = fullfile(root,'logs');
if ~exist(logDir,'dir')
    mkdir(logDir);
end
diary(fullfile(logDir,'STAGE55_NORMATIVE_MICRO_NATIVE.log'));
cleanupDiary = onCleanup(@() diary('off')); %#ok<NASGU>

family = pastafari.WholeMonthWeavingFamilyPolynomial([2 2]);
assert(family.count() == pastafari.BigInt(2), ...
    'Brute-force micro reference expects exactly two legal words.');
referenceWords = [1 1 2 2; 1 2 1 2];
expectedMonths = [1 1 2 2; 1 2 1 2];
expectedDays = [1 2 1 2; 1 1 2 2];
catalog = pastafari.sourceLanguageCatalog();
assert(strcmp(catalog.cutlets(1).text,'brąz'));
assert(strcmp(catalog.cutlets(2).text,'lis'));
assert(strcmp(catalog.months(1).text,'glina'));
assert(strcmp(catalog.months(2).text,'granat'));
checked = 0;
for rank = 1:2
    weaving = family.itemAt1(pastafari.BigInt(rank));
    assert(isequal(weaving,referenceWords(rank,:)), ...
        'Production polynomial unrank differs from brute-force micro rank.');
    for position = 1:4
        target = pastafari.BigInt(99 + position);
        ctx = pastafari.MonsterContext(target,target);
        [ctx,monthId,dayInMonth] = ...
            pastafari.MonthDayCompatibilityRoute.call( ...
                ctx,weaving,pastafari.BigInt(99),target);
        assert(monthId == expectedMonths(rank,position));
        assert(dayInMonth == pastafari.BigInt(expectedDays(rank,position)));
        if position == 1
            cutletName = catalog.cutlets(1).text;
            dayInCutlet = pastafari.BigInt(1);
            expectedCutlet = 'brąz';
            expectedCutletDay = 1;
        else
            cutletName = catalog.cutlets(2).text;
            dayInCutlet = pastafari.BigInt(position-1);
            expectedCutlet = 'lis';
            expectedCutletDay = position-1;
        end
        monthName = catalog.months(3-monthId).text;
        actual = {pastafari.BigInt(5000),cutletName,dayInCutlet, ...
            monthName,dayInMonth};
        expectedMonthName = 'granat';
        if expectedMonths(rank,position) == 2
            expectedMonthName = 'glina';
        end
        assert(numel(actual) == 5);
        assert(actual{1} == pastafari.BigInt(5000));
        assert(strcmp(actual{2},expectedCutlet));
        assert(actual{3} == pastafari.BigInt(expectedCutletDay));
        assert(strcmp(actual{4},expectedMonthName));
        assert(actual{5} == pastafari.BigInt(expectedDays(rank,position)));
        assert(any(strcmp(ctx.branchTrace, ...
            'DISCOVERY_25_CONTIGUOUS_MONTH_DAY')));
        assert(any(strcmp(ctx.branchTrace,'PATCH_25_OCCURRENCE_COUNT')));
        checked = checked + 1;
    end
end
assert(checked == 8);
fprintf('STAGE55_NORMATIVE_MICRO_NATIVE_PASS CASES=%d RANKS=2 FIELDS=5\n',checked);
fprintf('STAGE55_FULL_YEAR_ORACLE_NOT_VERIFIED\n');
end
