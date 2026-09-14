classdef NextBowlCompatibilityRoute
    % Produkcyjna trasa Discovery 12.
    %
    % orderAt46 pochodzi już z poprawnego PATCH 11, lecz legacy successor
    % ignoruje pozycję ID w tym latchu i używa stałego pierścienia nazw.
    methods (Static)
        function [ctx, successor] = call(ctx, orderAt46, queriedBowlId)
            pastafari.ValidationManager.requireContext(ctx);

            if ~isnumeric(orderAt46) || ~isvector(orderAt46) || ...
                    numel(orderAt46) ~= 6 || ~isequal(sort(orderAt46), 1:6)
                error('Pastafari:Successor:OrderAt46', ...
                    'Discovery 12 wymaga poprawnego orderAt46Latch 1..6.');
            end
            if ~(isnumeric(queriedBowlId) && isscalar(queriedBowlId) && ...
                    isfinite(queriedBowlId) && fix(queriedBowlId) == queriedBowlId && ...
                    queriedBowlId >= 1 && queriedBowlId <= 6)
                error('Pastafari:Successor:QueriedBowlId', ...
                    'Discovery 12 wymaga queried bowl ID z zakresu 1..6.');
            end
            if ~any(orderAt46 == queriedBowlId)
                error('Pastafari:Successor:MissingBowlId', ...
                    'Queried bowl ID musi występować w orderAt46Latch.');
            end

            ctx.phase = 'DISCOVERY_12';
            ctx.subPhase = 12;
            ctx.mode = 'FIXED_NAME_SUCCESSOR';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_12_FIXED_NAME_SUCCESSOR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery12.fixedNameSuccessor.calls');

            rawSuccessor = ...
                pastafari.LegacyFixedNameSuccessor.next(queriedBowlId);

            ctx.successorOrderAt46 = reshape(orderAt46, 1, 6);
            ctx.successorQueriedBowlId = queriedBowlId;
            ctx.legacyFixedNameSuccessor = rawSuccessor;
            ctx.nextBowlCandidate = rawSuccessor;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 12 wyznacza successor z fixed-name ring ', ...
                 '1->2->3->4->5->6->1 zamiast z pozycji ID w orderAt46Latch.'];

            successor = rawSuccessor;
        end
    end
end
