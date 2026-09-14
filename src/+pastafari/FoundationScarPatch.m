classdef FoundationScarPatch
    % PATCH 02: korekta licznika dnia nakładana na historyczny oldDayTag.
    % Drugi guard dla Foundation jest celowo zachowaną blizną historyczną.
    methods (Static)
        function value = apply(day, legacyValue)
            pastafari.ValidationManager.requireExactIntegerInput(day);
            pastafari.ValidationManager.requireExactIntegerInput(legacyValue);

            d = pastafari.BigInt.coerce(day);
            n = pastafari.BigInt.coerce(legacyValue);
            foundation = pastafari.BigInt('-15055671');

            if d >= foundation
                n = n + pastafari.BigInt(1);
            end

            % Celowo redundantny guard — musi pozostać jako historyczna blizna.
            if d == foundation && n ~= pastafari.BigInt(1)
                n = pastafari.BigInt(1);
            end

            value = n;
        end
    end
end
