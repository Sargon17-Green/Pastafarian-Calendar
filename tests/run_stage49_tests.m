function run_stage49_tests()
% PATCH 24: zachowaj daily ghost, ale publikuj tylko identyczny ghost albo
% exact whole-weave DP unrank.

% Niezmieniony regression Discovery 24 ma po PATCH 24 przejść na GREEN.
run_stage48_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

lengths = [4 4 4];

% 1. Cała family [4,4,4]: production count/unrank kontra test-only brute.
family = pastafari.WholeMonthWeavingFamily(lengths);
assert(family.count() == pastafari.BigInt(1301), ...
    'Whole-weave family [4,4,4] powinna mieć dokładnie 1301 elementów.');

reference = enumerateLegalWeavesTestOnly(lengths);
assert(size(reference, 1) == 1301, ...
    'Test-only brute whole-weave family ma błędny count.');

for r = 1:size(reference, 1)
    actual = family.itemAt1(pastafari.BigInt(r));
    assert(isequal(actual, reference(r, :)), ...
        ['Whole-weave itemAt1 utracił lexicographic order przy rank ', ...
         num2str(r), '.']);
    assert(isLegalWeaving(actual, lengths), ...
        'Whole-weave itemAt1 zwrócił nielegalny splot.');
end

assert(isequal(family.itemAt1(pastafari.BigInt(1)), reference(1, :)), ...
    'Rank 1 whole-weave family jest błędny.');
assert(isequal(family.itemAt1(pastafari.BigInt(1301)), reference(end, :)), ...
    'Ostatni rank whole-weave family jest błędny.');

% 2. Główny Stage 48 witness: raw ghost zostaje, semantic wynik jest DP unrank.
structureSauce = syntheticSauce();
ctx = pastafari.MonsterContext(0, 0);
[ctx, actual] = ...
    pastafari.MonthWeavingCompatibilityRoute.call( ...
        ctx, structureSauce, lengths);

expectedGhost = [2 3 1 2 3 1 2 3 1 2 3 1];
expectedCorrect = [1 1 2 3 2 1 3 2 1 2 3 3];

assert(ctx.monthWeavingStreamFirst == pastafari.BigInt(64145), ...
    'PATCH 24 utracił bowl-4/seal-32 first=64145.');
assert(ctx.monthWeavingStreamDirectionStep == 1, ...
    'PATCH 24 utracił directionStep=+1.');
assert(isequal(ctx.legacyDailyMonthWeaving, expectedGhost), ...
    'PATCH 24 zmienił historyczny daily ghost.');
assert(isequal(ctx.legacyDailyMonthRawProposals, expectedGhost), ...
    'PATCH 24 zmienił raw daily proposals.');
assert(isequal(ctx.legacyDailyMonthRemainingFinal, [0 0 0]), ...
    'PATCH 24 zmienił finalne multiplicities ghosta.');

assert(ctx.wholeMonthWeavingFamilyCount == pastafari.BigInt(1301), ...
    'PATCH 24 ma błędny whole-weave family count.');
assert(ctx.wholeMonthWeavingRank == pastafari.BigInt(396), ...
    'PATCH 24 powinien wybrać whole-weave rank 396.');
assert(isequal(ctx.wholeMonthWeavingDPResult, expectedCorrect), ...
    'Kontekst utracił exact DP-unrank result.');
assert(~ctx.wholeMonthWeavingReusedGhost, ...
    'Nielegalny Stage 48 ghost nie może zostać reuse.');
assert(isequal(actual, expectedCorrect), ...
    'Publikowany whole weave jest błędny.');
assert(isequal(ctx.monthWeavingCandidate, expectedCorrect), ...
    'Kontekst utracił semantic month-weaving candidate.');
assert(isLegalWeaving(actual, lengths), ...
    'Publikowany splot musi być legalny.');

