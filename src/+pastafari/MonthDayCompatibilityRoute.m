classdef MonthDayCompatibilityRoute
    % Produkcyjna trasa Discovery 25.
    %
    % Stage 50 publikuje jeszcze historyczne contiguous-difference
    % dayInMonth. Whole weave może jednak rozdzielać wystąpienia miesiąca.
    methods (Static)
        function [ctx, monthId, dayInMonth] = call( ...
                ctx, weaving, yearOpenDay, targetDay)
            pastafari.ValidationManager.requireContext(ctx);

            ghost = pastafari.LegacyContiguousMonthDay.compute( ...
                weaving, yearOpenDay, targetDay);

            ctx.phase = 'DISCOVERY_25';
            ctx.subPhase = 25;
            ctx.mode = 'CONTIGUOUS_MONTH_DAY';
            ctx.status = 'LEGACY_PATH_ACTIVE';
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
            ctx.monthAtTargetCandidate = ghost.monthId;
            ctx.dayInMonthCandidate = ghost.dayInMonth;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['Discovery 25 month=%d targetPosition=%s firstPosition=%s ', ...
                 'legacyDayInMonth=%s przez różnicę dni.'], ...
                ghost.monthId, char(ghost.targetPosition1), ...
                char(ghost.firstPosition1), char(ghost.dayInMonth));

            monthId = ghost.monthId;
            dayInMonth = ghost.dayInMonth;
        end
    end
end
