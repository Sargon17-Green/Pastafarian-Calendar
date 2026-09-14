classdef VaultOldPendingPatch
    % PATCH 10: wszystkie reads jednego round pochodzą z jednego vaultOld,
    % wszystkie writes trafiają do pending, a commit następuje dopiero po 6.
    methods (Static)
        function nextBowls = apply( ...
                bowls, dropNumber, drop, stoneRow, order, pours)
            if ~iscell(bowls) || numel(bowls) ~= 6
                error('Pastafari:Bowls:VaultShape', ...
                    'PATCH 10 wymaga sześciu mis wejściowych.');
            end
            if ~iscell(stoneRow) || numel(stoneRow) ~= 5
                error('Pastafari:Bowls:VaultStoneRow', ...
                    'PATCH 10 wymaga pięciu kamieni.');
            end
            if ~isnumeric(order) || ~isvector(order) || numel(order) ~= 6 || ...
                    ~isequal(sort(order), 1:6)
                error('Pastafari:Bowls:VaultOrder', ...
                    'PATCH 10 wymaga permutacji bowl IDs 1..6.');
            end
            if ~iscell(pours) || numel(pours) ~= 6
                error('Pastafari:Bowls:VaultPours', ...
                    'PATCH 10 wymaga sześciu pours.');
            end
            pastafari.ValidationManager.requireExactIntegerInput(drop);

            vaultOld = bowls;
            pending = cell(1, 6);
            stoneByPosition = [1 2 3 4 5 1];

            for position = 1:6
                id = order(position);
                previousId = order( ...
                    pastafari.VaultOldPendingPatch.wrap1(position - 1, 6));
                nextId = order( ...
                    pastafari.VaultOldPendingPatch.wrap1(position + 1, 6));

                s = vaultOld{id} + ...
                    pastafari.BigInt(2) * vaultOld{previousId} + ...
                    pastafari.BigInt(3) * vaultOld{nextId} + ...
                    pours{position} + drop + ...
                    stoneRow{stoneByPosition(position)};

                pending{id} = ...
                    pastafari.VaultOldPendingPatch.saveHistorical( ...
                        s.square() + pastafari.BigInt(5) * ...
                        vaultOld{previousId} * vaultOld{nextId} + ...
                        pastafari.BigInt(dropNumber * position));
            end

            nextBowls = pending;
        end
    end

    methods (Static, Access = private)
        function idx = wrap1(position, sizeValue)
            idx = mod(position - 1, sizeValue) + 1;
        end

        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