% 3. Trzy historyczne answer-ring witnesses: jeden rank dla całego splotu.
witnesses = { ...
    struct( ...
        'first', ...
            '156621837332624240885492203280715109403', ...
        'step', 1, ...
        'rank', 259, ...
        'correct', [1 1 2 2 1 3 2 1 3 3 2 3]), ...
    struct( ...
        'first', ...
            '80803525669999255172801708465153447025', ...
        'step', -1, ...
        'rank', 23, ...
        'correct', [1 1 1 2 1 2 2 3 3 2 3 3]), ...
    struct( ...
        'first', ...
            '38196695267841223610584811766559928411', ...
        'step', 1, ...
        'rank', 1129, ...
        'correct', [1 2 3 1 3 2 1 1 3 2 2 3])};

for k = 1:numel(witnesses)
    w = witnesses{k};
    stream = struct( ...
        'first', pastafari.BigInt(w.first), ...
        'directionStep', w.step);

    [ghost, ~, ~] = ...
        pastafari.legacyChooseEachDaySeparately(stream, lengths);

    localCtx = pastafari.MonsterContext(0, 0);
    [localCtx, count, rank, result, correct, reused] = ...
        pastafari.MonthWeavingDPPatchWrapper.callWithRing( ...
            localCtx, stream, lengths, ghost); %#ok<ASGLU>

    assert(count == pastafari.BigInt(1301), ...
        'Historyczny witness ma błędny whole-family count.');
    assert(rank == pastafari.BigInt(w.rank), ...
        ['Historyczny witness ', num2str(k), ' ma błędny rank.']);
    assert(isequal(correct, w.correct), ...
        ['Historyczny witness ', num2str(k), ' ma błędny DP unrank.']);
    assert(isequal(result, w.correct), ...
        ['Historyczny witness ', num2str(k), ' publikuje błędny splot.']);
    assert(~reused, ...
        'Nielegalny historyczny ghost nie może być reuse.');
    assert(isLegalWeaving(result, lengths), ...
        'Każdy patched historyczny witness musi być legalny.');
end

% 4. Reuse branch: dla jednego miesiąca ghost jest jedynym legalnym splotem.
singleLengths = [4];
singleStream = struct( ...
    'first', pastafari.BigInt(12345), ...
    'directionStep', 1);
[singleGhost, ~, ~] = ...
    pastafari.legacyChooseEachDaySeparately(singleStream, singleLengths);

singleCtx = pastafari.MonsterContext(0, 0);
[singleCtx, singleCount, singleRank, singleResult, ...
    singleCorrect, singleReused] = ...
    pastafari.MonthWeavingDPPatchWrapper.callWithRing( ...
        singleCtx, singleStream, singleLengths, singleGhost); %#ok<ASGLU>

assert(singleCount == pastafari.BigInt(1) && ...
       singleRank == pastafari.BigInt(1), ...
    'Jednomiesięczna family powinna mieć dokładnie jeden rank.');
assert(singleReused, ...
    'Jeżeli ghost==correct, PATCH 24 powinien reuse ghost.');
assert(isequal(singleGhost, [1 1 1 1]) && ...
       isequal(singleCorrect, singleGhost) && ...
       isequal(singleResult, singleGhost), ...
    'Reuse branch ma niepoprawny jednomiesięczny wynik.');

% 5. Trace + metrics zachowują jednocześnie scar i patch.
assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_24_DAILY_MONTH_CHOOSER')), ...
    'Brakuje raw Discovery 24 trace.');
assert(any(strcmp(ctx.branchTrace, ...
    'PATCH_24_WEAVING_DP_DETOUR')), ...
    'Brakuje PATCH 24 trace.');

legacyKey = matlab.lang.makeValidName( ...
    'discovery24.dailyMonthChooser.calls');
patchKey = matlab.lang.makeValidName( ...
    'patch24.weavingDPDetour.calls');

