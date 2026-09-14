function result = calendarDateSpaghetti(calculationDay, targetDay)
% Szkielet produkcyjny rozbudowany do etapu 14; aktywne są PATCH 01-06
% oraz Discovery 07.

pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
pastafari.ValidationManager.requireExactIntegerInput(targetDay);
ctx = pastafari.MonsterContext(calculationDay, targetDay);
ctx.metrics = pastafari.MetricsShell.bump(ctx.metrics, 'calendar.bootstrap.calls');
ctx = pastafari.MonsterDispatcher.dispatch(ctx, @bootstrapHandler);

[ctx, ~] = pastafari.SaveCompatibilityRoute.call(ctx, calculationDay); %#ok<ASGLU>
[ctx, counts] = pastafari.WorkCountsCompatibilityRoute.call( ...
    ctx, calculationDay, targetDay);
[ctx, stones] = pastafari.StoneTableCompatibilityRoute.call(ctx);
[ctx, hidden] = pastafari.HiddenCompatibilityRoute.call( ...
    ctx, counts, stones);
[ctx, priorVisible] = pastafari.VisibleDropCompatibilityRoute.call( ...
    ctx, counts, stones, hidden);

% Discovery 07 nakłada nową historyczną wadę już po poprawnym priorPatch.
[ctx, ~] = pastafari.GrindTableCompatibilityRoute.call( ...
    ctx, counts, stones, hidden, priorVisible); %#ok<ASGLU>

error('Pastafari:Bootstrap:NotImplementedYet', ...
    ['Etap 14 aktywuje historyczną ścieżkę Discovery 07; ', ...
     'pełna semantyka kalendarza nie jest jeszcze zaimplementowana.']);

    function inner = bootstrapHandler(inner)
        inner.phase = 'BOOTSTRAP_READY';
        inner.status = 'SKELETON_ONLY';
        inner.diagnostics{end + 1} = ...
            'Neutralny szkielet rozruchowy pozostaje aktywny pod historycznymi warstwami.';
    end
end
