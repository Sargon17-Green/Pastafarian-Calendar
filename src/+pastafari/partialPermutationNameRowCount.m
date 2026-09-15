function total = partialPermutationNameRowCount(masterCount, outputCount)
% Liczba uporządkowanych K-elementowych wierszy bez powtórzeń z N nazw.
% Jest to falling factorial N*(N-1)*...*(N-K+1).

pastafari.ValidationManager.requireExactIntegerInput(masterCount);
pastafari.ValidationManager.requireExactIntegerInput(outputCount);

master = pastafari.BigInt.coerce(masterCount);
outputs = pastafari.BigInt.coerce(outputCount);

if master < pastafari.BigInt(1) || outputs < pastafari.BigInt(0)
    error('Pastafari:Names:PartialPermutationShape', ...
        'masterCount musi być dodatni, a outputCount nieujemny.');
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
