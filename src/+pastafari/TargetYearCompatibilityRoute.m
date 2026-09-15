classdef TargetYearCompatibilityRoute
    % Produkcyjna trasa Discovery 18.
    %
    % Stage 36 publikuje jeszcze wynik starego jump guess /365.
    % Nie istnieje jeszcze sequential next/previous year walk.
    methods (Static)
        function [ctx, year] = call(ctx, anchorYear, targetDay, years)
            pastafari.ValidationManager.requireContext(ctx);

            ctx.phase = 'DISCOVERY_18';
            ctx.subPhase = 18;
            ctx.mode = 'OLD_YEAR_JUMP_GUESS_BY_365';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_18_OLD_YEAR_JUMP_GUESS_BY_365';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery18.oldYearJumpGuess.calls');

            [rawYear, telemetry] = ...
                pastafari.LegacyOldYearJumpGuess.apply( ...
                    anchorYear, targetDay, years);

            ctx.legacyYearJumpAnchorNumber = telemetry.anchorNumber;
            ctx.legacyYearJumpAnchorOpenDay = telemetry.anchorOpenDay;
            ctx.legacyYearJumpTargetDay = telemetry.targetDay;
            ctx.legacyYearJumpDeltaDays = telemetry.deltaDays;
            ctx.legacyYearJumpOffset365 = telemetry.guessOffset365;
            ctx.legacyYearJumpGuessNumber = telemetry.guessedNumber;
            ctx.legacyYearJumpGuessedYear = rawYear;
            ctx.targetYearCandidate = rawYear;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 18 wybiera rok bezpośrednio z oszacowania ', ...
                 'floor(deltaDays/365), bez sequential year walk.'];

            year = rawYear;
        end
    end
end
