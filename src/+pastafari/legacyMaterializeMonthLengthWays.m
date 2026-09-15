function [ways, proof] = legacyMaterializeMonthLengthWays( ...
        totalDays, monthCount, safeCap)
% Historyczna operacja konkretnej listy wszystkich bounded compositions.
%
% Zachowuje leksykograficzny porządek wartości 4..123. Twarda safeCap
% zapobiega prawdziwemu OOM w odtwarzanym historycznym defekcie.

pastafari.ValidationManager.requireExactIntegerInput(totalDays);
pastafari.ValidationManager.requireExactIntegerInput(monthCount);
pastafari.ValidationManager.requireExactIntegerInput(safeCap);

total = pastafari.BigInt.coerce(totalDays);
months = pastafari.BigInt.coerce(monthCount);
cap = pastafari.BigInt.coerce(safeCap);

if total < pastafari.BigInt(1) || months < pastafari.BigInt(1) || ...
        cap < pastafari.BigInt(1)
    error('Pastafari:MonthLengths:LegacyMaterializationShape', ...
        'totalDays, monthCount i safeCap muszą być dodatnie.');
end

proof = pastafari.proveLegacyMonthLengthFamilyLowerBound(total, months);

if proof.lowerBound > cap
    error('Pastafari:MonthLengths:LegacyMaterializationTooLarge', ...
        ['Historyczne list_all_ways próbowałoby materializować co najmniej ', ...
         char(proof.lowerBound), ' wierszy przy safeCap=', char(cap), '.']);
end

T = total.toDoubleExact();
K = months.toDoubleExact();
capN = cap.toDoubleExact();
ways = {};
prefix = zeros(1, K);

visit(1, T);

    function visit(position, remainingTotal)
        slotsLeft = K - position + 1;

        if slotsLeft == 1
            if remainingTotal >= 4 && remainingTotal <= 123
                if numel(ways) >= capN
                    error('Pastafari:MonthLengths:LegacyMaterializationTooLarge', ...
                        ['Historyczne list_all_ways przekroczyło safeCap=', ...
                         num2str(capN), '.']);
                end
                prefix(position) = remainingTotal;
                ways{end + 1} = prefix; %#ok<AGROW>
            end
            return
        end

        minValue = max(4, remainingTotal - 123 * (slotsLeft - 1));
        maxValue = min(123, remainingTotal - 4 * (slotsLeft - 1));

        for value = minValue:maxValue
            prefix(position) = value;
            visit(position + 1, remainingTotal - value);
        end
    end
end
