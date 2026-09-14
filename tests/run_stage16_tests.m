function run_stage16_tests()
% DISCOVERY 08: zero-based rank jest używany jako końcowa ranga permutacji.
% Ten sam regression ma stać się zielony po one-based rank detour w etapie 17.

run_stage15_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

% Sama historyczna funkcja unrank0 jest poprawnym zero-based unrankiem
% i musi pozostać fizycznie zachowana także po patchu.
first0 = pastafari.LegacyPermutationUnrank0.unrank0( ...
    pastafari.BigInt(0), 1:6);
last0 = pastafari.LegacyPermutationUnrank0.unrank0( ...
    pastafari.BigInt(719), 1:6);
assert(isequal(first0, [1 2 3 4 5 6]), ...
    'Historyczny unrank0 rank 0 powinien zwracać pierwszą permutację.');
assert(isequal(last0, [6 5 4 3 2 1]), ...
    'Historyczny unrank0 rank 719 powinien zwracać ostatnią permutację.');

inputs = {pastafari.BigInt(1), pastafari.BigInt(720)};
expectedRank0 = {pastafari.BigInt(1), pastafari.BigInt(0)};
legacyExpected = { ...
    [1 2 3 4 6 5], ...
    [1 2 3 4 5 6]};
labels = {'RANK_1', 'RANK_720'};

divergent = false(1, 2);

for k = 1:2
    ctx = pastafari.MonsterContext(inputs{k}, inputs{k});
    [ctx, actual] = ...
        pastafari.PermutationCompatibilityRoute.call(ctx, inputs{k});
    expected = normative_oracle('permutation', inputs{k});

    assert(ctx.permutationInput == inputs{k}, ...
        ['Kontekst utracił wejście permutacji dla ', labels{k}, '.']);
    assert(ctx.legacyPermutationRank0 == expectedRank0{k}, ...
        ['Historyczna ranga zero-based jest błędna dla ', labels{k}, '.']);
    assert(isequal(ctx.legacyPermutationOrder, legacyExpected{k}), ...
        ['Surowa historyczna permutacja jest nieoczekiwana dla ', ...
         labels{k}, '.']);

    % To jest właściwa historyczna blizna, która ma pozostać także po PATCH 08.
    rawAgain = pastafari.LegacyPermutationUnrank0.unrank0( ...
        ctx.legacyPermutationRank0, 1:6);
    assert(isequal(rawAgain, ctx.legacyPermutationOrder), ...
        ['Legacy unrank0 nie jest stabilny dla ', labels{k}, '.']);

    assert(any(strcmp(ctx.branchTrace, ...
        'DISCOVERY_08_OLD_PERMUTATION_UNRANK0')), ...
        'Brakuje śladu Discovery 08.');
    metricKey = matlab.lang.makeValidName( ...
        'discovery08.oldPermutationUnrank0.calls');
    assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
        'Licznik oldPermutationUnrank0 jest niepoprawny.');

    divergent(k) = ~isequal(actual, expected);

    fprintf(['STAGE16 DISCOVERY08 CASE=%s LEGACY_RANK0=%s ', ...
        'ACTUAL=[%s] EXPECTED=[%s] CLASSIFICATION=%s\n'], ...
        labels{k}, char(ctx.legacyPermutationRank0), ...
        orderText(actual), orderText(expected), ...
        classification(divergent(k)));
end

assert(isequal(divergent, [true, true]), ...
    'Discovery 08 musi ujawnić rozbieżność zarówno dla rangi 1, jak i 720.');

foundation = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 16.');

if any(divergent)
    fprintf('STAGE_16_DISCOVERY_08_EXPECTED_RED\n');
    error('Pastafari:Discovery08:ZeroBasedPermutationRank', ...
        ['Oczekiwana rozbieżność Discovery 08: regularMod(v,720) jest ', ...
         'używany bezpośrednio jako końcowa ranga zero-based.']);
end

fprintf('STAGE_16_DISCOVERY_08_REGRESSION_GREEN\n');
end

function text = orderText(order)
text = strtrim(sprintf('%d ', order));
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
