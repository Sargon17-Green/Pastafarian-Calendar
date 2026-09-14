classdef GrindTableCompatibilityRoute
    % Produkcyjna trasa mielenia po PATCH 07.
    % Historyczny lookup grind+1 jest wykonywany najpierw na tabeli bez
    % sentinel i zachowywany jako blizna. Publikowana ścieżka używa tego
    % samego lookupu na tabeli z sentinel row pod logicznym indeksem 0.
    methods (Static)
        function [ctx, visible] = call(ctx, counts, stones, hidden, priorVisible)
            pastafari.ValidationManager.requireContext(ctx);

            if ~iscell(stones) || ~isequal(size(stones), [46, 5])
                error('Pastafari:GrindTable:StoneShape', ...
                    'Trasa mielenia wymaga tabeli kamieni 46x5.');
            end
            if ~iscell(hidden) || numel(hidden) ~= 7
                error('Pastafari:GrindTable:HiddenShape', ...
                    'Trasa mielenia wymaga siedmiu logicznych hidden.');
            end
            if ~iscell(priorVisible) || numel(priorVisible) ~= 46
                error('Pastafari:GrindTable:PriorVisibleShape', ...
                    'Trasa mielenia wymaga 46 poprawionych visible drops.');
            end

            ctx.branchTrace{end + 1} = 'DISCOVERY_07_GRIND_TABLE_INDEX';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery07.grindTableIndex.calls');

            legacyRows = ...
                pastafari.LegacyGrindTableAdapter.rowsWithoutSentinel();
            [legacyVisible, requested, resolved] = ...
                pastafari.GrindTableCompatibilityRoute.buildWithRows( ...
                    counts, stones, hidden, legacyRows);

            ctx.phase = 'PATCH_07';
            ctx.subPhase = 7;
            ctx.mode = 'SENTINEL_GRIND_ROW_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_07_SENTINEL_GRIND_ROW';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch07.sentinelGrindRow.calls');

            patchedRows = pastafari.SentinelGrindRowPatch.rowsWithSentinel();
            [visible, ~, ~] = ...
                pastafari.GrindTableCompatibilityRoute.buildWithRows( ...
                    counts, stones, hidden, patchedRows);

            ctx.preGrindVisibleDrops = priorVisible;
            ctx.legacyGrindRequestedIndices = requested;
            ctx.legacyGrindResolvedIndices = resolved;
            ctx.legacyGrindVisibleDrops = legacyVisible;
            ctx.grindVisibleCandidate = visible;
            ctx.visibleDropsCandidate = visible;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 07 zachowuje historyczne grind+1, ale dodaje ', ...
                 'sentinel row przed 11 kanonicznymi wierszami.'];
        end
    end

    methods (Static, Access = private)
        function [visible, requested, resolved] = buildWithRows( ...
                counts, stones, hidden, rows)
            visible = cell(1, 46);
            requested = zeros(1, 11);
            resolved = zeros(1, 11);
            offsets = [1, 3, 7];

            for grind = 1:11
                [~, requested(grind), resolved(grind)] = ...
                    pastafari.LegacyGrindTableAdapter.rowForGrind( ...
                        rows, grind);
            end

            for i = 1:46
                priors = cell(1, 3);
                for priorNumber = 1:3
                    [value, found, slot] = ...
                        pastafari.LegacyPriorAdapter.legacyPrior( ...
                            visible, i, offsets(priorNumber));
                    if found
                        priors{priorNumber} = value;
                    else
                        priors{priorNumber} = ...
                            pastafari.PriorPatch.resolveMissing(slot, hidden);
                    end
                end

                p1 = priors{1};
                p3 = priors{2};
                p7 = priors{3};

                value = pastafari.GrindTableCompatibilityRoute.saveHistorical( ...
                    stones{i, 1} * counts.action + ...
                    stones{i, 2} * counts.target + ...
                    stones{i, 3} * counts.distance + ...
                    stones{i, 4} * counts.connection + ...
                    stones{i, 5} * pastafari.BigInt(counts.direction) + ...
                    p1 + pastafari.BigInt(3) * p3 + ...
                    pastafari.BigInt(5) * p7 + pastafari.BigInt(i));

                for grind = 1:11
                    oldValue = value;
                    [row, ~, ~] = ...
                        pastafari.LegacyGrindTableAdapter.rowForGrind( ...
                            rows, grind);
                    value = ...
                        pastafari.GrindTableCompatibilityRoute.saveHistorical( ...
                            oldValue.square() + ...
                            pastafari.BigInt(row(1)) * oldValue + ...
                            pastafari.BigInt(row(2)) * p1 + ...
                            pastafari.BigInt(row(3)) * p3 + ...
                            pastafari.BigInt(row(4)) * p7 + ...
                            stones{i, row(5)});
                end

                visible{i} = value;
            end
        end

        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
