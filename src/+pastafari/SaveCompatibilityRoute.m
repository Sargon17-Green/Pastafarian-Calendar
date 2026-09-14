classdef SaveCompatibilityRoute
    % Produkcyjna trasa zgodności SAVE w stanie Discovery 01.
    % W tym etapie deleguje bezpośrednio do błędnego oldRemainder.
    methods (Static)
        function [ctx, value] = call(ctx, inputValue)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(inputValue);

            ctx.phase = 'DISCOVERY_01';
            ctx.subPhase = 1;
            ctx.mode = 'LEGACY_SAVE_REMAINDER';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'DISCOVERY_01_OLD_REMAINDER';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery01.oldRemainder.calls');

            ctx.legacyRemainderInput = pastafari.BigInt.coerce(inputValue);
            value = pastafari.LegacyRemainderAdapter.oldRemainder( ...
                ctx.legacyRemainderInput);
            ctx.legacyRemainderValue = value;
            ctx.saveCandidate = value;
            ctx.diagnostics{end + 1} = ...
                'Aktywna historyczna ścieżka oldRemainder bez łaty savePatch.';
        end
    end
end
