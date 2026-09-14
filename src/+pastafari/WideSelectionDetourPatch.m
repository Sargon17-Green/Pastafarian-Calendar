classdef WideSelectionDetourPatch
    % PATCH 14: dokładny detour dla N>M.
    %
    % Wybiera minimalne places z space=M^places>=N, składa little-endian
    % wide value z kolejnych odpowiedzi tego samego answer ring, a następnie
    % wykonuje rejection w przestrzeni space.
    methods (Static)
        function [rank, wide, acceptedWide, places, space, acceptanceLimit, rejectionSteps] = ...
                apply(stream, N)
            pastafari.ValidationManager.requireExactIntegerInput(N);

            N = pastafari.BigInt.coerce(N);
            M = pastafari.BigInt( ...
                '170141183460469231731687303715884105727');

            if N <= M
                error('Pastafari:Selection:WideChoice', ...
                    'PATCH 14 wide detour wymaga N > M.');
            end

            places = 1;
            space = M;
            while space < N
                places = places + 1;
                space = space * M;
            end

            wide = pastafari.BigInt(1);
            weight = pastafari.BigInt(1);
            for j = 0:(places - 1)
                digit = pastafari.AnswerRingStreamFactory.answerAt( ...
                    stream, pastafari.BigInt(j)) - pastafari.BigInt(1);
                wide = wide + digit * weight;
                weight = weight * M;
            end

            acceptanceLimit = space.floorDiv(N) * N;
            acceptedWide = wide;
            rejectionSteps = pastafari.BigInt(0);

            while true
                if acceptedWide <= acceptanceLimit
                    rank = ...
                        (acceptedWide - pastafari.BigInt(1)).regularMod(N) + ...
                        pastafari.BigInt(1);
                    return
                end

                acceptedWide = pastafari.BigInt(1) + ...
                    (acceptedWide - pastafari.BigInt(1) + ...
                     pastafari.BigInt(stream.directionStep)).regularMod(space);
                rejectionSteps = rejectionSteps + pastafari.BigInt(1);
            end
        end
    end
end
