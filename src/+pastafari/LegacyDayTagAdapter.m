classdef LegacyDayTagAdapter
    % Historyczna, celowo błędna warstwa Discovery 02.
    % oldDayTag(day) = 2*abs(day-FOUNDATION).
    % Nie wolno naprawiać tej funkcji w miejscu; etap 5 ma nałożyć osobną łatę.
    methods (Static)
        function value = oldDayTag(day)
            pastafari.ValidationManager.requireExactIntegerInput(day);
            d = pastafari.BigInt.coerce(day);
            foundation = pastafari.BigInt('-15055671');
            value = pastafari.BigInt(2) * abs(d - foundation);
        end
    end
end
