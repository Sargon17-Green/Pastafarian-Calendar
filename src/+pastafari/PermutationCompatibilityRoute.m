classdef PermutationCompatibilityRoute
    % Produkcyjna trasa Discovery 08.
    % Błędnie traktuje regularMod(v,720) jako końcową rangę zero-based.
    methods (Static)
        function [ctx, order] = call(ctx, value)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(value);

            ctx.phase = 'DISCOVERY_08';
            ctx.subPhase = 8;
            ctx.mode = 'ZERO_BASED_PERMUTATION_RANK_AS_FINAL';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'DISCOVERY_08_OLD_PERMUTATION_UNRANK0';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery08.oldPermutationUnrank0.calls');

            v = pastafari.BigInt.coerce(value);
            rank0 = v.regularMod(pastafari.BigInt(720));
            rawOrder = pastafari.LegacyPermutationUnrank0.unrank0( ...
                rank0, 1:6);

            ctx.permutationInput = v;
            ctx.legacyPermutationRank0 = rank0;
            ctx.legacyPermutationOrder = rawOrder;
            ctx.permutationOrderCandidate = rawOrder;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 08 używa regularMod(v,720) bez detour ', ...
                 'rankingu 1-based; rank 1 staje się rank0=1, a 720 rank0=0.'];

            order = rawOrder;
        end
    end
end
