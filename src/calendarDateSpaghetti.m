function result = calendarDateSpaghetti(calculationDay, targetDay)
% Szkielet produkcyjny rozbudowany do etapu 6; aktywne są PATCH 01,
% PATCH 02 oraz Discovery 03.

pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
pastafari.ValidationManager.requireExactIntegerInput(targetDay);
ctx = pastafari.MonsterContext(calculationDay, targetDay);
ctx.metrics = pastafari.MetricsShell.bump(ctx.metrics, 'calendar.bootstrap.calls');
ctx = pastafari.MonsterDispatcher.dispatch(ctx, @bootstrapHandler);

% Pierwsza historyczna blizna pozostaje przykryta przez PATCH 01.
[ctx, ~] = pastafari.SaveCompatibilityRoute.call(ctx, calculationDay); %#ok<ASGLU>

% WorkCountsCompatibilityRoute przechodzi przez poprawiony Foundation scar,
% lecz jego distance nadal pochodzi z historycznej różnicy tagów dni.
[ctx, ~] = pastafari.WorkCountsCompatibilityRoute.call( ...
    ctx, calculationDay, targetDay); %#ok<ASGLU>

error('Pastafari:Bootstrap:NotImplementedYet', ...
    ['Etap 6 aktywuje historyczną ścieżkę Discovery 03; ', ...
     'pełna semantyka kalendarza nie jest jeszcze zaimplementowana.']);

    function inner = bootstrapHandler(inner)
        inner.phase = 'BOOTSTRAP_READY';
        inner.status = 'SKELETON_ONLY';
        inner.diagnostics{end + 1} = ...
            'Neutralny szkielet rozruchowy pozostaje aktywny pod historycznymi warstwami.';
    end
end
