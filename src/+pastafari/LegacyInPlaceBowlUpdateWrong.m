classdef LegacyInPlaceBowlUpdateWrong
    % Historyczna wada Discovery 10.
    % Wszystkie odczyty i zapisy jednego round używają tego samego working.
    % Wynik pozycji jest wpisywany natychmiast, więc późniejsze pozycje
    % mogą czytać już zmienione current/previous/next.
    methods (Static)
        function working = apply(bowls, dropNumber, drop, stoneRow, order, pours)
            if ~iscell(bowls) || numel(bowls) ~= 6
                error('Pastafari:Bowls:InPlaceShape', ...
                    'Historyczna aktualizacja in-place wymaga sześciu mis.');
            end
            if ~iscell(stoneRow) || numel(stoneRow) ~= 5
                error('Pastafari:Bowls:InPlaceStoneRow', ...
                    'Historyczna aktualizacja in-place wymaga pięciu kamieni.');
            end
            if ~isnumeric(order) || ~isvector(order) || numel(order) ~= 6 || ...
                    ~isequal(sort(order), 1:6)
                error('Pastafari:Bowls:InPlaceOrder', ...
                    'Historyczna aktualizacja in-place wymaga permutacji 1..6.');
            end
            if ~iscell(pours) || numel(pours) ~= 6
                error('Pastafari:Bowls:InPlacePours', ...
                    'Historyczna aktualizacja in-place wymaga sześciu pours.');
            end
            pastafari.ValidationManager.requireExactIntegerInput(drop);

            working = bowls;
            stoneByPosition = [1 2 3 4 5 1];

            for position = 1:6
                id = order(position);
                previousId = order( ...
                    pastafari.LegacyInPlaceBowlUpdateWrong.wrap1( ...
                        position - 1, 6));
                nextId = order( ...
                    pastafari.LegacyInPlaceBowlUpdateWrong.wrap1( ...
                        position + 1, 6));

                s = working{id} + ...
                    pastafari.BigInt(2) * working{previousId} + ...
                    pastafari.BigInt(3) * working{nextId} + ...
                    pours{position} + drop + ...
                    stoneRow{stoneByPosition(position)};

                working{id} = ...
                    pastafari.LegacyInPlaceBowlUpdateWrong.saveHistorical( ...
                        s.square() + pastafari.BigInt(5) * ...
                        working{previousId} * working{nextId} + ...
                        pastafari.BigInt(dropNumber * position));
            end
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
