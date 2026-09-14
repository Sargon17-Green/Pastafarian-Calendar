function run_stage26_tests()
% DISCOVERY 13: biasedLegacyPick jest wołany przed rejection.
% Surowa blizna ma pozostać po PATCH 13, natomiast publikowany rank
% ma wtedy najpierw przejść rejection na tym samym answer ring.

run_stage25_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

M = pastafari.BigInt('170141183460469231731687303715884105727');
N = pastafari.BigInt(922);
limit = M.floorDiv(N) * N;

% M mod 922 = 221: bez rejection pierwsze 221 rang ma o jeden
% punkt answer ring więcej niż pozostałe rangi.
assert(M.regularMod(N) == pastafari.BigInt(221), ...
    'Fixture bias wymaga M mod 922 = 221.');

% Kontrolowany stream zaczyna dokładnie o jeden ponad acceptance limit.
% Przy directionStep=-1 rejection powinien wykonać dokładnie jeden krok
% na tym samym answer ring i zaakceptować x=limit.
stream = struct( ...
    'first', limit + pastafari.BigInt(1), ...
    'directionStep', -1);

x0 = pastafari.AnswerRingStreamFactory.answerAt( ...
    stream, pastafari.BigInt(0));
x1 = pastafari.AnswerRingStreamFactory.answerAt( ...
    stream, pastafari.BigInt(1));

assert(x0 == limit + pastafari.BigInt(1), ...
    'Pierwsza odpowiedź fixture powinna przekraczać limit o 1.');
assert(x1 == limit, ...
    'Druga odpowiedź tego samego ring powinna być dokładnie limitem.');

rawRank = pastafari.LegacyBiasedPick.pick(x0, N);
expectedRank = normative_oracle('chooseRank', stream, N);

assert(rawRank == pastafari.BigInt(1), ...
    'Legacy modulo dla limit+1 powinno zwracać rank 1.');
assert(expectedRank == N, ...
    'Po jednym rejection normatywny rank powinien wynosić N=922.');

ctx = pastafari.MonsterContext(0, 0);
[ctx, actualRank] = pastafari.SmallPickCompatibilityRoute.call( ...
    ctx, stream, N);

assert(ctx.legacyBiasedPickInput == x0, ...
    'Kontekst utracił surowe x przekazane do biasedLegacyPick.');
assert(ctx.legacyBiasedPickSize == N, ...
    'Kontekst utracił N historycznego wyboru.');
assert(ctx.legacyBiasedPickRank == rawRank, ...
    'Kontekst utracił surowy rank legacy.');
assert(ctx.answerRingFirst == stream.first, ...
    'Kontekst utracił first answer ring.');
assert(ctx.answerRingDirectionStep == -1, ...
    'Kontekst utracił directionStep answer ring.');

assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_13_BIASED_LEGACY_PICK_MODULO')), ...
    'Brakuje śladu Discovery 13.');
metricKey = matlab.lang.makeValidName( ...
    'discovery13.biasedLegacyPick.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik biasedLegacyPick jest niepoprawny.');

divergent = actualRank ~= expectedRank;

fprintf(['STAGE26 DISCOVERY13 X0=%s X1=%s N=%s RAW=%s ', ...
    'ACTUAL=%s EXPECTED=%s CLASSIFICATION=%s\n'], ...
    char(x0), char(x1), char(N), char(rawRank), char(actualRank), ...
    char(expectedRank), classification(divergent));

% Kontrola bez rejection: gdy first==limit, legacy i oracle muszą się zgadzać.
controlStream = struct('first', limit, 'directionStep', -1);
controlExpected = normative_oracle('chooseRank', controlStream, N);
controlCtx = pastafari.MonsterContext(0, 0);
[controlCtx, controlActual] = ...
    pastafari.SmallPickCompatibilityRoute.call( ...
        controlCtx, controlStream, N);
assert(controlActual == controlExpected, ...
    'Control first==limit powinien być zgodny bez rejection.');
assert(controlCtx.legacyBiasedPickRank == N, ...
    'Control legacy rank powinien wynosić 922.');

foundation = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 26.');

if divergent
    assert(actualRank == rawRank, ...
        'Discovery 13 powinno publikować bezpośredni raw biased rank.');
    fprintf('STAGE_26_DISCOVERY_13_EXPECTED_RED\n');
    error('Pastafari:Discovery13:BiasedLegacyPickModulo', ...
        ['Oczekiwana rozbieżność Discovery 13: biasedLegacyPick został ', ...
         'wywołany przed rejection na answer ring.']);
end

fprintf('STAGE_26_DISCOVERY_13_REGRESSION_GREEN\n');
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
