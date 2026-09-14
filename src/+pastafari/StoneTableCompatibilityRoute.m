classdef StoneTableCompatibilityRoute
    % Produkcyjna trasa tabeli kamieni w stanie Discovery 04.
    % W etapie 8 publikuje bezpośrednio sekwencyjnie mutowaną tabelę legacy.
    methods (Static)
        function [ctx, stones] = call(ctx)
            pastafari.ValidationManager.requireContext(ctx);

            ctx.phase = 'DISCOVERY_04';
            ctx.subPhase = 4;
            ctx.mode = 'SEQUENTIAL_STONE_MUTATION';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'DISCOVERY_04_SEQUENTIAL_STONES';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery04.sequentialStoneMutation.calls');

            stones = pastafari.LegacyStoneMutationAdapter.buildTable();
            ctx.legacyStoneTable = stones;
            ctx.legacySecondStoneRow = stones(2, :);
            ctx.stoneTableCandidate = stones;
            ctx.diagnostics{end + 1} = ...
                ['Tabela kamieni jest nadal budowana przez mutację in-place; ', ...
                 'brak PATCH 04 snapshotu poprzedniego wiersza.'];
        end
    end
end
