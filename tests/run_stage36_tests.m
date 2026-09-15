function run_stage36_tests()
% DISCOVERY 18: old year jump wybiera numer przez floor(deltaDays/365).
% Raw guess ma pozostać po PATCH 18, ale publikowany rok ma wtedy
% pochodzić z sequential next/previous walk.

run_stage35_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

years = makeYearChain();
anchor = yearByNumber(years, 5000);

% Trzy lokalne przypadki, w których 365-guess jest jeszcze poprawny.
controls = { ...
    struct('target', -100, 'expected', 4999), ...
    struct('target', 100, 'expected', 5000), ...
    struct('target', 400, 'expected', 5001)};

for k = 1:numel(controls)
    c = controls{k};
    expected = yearByNumber(years, c.expected);

    [raw, telemetry] = pastafari.LegacyOldYearJumpGuess.apply( ...
        anchor, pastafari.BigInt(c.target), years);

    assert(~isempty(raw), 'Control raw guess nie może być pusty.');
    assert(pastafari.BigInt.coerce(raw.number) == ...
        pastafari.BigInt(c.expected), ...
        'Control /365 powinien przypadkiem trafić w poprawny rok.');
    assert(telemetry.guessedNumber == pastafari.BigInt(c.expected), ...
        'Control telemetry ma błędny guessed number.');

    ctx = pastafari.MonsterContext(0, 0);
    [ctx, actual] = pastafari.TargetYearCompatibilityRoute.call( ...
        ctx, anchor, pastafari.BigInt(c.target), years);

    assert(~isempty(actual), 'Control route nie może zwrócić pustego roku.');
    assert(pastafari.BigInt.coerce(actual.number) == ...
        pastafari.BigInt.coerce(expected.number), ...
        'Discovery 18 nie może psuć lokalnego control.');
end

% Dwa odległe targets: zmienne długości lat kumulują drift /365.
cases = { ...
    struct('label', 'FUTURE', 'target', 1500, ...
           'rawNumber', 5004, 'expectedNumber', 5003), ...
    struct('label', 'PAST', 'target', -1200, ...
           'rawNumber', 4996, 'expectedNumber', 4997)};

divergent = false(1, numel(cases));

for k = 1:numel(cases)
    c = cases{k};
    target = pastafari.BigInt(c.target);
    expected = normativeContainingYear(years, target);

    assert(pastafari.BigInt.coerce(expected.number) == ...
        pastafari.BigInt(c.expectedNumber), ...
        ['Normatywny fixture jest błędny dla ', c.label, '.']);

    [raw, telemetry] = ...
        pastafari.LegacyOldYearJumpGuess.apply(anchor, target, years);

    assert(~isempty(raw), ...
        ['Raw jump guess nie może być pusty dla ', c.label, '.']);
    assert(telemetry.guessedNumber == pastafari.BigInt(c.rawNumber), ...
        ['Nieoczekiwany raw guessed number dla ', c.label, '.']);
    assert(pastafari.BigInt.coerce(raw.number) == ...
        pastafari.BigInt(c.rawNumber), ...
        ['Nieoczekiwany raw guessed year dla ', c.label, '.']);
    assert(pastafari.BigInt.coerce(raw.number) ~= ...
        pastafari.BigInt.coerce(expected.number), ...
        ['Distant fixture musi ujawniać drift /365 dla ', c.label, '.']);

    ctx = pastafari.MonsterContext(0, 0);
    [ctx, actual] = pastafari.TargetYearCompatibilityRoute.call( ...
        ctx, anchor, target, years);

    % Raw telemetry/scar musi pozostać również po PATCH 18.
    assert(ctx.legacyYearJumpAnchorNumber == pastafari.BigInt(5000), ...
        'Kontekst utracił anchor year number.');
    assert(ctx.legacyYearJumpAnchorOpenDay == pastafari.BigInt(0), ...
        'Kontekst utracił anchor open day.');
    assert(ctx.legacyYearJumpTargetDay == target, ...
        'Kontekst utracił target day.');
    assert(ctx.legacyYearJumpGuessNumber == pastafari.BigInt(c.rawNumber), ...
        ['Kontekst utracił raw /365 guess dla ', c.label, '.']);
    assert(~isempty(ctx.legacyYearJumpGuessedYear), ...
        'Kontekst utracił raw guessed year.');
    assert(pastafari.BigInt.coerce(ctx.legacyYearJumpGuessedYear.number) == ...
        pastafari.BigInt(c.rawNumber), ...
        'Raw guessed year w kontekście jest błędny.');

    assert(any(strcmp(ctx.branchTrace, ...
        'DISCOVERY_18_OLD_YEAR_JUMP_GUESS_BY_365')), ...
        'Brakuje śladu Discovery 18.');
    metricKey = matlab.lang.makeValidName( ...
        'discovery18.oldYearJumpGuess.calls');
    assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
        'Licznik old year jump guess jest niepoprawny.');

    if isempty(actual)
        divergent(k) = true;
        actualText = 'EMPTY';
    else
        actualNumber = pastafari.BigInt.coerce(actual.number);
        divergent(k) = actualNumber ~= ...
            pastafari.BigInt.coerce(expected.number);
        actualText = char(actualNumber);
    end

    fprintf(['STAGE36 DISCOVERY18 CASE=%s TARGET=%s RAW=%s ', ...
        'ACTUAL=%s EXPECTED=%s CLASSIFICATION=%s\n'], ...
        c.label, char(target), char(telemetry.guessedNumber), ...
        actualText, char(expected.number), classification(divergent(k)));
