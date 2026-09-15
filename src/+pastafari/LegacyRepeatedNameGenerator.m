classdef LegacyRepeatedNameGenerator
    % Historyczna wada Discovery 22.
    %
    % Rodzina ma masterCount^outputCount elementów. Każda pozycja wybiera
    % canonicalIndex niezależnie z 1..masterCount, więc powtórzenia są
    % legalne. Porządek jest zwykłym porządkiem leksykograficznym.
    methods (Static)
        function [ctx, rank, indices, familyCount, descriptor] = ...
                callWithRing(ctx, stream, masterCount, outputCount)
            pastafari.ValidationManager.requireContext(ctx);

            [N, K] = ...
                pastafari.LegacyRepeatedNameGenerator.validateCounts( ...
                    masterCount, outputCount);

            familyCount = ...
                pastafari.LegacyRepeatedNameGenerator.familyCount(N, K);

            [ctx, rank] = ...
                pastafari.GeneralSelectionCompatibilityRoute.call( ...
                    ctx, stream, familyCount);

            indices = ...
                pastafari.LegacyRepeatedNameGenerator.unrank1( ...
                    N, K, rank);

            descriptor = struct( ...
                'familyName', ...
                    'REPEATED_LEXICOGRAPHIC_CANONICAL_INDICES', ...
                'masterCount', pastafari.BigInt(N), ...
                'outputCount', pastafari.BigInt(K), ...
                'count', familyCount, ...
                'repeatsAllowed', true);
        end

        function total = familyCount(masterCount, outputCount)
            [N, K] = ...
                pastafari.LegacyRepeatedNameGenerator.validateCounts( ...
                    masterCount, outputCount);

            total = pastafari.BigInt(1);
            base = pastafari.BigInt(N);
            for k = 1:K
                total = total * base;
            end
        end

        function indices = unrank1(masterCount, outputCount, rank1)
            [N, K] = ...
                pastafari.LegacyRepeatedNameGenerator.validateCounts( ...
                    masterCount, outputCount);
            pastafari.ValidationManager.requireExactIntegerInput(rank1);

            total = ...
                pastafari.LegacyRepeatedNameGenerator.familyCount(N, K);
            rank = pastafari.BigInt.coerce(rank1);

            if rank < pastafari.BigInt(1) || rank > total
                error('Pastafari:Names:LegacyRepeatedRank', ...
                    'Rank musi należeć do 1..masterCount^outputCount.');
            end

            remaining = rank - pastafari.BigInt(1);
            base = pastafari.BigInt(N);
            indices = zeros(1, K);

            % Ostatnia pozycja jest najmniej znaczącą cyfrą base-N.
            % To daje zwykły porządek leksykograficzny całych sekwencji.
            for position = K:-1:1
                digit = remaining.regularMod(base);
                indices(position) = digit.toDoubleExact() + 1;
                remaining = remaining.floorDiv(base);
            end

            if remaining ~= pastafari.BigInt(0)
                error('Pastafari:Names:LegacyRepeatedUnrank', ...
                    'Po unrank pozostała niezerowa część rank.');
            end
        end
    end

    methods (Static, Access = private)
        function [N, K] = validateCounts(masterCount, outputCount)
            pastafari.ValidationManager.requireExactIntegerInput(masterCount);
            pastafari.ValidationManager.requireExactIntegerInput(outputCount);

            master = pastafari.BigInt.coerce(masterCount);
            outputs = pastafari.BigInt.coerce(outputCount);

            if master < pastafari.BigInt(1) || ...
                    outputs < pastafari.BigInt(1)
                error('Pastafari:Names:LegacyRepeatedShape', ...
                    'masterCount i outputCount muszą być dodatnie.');
            end

            N = master.toDoubleExact();
            K = outputs.toDoubleExact();
        end
    end
end
