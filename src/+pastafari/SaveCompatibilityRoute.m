classdef SaveCompatibilityRoute
    % Produkcyjna trasa zgodności SAVE po PATCH 01.
    % Najpierw zachowuje wynik historycznego oldRemainder, a następnie nakłada savePatch.
    methods (Static)
        function [ctx, value] = call(ctx, inputValue)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(inputValue);

            ctx.phase = 'PATCH_01';
            ctx.subPhase = 1;
            ctx.mode = 'SAVE_PATCH_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';

            ctx.branchTrace{end + 1} = 'DISCOVERY_01_OLD_REMAINDER';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery01.oldRemainder.calls');

            ctx.legacyRemainderInput = pastafari.BigInt.coerce(inputValue);
            rawLegacy = pastafari.LegacyRemainderAdapter.oldRemainder( ...
                ctx.legacyRemainderInput);
            ctx.legacyRemainderValue = rawLegacy;

            ctx.branchTrace{end + 1} = 'PATCH_01_SAVE_PATCH';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch01.savePatch.calls');

            value = pastafari.SavePatch.apply(rawLegacy);
            ctx.saveCandidate = value;
            ctx.diagnostics{end + 1} = ...
                'savePatch zamienia wyłącznie zerowy wynik legacy na M.';
        end
    end
end
