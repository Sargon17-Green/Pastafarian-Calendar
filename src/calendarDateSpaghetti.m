function result = calendarDateSpaghetti(calculationDay, targetDay)
% Szkielet produkcyjny rozbudowany w etapie 2 o historyczną ścieżkę Discovery 01.

pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
pastafari.ValidationManager.requireExactIntegerInput(targetDay);
ctx = pastafari.MonsterContext(calculationDay, targetDay);
ctx.metrics = pastafari.MetricsShell.bump(ctx.metrics, 'calendar.bootstrap.calls');
ctx = pastafari.MonsterDispatcher.dispatch(ctx, @bootstrapHandler);

% Pierwsza rzeczywista blizna historyczna: SAVE korzysta jeszcze bezpośrednio
% z regularnego modulo. Wynik nie jest jeszcze końcowym wynikiem kalendarza.
[ctx, ~] = pastafari.SaveCompatibilityRoute.call(ctx, calculationDay); %#ok<ASGLU>

error('Pastafari:Bootstrap:NotImplementedYet', ...
    ['Etap 2 aktywuje wyłącznie historyczną ścieżkę Discovery 01; ', ...
     'pełna semantyka kalendarza nie jest jeszcze zaimplementowana.']);

    function inner = bootstrapHandler(inner)
        inner.phase = 'BOOTSTRAP_READY';
        inner.status = 'SKELETON_ONLY';
        inner.diagnostics{end + 1} = ...
            'Neutralny szkielet rozruchowy pozostaje aktywny pod pierwszą warstwą legacy.';
    end
end
