classdef YearIntervalCompatibilityRoute
    % Produkcyjna trasa year interval po PATCH 26.
    %
    % Najpierw zawsze wykonuje historyczny resolver [open,close] i zachowuje
    % pełny ghost Discovery 26. Dopiero potem publikuje rok z (open,close].
    methods (Static)
        function [ctx, year] = call(ctx, anchorYear, targetDay, years)
            pastafari.ValidationManager.requireContext(ctx);

            % Realna historyczna blizna Discovery 26.
            [ghost, telemetry] = ...
                pastafari.LegacyClosedOpeningYearResolver.apply( ...
                    anchorYear, targetDay, years);

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_26_CLOSED_OPENING_GATE';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery26.closedOpeningGate.calls');

            ctx.yearIntervalAnchorNumber = telemetry.anchorNumber;
            ctx.yearIntervalTargetDay = telemetry.targetDay;
            ctx.legacyClosedOpeningYearNumber = telemetry.finalNumber;
            ctx.legacyClosedOpeningOpenDay = telemetry.finalOpenDay;
            ctx.legacyClosedOpeningCloseDay = telemetry.finalCloseDay;
            ctx.legacyClosedOpeningForwardSteps = telemetry.forwardSteps;
            ctx.legacyClosedOpeningBackwardSteps = telemetry.backwardSteps;
            ctx.legacyClosedOpeningYearCandidate = ghost;

            % PATCH 26: semantic interval jest dokładnie (open,close].
            [correctYear, patchTelemetry] = ...
                pastafari.OpenClosedYearIntervalPatch.apply( ...
                    anchorYear, targetDay, years);

            ctx.phase = 'PATCH_26';
            ctx.subPhase = 26;
            ctx.mode = 'OPEN_CLOSED_YEAR_INTERVAL_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_26_OPEN_CLOSED_INTERVAL';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch26.openClosedInterval.calls');

            ctx.yearIntervalCandidate = correctYear;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 26 target=%s rawYear=%s semanticYear=%s ', ...
                 'interval=(open,close] backward=%d forward=%d.'], ...
                char(telemetry.targetDay), char(telemetry.finalNumber), ...
                char(patchTelemetry.finalNumber), ...
                patchTelemetry.backwardSteps, patchTelemetry.forwardSteps);

            year = correctYear;
        end
    end
end
