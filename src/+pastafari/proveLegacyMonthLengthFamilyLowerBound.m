function proof = proveLegacyMonthLengthFamilyLowerBound( ...
        totalDays, monthCount)
% Bezpieczny dowód dolnej granicy bez materializacji rodziny.
%
% Dla pierwszych K-1 miesięcy wybieramy wspólny przedział [a,b].
% a,b są tak dobrane, aby niezależnie od wyborów ostatni miesiąc zawsze
% pozostał w 4..123. Każdy z width^(K-1) wyborów daje legalny wiersz.

pastafari.ValidationManager.requireExactIntegerInput(totalDays);
pastafari.ValidationManager.requireExactIntegerInput(monthCount);

total = pastafari.BigInt.coerce(totalDays);
months = pastafari.BigInt.coerce(monthCount);

if total < pastafari.BigInt(1) || months < pastafari.BigInt(1)
    error('Pastafari:MonthLengths:LowerBoundShape', ...
        'totalDays i monthCount muszą być dodatnie.');
end

T = total.toDoubleExact();
K = months.toDoubleExact();

if K == 1
    if T >= 4 && T <= 123
        width = 1;
        firstMin = T;
        firstMax = T;
        lowerBound = pastafari.BigInt(1);
    else
        width = 0;
        firstMin = [];
        firstMax = [];
        lowerBound = pastafari.BigInt(0);
    end
else
    firstMin = max(4, ceil((T - 123) / (K - 1)));
    firstMax = min(123, floor((T - 4) / (K - 1)));
    width = max(0, firstMax - firstMin + 1);

    if width == 0
        lowerBound = pastafari.BigInt(0);
    else
        lowerBound = pastafari.BigInt(1);
        for j = 1:(K - 1)
            lowerBound = lowerBound * pastafari.BigInt(width);
        end
    end
end

proof = struct( ...
    'method', 'CARTESIAN_FIRST_K_MINUS_1', ...
    'totalDays', total, ...
    'monthCount', months, ...
    'firstValueMin', firstMin, ...
    'firstValueMax', firstMax, ...
    'width', pastafari.BigInt(width), ...
    'lowerBound', lowerBound);
end
