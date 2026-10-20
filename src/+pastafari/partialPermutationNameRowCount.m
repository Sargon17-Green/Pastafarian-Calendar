function total = partialPermutationNameRowCount(masterCount, outputCount)
% Liczba uporządkowanych K-elementowych wierszy bez powtórzeń z N nazw.
% Jest to falling factorial N*(N-1)*...*(N-K+1).

pastafari.ValidationManager.requireExactIntegerInput(masterCount);
pastafari.ValidationManager.requireExactIntegerInput(outputCount);

master = pastafari.BigInt.coerce(masterCount);
outputs = pastafari.BigInt.coerce(outputCount);

% Dla pustego alfabetu i pustego wiersza istnieje dokładnie jedna
% permutacja: pusty wiersz. 0P0 = 1 (iloczyn pusty).
% Jest to wymagane także dla ostatniego bloku przy unrankingu NPN.
if master < pastafari.BigInt(0) || outputs < pastafari.BigInt(0)
    error('Pastafari:Names:PartialPermutationShape', ...
        'masterCount i outputCount muszą być nieujemne.');
end

if outputs > master
    total = pastafari.BigInt(0);
    return
end

N = master.toDoubleExact();
K = outputs.toDoubleExact();

total = pastafari.BigInt(1);
for j = 0:(K - 1)
    total = total * pastafari.BigInt(N - j);
end
end
