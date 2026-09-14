classdef LegacyDistanceAdapter
    % Historyczna, celowo błędna warstwa Discovery 03.
    % oldDistance(c,t) = abs(dayTagWithFoundationScar(c) - dayTagWithFoundationScar(t)).
    % Nie ma tu jeszcze dystansu chronologicznego ani końcowego +1.
    methods (Static)
        function value = oldDistance(calculationDay, targetDay)
            pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
            pastafari.ValidationManager.requireExactIntegerInput(targetDay);

            c = pastafari.BigInt.coerce(calculationDay);
            t = pastafari.BigInt.coerce(targetDay);

            cLegacy = pastafari.LegacyDayTagAdapter.oldDayTag(c);
            tLegacy = pastafari.LegacyDayTagAdapter.oldDayTag(t);
            cTag = pastafari.FoundationScarPatch.apply(c, cLegacy);
            tTag = pastafari.FoundationScarPatch.apply(t, tLegacy);

            value = abs(cTag - tTag);
        end
    end
end
