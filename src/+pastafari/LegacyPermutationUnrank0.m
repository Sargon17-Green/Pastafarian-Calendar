classdef LegacyPermutationUnrank0
    % Historyczny unrank permutacji z rangą zero-based.
    % Sama funkcja oczekuje rank0 w zakresie 0..n!-1 i musi pozostać
    % niezmieniona także po przyszłym detour rankingu 1-based.
    methods (Static)
        function order = unrank0(rank0, itemsAscending)
            pastafari.ValidationManager.requireExactIntegerInput(rank0);

            if ~isnumeric(itemsAscending) || ~isvector(itemsAscending) || ...
                    isempty(itemsAscending)
                error('Pastafari:Permutation:Items', ...
                    'Lista elementów permutacji musi być niepustym wektorem.');
            end
            if numel(unique(itemsAscending)) ~= numel(itemsAscending)
                error('Pastafari:Permutation:DuplicateItems', ...
                    'Elementy permutacji muszą być różne.');
            end

            r = pastafari.BigInt.coerce(rank0);
            maxRank = pastafari.BigInt(factorial(numel(itemsAscending)) - 1);
            if r < pastafari.BigInt(0) || r > maxRank
                error('Pastafari:Permutation:LegacyRank0', ...
                    'Historyczna ranga zero-based jest poza zakresem.');
            end

            rNumber = r.toDoubleExact();
            remaining = itemsAscending;
            order = zeros(1, numel(itemsAscending));

            for position = 1:numel(itemsAscending)
                slotsLeft = numel(remaining);
                block = factorial(slotsLeft - 1);
                q = floor(rNumber / block);
                rNumber = mod(rNumber, block);
                order(position) = remaining(q + 1);
                remaining(q + 1) = [];
            end
        end
    end
end
