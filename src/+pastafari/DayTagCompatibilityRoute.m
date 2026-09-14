classdef DayTagCompatibilityRoute
    % Produkcyjna trasa licznika dnia w stanie Discovery 02.
    % W etapie 4 publikuje bezpośrednio błędny wynik oldDayTag.
    methods (Static)
        function [ctx, value] = call(ctx, day)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(day);

            ctx.phase = 'DISCOVERY_02';
            ctx.subPhase = 2;
            ctx.mode = 'LEGACY_DAY_TAG';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'DISCOVERY_02_OLD_DAY_TAG';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery02.oldDayTag.calls');

            ctx.dayTagInput = pastafari.BigInt.coerce(day);
            value = pastafari.LegacyDayTagAdapter.oldDayTag(ctx.dayTagInput);
            ctx.legacyDayTagValue = value;
            ctx.dayTagCandidate = value;
            ctx.diagnostics{end + 1} = ...
                'Aktywna historyczna ścieżka oldDayTag bez łaty Foundation scar.';
        end
    end
end