assert(isfield(ctx.metrics, legacyKey) && ...
       ctx.metrics.(legacyKey) == 1, ...
    'Raw Discovery 24 metric jest błędny.');
assert(isfield(ctx.metrics, patchKey) && ...
       ctx.metrics.(patchKey) == 1, ...
    'PATCH 24 metric jest błędny.');

% 6. Fizyczny legacy chooser pozostaje nielegalnym ghostem.
legacyAgainStream = pastafari.buildMonthWeavingAnswerRing(structureSauce);
[legacyAgain, ~, legacyRemaining] = ...
    pastafari.legacyChooseEachDaySeparately( ...
        legacyAgainStream, lengths);
assert(isequal(legacyAgain, expectedGhost), ...
    'legacyChooseEachDaySeparately został zmieniony przez PATCH 24.');
assert(isequal(legacyRemaining, [0 0 0]), ...
    'Legacy chooser utracił historyczne multiplicities.');
assert(~isLegalWeaving(legacyAgain, lengths), ...
    'Legacy chooser nie może zostać cicho naprawiony.');

fprintf('STAGE_49_PATCH_24_GREEN\n');
end

function ways = enumerateLegalWeavesTestOnly(lengths)
lengths = double(lengths(:).');
totalDays = sum(lengths);
buffer = zeros(1, totalDays);
ways = zeros(0, totalDays);

visit(lengths, 0, 0, 1);

    function visit(remaining, openedUpTo, closedUpTo, position)
        if position > totalDays
            ways(end + 1, :) = buffer; %#ok<AGROW>
            return
        end

        for j = 1:numel(lengths)
            if remaining(j) == 0
                continue
            end

            alreadyOpened = remaining(j) < lengths(j);
            if ~alreadyOpened && j ~= openedUpTo + 1
                continue
            end

            willClose = remaining(j) == 1;
            if willClose && j ~= closedUpTo + 1
                continue
            end

            nextRemaining = remaining;
            nextOpened = openedUpTo;
            nextClosed = closedUpTo;

            if nextRemaining(j) == lengths(j)
                nextOpened = j;
            end

            nextRemaining(j) = nextRemaining(j) - 1;

            if nextRemaining(j) == 0
                nextClosed = j;
            end

            buffer(position) = j;
            visit(nextRemaining, nextOpened, nextClosed, position + 1);
        end
    end
end

function tf = isLegalWeaving(weaving, lengths)
lengths = double(lengths(:).');
remaining = lengths;
openedUpTo = 0;
closedUpTo = 0;
tf = true;

if numel(weaving) ~= sum(lengths)
    tf = false;
    return
end

for position = 1:numel(weaving)
    j = weaving(position);

    if ~(isnumeric(j) && isscalar(j) && isfinite(j) && ...
            fix(j) == j && j >= 1 && j <= numel(lengths))
        tf = false;
        return
    end

    if remaining(j) == 0
        tf = false;
        return
    end

    alreadyOpened = remaining(j) < lengths(j);
    if ~alreadyOpened && j ~= openedUpTo + 1
        tf = false;
        return
    end

    willClose = remaining(j) == 1;
    if willClose && j ~= closedUpTo + 1
        tf = false;
        return
    end

    if remaining(j) == lengths(j)
        openedUpTo = j;
    end

    remaining(j) = remaining(j) - 1;

    if remaining(j) == 0
        closedUpTo = j;
    end
end

tf = all(remaining == 0);
end

function sauce = syntheticSauce()
sauce = struct( ...
    'bowls', {{ ...
        pastafari.BigInt(17), pastafari.BigInt(19), ...
        pastafari.BigInt(23), pastafari.BigInt(29), ...
        pastafari.BigInt(31), pastafari.BigInt(37)}}, ...
    'orderAt46Latch', [1 2 3 4 5 6]);
end

function cleanupPaths(root)
pastafari.LegacyYearNumberStructureCache.clear();
rmpath(fullfile(root, 'src'));
end
