classdef Year5000OrderingCompatibilityRoute
    % Produkcyjna trasa Discovery 17.
    %
    % Kandydaci wejściowi są już po PATCH 16. Stage 34 publikuje jeszcze
    % historyczny stabilny sort tylko po długości; ties nie są porządkowane
    % po opening gate.
    methods (Static)
        function [ctx, ordered] = call(ctx, candidates)
            pastafari.ValidationManager.requireContext(ctx);
            if ~iscell(candidates)
                error('Pastafari:Years:Year5000CandidateList', ...
                    'Lista kandydatów roku 5000 musi być cell array.');
            end

            ctx.phase = 'DISCOVERY_17';
            ctx.subPhase = 17;
            ctx.mode = 'YEAR_5000_STABLE_LENGTH_ONLY';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_17_YEAR_5000_TIE';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery17.year5000Tie.calls');

            legacyOrdered = ...
                pastafari.LegacyYear5000StableLengthSort.apply(candidates);

            ctx.year5000InputCandidates = candidates;
            ctx.legacyYear5000StableLengthOrder = legacyOrdered;
            ctx.year5000CandidateOrder = legacyOrdered;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 17 sortuje rok 5000 stabilnie tylko po ', ...
                 'lengthDays; equal-length run zachowuje kolejność wejścia.'];

            ordered = legacyOrdered;
        end
    end
end
