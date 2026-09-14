classdef BowlPourCompatibilityRoute
    % Produkcyjna trasa Discovery 09.
    % Tylko pours pozostają historycznie przywiązane do bowls 1,2,3.
    % Aktualizacja sześciu mis korzysta jeszcze z poprawnego snapshotu old;
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

            ctx.phase = 'DISCOVERY_09';
            ctx.subPhase = 9;
            ctx.mode = 'FIXED_BOWL_POURS';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'DISCOVERY_09_FIXED_BOWL_POURS';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery09.fixedBowlPours.calls');

            bowls = pastafari.BowlPourCompatibilityRoute.initialBowls(counts);
            ctx.initialBowlsCandidate = bowls;
            stoneByPosition = [1 2 3 4 5 1];

            for dropNumber = 1:46
                drop = visible{dropNumber};
                order = pastafari.BowlPourCompatibilityRoute.orderFromDrop(drop);
                old = bowls;

                pours = pastafari.LegacyFixedBowlPourAdapter.compute( ...
                    old, drop, stones(dropNumber, :), dropNumber);

                if dropNumber == 1
                    ctx.legacyFirstRoundPours = pours;
                    ctx.firstRoundPoursCandidate = pours;
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
                ctx.currentBowlOrder = order;
            end

            ctx.legacyFixedBowlFinalBowls = bowls;
            ctx.bowlsCandidate = bowls;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 09 interpretuje trzy pours jako bowl IDs 1,2,3 ', ...
                 'zamiast positions mapowanych przez bieżący order.'];
        end
    end

    methods (Static, Access = private)
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
