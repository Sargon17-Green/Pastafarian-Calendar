function result = calendarDateSpaghetti(calculationDay, targetDay)
% Szkielet produkcyjny rozbudowany do etapu 4; aktywne są PATCH 01 i Discovery 02.

pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
pastafari.ValidationManager.requireExactIntegerInput(targetDay);
ctx = pastafari.MonsterContext(calculationDay, targetDay);
ctx.metrics = pastafari.MetricsShell.bump(ctx.metrics, 'calendar.bootstrap.calls');
ctx = pastafari.MonsterDispatcher.dispatch(ctx, @bootstrapHandler);

% Pierwsza historyczna blizna jest już przykryta przez PATCH 01.
[ctx, ~] = pastafari.SaveCompatibilityRoute.call(ctx, calculationDay); %#ok<ASGLU>

% Discovery 02 dodaje kolejny rzeczywisty defekt: produkcyjny licznik dnia
% publikuje jeszcze bezpośrednio 2*abs(day-FOUNDATION).
[ctx, ~] = pastafari.DayTagCompatibilityRoute.call(ctx, calculationDay); %#ok<ASGLU>

error('Pastafari:Bootstrap:NotImplementedYet', ...
    ['Etap 4 aktywuje historyczną ścieżkę Discovery 02; ', ...
     'pełna semantyka kalendarza nie jest jeszcze zaimplementowana.']);

    function inner = bootstrapHandler(inner)
        inner.phase = 'BOOTSTRAP_READY';
        inner.status = 'SKELETON_ONLY';
        inner.diagnostics{end + 1} = ...
            'Neutralny szkielet rozruchowy pozostaje aktywny pod pierwszą warstwą legacy.';
    end
end
