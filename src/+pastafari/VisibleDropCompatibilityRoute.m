classdef VisibleDropCompatibilityRoute
    % Produkcyjna trasa widocznych kropli w stanie Discovery 06.
    % legacyPrior nie zna slotów 0..-6. Brakujący poprzednik jest zastępowany
    % zerem wyłącznie po to, aby historyczna ścieżka mogła dalej się wykonać.
    methods (Static)
        function [ctx, visible] = call(ctx, counts, stones, hidden)
            pastafari.ValidationManager.requireContext(ctx);

            if ~iscell(stones) || ~isequal(size(stones), [46, 5])
                error('Pastafari:Prior:StoneShape', ...
                    'Trasa widocznych kropli wymaga tabeli kamieni 46x5.');
            end
            if ~iscell(hidden) || numel(hidden) ~= 7
                error('Pastafari:Prior:HiddenShape', ...
                    'Trasa widocznych kropli wymaga siedmiu logicznych hidden.');
            end

            ctx.phase = 'DISCOVERY_06';
            ctx.subPhase = 6;
            ctx.mode = 'LEGACY_PRIOR_WITHOUT_NEGATIVE_SLOTS';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'DISCOVERY_06_LEGACY_PRIOR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery06.legacyPrior.calls');

            [visible, requestedSlots, missingMatrix] = ...
                pastafari.VisibleDropCompatibilityRoute.buildLegacy( ...
                    counts, stones);

            ctx.legacyPriorRequestedSlots = requestedSlots;
            ctx.legacyPriorMissingMatrix = missingMatrix;
            ctx.legacyVisibleDrops = visible;
            ctx.visibleDropsCandidate = visible;
            ctx.diagnostics{end + 1} = ...
                ['legacyPrior rozumie tylko dodatnie indeksy visible; ', ...
                 'sloty 0..-6 nie widzą jeszcze hidden 1..7.'];
        end
    end

    methods (Static, Access = private)
        function [visible, requestedSlots, missingMatrix] = buildLegacy(counts, stones)
            visible = cell(1, 46);
            requestedSlots = zeros(46, 3);
            missingMatrix = false(46, 3);
            offsets = [1, 3, 7];

            grinds = [ ...
                3 5 7 11 1; ...
                5 7 11 13 2; ...
                7 11 13 17 3; ...
                11 13 17 19 4; ...
                13 17 19 23 5; ...
                17 19 23 29 1; ...
                19 23 29 31 2; ...
                23 29 31 37 3; ...
                29 31 37 41 4; ...
                31 37 41 43 5; ...
                37 41 43 47 1];

            for i = 1:46
                priors = cell(1, 3);

                for priorNumber = 1:3
                    [value, found, slot] = ...
                        pastafari.LegacyPriorAdapter.legacyPrior( ...
                            visible, i, offsets(priorNumber));
                    requestedSlots(i, priorNumber) = slot;
                    missingMatrix(i, priorNumber) = ~found;

                    if found
                        priors{priorNumber} = value;
                    else
                        priors{priorNumber} = pastafari.BigInt(0);
                    end
                end

                p1 = priors{1};
                p3 = priors{2};
                p7 = priors{3};

                x = pastafari.VisibleDropCompatibilityRoute.saveHistorical( ...
                    stones{i, 1} * counts.action + ...
                    stones{i, 2} * counts.target + ...
                    stones{i, 3} * counts.distance + ...
                    stones{i, 4} * counts.connection + ...
                    stones{i, 5} * pastafari.BigInt(counts.direction) + ...
                    p1 + pastafari.BigInt(3) * p3 + ...
                    pastafari.BigInt(5) * p7 + pastafari.BigInt(i));

                for grind = 1:11
                    oldX = x;
                    row = grinds(grind, :);
                    x = pastafari.VisibleDropCompatibilityRoute.saveHistorical( ...
                        oldX.square() + pastafari.BigInt(row(1)) * oldX + ...
                        pastafari.BigInt(row(2)) * p1 + ...
                        pastafari.BigInt(row(3)) * p3 + ...
                        pastafari.BigInt(row(4)) * p7 + ...
                        stones{i, row(5)});
                end

                visible{i} = x;
            end
        end

        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
