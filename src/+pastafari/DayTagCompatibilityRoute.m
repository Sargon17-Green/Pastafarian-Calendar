classdef DayTagCompatibilityRoute
    % Produkcyjna trasa licznika dnia po PATCH 02.
    % Zachowuje surowy oldDayTag, po czym nakłada FoundationScarPatch.
    methods (Static)
        function [ctx, value] = call(ctx, day)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(day);

            ctx.phase = 'PATCH_02';
            ctx.subPhase = 2;
            ctx.mode = 'FOUNDATION_SCAR_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';

            ctx.branchTrace{end + 1} = 'DISCOVERY_02_OLD_DAY_TAG';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery02.oldDayTag.calls');

            ctx.dayTagInput = pastafari.BigInt.coerce(day);
            rawLegacy = pastafari.LegacyDayTagAdapter.oldDayTag(ctx.dayTagInput);
            ctx.legacyDayTagValue = rawLegacy;

            ctx.branchTrace{end + 1} = 'PATCH_02_FOUNDATION_SCAR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch02.foundationScar.calls');

            value = pastafari.FoundationScarPatch.apply( ...
                ctx.dayTagInput, rawLegacy);
            ctx.dayTagCandidate = value;
            ctx.diagnostics{end + 1} = ...
                ['FoundationScarPatch dodaje +1 od Foundation wzwyż i ', ...
                 'zachowuje redundantny guard Foundation jako bliznę.'];
        end
    end
end
