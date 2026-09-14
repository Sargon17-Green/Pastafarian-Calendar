classdef LegacyShortOnlySelectionDispatcher
    % Historyczna wada Discovery 14.
    % Każde N, również N>M, jest kierowane do krótkiej ścieżki PATCH 13.
    % Nie istnieje jeszcze żaden wide detour.
    methods (Static)
        function [ctx, rank] = call(ctx, stream, N)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(N);

            N = pastafari.BigInt.coerce(N);
            M = pastafari.BigInt( ...
                '170141183460469231731687303715884105727');

            if N < pastafari.BigInt(1)
                error('Pastafari:Selection:GeneralSize', ...
                    'Ogólny wybór wymaga dodatniego N.');
            end

            ctx.legacyShortOnlyAssumed = true;
            ctx.legacyGeneralSelectionRequestedSize = N;
            ctx.legacyWideSelectionUnsupported = false;
            ctx.legacyWideSelectionError = '';
            ctx.legacyGeneralSelectionResult = [];

            rank = [];
            try
                % Historyczna wada: nie ma rozgałęzienia po N<=M.
                [ctx, rank] = ...
                    pastafari.SmallPickCompatibilityRoute.call( ...
                        ctx, stream, N);
                ctx.legacyGeneralSelectionResult = rank;
            catch err
                if N > M && strcmp( ...
                        err.identifier, ...
                        'Pastafari:Selection:LegacyShortAssumption')
                    ctx.legacyWideSelectionUnsupported = true;
                    ctx.legacyWideSelectionError = err.identifier;
                    ctx.legacyGeneralSelectionResult = [];
                    rank = [];
                    return
                end
                rethrow(err)
            end
        end
    end
end
