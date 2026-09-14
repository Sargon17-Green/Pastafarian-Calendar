classdef OrderAt46CompatibilityRoute
    % Produkcyjna trasa Discovery 11.
    %
    % Poprawne bowl rounds z PATCH 10 pozostają bez zmian. Ta warstwa:
    % 1. zapisuje 46 drop orders do jednego legacyOrderMemory,
    % 2. zapamiętuje obserwacyjnie order po drop 46,
    % 3. wykonuje 12 poprawnych post-stirs,
    % 4. nadpisuje tę samą pamięć order przy każdym post-stir,
    % 5. queryOrder błędnie czyta ostatni zapis (post-stir 12).
    %
    % W etapie 22 nie istnieje jeszcze orderAt46Latch.
    methods (Static)
        function [ctx, bowls, queriedOrder] = call( ...
                ctx, visible, bowlsAfterDrop46)
            pastafari.ValidationManager.requireContext(ctx);

            if ~iscell(visible) || numel(visible) ~= 46
                error('Pastafari:OrderMemory:VisibleShape', ...
                    'Discovery 11 wymaga dokładnie 46 visible drops.');
            end
            if ~iscell(bowlsAfterDrop46) || numel(bowlsAfterDrop46) ~= 6
                error('Pastafari:OrderMemory:BowlShape', ...
                    'Discovery 11 wymaga sześciu mis po drop 46.');
            end

            ctx.phase = 'DISCOVERY_11';
            ctx.subPhase = 11;
            ctx.mode = 'OVERWRITABLE_ORDER_MEMORY';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_11_LOST_ORDER_AT_DROP_46';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery11.lostOrderAtDrop46.calls');

            memory = pastafari.LegacyOverwritableOrderMemory();

            for dropNumber = 1:46
                order = pastafari.OrderAt46CompatibilityRoute.orderFromValue( ...
                    visible{dropNumber});
                memory.write(order, sprintf('drop %d', dropNumber));

                if dropNumber == 46
                    ctx.legacyOrderAtDrop46Observed = order;
                end
            end

            ctx.prePostStirBowlsCandidate = bowlsAfterDrop46;
            bowls = bowlsAfterDrop46;

            for stir = 1:12
                old = bowls;

                savedStirSum = pastafari.BigInt(0);
                for id = 1:6
                    savedStirSum = savedStirSum + old{id};
                end
                savedStirSum = ...
                    pastafari.OrderAt46CompatibilityRoute.saveHistorical( ...
                        savedStirSum + pastafari.BigInt(149 * stir));

                order = pastafari.OrderAt46CompatibilityRoute.orderFromValue( ...
                    savedStirSum);
                memory.write(order, sprintf('post-stir %d', stir));

                pending = cell(1, 6);
                for position = 1:6
                    id = order(position);
                    previousId = order( ...
                        pastafari.OrderAt46CompatibilityRoute.wrap1( ...
                            position - 1, 6));
                    nextId = order( ...
                        pastafari.OrderAt46CompatibilityRoute.wrap1( ...
                            position + 1, 6));

                    s = old{id} + ...
                        pastafari.BigInt(3) * old{previousId} + ...
                        pastafari.BigInt(5) * old{nextId} + ...
                        savedStirSum + pastafari.BigInt(stir) + ...
                        pastafari.BigInt(position * position);

                    pending{id} = ...
                        pastafari.OrderAt46CompatibilityRoute.saveHistorical( ...
                            s.square() + pastafari.BigInt(7) * ...
                            old{previousId} * old{nextId});
                end

                bowls = pending;
            end

            queriedOrder = memory.queryOrder();

            ctx.legacyOverwritableOrderMemoryFinal = memory.currentOrder;
            ctx.legacyOrderMemoryWriteCount = memory.writeCount;
            ctx.legacyOrderMemoryLastSource = memory.lastSource;
            ctx.queriedOrderCandidate = queriedOrder;
            ctx.postStirBowlsCandidate = bowls;
            ctx.currentBowlOrder = queriedOrder;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 11 używa jednego overwritable order memory: ', ...
                 '46 drop writes + 12 post-stir writes. queryOrder zwraca ', ...
                 'post-stir 12 zamiast order z drop 46.'];
        end
    end

    methods (Static, Access = private)
        function order = orderFromValue(value)
            [~, rank0] = pastafari.OneBasedRankDetourPatch.apply(value);
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
