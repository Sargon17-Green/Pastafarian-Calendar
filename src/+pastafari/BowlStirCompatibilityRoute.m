classdef BowlStirCompatibilityRoute
    % Produkcyjna trasa mis po PATCH 10.
    % Najpierw wykonuje pełną surową ścieżkę Discovery 10 przez niezmieniony
    % LegacyInPlaceBowlUpdateWrong. Publikowana ścieżka używa vaultOld +
    % pending i zatwierdza wszystkie sześć writes dopiero po całym round.
    methods (Static)
        function [ctx, bowls] = call( ...
                ctx, counts, stones, visible, preInPlaceBowls)
            pastafari.ValidationManager.requireContext(ctx);

            if ~iscell(stones) || ~isequal(size(stones), [46, 5])
                error('Pastafari:Bowls:StirStoneShape', ...
                    'Trasa bowl stir wymaga tabeli kamieni 46x5.');
            end
            if ~iscell(visible) || numel(visible) ~= 46
                error('Pastafari:Bowls:StirVisibleShape', ...
                    'Trasa bowl stir wymaga dokładnie 46 visible drops.');
            end
            if ~iscell(preInPlaceBowls) || numel(preInPlaceBowls) ~= 6
                error('Pastafari:Bowls:PreInPlaceShape', ...
                    'PATCH 10 wymaga sześciu mis z zielonego PATCH 09.');
            end

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_10_IN_PLACE_BOWL_CONTAMINATION';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery10.inPlaceBowlContamination.calls');

            ctx.preInPlaceBowlsCandidate = preInPlaceBowls;

            initial = pastafari.BowlStirCompatibilityRoute.initialBowls(counts);

            [legacyFinal, legacyFirst, ~] = ...
                pastafari.BowlStirCompatibilityRoute.buildLegacy( ...
                    initial, stones, visible);

            ctx.phase = 'PATCH_10';
            ctx.subPhase = 10;
            ctx.mode = 'VAULT_OLD_PENDING_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = 'PATCH_10_VAULT_OLD_PENDING';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch10.vaultOldPending.calls');

            [bowls, patchedFirst, finalOrder] = ...
                pastafari.BowlStirCompatibilityRoute.buildPatched( ...
                    initial, stones, visible);

            ctx.legacyInPlaceFirstRoundBowls = legacyFirst;
            ctx.firstRoundStirCandidate = patchedFirst;
            ctx.legacyInPlaceFinalBowls = legacyFinal;
            ctx.stirBowlsCandidate = bowls;
            ctx.bowlsCandidate = bowls;
            ctx.currentBowlOrder = finalOrder;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 10 zachowuje surową ścieżkę in-place jako bliznę, ', ...
                 'ale publikuje rounds czytające wyłącznie z vaultOld, ', ...
                 'piszące do pending i commitujące po sześciu positions.'];
        end
    end

    methods (Static, Access = private)
        function [bowls, firstRound, finalOrder] = ...
                buildLegacy(initial, stones, visible)
            bowls = initial;
            firstRound = [];
            finalOrder = [];

            for dropNumber = 1:46
                drop = visible{dropNumber};
                order = ...
                    pastafari.BowlStirCompatibilityRoute.orderFromDrop(drop);

                pours = pastafari.BowlAliasPatch.computePours( ...
                    bowls, drop, stones(dropNumber, :), dropNumber, order);

                bowls = pastafari.LegacyInPlaceBowlUpdateWrong.apply( ...
                    bowls, dropNumber, drop, stones(dropNumber, :), ...
                    order, pours);

                if dropNumber == 1
                    firstRound = bowls;
                end
                finalOrder = order;
            end
        end

        function [bowls, firstRound, finalOrder] = ...
                buildPatched(initial, stones, visible)
            bowls = initial;
            firstRound = [];
            finalOrder = [];

            for dropNumber = 1:46
                drop = visible{dropNumber};
                order = ...
                    pastafari.BowlStirCompatibilityRoute.orderFromDrop(drop);

                % Pours także muszą czytać stan wejściowy tego round.
                vaultOld = bowls;
                pours = pastafari.BowlAliasPatch.computePours( ...
                    vaultOld, drop, stones(dropNumber, :), ...
                    dropNumber, order);

                bowls = pastafari.VaultOldPendingPatch.apply( ...
                    vaultOld, dropNumber, drop, stones(dropNumber, :), ...
                    order, pours);

                if dropNumber == 1
                    firstRound = bowls;
                end
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
