classdef FilteredLegacyCutletPartitionFamily
    % PATCH 21: dokładna filtrowana podrodzina historycznej rodziny.
    %
    % Porządek jest dokładnie podciągiem leksykograficznym rodziny legacy:
    % zachowujemy tylko dodatnie kompozycje, których właściwy prefix sum
    % jest równy requiredBoundary.
    %
    % Produkcja nie materializuje rodziny. Count i unrank są kombinatoryczne.
    methods (Static)
        function descriptor = describe( ...
                gapCount, cutletCount, requiredBoundary)
            [G, K, required] = ...
                pastafari.FilteredLegacyCutletPartitionFamily.validate( ...
                    gapCount, cutletCount, requiredBoundary);

            descriptor = struct( ...
                'familyName', 'FILTERED_LEGACY_PREFIX_BOUNDARY', ...
                'gapCount', pastafari.BigInt(G), ...
                'cutletCount', pastafari.BigInt(K), ...
                'requiredBoundary', pastafari.BigInt(required), ...
                'count', ...
                    pastafari.FilteredLegacyCutletPartitionFamily.count( ...
                        G, K, required));
        end

        function total = count(gapCount, cutletCount, requiredBoundary)
            [G, K, ~] = ...
                pastafari.FilteredLegacyCutletPartitionFamily.validate( ...
                    gapCount, cutletCount, requiredBoundary);

            if G < K || K < 2
                total = pastafari.BigInt(0);
                return
            end

            % Vandermonde: suma po możliwej pozycji wymaganej granicy.
            total = ...
                pastafari.FilteredLegacyCutletPartitionFamily.binomial( ...
                    G - 2, K - 2);
        end

        function partition = unrank1( ...
                gapCount, cutletCount, requiredBoundary, rank1)
            [G, K, required] = ...
                pastafari.FilteredLegacyCutletPartitionFamily.validate( ...
                    gapCount, cutletCount, requiredBoundary);
            pastafari.ValidationManager.requireExactIntegerInput(rank1);

            total = ...
                pastafari.FilteredLegacyCutletPartitionFamily.count( ...
                    G, K, required);
            r = pastafari.BigInt.coerce(rank1);

            if r < pastafari.BigInt(1) || r > total
                error('Pastafari:Cutlets:FilteredPartitionRank', ...
                    'Rank musi należeć do 1..count filtrowanej rodziny.');
            end

            partition = zeros(1, K);
            remaining = G;
            slots = K;
            cumulative = 0;
            hitBoundary = false;

            for position = 1:(K - 1)
                maxX = remaining - (slots - 1);
                selected = false;

                for x = 1:maxX
                    nextCumulative = cumulative + x;
                    nextHit = hitBoundary;

                    if ~hitBoundary
                        if nextCumulative == required
                            nextHit = true;
                        elseif nextCumulative > required
                            continue
                        end
                    end

                    block = ...
                        pastafari.FilteredLegacyCutletPartitionFamily. ...
                            countState( ...
                                remaining - x, slots - 1, ...
                                nextCumulative, nextHit, required);

                    if r > block
                        r = r - block;
                    else
                        partition(position) = x;
                        remaining = remaining - x;
                        slots = slots - 1;
                        cumulative = nextCumulative;
                        hitBoundary = nextHit;
                        selected = true;
                        break
                    end
                end

                if ~selected
                    error('Pastafari:Cutlets:FilteredPartitionUnrank', ...
                        'Nie udało się odtworzyć filtrowanej kompozycji.');
                end
            end

            partition(K) = remaining;

            if ~hitBoundary
                error('Pastafari:Cutlets:FilteredBoundaryMissing', ...
                    'Odtworzona kompozycja nie zawiera wymaganej granicy.');
            end
        end
    end

    methods (Static, Access = private)
        function total = countState( ...
                remaining, slots, cumulative, hitBoundary, required)
            if slots < 1 || remaining < slots
                total = pastafari.BigInt(0);
                return
            end

            if slots == 1
                if hitBoundary
                    total = pastafari.BigInt(1);
                else
                    total = pastafari.BigInt(0);
                end
                return
            end

            if hitBoundary
                total = ...
                    pastafari.FilteredLegacyCutletPartitionFamily.binomial( ...
                        remaining - 1, slots - 1);
                return
            end

            need = required - cumulative;
            if need <= 0 || need >= remaining
                total = pastafari.BigInt(0);
                return
            end

            % Wśród przyszłych proper prefixes jedna granica ma trafić
            % dokładnie w required. Suma bloków redukuje się przez Vandermonde.
            total = ...
                pastafari.FilteredLegacyCutletPartitionFamily.binomial( ...
                    remaining - 2, slots - 2);
        end

        function [G, K, required] = validate( ...
                gapCount, cutletCount, requiredBoundary)
            pastafari.ValidationManager.requireExactIntegerInput(gapCount);
            pastafari.ValidationManager.requireExactIntegerInput(cutletCount);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                requiredBoundary);

            gap = pastafari.BigInt.coerce(gapCount);
            cutlets = pastafari.BigInt.coerce(cutletCount);
            boundary = pastafari.BigInt.coerce(requiredBoundary);

            if gap < pastafari.BigInt(1) || ...
                    cutlets < pastafari.BigInt(1)
                error('Pastafari:Cutlets:FilteredPartitionShape', ...
                    'gapCount i cutletCount muszą być dodatnie.');
            end

            if boundary <= pastafari.BigInt(0) || boundary >= gap
                error('Pastafari:Cutlets:FilteredBoundary', ...
                    ['requiredBoundary musi należeć do przedziału ', ...
                     '1..gapCount-1.']);
            end

            G = gap.toDoubleExact();
            K = cutlets.toDoubleExact();
            required = boundary.toDoubleExact();
        end

        function value = binomial(n, k)
            if k < 0 || k > n
                value = pastafari.BigInt(0);
                return
            end

            k = min(k, n - k);
            value = pastafari.BigInt(1);

            for i = 1:k
                value = (value * pastafari.BigInt(n - k + i)).floorDiv( ...
                    pastafari.BigInt(i));
            end
        end
    end
end
