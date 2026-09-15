classdef VirtualLegacyList < handle
    % PATCH 23: wirtualna reprezentacja legacy month-length family.
    %
    % Reprezentuje dokładnie ten sam leksykograficzny zbiór bounded
    % compositions co historyczne list_all_ways, ale nie przechowuje
    % żadnych wierszy. Przechowuje wyłącznie exact DP counts.
    properties (SetAccess = private)
        totalDays
        monthCount
        minLength
        maxLength
    end

    properties (Access = private)
        totalDaysDouble
        monthCountDouble
        dp
    end

    methods
        function obj = VirtualLegacyList(totalDays, monthCount)
            pastafari.ValidationManager.requireExactIntegerInput(totalDays);
            pastafari.ValidationManager.requireExactIntegerInput(monthCount);

            total = pastafari.BigInt.coerce(totalDays);
            months = pastafari.BigInt.coerce(monthCount);

            if total < pastafari.BigInt(0) || ...
                    months < pastafari.BigInt(1)
                error('Pastafari:MonthLengths:VirtualListShape', ...
                    'totalDays musi być nieujemny, a monthCount dodatni.');
            end

            obj.totalDays = total;
            obj.monthCount = months;
            obj.minLength = pastafari.BigInt(4);
            obj.maxLength = pastafari.BigInt(123);
            obj.totalDaysDouble = total.toDoubleExact();
            obj.monthCountDouble = months.toDoubleExact();
            obj.dp = obj.buildSlidingWindowDP();
        end

        function total = count(obj)
            total = obj.dp{ ...
                obj.monthCountDouble + 1, ...
                obj.totalDaysDouble + 1};
        end

        function row = itemAt1(obj, rank1)
            pastafari.ValidationManager.requireExactIntegerInput(rank1);

            totalCount = obj.count();
            rank = pastafari.BigInt.coerce(rank1);
            if rank < pastafari.BigInt(1) || rank > totalCount
                error('Pastafari:MonthLengths:VirtualRank', ...
                    'Rank musi należeć do 1..count wirtualnej rodziny.');
            end

            K = obj.monthCountDouble;
            remainingTotal = obj.totalDaysDouble;
            row = zeros(1, K);
            r = rank;

            for position = 1:(K - 1)
                slotsLeft = K - position + 1;
                minValue = max(4, ...
                    remainingTotal - 123 * (slotsLeft - 1));
                maxValue = min(123, ...
                    remainingTotal - 4 * (slotsLeft - 1));
                selected = false;

                for value = minValue:maxValue
                    block = obj.countState( ...
                        slotsLeft - 1, remainingTotal - value);

                    if r > block
                        r = r - block;
                    else
                        row(position) = value;
                        remainingTotal = remainingTotal - value;
                        selected = true;
                        break
                    end
                end

                if ~selected
                    error('Pastafari:MonthLengths:VirtualUnrank', ...
                        'Nie udało się odnaleźć leksykograficznego bloku.');
                end
            end

            row(K) = remainingTotal;

            if row(K) < 4 || row(K) > 123 || ...
                    sum(row) ~= obj.totalDaysDouble
                error('Pastafari:MonthLengths:VirtualUnrankInvariant', ...
                    'Wirtualny unrank naruszył bounded-composition invariant.');
            end
        end
    end

    methods (Access = private)
        function table = buildSlidingWindowDP(obj)
            T = obj.totalDaysDouble;
            K = obj.monthCountDouble;
            table = cell(K + 1, T + 1);

            for rowIndex = 1:(K + 1)
                for colIndex = 1:(T + 1)
                    table{rowIndex, colIndex} = pastafari.BigInt(0);
                end
            end

            table{1, 1} = pastafari.BigInt(1);

            for slots = 1:K
                previousRow = slots;
                currentRow = slots + 1;
                window = pastafari.BigInt(0);

                for total = 0:T
                    addIndex = total - 4;
                    removeIndex = total - 124;

                    if addIndex >= 0
                        window = window + ...
                            table{previousRow, addIndex + 1};
                    end
                    if removeIndex >= 0
                        window = window - ...
                            table{previousRow, removeIndex + 1};
                    end

                    table{currentRow, total + 1} = window;
                end
            end
        end

        function total = countState(obj, slots, remainingTotal)
            if slots < 0 || remainingTotal < 0 || ...
                    slots > obj.monthCountDouble || ...
                    remainingTotal > obj.totalDaysDouble
                total = pastafari.BigInt(0);
                return
            end

            total = obj.dp{slots + 1, remainingTotal + 1};
        end
    end
end
