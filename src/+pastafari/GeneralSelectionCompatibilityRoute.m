classdef GeneralSelectionCompatibilityRoute
    % Produkcyjna trasa Discovery 14.
    %
    % Raw historyczny dispatcher zakłada, że każdy wybór jest krótki.
    % W etapie 28 publikowany wynik jest dokładnie wynikiem tego dispatchera.
    methods (Static)
        function [ctx, rank] = call(ctx, stream, N)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(N);

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_14_SHORT_ONLY_SELECTOR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery14.shortOnlySelector.calls');

            [ctx, legacyResult] = ...
                pastafari.LegacyShortOnlySelectionDispatcher.call( ...
                    ctx, stream, N);

            ctx.phase = 'DISCOVERY_14';
            ctx.subPhase = 14;
            ctx.mode = 'SHORT_ONLY_SELECTOR';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.generalSelectionCandidate = legacyResult;

            if ctx.legacyWideSelectionUnsupported
                ctx.diagnostics{end + 1} = ...
                    ['Discovery 14 skierowało N>M do short selector; ', ...
                     'wide selection pozostaje nieobsługiwany.'];
            else
                ctx.diagnostics{end + 1} = ...
                    'Discovery 14 użyło short selector dla N<=M.';
            end

            rank = legacyResult;
        end
    end
end
