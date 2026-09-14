function run_stage14_tests()
% DISCOVERY 07: przesunięte indeksowanie tabeli 11 mielenia.
% Ten sam regression ma stać się zielony po dodaniu sentinel row w etapie 15.

run_stage13_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

rows = pastafari.LegacyGrindTableAdapter.rowsWithoutSentinel();
canonicalFirst = [3 5 7 11 1];
legacyFirstExpected = [5 7 11 13 2];

[firstRow, requestedFirst, resolvedFirst] = ...
    pastafari.LegacyGrindTableAdapter.rowForGrind(rows, 1);
assert(isequal(firstRow, legacyFirstExpected), ...
    'Historyczna pierwsza grind musi pobierać drugi wiersz tabeli.');
assert(~isequal(firstRow, canonicalFirst), ...
    'Discovery 07 nie ujawniło przesunięcia pierwszego mielenia.');
assert(requestedFirst == 2 && resolvedFirst == 2, ...
    'Pierwsze mielenie musi żądać i rozwiązać fizyczny indeks 2.');

[~, requestedLast, resolvedLast] = ...
    pastafari.LegacyGrindTableAdapter.rowForGrind(rows, 11);
assert(requestedLast == 12 && resolvedLast == 11, ...
    'Historyczny guard końca tabeli ma nasycić żądanie 12 do ostatniego wiersza.');

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
    hidden = referenceHiddenDrops(counts, stones);
    expected = referenceVisibleDrops(counts, stones, hidden);

    priorCtx = pastafari.MonsterContext(c, t);
    [priorCtx, priorVisible] = ...
        pastafari.VisibleDropCompatibilityRoute.call( ...
            priorCtx, counts, stones, hidden);

    % Stan sprzed Discovery 07 musi być poprawny.
    for i = 1:46
        assert(priorVisible{i} == expected{i}, ...
            ['PATCH 06 nie jest zielony przed Discovery 07 dla ', ...
             labels{caseIndex}, ', drop ', num2str(i), '.']);
    end

    ctx = pastafari.MonsterContext(c, t);
    [ctx, actual] = pastafari.GrindTableCompatibilityRoute.call( ...
        ctx, counts, stones, hidden, priorVisible);

    assert(isequal(ctx.legacyGrindRequestedIndices, 2:12), ...
        'Discovery 07 zapisało nieoczekiwane żądane indeksy grind.');
    assert(isequal(ctx.legacyGrindResolvedIndices, [2:11 11]), ...
        'Discovery 07 zapisało nieoczekiwane rozwiązane indeksy grind.');

    divergent = false(1, 46);
    for i = 1:46
        divergent(i) = actual{i} ~= expected{i};
        if i <= 3
            fprintf(['STAGE14 DISCOVERY07 CASE=%s DROP=%d ACTUAL=%s ', ...
                'EXPECTED=%s CLASSIFICATION=%s\n'], ...
                labels{caseIndex}, i, char(actual{i}), char(expected{i}), ...
                classification(divergent(i)));
        end
    end

    assert(ctx.legacyGrindVisibleDrops{1} == actual{1}, ...
        'Kontekst nie zachował surowego wyniku grind-table legacy.');
    assert(ctx.grindVisibleCandidate{1} == actual{1}, ...
        'Kontekst nie zachował publikowanego wyniku Discovery 07.');
    assert(any(strcmp(ctx.branchTrace, ...
        'DISCOVERY_07_GRIND_TABLE_INDEX')), ...
        'Brakuje śladu Discovery 07.');

    metricKey = matlab.lang.makeValidName( ...
        'discovery07.grindTableIndex.calls');
    assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
        'Licznik grind-table index jest niepoprawny.');

    anyDivergence = anyDivergence || any(divergent);
end

caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 14.');

if anyDivergence
    fprintf('STAGE_14_DISCOVERY_07_EXPECTED_RED\n');
    error('Pastafari:Discovery07:GrindTableIndex', ...
        ['Oczekiwana rozbieżność Discovery 07: historyczne indeksowanie ', ...
         'grind+1 przesuwa 11-wierszową tabelę mielenia.']);
end

fprintf('STAGE_14_DISCOVERY_07_REGRESSION_GREEN\n');
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

function visible = referenceVisibleDrops(counts, stones, hidden)
timeline = cell(1, 53);
for k = 1:7
    timeline{8 - k} = hidden{k};
end

visible = cell(1, 46);
grinds = [ ...
    3 5 7 11 1; ...
    5 7 11 13 2; ...
    7 11 13 17 3; ...
    11 13 17 19 4; ...
    13 17 19 23 5; ...
    17 19 23 29 1; ...
    19 23 29 31 2; ...
    23 29 31 37 3; ...
    29 31 37 41 4; ...
    31 37 41 43 5; ...
    37 41 43 47 1];

for i = 1:46
    p1 = timeline{i + 6};
    p3 = timeline{i + 4};
    p7 = timeline{i};

    x = saveReference( ...
        stones{i, 1} * counts.action + ...
        stones{i, 2} * counts.target + ...
        stones{i, 3} * counts.distance + ...
        stones{i, 4} * counts.connection + ...
        stones{i, 5} * pastafari.BigInt(counts.direction) + ...
        p1 + pastafari.BigInt(3) * p3 + ...
        pastafari.BigInt(5) * p7 + pastafari.BigInt(i));

    for grind = 1:11
        oldX = x;
        row = grinds(grind, :);
        x = saveReference( ...
            oldX.square() + pastafari.BigInt(row(1)) * oldX + ...
            pastafari.BigInt(row(2)) * p1 + ...
            pastafari.BigInt(row(3)) * p3 + ...
            pastafari.BigInt(row(4)) * p7 + ...
            stones{i, row(5)});
    end

    visible{i} = x;
    timeline{i + 7} = x;
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
