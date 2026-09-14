function result = calendarDateSpaghetti(calculationDay, targetDay)
% Szkielet produkcyjny rozbudowany do etapu 22; aktywne są PATCH 01-10
% oraz Discovery 11.

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

[ctx, ~] = pastafari.PermutationCompatibilityRoute.call( ...
    ctx, visible{1}); %#ok<ASGLU>

[ctx, preInPlaceBowls] = pastafari.BowlPourCompatibilityRoute.call( ...
    ctx, counts, stones, visible);

[ctx, bowlsAfterDrop46] = pastafari.BowlStirCompatibilityRoute.call( ...
    ctx, counts, stones, visible, preInPlaceBowls);

[ctx, ~, ~] = pastafari.OrderAt46CompatibilityRoute.call( ...
    ctx, visible, bowlsAfterDrop46); %#ok<ASGLU>

error('Pastafari:Bootstrap:NotImplementedYet', ...
    ['Etap 22 aktywuje historyczną ścieżkę Discovery 11; ', ...
     'pełna semantyka kalendarza nie jest jeszcze zaimplementowana.']);

    function inner = bootstrapHandler(inner)
        inner.phase = 'BOOTSTRAP_READY';
        inner.status = 'SKELETON_ONLY';
        inner.diagnostics{end + 1} = ...
            'Neutralny szkielet rozruchowy pozostaje aktywny pod historycznymi warstwami.';
    end
end
