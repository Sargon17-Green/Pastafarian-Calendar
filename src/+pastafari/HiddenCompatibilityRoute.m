classdef HiddenCompatibilityRoute
    % Produkcyjna trasa hidden po PATCH 05.
    % Fizyczny magazyn nadal ma kolejność hidden7..hidden1.
    % Najpierw zachowujemy naiwny odczyt legacy, a publikujemy odczyt przez 8-k.
    methods (Static)
        function [ctx, logicalHidden] = call(ctx, counts, stones)
            pastafari.ValidationManager.requireContext(ctx);

            ctx.branchTrace{end + 1} = 'DISCOVERY_05_BACKWARD_HIDDEN_STORAGE';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery05.backwardHiddenStorage.calls');

            storage = pastafari.LegacyBackwardHiddenStore.build(counts, stones);

            naiveLegacy = cell(1, 7);
            for k = 1:7
                naiveLegacy{k} = ...
                    pastafari.LegacyBackwardHiddenStore.readNaive(storage, k);
            end

            ctx.phase = 'PATCH_05';
            ctx.subPhase = 5;
            ctx.mode = 'HIDDEN_INDEX_TRANSLATOR_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_05_HIDDEN_INDEX_TRANSLATOR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch05.hiddenIndexTranslator.calls');

            logicalHidden = cell(1, 7);
            for k = 1:7
                logicalHidden{k} = ...
                    pastafari.HiddenIndexTranslator.read(storage, k);
            end

            ctx.hiddenBackward = storage;
            ctx.legacyHiddenLogicalCandidate = naiveLegacy;
            ctx.hiddenLogicalCandidate = logicalHidden;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 05 pozostawia fizyczny magazyn 7..1 bez zmian, ', ...
                 'zachowuje naiwny odczyt legacy i publikuje hidden k ', ...
                 'przez fizyczny slot 8-k.'];
        end
    end
end
