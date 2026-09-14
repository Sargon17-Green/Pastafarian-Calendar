classdef BowlStirCompatibilityRoute
    % Produkcyjna trasa Discovery 10.
    % PATCH 09 pozostaje osobną, zieloną warstwą. Ta nowa warstwa ponownie
    % buduje rounds z poprawnymi bowl aliases, lecz sześć bowl writes wykonuje
    % sekwencyjnie in-place przez LegacyInPlaceBowlUpdateWrong.
    %
    % W etapie 20 nie istnieje jeszcze vaultOld ani pending dla tej trasy.
    methods (Static)
        function [ctx, bowls] = call( ...
                ctx, counts, stones, visible, preInPlaceBowls)
            pastafari.ValidationManager.requireContext(ctx);

            if ~iscell(stones) || ~isequal(size(stones), [46, 5])
                error('Pastafari:Bowls:StirStoneShape', ...
                    'Discovery 10 wymaga tabeli kamieni 46x5.');
            end
            if ~iscell(visible) || numel(visible) ~= 46
                error('Pastafari:Bowls:StirVisibleShape', ...
                    'Discovery 10 wymaga dokładnie 46 visible drops.');
            end
            if ~iscell(preInPlaceBowls) || numel(preInPlaceBowls) ~= 6
                error('Pastafari:Bowls:PreInPlaceShape', ...
                    'Discovery 10 wymaga sześciu mis z zielonego PATCH 09.');
            end

            ctx.phase = 'DISCOVERY_10';
            ctx.subPhase = 10;
            ctx.mode = 'SEQUENTIAL_IN_PLACE_BOWL_STIR';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_10_IN_PLACE_BOWL_CONTAMINATION';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery10.inPlaceBowlContamination.calls');

            ctx.preInPlaceBowlsCandidate = preInPlaceBowls;

            bowls = pastafari.BowlStirCompatibilityRoute.initialBowls(counts);

            for dropNumber = 1:46
                drop = visible{dropNumber};
                order = ...
                    pastafari.BowlStirCompatibilityRoute.orderFromDrop(drop);

                % PATCH 09 pozostaje aktywny: pours są poprawnie mapowane przez
                % bieżący order. Nowa wada dotyczy wyłącznie bowl stir.
                pours = pastafari.BowlAliasPatch.computePours( ...
                    bowls, drop, stones(dropNumber, :), dropNumber, order);

                bowls = pastafari.LegacyInPlaceBowlUpdateWrong.apply( ...
                    bowls, dropNumber, drop, stones(dropNumber, :), ...
                    order, pours);

                if dropNumber == 1
                    ctx.legacyInPlaceFirstRoundBowls = bowls;
                    ctx.firstRoundStirCandidate = bowls;
                end

                ctx.currentBowlOrder = order;
            end

            ctx.legacyInPlaceFinalBowls = bowls;
            ctx.stirBowlsCandidate = bowls;
            ctx.bowlsCandidate = bowls;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 10 zapisuje każdą bowl natychmiast do working; ', ...
                 'późniejsze positions czytają już zmienionych sąsiadów.'];
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
                    pastafari.BowlStirCompatibilityRoute.saveHistorical( ...
                        s.square() + pastafari.BigInt(id));
            end
        end

        function order = orderFromDrop(drop)
            [~, rank0] = pastafari.OneBasedRankDetourPatch.apply(drop);
            order = pastafari.LegacyPermutationUnrank0.unrank0(rank0, 1:6);
        end

        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
