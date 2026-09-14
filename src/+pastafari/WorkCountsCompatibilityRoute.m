classdef WorkCountsCompatibilityRoute
    % Produkcyjna trasa mianowań pracy w stanie Discovery 03.
    % Action, target, connection i direction są już poprawne; distance
    % nadal pochodzi z historycznego oldDistance.
    methods (Static)
        function [ctx, counts] = call(ctx, calculationDay, targetDay)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
            pastafari.ValidationManager.requireExactIntegerInput(targetDay);

            c = pastafari.BigInt.coerce(calculationDay);
            t = pastafari.BigInt.coerce(targetDay);

            [ctx, action] = pastafari.DayTagCompatibilityRoute.call(ctx, c);
            [ctx, target] = pastafari.DayTagCompatibilityRoute.call(ctx, t);

            ctx.phase = 'DISCOVERY_03';
            ctx.subPhase = 3;
            ctx.mode = 'LEGACY_DISTANCE_FROM_DAY_TAGS';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'DISCOVERY_03_OLD_DISTANCE';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery03.oldDistance.calls');

            rawDistance = pastafari.LegacyDistanceAdapter.oldDistance(c, t);
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
            ctx.distanceCandidate = rawDistance;
            ctx.connectionCount = connection;
            ctx.directionCount = direction;
            ctx.diagnostics{end + 1} = ...
                'Distance nadal pochodzi z różnicy tagów dni; brak PATCH 03.';

            counts = struct( ...
                'action', action, ...
                'target', target, ...
                'distance', rawDistance, ...
                'connection', connection, ...
                'direction', direction);
        end
    end
end
