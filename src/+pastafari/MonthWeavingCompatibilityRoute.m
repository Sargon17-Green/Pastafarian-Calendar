classdef MonthWeavingCompatibilityRoute
    % Produkcyjna trasa month weaving po PATCH 24.
    %
    % Najpierw zawsze wykonuje historyczny daily chooser i zachowuje ghost.
    % Następnie wybiera dokładnie jeden rank z całej legalnej whole-weave
    % family i wykonuje DP lexicographic unrank.
    methods (Static)
        function [ctx, weaving] = call(ctx, structureSauce, monthLengths)
            pastafari.ValidationManager.requireContext(ctx);

            % Realny historyczny ghost Discovery 24.
            [ctx, stream, ghost, proposals, remaining] = ...
                pastafari.LegacyMonthWeavingAdapter.call( ...
                    ctx, structureSauce, monthLengths);

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

            [ctx, familyCount, rank, result, correct, reusedGhost] = ...
                pastafari.MonthWeavingDPPatchWrapper.callWithRing( ...
                    ctx, stream, monthLengths, ghost);

            ctx.phase = 'PATCH_24';
            ctx.subPhase = 24;
            ctx.mode = 'WHOLE_WEAVE_DP_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_24_WEAVING_DP_DETOUR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch24.weavingDPDetour.calls');

            ctx.wholeMonthWeavingFamilyCount = familyCount;
            ctx.wholeMonthWeavingRank = rank;
            ctx.wholeMonthWeavingDPResult = correct;
            ctx.wholeMonthWeavingReusedGhost = reusedGhost;
            ctx.monthWeavingCandidate = result;

            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 24 wholeCount=%s rank=%s reusedGhost=%d; ', ...
                 'daily ghost pozostaje zapisany osobno.'], ...
                char(familyCount), char(rank), reusedGhost);

            weaving = result;
        end
    end
end
