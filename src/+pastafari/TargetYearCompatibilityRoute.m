classdef TargetYearCompatibilityRoute
    % Produkcyjna trasa target year po PATCH 18.
    %
    % Najpierw wykonuje historyczny /365 guess i zachowuje pełną telemetrię.
    % Publikowana ścieżka startuje od anchor year i chodzi po jednym
    % rzeczywistym roku next/previous aż target należy do (open, close].
    methods (Static)
        function [ctx, year] = call(ctx, anchorYear, targetDay, years)
            pastafari.ValidationManager.requireContext(ctx);

            % Surowa historyczna blizna Discovery 18.
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

            % PATCH 18: rzeczywisty sequential walk.
            ctx.phase = 'PATCH_18';
            ctx.subPhase = 18;
            ctx.mode = 'SEQUENTIAL_YEAR_WALK_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_18_SEQUENTIAL_YEAR_WALK';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch18.sequentialYearWalk.calls');

            [year, walk] = pastafari.SequentialYearWalkPatch.apply( ...
                anchorYear, targetDay, years);

            ctx.targetYearCandidate = year;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 18 zachowuje raw /365 guess, ale publikuje rok po ', ...
                 'sequential walk: forward=%d, backward=%d, final=%s.'], ...
                walk.forwardSteps, walk.backwardSteps, char(walk.finalNumber));
        end
    end
end
