classdef LatchedSuccessorPatch
    % PATCH 12: successor wynika wyłącznie z pozycji queried bowl ID
    % w poprawnym orderAt46Latch.
    methods (Static)
        function successor = apply(orderAt46, queriedBowlId)
            if ~isnumeric(orderAt46) || ~isvector(orderAt46) || ...
                    numel(orderAt46) ~= 6 || ~isequal(sort(orderAt46), 1:6)
                error('Pastafari:Successor:LatchedOrder', ...
                    'PATCH 12 wymaga permutacji bowl IDs 1..6.');
            end
            if ~(isnumeric(queriedBowlId) && isscalar(queriedBowlId) && ...
                    isfinite(queriedBowlId) && fix(queriedBowlId) == queriedBowlId && ...
                    queriedBowlId >= 1 && queriedBowlId <= 6)
                error('Pastafari:Successor:LatchedBowlId', ...
                    'PATCH 12 wymaga queried bowl ID z zakresu 1..6.');
            end

            orderAt46 = reshape(orderAt46, 1, 6);
            position = find(orderAt46 == queriedBowlId, 1, 'first');
            if isempty(position)
                error('Pastafari:Successor:LatchedMissingBowlId', ...
                    'Queried bowl ID musi występować w orderAt46Latch.');
            end

            nextPosition = mod(position, numel(orderAt46)) + 1;
            successor = orderAt46(nextPosition);
        end
    end
end
