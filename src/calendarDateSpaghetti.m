function result = calendarDateSpaghetti(calculationDay, targetDay)
% Szkielet produkcyjny rozbudowany do etapu 30; aktywne są PATCH 01-14
% oraz Discovery 15.

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

[ctx, finalBowls, orderAt46] = ...
    pastafari.OrderAt46CompatibilityRoute.call( ...
        ctx, visible, bowlsAfterDrop46);

queriedBowlId = orderAt46(4);
[ctx, ~] = pastafari.NextBowlCompatibilityRoute.call( ...
    ctx, orderAt46, queriedBowlId); %#ok<ASGLU>

selectionBowlId = 1;
selectionNextId = ...
    pastafari.LatchedSuccessorPatch.apply(orderAt46, selectionBowlId);
stream = pastafari.AnswerRingStreamFactory.fromSauce( ...
    finalBowls, selectionBowlId, selectionNextId, 1);

[ctx, ~] = pastafari.SmallPickCompatibilityRoute.call( ...
    ctx, stream, pastafari.BigInt(922)); %#ok<ASGLU>

M = pastafari.BigInt('170141183460469231731687303715884105727');
[ctx, ~] = pastafari.GeneralSelectionCompatibilityRoute.call( ...
    ctx, stream, M + pastafari.BigInt(1)); %#ok<ASGLU>

% Discovery 15: pierwsze realne pytanie o bramę ujemną.
[ctx, ~] = pastafari.GateGapCompatibilityRoute.call( ...
    ctx, pastafari.BigInt(-1)); %#ok<ASGLU>

error('Pastafari:Bootstrap:NotImplementedYet', ...
    ['Etap 30 aktywuje historyczną ścieżkę Discovery 15; ', ...
     'pełna semantyka kalendarza nie jest jeszcze zaimplementowana.']);

    function inner = bootstrapHandler(inner)
        inner.phase = 'BOOTSTRAP_READY';
        inner.status = 'SKELETON_ONLY';
        inner.diagnostics{end + 1} = ...
            'Neutralny szkielet rozruchowy pozostaje aktywny pod historycznymi warstwami.';
    end
end
