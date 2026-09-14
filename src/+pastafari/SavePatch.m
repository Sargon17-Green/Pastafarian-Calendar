classdef SavePatch
    % PATCH 01: łata nakładana na historyczny oldRemainder.
    % Celowo nie zmienia implementacji oldRemainder.
    methods (Static)
        function value = apply(legacyValue)
            pastafari.ValidationManager.requireExactIntegerInput(legacyValue);
            raw = pastafari.BigInt.coerce(legacyValue);
            if raw.iszero()
                value = pastafari.BigInt(2).powNonnegative(127) - pastafari.BigInt(1);
            else
                value = raw;
            end
        end
    end
end
