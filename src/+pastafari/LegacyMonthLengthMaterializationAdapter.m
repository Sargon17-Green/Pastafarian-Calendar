classdef LegacyMonthLengthMaterializationAdapter
    % Adapter zachowujący historyczną próbę list_all_ways jako scar.
    methods (Static)
        function [ctx, ways, descriptor, blocked] = ...
                call(ctx, totalDays, monthCount)
            pastafari.ValidationManager.requireContext(ctx);

            total = pastafari.BigInt.coerce(totalDays);
            months = pastafari.BigInt.coerce(monthCount);
            descriptor = ...
                pastafari.LegacyAllMonthLengthWaysAPI.probeAllWays( ...
                    total, months);

            ctx.monthLengthTotalDays = total;
            ctx.monthLengthCountCandidate = months;
            ctx.legacyMonthLengthSafeCap = descriptor.safeCap;
            ctx.legacyMonthLengthLowerBound = ...
                descriptor.lowerBoundProof.lowerBound;
            ctx.legacyMonthLengthProofWidth = ...
                descriptor.lowerBoundProof.width;
            ctx.legacyMonthLengthMaterializationAttempted = true;
            ctx.legacyMonthLengthMaterializationBlocked = false;
            ctx.legacyMonthLengthMaterializationError = '';
            ctx.legacyMonthLengthConcreteCount = [];
            ctx.legacyMonthLengthConcreteWays = {};

            ways = {};
            blocked = false;

            try
                [ways, descriptor] = ...
                    pastafari.LegacyAllMonthLengthWaysAPI.listAllWays( ...
                        total, months);
            catch err
                if strcmp(err.identifier, ...
                        'Pastafari:MonthLengths:LegacyMaterializationTooLarge')
                    blocked = true;
                    ctx.legacyMonthLengthMaterializationBlocked = true;
                    ctx.legacyMonthLengthMaterializationError = err.identifier;
                    return
                end
                rethrow(err)
            end

            ctx.legacyMonthLengthConcreteCount = ...
                pastafari.BigInt(numel(ways));
            ctx.legacyMonthLengthConcreteWays = ways;
        end
    end
end
