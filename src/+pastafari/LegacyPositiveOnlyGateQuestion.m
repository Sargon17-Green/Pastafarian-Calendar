classdef LegacyPositiveOnlyGateQuestion
    % Historyczna wada Discovery 15.
    %
    % Dla signedStep=-n również pyta Foundation+n. Znak kroku bramy
    % jest ignorowany, więc ujemne bramy dostają lustrzane pytanie dodatnie.
    methods (Static)
        function [gap, questionDay] = ask(signedStep)
            pastafari.ValidationManager.requireExactIntegerInput(signedStep);

            step = pastafari.BigInt.coerce(signedStep);
            if step == pastafari.BigInt(0)
                error('Pastafari:Gates:ZeroStep', ...
                    'Pytanie o odstęp bramy wymaga kroku różnego od zera.');
            end

            foundation = pastafari.BigInt('-15055671');
            questionDay = foundation + abs(step);
            gap = pastafari.GateQuestionEngine.gapForQuestionDay(questionDay);
        end
    end
end
