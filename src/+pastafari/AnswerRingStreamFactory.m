classdef AnswerRingStreamFactory
    % Buduje normatywny strumień odpowiedzi pytanej misy.
    % Ta warstwa nie wykonuje wyboru ani rejection.
    methods (Static)
        function stream = fromSauce(bowls, bowlId, nextBowlId, seal)
            if ~iscell(bowls) || numel(bowls) ~= 6
                error('Pastafari:AnswerRing:Bowls', ...
                    'Strumień odpowiedzi wymaga sześciu mis.');
            end
            pastafari.AnswerRingStreamFactory.requireBowlId( ...
                bowlId, 'pytanej');
            pastafari.AnswerRingStreamFactory.requireBowlId( ...
                nextBowlId, 'następnej');
            pastafari.ValidationManager.requireExactIntegerInput(seal);

            sealValue = pastafari.BigInt.coerce(seal);
            first = pastafari.AnswerRingStreamFactory.saveHistorical( ...
                (bowls{bowlId} + sealValue + pastafari.BigInt(181)).square() + ...
                pastafari.BigInt(179) * bowls{nextBowlId} + sealValue);

            directionNumber = ...
                pastafari.AnswerRingStreamFactory.saveHistorical( ...
                    (first + sealValue + pastafari.BigInt(1) + ...
                     pastafari.BigInt(193)).square() + ...
                    pastafari.BigInt(193) * first + ...
                    pastafari.BigInt(197) * bowls{6});

            if directionNumber.regularMod(pastafari.BigInt(2)) == ...
                    pastafari.BigInt(1)
                directionStep = 1;
            else
                directionStep = -1;
            end

            stream = struct( ...
                'first', first, ...
                'directionStep', directionStep);
        end

        function answer = answerAt(stream, offset)
            if ~isstruct(stream) || ~isfield(stream, 'first') || ...
                    ~isfield(stream, 'directionStep')
                error('Pastafari:AnswerRing:Stream', ...
                    'Strumień odpowiedzi musi zawierać first i directionStep.');
            end
            pastafari.ValidationManager.requireExactIntegerInput(stream.first);
            pastafari.ValidationManager.requireExactIntegerInput(offset);

            if ~(isnumeric(stream.directionStep) && ...
                    isscalar(stream.directionStep) && ...
                    any(stream.directionStep == [-1, 1]))
                error('Pastafari:AnswerRing:Direction', ...
                    'Krok pierścienia odpowiedzi musi wynosić -1 albo +1.');
            end

            M = pastafari.BigInt( ...
                '170141183460469231731687303715884105727');
            first = pastafari.BigInt.coerce(stream.first);
            k = pastafari.BigInt.coerce(offset);

            answer = pastafari.BigInt(1) + ...
                (first - pastafari.BigInt(1) + ...
                 pastafari.BigInt(stream.directionStep) * k).regularMod(M);
        end
    end

    methods (Static, Access = private)
        function requireBowlId(value, label)
            if ~(isnumeric(value) && isscalar(value) && isfinite(value) && ...
                    fix(value) == value && value >= 1 && value <= 6)
                error('Pastafari:AnswerRing:BowlId', ...
                    ['ID ', label, ' misy musi należeć do 1..6.']);
            end
        end

        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
