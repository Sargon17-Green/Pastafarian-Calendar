function assert_public_calendar_entry_contract(calculationDay, targetDay)
% Test-only guard for the public entry after the final Stage 54 integration.
% Historical DISCOVERY tests check their legacy adapters separately.
% Here we verify the modern front-door contract without running the costly
% full calendar on every recursively executed stage regression.

pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
pastafari.ValidationManager.requireExactIntegerInput(targetDay);

calculationExact = pastafari.BigInt.coerce(calculationDay);
targetExact = pastafari.BigInt.coerce(targetDay);
ctx = pastafari.MonsterContext(calculationDay, targetDay);
assert(isa(ctx, 'pastafari.MonsterContext'), ...
    'Nie udało się utworzyć neutralnego kontekstu.');
assert(pastafari.BigInt.coerce(ctx.calculationDay) == calculationExact, ...
    'Kontekst zmienił dokładną wartość calculationDay.');
assert(pastafari.BigInt.coerce(ctx.targetDay) == targetExact, ...
    'Kontekst zmienił dokładną wartość targetDay.');

persistent publicEntryChecked
if ~isempty(publicEntryChecked) && publicEntryChecked
    return
end

root = fileparts(fileparts(mfilename('fullpath')));
expectedPath = fullfile(root, 'src', 'calendarDateSpaghetti.m');
actualPath = which('calendarDateSpaghetti');
assert(strcmp(actualPath, expectedPath), ...
    'Test nie wskazuje produkcyjnego calendarDateSpaghetti.');
source = fileread(actualPath);
assert(contains(source, 'pastafari.ValidationManager.requireExactIntegerInput'), ...
    'Publiczna funkcja utraciła walidację dokładnych liczb.');
assert(contains(source, 'pastafari.finalMonsterIntegration('), ...
    'Publiczna funkcja nie wywołuje pełnej integracji.');
assert(~contains(source, 'Pastafari:Bootstrap:NotImplementedYet'), ...
    'Publiczna funkcja nadal zawiera przestarzały błąd bootstrapu.');

% Exercise the real public entry with an invalid input: the failure must
% happen in validation, before an expensive full calendar calculation.
caught = false;
try
    calendarDateSpaghetti(NaN, 0);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Validation:IntegerInput');
end
assert(caught, ...
    'Publiczne wejście nie odrzuciło niecałkowitej wartości NaN.');

% The real full output is verified in run_stage54_tests (heavy differential),
% which run_stage55_final_audit forces explicitly.
publicEntryChecked = true;
end
