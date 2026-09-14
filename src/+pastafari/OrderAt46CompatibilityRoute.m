classdef OrderAt46CompatibilityRoute
    % Produkcyjna trasa order po PATCH 11.
    %
    % Historyczny LegacyOverwritableOrderMemory nadal otrzymuje dokładnie
    % 46 drop writes i 12 post-stir writes. PATCH 11 tworzy niezależny,
    % jednokrotny orderAt46Latch bezpośrednio po drop 46 i przed post-stir 1.
    % queryOrder publikuje wyłącznie wartość latcha.
    methods (Static)
        function [ctx, bowls, queriedOrder] = call( ...
                ctx, visible, bowlsAfterDrop46)
            pastafari.ValidationManager.requireContext(ctx);

            if ~iscell(visible) || numel(visible) ~= 46
                error('Pastafari:OrderMemory:VisibleShape', ...
                    'PATCH 11 wymaga dokładnie 46 visible drops.');
            end
            if ~iscell(bowlsAfterDrop46) || numel(bowlsAfterDrop46) ~= 6
                error('Pastafari:OrderMemory:BowlShape', ...
                    'PATCH 11 wymaga sześciu mis po drop 46.');
            end

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_11_LOST_ORDER_AT_DROP_46';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery11.lostOrderAtDrop46.calls');

            memory = pastafari.LegacyOverwritableOrderMemory();
            orderAt46Latch = pastafari.OrderAt46LatchPatch();

            for dropNumber = 1:46
                order = pastafari.OrderAt46CompatibilityRoute.orderFromValue( ...
                    visible{dropNumber});
                memory.write(order, sprintf('drop %d', dropNumber));

                if dropNumber == 46
                    ctx.legacyOrderAtDrop46Observed = order;
                    orderAt46Latch.captureOnce(order);
                end
            end

            ctx.phase = 'PATCH_11';
            ctx.subPhase = 11;
            ctx.mode = 'ORDER_AT_46_LATCH_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_11_ORDER_AT_46_LATCH';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch11.orderAt46Latch.calls');

            ctx.prePostStirBowlsCandidate = bowlsAfterDrop46;
            bowls = bowlsAfterDrop46;

            % Post-stirs nadal nadpisują wyłącznie historyczną pamięć.
            % Latch nie jest dotykany w tej pętli.
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

            % Jedyna publikowana odpowiedź order pochodzi z latcha.
            queriedOrder = orderAt46Latch.queryOrder();

            % Surowa historyczna pamięć pozostaje w pełni obserwowalna.
            ctx.legacyOverwritableOrderMemoryFinal = memory.currentOrder;
            ctx.legacyOrderMemoryWriteCount = memory.writeCount;
            ctx.legacyOrderMemoryLastSource = memory.lastSource;
            ctx.queriedOrderCandidate = queriedOrder;
            ctx.postStirBowlsCandidate = bowls;
            ctx.currentBowlOrder = queriedOrder;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 11 zachowuje wszystkie 58 legacy order writes, ', ...
                 'ale queryOrder czyta jednokrotny snapshot order z drop 46.'];
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
