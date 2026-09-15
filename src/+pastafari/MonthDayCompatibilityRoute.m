classdef MonthDayCompatibilityRoute
    % Produkcyjna trasa month/day po PATCH 25.
    %
    % Najpierw zawsze wykonuje LegacyContiguousMonthDay i zachowuje pełny
    % ghost Discovery 25. Następnie nadpisuje wyłącznie semantic dayInMonth
    % prefix occurrence count wybranego month id.
    methods (Static)
        function [ctx, monthId, dayInMonth] = call( ...
                ctx, weaving, yearOpenDay, targetDay)
            pastafari.ValidationManager.requireContext(ctx);

            % Realna historyczna blizna Discovery 25.
            ghost = pastafari.LegacyContiguousMonthDay.compute( ...
                weaving, yearOpenDay, targetDay);

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_25_CONTIGUOUS_MONTH_DAY';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery25.contiguousMonthDay.calls');

            ctx.monthDayYearOpenDay = ...
                pastafari.BigInt.coerce(yearOpenDay);
            ctx.monthDayTargetDay = ...
                pastafari.BigInt.coerce(targetDay);
            ctx.monthDayTargetPosition1 = ghost.targetPosition1;
            ctx.legacyContiguousMonthId = ghost.monthId;
            ctx.legacyContiguousMonthFirstPosition1 = ghost.firstPosition1;
            ctx.legacyContiguousMonthFirstDay = ghost.firstDay;
            ctx.legacyContiguousDayInMonth = ghost.dayInMonth;

            [correctDay, reusedLegacy] = ...
                pastafari.MonthDayOccurrencePatchWrapper.apply( ...
                    weaving, ghost);

            ctx.phase = 'PATCH_25';
            ctx.subPhase = 25;
            ctx.mode = 'MONTH_OCCURRENCE_COUNT_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_25_OCCURRENCE_COUNT';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch25.occurrenceCount.calls');

            ctx.monthAtTargetCandidate = ghost.monthId;
            ctx.dayInMonthCandidate = correctDay;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 25 month=%d targetPosition=%s legacyDay=%s ', ...
                 'occurrenceDay=%s reusedLegacy=%d.'], ...
                ghost.monthId, char(ghost.targetPosition1), ...
                char(ghost.dayInMonth), char(correctDay), reusedLegacy);

            monthId = ghost.monthId;
            dayInMonth = correctDay;
        end
    end
end
