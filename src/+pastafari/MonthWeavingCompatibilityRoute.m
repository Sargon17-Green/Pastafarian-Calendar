classdef MonthWeavingCompatibilityRoute
    % Produkcyjna trasa Discovery 24.
    %
    % Stage 48 publikuje jeszcze historyczny daily chooser. Nie istnieje
    % jeszcze whole-weave count ani DP unrank.
    methods (Static)
        function [ctx, weaving] = call(ctx, structureSauce, monthLengths)
            pastafari.ValidationManager.requireContext(ctx);

            [ctx, stream, ghost, proposals, remaining] = ...
                pastafari.LegacyMonthWeavingAdapter.call( ...
                    ctx, structureSauce, monthLengths);

            ctx.phase = 'DISCOVERY_24';
            ctx.subPhase = 24;
            ctx.mode = 'DAILY_MONTH_CHOOSER';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_24_DAILY_MONTH_CHOOSER';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery24.dailyMonthChooser.calls');

            ctx.monthWeavingLengthsInput = double(monthLengths(:).');
            ctx.monthWeavingStreamFirst = stream.first;
            ctx.monthWeavingStreamDirectionStep = stream.directionStep;
            ctx.legacyDailyMonthRawProposals = proposals;
            ctx.legacyDailyMonthWeaving = ghost;
            ctx.legacyDailyMonthRemainingFinal = remaining;
            ctx.monthWeavingCandidate = ghost;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 24 wybiera month id niezależnie dla każdego ', ...
                 'dnia i tylko omija już pełne miesiące.'];

            weaving = ghost;
        end
    end
end
