classdef ChronologicalDistancePatch
    % PATCH 03: zastępuje legacy distance dystansem chronologicznym i dodaje 1.
    % Historyczny oldDistance pozostaje fizycznie zachowany poza tą klasą.
    methods (Static)
        function value = apply(calculationDay, targetDay, legacyValue)
            pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
            pastafari.ValidationManager.requireExactIntegerInput(targetDay);
            pastafari.ValidationManager.requireExactIntegerInput(legacyValue);

            c = pastafari.BigInt.coerce(calculationDay);
            t = pastafari.BigInt.coerce(targetDay);

            % legacyValue jest celowo przyjmowany i zachowywany przez trasę,
            % lecz PATCH 03 zastępuje go poprawnym dystansem osi dni.
            pastafari.BigInt.coerce(legacyValue); %#ok<VUNUS>
            value = abs(t - c) + pastafari.BigInt(1);
        end
    end
end
