classdef HiddenCompatibilityRoute
    % Produkcyjna trasa hidden w stanie Discovery 05.
    % Fizyczny magazyn jest odwrócony, ale legacy nadal odczytuje slot k
    % bez tłumaczenia go na slot 8-k.
    methods (Static)
        function [ctx, logicalHidden] = call(ctx, counts, stones)
            pastafari.ValidationManager.requireContext(ctx);

            ctx.phase = 'DISCOVERY_05';
            ctx.subPhase = 5;
            ctx.mode = 'BACKWARD_HIDDEN_STORAGE';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'DISCOVERY_05_BACKWARD_HIDDEN_STORAGE';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery05.backwardHiddenStorage.calls');

            storage = pastafari.LegacyBackwardHiddenStore.build(counts, stones);
            logicalHidden = cell(1, 7);
            for k = 1:7
                logicalHidden{k} = ...
                    pastafari.LegacyBackwardHiddenStore.readNaive(storage, k);
            end

            ctx.hiddenBackward = storage;
            ctx.legacyHiddenLogicalCandidate = logicalHidden;
            ctx.diagnostics{end + 1} = ...
                ['Hidden są fizycznie zapisane jako 7..1, a odczyt legacy ', ...
                 'nadal traktuje slot k jako hidden k. Brak translatora 8-k.'];
        end
    end
end
