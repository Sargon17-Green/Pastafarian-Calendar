function result = calendarDateSpaghetti(calculationDay, targetDay)
% Szkielet produkcyjny rozbudowany do etapu 18; aktywne są PATCH 01-08
% oraz Discovery 09.

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
[ctx, visible] = pastafari.GrindTableCompatibilityRoute.call( ...
    ctx, counts, stones, hidden, priorVisible);

% Zachowujemy jawne przejście przez PATCH 08.
[ctx, ~] = pastafari.PermutationCompatibilityRoute.call( ...
    ctx, visible{1}); %#ok<ASGLU>

% Discovery 09 dodaje historyczne pours do stałych bowl IDs 1,2,3.
[ctx, ~] = pastafari.BowlPourCompatibilityRoute.call( ...
    ctx, counts, stones, visible); %#ok<ASGLU>

error('Pastafari:Bootstrap:NotImplementedYet', ...
    ['Etap 18 aktywuje historyczną ścieżkę Discovery 09; ', ...
     'pełna semantyka kalendarza nie jest jeszcze zaimplementowana.']);

    function inner = bootstrapHandler(inner)
        inner.phase = 'BOOTSTRAP_READY';
        inner.status = 'SKELETON_ONLY';
        inner.diagnostics{end + 1} = ...
            'Neutralny szkielet rozruchowy pozostaje aktywny pod historycznymi warstwami.';
    end
end
