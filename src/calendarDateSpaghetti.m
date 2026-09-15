function result = calendarDateSpaghetti(calculationDay, targetDay)
% Produkcyjna funkcja kalendarza po etapie 54.
% Wszystkie 26 historycznych defect/patch pairs pozostają fizycznie obecne,
% a finalMonsterIntegration łączy je w jedną autorytatywną trasę.

pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
pastafari.ValidationManager.requireExactIntegerInput(targetDay);

ctx = pastafari.MonsterContext(calculationDay, targetDay);
ctx.metrics = pastafari.MetricsShell.bump( ...
    ctx.metrics, 'calendar.bootstrap.calls');
ctx = pastafari.MonsterDispatcher.dispatch(ctx, @bootstrapHandler);
[ctx, result] = pastafari.finalMonsterIntegration( ...
    ctx, calculationDay, targetDay); %#ok<ASGLU>

    function inner = bootstrapHandler(inner)
        inner.phase = 'BOOTSTRAP_READY';
        inner.status = 'FINAL_INTEGRATION_READY';
        inner.diagnostics{end + 1} = ...
            ['Neutralny bootstrap przekazuje sterowanie do ', ...
             'finalMonsterIntegration.'];
    end
end
