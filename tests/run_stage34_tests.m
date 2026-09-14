function run_stage34_tests()
% DISCOVERY 17: Year 5000 jest sortowany stabilnie tylko po długości.
% Equal-length runs mają złą kolejność opening gate przed PATCH 17.

run_stage33_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

rawCandidates = { ...
    makeCandidate(1, 30, 3000, 400), ...
    makeCandidate(2, 50, 5000, 300), ...
    makeCandidate(3, 10, 1000, 400), ...
    makeCandidate(4, 20, 2000, 300), ...
    makeCandidate(5, 25, 2500, 400), ...
    makeCandidate(6, 1, 100, 500)};

% PATCH 16 musi pozostawić wszystkie te kandydaty i ich kolejność.
ctx = pastafari.MonsterContext(0, 0);
[ctx, filtered] = ...
    pastafari.YearCandidateCompatibilityRoute.call(ctx, rawCandidates);
assert(isequal(candidateIds(filtered), [1 2 3 4 5 6]), ...
    'PATCH 16 nie powinien zmieniać kolejności poprawnych kandydatów.');

legacyOrdered = ...
    pastafari.LegacyYear5000StableLengthSort.apply(filtered);
legacyIds = candidateIds(legacyOrdered);
assert(isequal(legacyIds, [2 4 1 3 5 6]), ...
    'Historyczny stabilny sort tylko po długości jest nieoczekiwany.');

% Normatywnie: length rośnie, a tylko w obrębie równego length
% opening gate również rośnie.
normativeOrdered = normativeYear5000Order(filtered);
normativeIds = candidateIds(normativeOrdered);
assert(isequal(normativeIds, [4 2 3 5 1 6]), ...
    'Normatywny fixture Year 5000 jest nieoczekiwany.');

% Dwie niezależne tie runs mają być błędne w legacy.
assert(isequal(candidateIds(legacyOrdered(1:2)), [2 4]), ...
    'Legacy run length=300 utracił stabilność wejścia.');
assert(isequal(candidateIds(normativeOrdered(1:2)), [4 2]), ...
    'Normatywny run length=300 powinien sortować opening gate.');
assert(isequal(candidateIds(legacyOrdered(3:5)), [1 3 5]), ...
    'Legacy run length=400 utracił stabilność wejścia.');
assert(isequal(candidateIds(normativeOrdered(3:5)), [3 5 1]), ...
    'Normatywny run length=400 powinien sortować opening gate.');

[ctx, actual] = ...
    pastafari.Year5000OrderingCompatibilityRoute.call(ctx, filtered);

assert(isequal( ...
    candidateIds(ctx.year5000InputCandidates), [1 2 3 4 5 6]), ...
    'Kontekst utracił input Year 5000.');
assert(isequal( ...
    candidateIds(ctx.legacyYear5000StableLengthOrder), legacyIds), ...
    'Kontekst utracił raw stable-length order.');

assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_17_YEAR_5000_TIE')), ...
    'Brakuje śladu Discovery 17.');
metricKey = matlab.lang.makeValidName( ...
    'discovery17.year5000Tie.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik Year 5000 tie jest niepoprawny.');

actualIds = candidateIds(actual);
rawPattern = isequal(actualIds, legacyIds);
greenPattern = isequal(actualIds, normativeIds);
assert(rawPattern || greenPattern, ...
    ['Stage 34 powinno publikować stable-length legacy order przed ', ...
     'PATCH 17 albo dokładny tie-run order po PATCH 17.']);

fprintf(['STAGE34 DISCOVERY17 RAW=[%s] ACTUAL=[%s] ', ...
    'EXPECTED=[%s] CLASSIFICATION=%s\n'], ...
    rowText(legacyIds), rowText(actualIds), rowText(normativeIds), ...
    classification(rawPattern));

foundation = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 34.');

if rawPattern
    fprintf('STAGE_34_DISCOVERY_17_EXPECTED_RED\n');
    error('Pastafari:Discovery17:Year5000Tie', ...
        ['Oczekiwana rozbieżność Discovery 17: equal-length Year 5000 ', ...
         'runs zachowują input order zamiast opening-gate order.']);
end

fprintf('STAGE_34_DISCOVERY_17_REGRESSION_GREEN\n');
end

function candidate = makeCandidate(id, openIndex, openDay, lengthDays)
candidate = struct( ...
    'id', id, ...
    'openGateIndex', pastafari.BigInt(openIndex), ...
    'closeGateIndex', pastafari.BigInt(openIndex + 6), ...
    'openGateDay', pastafari.BigInt(openDay), ...
    'closeGateDay', pastafari.BigInt(openDay + lengthDays));
end

function ordered = normativeYear5000Order(candidates)
ordered = candidates;
for i = 2:numel(ordered)
    current = ordered{i};
    j = i - 1;
    while j >= 1 && greaterYear5000(ordered{j}, current)
        ordered{j + 1} = ordered{j};
        j = j - 1;
    end
    ordered{j + 1} = current;
end
end

function tf = greaterYear5000(a, b)
la = candidateLength(a);
lb = candidateLength(b);
if la > lb
    tf = true;
elseif la < lb
    tf = false;
else
    tf = pastafari.BigInt.coerce(a.openGateDay) > ...
        pastafari.BigInt.coerce(b.openGateDay);
end
end

function lengthDays = candidateLength(candidate)
lengthDays = pastafari.BigInt.coerce(candidate.closeGateDay) - ...
    pastafari.BigInt.coerce(candidate.openGateDay);
end

function values = candidateIds(candidates)
values = zeros(1, numel(candidates));
for k = 1:numel(candidates)
    values(k) = candidates{k}.id;
end
end

function text = rowText(values)
text = strtrim(sprintf('%d ', values));
end

function text = classification(isRed)
if isRed
    text = 'EXPECTED_RED';
else
    text = 'MATCH';
end
end

function cleanupPaths(root)
rmpath(fullfile(root, 'src'));
end
