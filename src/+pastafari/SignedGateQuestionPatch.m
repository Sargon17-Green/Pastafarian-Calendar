classdef SignedGateQuestionPatch
    % PATCH 15: semantyczne pytanie zachowuje znak kroku bramy.
    %
    % signedStep=+n -> Foundation+n
    % signedStep=-n -> Foundation-n
    methods (Static)
        function [gap, questionDay] = ask(signedStep)
            pastafari.ValidationManager.requireExactIntegerInput(signedStep);

            step = pastafari.BigInt.coerce(signedStep);
            if step == pastafari.BigInt(0)
                error('Pastafari:Gates:ZeroStep', ...
                    'Pytanie o odstęp bramy wymaga kroku różnego od zera.');
            end

            foundation = pastafari.BigInt('-15055671');
            questionDay = foundation + step;
            gap = pastafari.GateQuestionEngine.gapForQuestionDay(questionDay);
        end
    end
end
