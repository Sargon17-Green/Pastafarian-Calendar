classdef BowlPourCompatibilityRoute
    % Produkcyjna trasa mis po PATCH 09.
    % Najpierw wykonuje pełną historyczną ścieżkę fixed-bowl pours jako bliznę.
    % Publikowana ścieżka używa bowlAlias[position]=order[position].
    % Obie ścieżki nadal używają snapshotu old i osobnego pending;
    % wada in-place contamination należy dopiero do Discovery 10.
    methods (Static)
        function [ctx, bowls] = call(ctx, counts, stones, visible)
            pastafari.ValidationManager.requireContext(ctx);

            if ~iscell(stones) || ~isequal(size(stones), [46, 5])
                error('Pastafari:Bowls:StoneShape', ...
                    'Trasa mis wymaga tabeli kamieni 46x5.');
            end
            if ~iscell(visible) || numel(visible) ~= 46
                error('Pastafari:Bowls:VisibleShape', ...
                    'Trasa mis wymaga dokładnie 46 visible drops.');
            end

            ctx.branchTrace{end + 1} = 'DISCOVERY_09_FIXED_BOWL_POURS';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery09.fixedBowlPours.calls');

            initial = pastafari.BowlPourCompatibilityRoute.initialBowls(counts);
            ctx.initialBowlsCandidate = initial;

            [legacyFinal, legacyFirstPours, ~] = ...
                pastafari.BowlPourCompatibilityRoute.buildRounds( ...
                    initial, stones, visible, false);

            ctx.phase = 'PATCH_09';
            ctx.subPhase = 9;
            ctx.mode = 'BOWL_ALIASES_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_09_BOWL_ALIASES';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch09.bowlAliases.calls');

            [bowls, patchedFirstPours, finalOrder] = ...
                pastafari.BowlPourCompatibilityRoute.buildRounds( ...
                    initial, stones, visible, true);

            ctx.legacyFirstRoundPours = legacyFirstPours;
            ctx.firstRoundPoursCandidate = patchedFirstPours;
            ctx.legacyFixedBowlFinalBowls = legacyFinal;
            ctx.bowlsCandidate = bowls;
            ctx.currentBowlOrder = finalOrder;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 09 zachowuje fixed-bowl pours jako bliznę, ale ', ...
                 'publikuje pours czytające old{bowlAlias(position)}, gdzie ', ...
                 'bowlAlias(position)=order(position).'];
        end
    end

    methods (Static, Access = private)
        function [bowls, firstPours, finalOrder] = buildRounds( ...
                initial, stones, visible, useAliases)
            bowls = initial;
            firstPours = [];
            finalOrder = [];
            stoneByPosition = [1 2 3 4 5 1];

            for dropNumber = 1:46
                drop = visible{dropNumber};
                order = pastafari.BowlPourCompatibilityRoute.orderFromDrop(drop);
                old = bowls;

                if useAliases
                    pours = pastafari.BowlAliasPatch.computePours( ...
                        old, drop, stones(dropNumber, :), dropNumber, order);
                else
                    pours = pastafari.LegacyFixedBowlPourAdapter.compute( ...
                        old, drop, stones(dropNumber, :), dropNumber);
                end

                if dropNumber == 1
                    firstPours = pours;
                end

                pending = cell(1, 6);
                for position = 1:6
                    id = order(position);
                    previousId = order(pastafari.BowlPourCompatibilityRoute.wrap1( ...
                        position - 1, 6));
                    nextId = order(pastafari.BowlPourCompatibilityRoute.wrap1( ...
                        position + 1, 6));

                    s = old{id} + ...
                        pastafari.BigInt(2) * old{previousId} + ...
                        pastafari.BigInt(3) * old{nextId} + ...
                        pours{position} + drop + ...
                        stones{dropNumber, stoneByPosition(position)};

                    pending{id} = ...
                        pastafari.BowlPourCompatibilityRoute.saveHistorical( ...
                            s.square() + pastafari.BigInt(5) * ...
                            old{previousId} * old{nextId} + ...
                            pastafari.BigInt(dropNumber * position));
                end

                bowls = pending;
                finalOrder = order;
            end
        end

        function bowls = initialBowls(counts)
            primes = [17 19 23 29 31 37];
            bowls = cell(1, 6);
            for id = 1:6
                s = counts.action + counts.target * pastafari.BigInt(id) + ...
                    counts.distance + counts.connection + ...
                    pastafari.BigInt(counts.direction) + ...
                    pastafari.BigInt(primes(id) * primes(id));
                bowls{id} = ...
                    pastafari.BowlPourCompatibilityRoute.saveHistorical( ...
                        s.square() + pastafari.BigInt(id));
            end
        end

        function order = orderFromDrop(drop)
            [~, rank0] = pastafari.OneBasedRankDetourPatch.apply(drop);
            order = pastafari.LegacyPermutationUnrank0.unrank0(rank0, 1:6);
        end

        function idx = wrap1(position, sizeValue)
            idx = mod(position - 1, sizeValue) + 1;
        end

        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
