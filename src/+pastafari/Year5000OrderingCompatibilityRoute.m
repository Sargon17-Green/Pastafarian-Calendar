classdef Year5000OrderingCompatibilityRoute
    % Produkcyjna trasa porządkowania Year 5000 po PATCH 17.
    %
    % Najpierw zawsze wykonuje historyczny stable length-only sort
    % i zachowuje jego pełny raw order. Dopiero potem PATCH 17 sortuje
    % wyłącznie contiguous equal-length runs po opening gate day.
    methods (Static)
        function [ctx, ordered] = call(ctx, candidates)
            pastafari.ValidationManager.requireContext(ctx);
            if ~iscell(candidates)
                error('Pastafari:Years:Year5000CandidateList', ...
                    'Lista kandydatów roku 5000 musi być cell array.');
            end

            % Surowa historyczna blizna Discovery 17.
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_17_YEAR_5000_TIE';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery17.year5000Tie.calls');

            legacyOrdered = ...
                pastafari.LegacyYear5000StableLengthSort.apply(candidates);

            ctx.year5000InputCandidates = candidates;
            ctx.legacyYear5000StableLengthOrder = legacyOrdered;

            % PATCH 17: tylko tie runs, bez ponownego globalnego sortu.
            ctx.phase = 'PATCH_17';
            ctx.subPhase = 17;
            ctx.mode = 'YEAR_5000_TIE_RUN_SORT_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_17_YEAR_5000_TIE_RUN_SORT';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch17.year5000TieRunSort.calls');

            ordered = ...
                pastafari.Year5000TieRunSortPatch.apply(legacyOrdered);

            ctx.year5000CandidateOrder = ordered;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 17 zachowuje globalny stable length-only order ', ...
                 'i porządkuje tylko equal-length runs po opening gate.'];
        end
    end
end
