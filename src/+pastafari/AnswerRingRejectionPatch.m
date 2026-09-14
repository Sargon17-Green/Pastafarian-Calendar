classdef AnswerRingRejectionPatch
    % PATCH 13: odrzucenie odbywa się przez przesuwanie offsetu
    % na tym samym answer ring. LegacyBiasedPick jest wołany dopiero
    % po znalezieniu x <= acceptanceLimit.
    methods (Static)
        function [rank, acceptedX, offset, acceptanceLimit] = apply(stream, N)
            pastafari.ValidationManager.requireExactIntegerInput(N);

            N = pastafari.BigInt.coerce(N);
            M = pastafari.BigInt( ...
                '170141183460469231731687303715884105727');

            if N < pastafari.BigInt(1) || N > M
                error('Pastafari:Selection:RejectionSize', ...
                    'PATCH 13 wymaga 1 <= N <= M.');
            end

            acceptanceLimit = M.floorDiv(N) * N;
            offset = pastafari.BigInt(0);

            while true
                x = pastafari.AnswerRingStreamFactory.answerAt( ...
                    stream, offset);

                if x <= acceptanceLimit
                    acceptedX = x;
                    rank = pastafari.LegacyBiasedPick.pick(acceptedX, N);
                    return
                end

                offset = offset + pastafari.BigInt(1);
            end
        end
    end
end
