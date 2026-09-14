classdef StoneTableCompatibilityRoute
    % Produkcyjna trasa tabeli kamieni po PATCH 04.
    % Historyczna mutacja sekwencyjna jest nadal wykonywana i zachowywana,
    % lecz publikowana tabela pochodzi z niezmiennych snapshotów.
    methods (Static)
        function [ctx, stones] = call(ctx)
            pastafari.ValidationManager.requireContext(ctx);

            ctx.phase = 'PATCH_04';
            ctx.subPhase = 4;
            ctx.mode = 'STONE_SNAPSHOT_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';

            ctx.branchTrace{end + 1} = 'DISCOVERY_04_SEQUENTIAL_STONES';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery04.sequentialStoneMutation.calls');

            [stones, legacyRows] = pastafari.StoneSnapshotPatch.buildTable();

            ctx.branchTrace{end + 1} = 'PATCH_04_STONE_SNAPSHOT';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch04.stoneSnapshot.calls');

            ctx.legacyStoneTable = legacyRows;
            ctx.legacySecondStoneRow = legacyRows(2, :);
            ctx.stoneTableCandidate = stones;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 04 wykonuje mutację legacy na kopii, ale wszystkie ', ...
                 'publikowane kamienie liczy ze snapshotu poprzedniego wiersza.'];
        end
    end
end
