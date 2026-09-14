classdef YearCandidateCompatibilityRoute
    % Produkcyjna trasa Discovery 16.
    %
    % W etapie 32 publikuje jeszcze raw listę wygenerowaną z historycznym
    % maksimum 5781. Nie istnieje jeszcze late filter do 5778.
    methods (Static)
        function [ctx, candidates] = call(ctx, rawCandidates)
            pastafari.ValidationManager.requireContext(ctx);

            ctx.phase = 'DISCOVERY_16';
            ctx.subPhase = 16;
            ctx.mode = 'LEGACY_YEAR_MAX_5781';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_16_LEGACY_YEAR_MAX_5781';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery16.legacyYearMax5781.calls');

            [legacyAccepted, legacyLengths] = ...
                pastafari.LegacyYearMax5781Filter.apply(rawCandidates);

            ctx.legacyYearMaxDays = pastafari.BigInt(5781);
            ctx.legacyYearCandidateLengths = legacyLengths;
            ctx.legacyYearCandidatesAccepted = legacyAccepted;
            ctx.yearCandidatesCandidate = legacyAccepted;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 16 publikuje kandydatów do 5781 dni; ', ...
                 'normatywny late max 5778 nie został jeszcze zastosowany.'];

            candidates = legacyAccepted;
        end
    end
end
