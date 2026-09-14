classdef GeneralSelectionCompatibilityRoute
    % Produkcyjna trasa ogólnego wyboru po PATCH 14.
    %
    % Najpierw zawsze wykonuje historyczny short-only dispatcher i zachowuje
    % jego wynik lub unsupported scar. Dla N<=M publikowany wynik pozostaje
    % dokładnie zieloną ścieżką PATCH 13. Dla N>M publikowany wynik przechodzi
    % przez WideSelectionDetourPatch.
    methods (Static)
        function [ctx, rank] = call(ctx, stream, N)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(N);

            N = pastafari.BigInt.coerce(N);
            M = pastafari.BigInt( ...
                '170141183460469231731687303715884105727');

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_14_SHORT_ONLY_SELECTOR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery14.shortOnlySelector.calls');

            [ctx, legacyResult] = ...
                pastafari.LegacyShortOnlySelectionDispatcher.call( ...
                    ctx, stream, N);

            if N <= M
                % PATCH 13 pozostaje jedyną semantyczną ścieżką short.
                ctx.phase = 'PATCH_14';
                ctx.subPhase = 14;
                ctx.mode = 'WIDE_DETOUR_SHORT_PASSTHROUGH';
                ctx.status = 'PATCHED_PATH_ACTIVE';
                ctx.branchTrace{end + 1} = ...
                    'PATCH_14_WIDE_DETOUR_SHORT_PASSTHROUGH';
                ctx.metrics = pastafari.MetricsShell.bump( ...
                    ctx.metrics, 'patch14.wideDetour.shortPassthrough.calls');

                ctx.generalSelectionCandidate = legacyResult;
                ctx.diagnostics{end + 1} = ...
                    ['PATCH 14 nie zmienia N<=M: publikowany wynik pochodzi ', ...
                     'z istniejącego PATCH 13.'];

                rank = legacyResult;
                return
            end

            if ~ctx.legacyWideSelectionUnsupported || ...
                    ~isempty(ctx.legacyGeneralSelectionResult)
                error('Pastafari:Selection:WideScarMissing', ...
                    ['PATCH 14 wymaga zachowanego raw short-only failure ', ...
                     'dla N>M.']);
            end

            ctx.phase = 'PATCH_14';
            ctx.subPhase = 14;
            ctx.mode = 'WIDE_DETOUR_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_14_WIDE_DETOUR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch14.wideDetour.calls');

            [rank, wide, acceptedWide, places, space, acceptanceLimit, rejectionSteps] = ...
                pastafari.WideSelectionDetourPatch.apply(stream, N);

            ctx.generalSelectionCandidate = rank;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 14: places=%d, wide=%s, acceptedWide=%s, ', ...
                 'space=%s, limit=%s, rejectionSteps=%s.'], ...
                places, char(wide), char(acceptedWide), char(space), ...
                char(acceptanceLimit), char(rejectionSteps));
        end
    end
end
