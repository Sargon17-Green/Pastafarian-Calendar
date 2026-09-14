classdef NextBowlCompatibilityRoute
    % Produkcyjna trasa successor po PATCH 12.
    %
    % Najpierw wykonuje historyczny fixed-name successor i zachowuje go
    % jako surową bliznę. Publikowana ścieżka znajduje queried bowl ID
    % w orderAt46Latch i zwraca następny element latcha z zawijaniem.
    methods (Static)
        function [ctx, successor] = call(ctx, orderAt46, queriedBowlId)
            pastafari.ValidationManager.requireContext(ctx);

            if ~isnumeric(orderAt46) || ~isvector(orderAt46) || ...
                    numel(orderAt46) ~= 6 || ~isequal(sort(orderAt46), 1:6)
                error('Pastafari:Successor:OrderAt46', ...
                    'PATCH 12 wymaga poprawnego orderAt46Latch 1..6.');
            end
            if ~(isnumeric(queriedBowlId) && isscalar(queriedBowlId) && ...
                    isfinite(queriedBowlId) && fix(queriedBowlId) == queriedBowlId && ...
                    queriedBowlId >= 1 && queriedBowlId <= 6)
                error('Pastafari:Successor:QueriedBowlId', ...
                    'PATCH 12 wymaga queried bowl ID z zakresu 1..6.');
            end
            if ~any(orderAt46 == queriedBowlId)
                error('Pastafari:Successor:MissingBowlId', ...
                    'Queried bowl ID musi występować w orderAt46Latch.');
            end

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_12_FIXED_NAME_SUCCESSOR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery12.fixedNameSuccessor.calls');

            rawSuccessor = ...
                pastafari.LegacyFixedNameSuccessor.next(queriedBowlId);

            ctx.phase = 'PATCH_12';
            ctx.subPhase = 12;
            ctx.mode = 'LATCHED_SUCCESSOR_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_12_LATCHED_SUCCESSOR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch12.latchedSuccessor.calls');

            successor = pastafari.LatchedSuccessorPatch.apply( ...
                orderAt46, queriedBowlId);

            ctx.successorOrderAt46 = reshape(orderAt46, 1, 6);
            ctx.successorQueriedBowlId = queriedBowlId;
            ctx.legacyFixedNameSuccessor = rawSuccessor;
            ctx.nextBowlCandidate = successor;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 12 zachowuje fixed-name successor jako bliznę, ', ...
                 'ale publikuje następną bowl według pozycji ID w ', ...
                 'orderAt46Latch.'];
        end
    end
end
