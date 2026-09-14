classdef LegacyRemainderAdapter
    % Historyczna, celowo błędna warstwa Discovery 01.
    % Nie wolno naprawiać tej funkcji w miejscu; późniejsza łata ma ją zachować.
    methods (Static)
        function value = oldRemainder(inputValue)
            pastafari.ValidationManager.requireExactIntegerInput(inputValue);
            x = pastafari.BigInt.coerce(inputValue);
            M = pastafari.BigInt(2).powNonnegative(127) - pastafari.BigInt(1);
            value = x.regularMod(M);
        end
    end
end
