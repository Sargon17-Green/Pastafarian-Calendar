classdef MetricsShell
    % Bazowa powłoka obserwowalności. Jej dane nie mogą wpływać na semantykę.
    methods (Static)
        function metrics = bump(metrics, key)
            safeKey = matlab.lang.makeValidName(key);
            if isfield(metrics, safeKey)
                metrics.(safeKey) = metrics.(safeKey) + 1;
            else
                metrics.(safeKey) = 1;
            end
        end
    end
end
