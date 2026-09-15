function out = partialPermutationNameRowUnrank( ...
        masterCount, outputCount, rank1)
% 1-based lexicographic unrank partial permutation bez powtórzeń.

pastafari.ValidationManager.requireExactIntegerInput(masterCount);
pastafari.ValidationManager.requireExactIntegerInput(outputCount);
pastafari.ValidationManager.requireExactIntegerInput(rank1);

master = pastafari.BigInt.coerce(masterCount);
outputs = pastafari.BigInt.coerce(outputCount);
rank = pastafari.BigInt.coerce(rank1);

if master < pastafari.BigInt(1) || outputs < pastafari.BigInt(1)
    error('Pastafari:Names:PartialPermutationShape', ...
        'masterCount i outputCount muszą być dodatnie.');
end

if outputs > master
    error('Pastafari:Names:PartialPermutationTooLong', ...
        'outputCount nie może przekraczać masterCount.');
end

total = pastafari.partialPermutationNameRowCount(master, outputs);
if rank < pastafari.BigInt(1) || rank > total
    error('Pastafari:Names:PartialPermutationRank', ...
        'Rank musi należeć do 1..fallingFactorial(masterCount,outputCount).');
end

N = master.toDoubleExact();
K = outputs.toDoubleExact();
remainingNames = 1:N;
out = zeros(1, K);
r = rank - pastafari.BigInt(1);

for position = 1:K
    suffixLength = K - position;
    block = pastafari.partialPermutationNameRowCount( ...
        pastafari.BigInt(numel(remainingNames) - 1), ...
        pastafari.BigInt(suffixLength));

    index0 = r.floorDiv(block).toDoubleExact();
    r = r.regularMod(block);

    if index0 < 0 || index0 >= numel(remainingNames)
        error('Pastafari:Names:PartialPermutationUnrank', ...
            'Lexicographic block index wyszedł poza remainingNames.');
    end

    out(position) = remainingNames(index0 + 1);
    remainingNames(index0 + 1) = [];
end

if r ~= pastafari.BigInt(0)
    error('Pastafari:Names:PartialPermutationRemainder', ...
        'Po partial-permutation unrank pozostała niezerowa część rank.');
end
end
