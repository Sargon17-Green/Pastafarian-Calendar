classdef MonthLengthCompatibilityRoute
    % Produkcyjna trasa month lengths po PATCH 23.
    %
    % Historyczna konkretna lista jest zawsze próbowana jako pierwsza.
    % Jeśli powstaje, zachowujemy raw rank i sprawdzamy exact equivalence.
    % Jeśli jest blocked, semantic path przechodzi na VirtualLegacyList.
    methods (Static)
        function [ctx, monthLengths] = call( ...
                ctx, structureSauce, totalDays, monthCount)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.MonthLengthCompatibilityRoute.requireSauce( ...
                structureSauce);

            [ctx, concreteWays, descriptor, blocked] = ...
                pastafari.LegacyMonthLengthMaterializationAdapter.call( ...
                    ctx, totalDays, monthCount);

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_23_MATERIALIZED_MONTH_LENGTHS';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery23.materializedMonthLengths.calls');

            nextBowlId = pastafari.LatchedSuccessorPatch.apply( ...
                structureSauce.orderAt46Latch, 3);
            stream = pastafari.AnswerRingStreamFactory.fromSauce( ...
                structureSauce.bowls, 3, nextBowlId, 31);

            virtualList = pastafari.VirtualLegacyList( ...
                totalDays, monthCount);
            virtualCount = virtualList.count();

            if virtualCount < pastafari.BigInt(1)
                error('Pastafari:MonthLengths:VirtualFamilyEmpty', ...
                    'Wirtualna rodzina długości miesięcy jest pusta.');
            end

            if blocked
                [ctx, semanticRank] = ...
                    pastafari.GeneralSelectionCompatibilityRoute.call( ...
                        ctx, stream, virtualCount);
                monthLengths = virtualList.itemAt1(semanticRank);
            else
                rawCount = pastafari.BigInt(numel(concreteWays));
                if rawCount ~= virtualCount
                    error('Pastafari:MonthLengths:VirtualCountMismatch', ...
                        ['VirtualLegacyList count różni się od konkretnej ', ...
                         'legacy list dla małej rodziny.']);
                end

                [ctx, rawRank] = ...
                    pastafari.GeneralSelectionCompatibilityRoute.call( ...
                        ctx, stream, rawCount);
                rawRow = concreteWays{rawRank.toDoubleExact()};
                virtualRow = virtualList.itemAt1(rawRank);

                if ~isequal(rawRow, virtualRow)
                    error('Pastafari:MonthLengths:VirtualOrderMismatch', ...
                        ['VirtualLegacyList itemAt1 utracił dokładny ', ...
                         'lexicographic order legacy list.']);
                end

                ctx.legacyMonthLengthRank = rawRank;
                semanticRank = rawRank;
                monthLengths = virtualRow;
            end

            ctx.phase = 'PATCH_23';
            ctx.subPhase = 23;
            ctx.mode = 'VIRTUAL_LEGACY_LIST_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_23_VIRTUAL_LEGACY_LIST';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch23.virtualLegacyList.calls');

            ctx.monthLengthStreamFirst = stream.first;
            ctx.monthLengthStreamDirectionStep = stream.directionStep;
            ctx.monthLengthsCandidate = monthLengths;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 23 blockedLegacy=%d virtualCount=%s ', ...
                 'semanticRank=%s family=%s.'], ...
                blocked, char(virtualCount), char(semanticRank), ...
                descriptor.familyName);
        end
    end

    methods (Static, Access = private)
        function requireSauce(sauce)
            if ~isstruct(sauce) || ...
                    ~isfield(sauce, 'bowls') || ...
                    ~isfield(sauce, 'orderAt46Latch')
                error('Pastafari:MonthLengths:StructureSauceShape', ...
                    'Month lengths wymagają bowls i orderAt46Latch.');
            end

            if ~iscell(sauce.bowls) || numel(sauce.bowls) ~= 6
                error('Pastafari:MonthLengths:StructureSauceBowls', ...
                    'Structure sauce musi zawierać sześć bowls.');
            end

            order = sauce.orderAt46Latch;
            if ~(isnumeric(order) && isvector(order) && ...
                    numel(order) == 6 && ...
                    isequal(sort(order(:).'), 1:6))
                error('Pastafari:MonthLengths:StructureSauceOrder', ...
                    'orderAt46Latch musi być permutacją 1..6.');
            end
        end
    end
end