end

assert(all(divergent) || ~any(divergent), ...
    ['Stage 36 ma być RED dla obu distant directions przed PATCH 18 ', ...
     'albo GREEN dla obu po sequential walk.']);

foundation = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 36.');

if any(divergent)
    assert(all(divergent), ...
        'Discovery 18 powinno mylić oba distant fixtures.');
    fprintf('STAGE_36_DISCOVERY_18_EXPECTED_RED\n');
    error('Pastafari:Discovery18:OldYearJumpGuessBy365', ...
        ['Oczekiwana rozbieżność Discovery 18: bezpośredni wybór roku ', ...
         'przez floor(deltaDays/365) dryfuje od rzeczywistych granic lat.']);
end

fprintf('STAGE_36_DISCOVERY_18_REGRESSION_GREEN\n');
end

function years = makeYearChain()
years = { ...
    makeYear(4996, -1930, -1565), ...
    makeYear(4997, -1565, -965), ...
    makeYear(4998, -965, -365), ...
    makeYear(4999, -365, 0), ...
    makeYear(5000, 0, 365), ...
    makeYear(5001, 365, 730), ...
    makeYear(5002, 730, 1330), ...
    makeYear(5003, 1330, 1930), ...
    makeYear(5004, 1930, 2295)};
end

function year = makeYear(number, openDay, closeDay)
year = struct( ...
    'number', pastafari.BigInt(number), ...
    'openGateDay', pastafari.BigInt(openDay), ...
    'closeGateDay', pastafari.BigInt(closeDay));
end

function year = yearByNumber(years, number)
year = [];
for k = 1:numel(years)
    if pastafari.BigInt.coerce(years{k}.number) == pastafari.BigInt(number)
        year = years{k};
        return
    end
end
error('Pastafari:Stage36:MissingYear', ...
    'Fixture nie zawiera wymaganego numeru roku.');
end

function year = normativeContainingYear(years, target)
year = [];
target = pastafari.BigInt.coerce(target);
for k = 1:numel(years)
    openDay = pastafari.BigInt.coerce(years{k}.openGateDay);
    closeDay = pastafari.BigInt.coerce(years{k}.closeGateDay);
    if openDay < target && target <= closeDay
        year = years{k};
        return
    end
end
error('Pastafari:Stage36:NoContainingYear', ...
    'Fixture nie zawiera roku obejmującego target.');
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
