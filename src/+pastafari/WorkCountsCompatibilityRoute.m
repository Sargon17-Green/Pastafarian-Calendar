classdef WorkCountsCompatibilityRoute
    % Produkcyjna trasa mianowań pracy po PATCH 03.
    % Zachowuje surowy oldDistance, a następnie zastępuje go dystansem
    % chronologicznym abs(t-c)+1.
    methods (Static)
        function [ctx, counts] = call(ctx, calculationDay, targetDay)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
            pastafari.ValidationManager.requireExactIntegerInput(targetDay);

            c = pastafari.BigInt.coerce(calculationDay);
            t = pastafari.BigInt.coerce(targetDay);

            [ctx, action] = pastafari.DayTagCompatibilityRoute.call(ctx, c);
            [ctx, target] = pastafari.DayTagCompatibilityRoute.call(ctx, t);

            ctx.branchTrace{end + 1} = 'DISCOVERY_03_OLD_DISTANCE';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery03.oldDistance.calls');
            rawDistance = pastafari.LegacyDistanceAdapter.oldDistance(c, t);

            ctx.phase = 'PATCH_03';
            ctx.subPhase = 3;
            ctx.mode = 'CHRONOLOGICAL_DISTANCE_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_03_CHRONOLOGICAL_DISTANCE';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch03.chronologicalDistance.calls');

            distance = pastafari.ChronologicalDistancePatch.apply( ...
                c, t, rawDistance);
            connection = action + target;

            if t < c
                direction = 1;
            elseif t == c
                direction = 2;
            else
                direction = 3;
            end

            ctx.actionCount = action;
            ctx.targetCount = target;
            ctx.legacyDistanceValue = rawDistance;
            ctx.distanceCandidate = distance;
            ctx.connectionCount = connection;
            ctx.directionCount = direction;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 03 zachowuje oldDistance jako bliznę, lecz publikuje ', ...
                 'chronologiczne abs(t-c)+1.'];

            counts = struct( ...
                'action', action, ...
                'target', target, ...
                'distance', distance, ...
                'connection', connection, ...
                'direction', direction);
        end
    end
end
