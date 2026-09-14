classdef BowlAliasPatch
    % PATCH 09: pozycja misy jest mapowana na rzeczywisty bowl ID
    % dokładnie przez bowlAlias[position] = order[position].
    methods (Static)
        function bowlAlias = fromOrder(order)
            if ~isnumeric(order) || ~isvector(order) || numel(order) ~= 6 || ...
                    ~isequal(sort(order), 1:6)
                error('Pastafari:Bowls:AliasOrder', ...
                    'bowlAlias wymaga permutacji dokładnie sześciu bowl IDs.');
            end
            bowlAlias = order;
        end

        function pours = computePours(oldBowls, drop, stoneRow, dropNumber, order)
            if ~iscell(oldBowls) || numel(oldBowls) ~= 6
                error('Pastafari:Bowls:AliasShape', ...
                    'PATCH 09 wymaga sześciu mis.');
            end
            if ~iscell(stoneRow) || numel(stoneRow) ~= 5
                error('Pastafari:Bowls:AliasStoneRow', ...
                    'PATCH 09 wymaga pięciu kamieni.');
            end
            pastafari.ValidationManager.requireExactIntegerInput(drop);

            bowlAlias = pastafari.BowlAliasPatch.fromOrder(order);
            d = pastafari.BigInt.coerce(drop);
            i = pastafari.BigInt(dropNumber);

            pours = { ...
                pastafari.BigInt(0), pastafari.BigInt(0), ...
                pastafari.BigInt(0), pastafari.BigInt(0), ...
                pastafari.BigInt(0), pastafari.BigInt(0)};

            pours{1} = pastafari.BowlAliasPatch.saveHistorical( ...
                d.square() + stoneRow{1} * oldBowls{bowlAlias(1)} + ...
                pastafari.BigInt(3) * i);
            pours{2} = pastafari.BowlAliasPatch.saveHistorical( ...
                d.square() + stoneRow{2} * oldBowls{bowlAlias(2)} + ...
                pastafari.BigInt(5) * i);
            pours{3} = pastafari.BowlAliasPatch.saveHistorical( ...
                d.square() + stoneRow{3} * oldBowls{bowlAlias(3)} + ...
                pastafari.BigInt(7) * i);
        end
    end

    methods (Static, Access = private)
        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
