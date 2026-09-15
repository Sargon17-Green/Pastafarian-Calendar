classdef YearIntervalCompatibilityRoute
    % Produkcyjna trasa Discovery 26.
    %
    % Stage 52 nadal publikuje historyczne [open,close]. Opening gate
    % bieżącego roku pozostaje więc błędnie w bieżącym roku.
    methods (Static)
        function [ctx, year] = call(ctx, anchorYear, targetDay, years)
            pastafari.ValidationManager.requireContext(ctx);

            [ghost, telemetry] = ...
                pastafari.LegacyClosedOpeningYearResolver.apply( ...
                    anchorYear, targetDay, years);

            ctx.phase = 'DISCOVERY_26';
            ctx.subPhase = 26;
            ctx.mode = 'CLOSED_OPENING_GATE';
            ctx.status = 'LEGACY_PATH_ACTIVE';
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
            ctx.yearIntervalCandidate = ghost;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['Discovery 26 target=%s anchor=%s publikuje year=%s ', ...
                 'według historycznego [open,close].'], ...
                char(telemetry.targetDay), char(telemetry.anchorNumber), ...
                char(telemetry.finalNumber));

            year = ghost;
        end
    end
end
