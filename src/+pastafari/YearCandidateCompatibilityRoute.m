classdef YearCandidateCompatibilityRoute
    % Produkcyjna trasa kandydatów roku po PATCH 16.
    %
    % Najpierw wykonuje historyczny generator max-5781 i zachowuje jego
    % pełną raw listę. Dopiero potem osobny late filter usuwa length>5778.
    % Nie ma jeszcze sortowania ani wyboru Year 5000.
    methods (Static)
        function [ctx, candidates] = call(ctx, rawCandidates)
            pastafari.ValidationManager.requireContext(ctx);

            % Surowa historyczna blizna Discovery 16.
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_16_LEGACY_YEAR_MAX_5781';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery16.legacyYearMax5781.calls');

            [legacyAccepted, legacyLengths] = ...
                pastafari.LegacyYearMax5781Filter.apply(rawCandidates);

            ctx.legacyYearMaxDays = pastafari.BigInt(5781);
            ctx.legacyYearCandidateLengths = legacyLengths;
            ctx.legacyYearCandidatesAccepted = legacyAccepted;

            % PATCH 16: późne odfiltrowanie wyłącznie ponad normatywny max.
            ctx.phase = 'PATCH_16';
            ctx.subPhase = 16;
            ctx.mode = 'LATE_5778_FILTER_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_16_LATE_5778_FILTER';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch16.late5778Filter.calls');

            [filtered, rejected] = ...
                pastafari.YearMax5778LateFilter.apply(legacyAccepted);

            ctx.yearCandidatesCandidate = filtered;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 16 zachowuje %d raw legacy candidates i publikuje ', ...
                 '%d po późnym filtrze lengthDays<=5778; odrzucono %d.'], ...
                numel(legacyAccepted), numel(filtered), numel(rejected));

            candidates = filtered;
        end
    end
end
