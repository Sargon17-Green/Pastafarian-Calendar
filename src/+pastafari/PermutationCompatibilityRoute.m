classdef PermutationCompatibilityRoute
    % Produkcyjna trasa permutacji po PATCH 08.
    % Najpierw zachowuje surową historyczną ścieżkę regularMod(v,720),
    % a publikowany wynik przeprowadza przez detour rankingu 1-based.
    methods (Static)
        function [ctx, order] = call(ctx, value)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(value);

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_08_OLD_PERMUTATION_UNRANK0';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery08.oldPermutationUnrank0.calls');

            v = pastafari.BigInt.coerce(value);

            % Historyczna blizna: błędna ranga zero-based pozostaje
            % obliczana i rozwijana dokładnie tak jak w Discovery 08.
            rawRank0 = v.regularMod(pastafari.BigInt(720));
            rawOrder = pastafari.LegacyPermutationUnrank0.unrank0( ...
                rawRank0, 1:6);

            ctx.phase = 'PATCH_08';
            ctx.subPhase = 8;
            ctx.mode = 'ONE_BASED_RANK_DETOUR_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_08_ONE_BASED_RANK_DETOUR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch08.oneBasedRankDetour.calls');

            [rank1, detourRank0] = ...
                pastafari.OneBasedRankDetourPatch.apply(v);
            order = pastafari.LegacyPermutationUnrank0.unrank0( ...
                detourRank0, 1:6);

            ctx.permutationInput = v;
            ctx.legacyPermutationRank0 = rawRank0;
            ctx.legacyPermutationOrder = rawOrder;
            ctx.permutationRank1Candidate = rank1;
            ctx.permutationDetourRank0 = detourRank0;
            ctx.permutationOrderCandidate = order;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 08 zachowuje surowe regularMod(v,720), ale ', ...
                 'publikuje unrank0(regularMod(v-1,720)).'];
        end
    end
end
