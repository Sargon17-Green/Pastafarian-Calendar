classdef LegacyAllPositiveCutletPartitionFamily
    % Historyczna rodzina Discovery 21.
    %
    % Wszystkie dodatnie kompozycje gapCount na cutletCount części,
    % w porządku leksykograficznym. Rodzina celowo NIE zna żadnego
    % internalGateOffset i nie filtruje według calculation-day gate.
    methods (Static)
        function descriptor = describe(gapCount, cutletCount)
            [G, K] = ...
                pastafari.LegacyAllPositiveCutletPartitionFamily.validate( ...
                    gapCount, cutletCount);

            descriptor = struct( ...
                'familyName', 'ALL_POSITIVE_LEXICOGRAPHIC', ...
                'gapCount', pastafari.BigInt(G), ...
                'cutletCount', pastafari.BigInt(K), ...
                'count', ...
                    pastafari.LegacyAllPositiveCutletPartitionFamily.count( ...
                        G, K));
        end

        function total = count(gapCount, cutletCount)
            [G, K] = ...
                pastafari.LegacyAllPositiveCutletPartitionFamily.validate( ...
                    gapCount, cutletCount);

            if G < K
                total = pastafari.BigInt(0);
                return
            end

            total = ...
                pastafari.LegacyAllPositiveCutletPartitionFamily.binomial( ...
                    G - 1, K - 1);
        end

        function partition = unrank1(gapCount, cutletCount, rank1)
            [G, K] = ...
                pastafari.LegacyAllPositiveCutletPartitionFamily.validate( ...
                    gapCount, cutletCount);
            pastafari.ValidationManager.requireExactIntegerInput(rank1);

            total = ...
                pastafari.LegacyAllPositiveCutletPartitionFamily.count(G, K);
            r = pastafari.BigInt.coerce(rank1);

            if r < pastafari.BigInt(1) || r > total
                error('Pastafari:Cutlets:LegacyPartitionRank', ...
                    'Rank musi należeć do 1..count rodziny legacy.');
            end

            partition = zeros(1, K);
            remaining = G;
            slots = K;

            for position = 1:(K - 1)
                maxX = remaining - (slots - 1);
                selected = false;

                for x = 1:maxX
                    block = ...
                        pastafari.LegacyAllPositiveCutletPartitionFamily.count( ...
                            remaining - x, slots - 1);

                    if r > block
                        r = r - block;
                    else
                        partition(position) = x;
                        remaining = remaining - x;
                        slots = slots - 1;
                        selected = true;
                        break
                    end
                end

                if ~selected
                    error('Pastafari:Cutlets:LegacyPartitionUnrank', ...
                        'Nie udało się odtworzyć kompozycji legacy.');
                end
            end

            partition(K) = remaining;
        end
    end

    methods (Static, Access = private)
        function [G, K] = validate(gapCount, cutletCount)
            pastafari.ValidationManager.requireExactIntegerInput(gapCount);
            pastafari.ValidationManager.requireExactIntegerInput(cutletCount);

            gap = pastafari.BigInt.coerce(gapCount);
            cutlets = pastafari.BigInt.coerce(cutletCount);

            if gap < pastafari.BigInt(1) || ...
                    cutlets < pastafari.BigInt(1)
                error('Pastafari:Cutlets:LegacyPartitionShape', ...
                    'gapCount i cutletCount muszą być dodatnie.');
            end

            G = gap.toDoubleExact();
            K = cutlets.toDoubleExact();
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
