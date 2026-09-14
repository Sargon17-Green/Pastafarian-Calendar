classdef OneBasedRankDetourPatch
    % PATCH 08: tworzy kanoniczną rangę 1-based, a następnie wraca do
    % rank0 wyłącznie na wejściu do niezmienionego legacy unrank0.
    methods (Static)
        function [rank1, rank0] = apply(value)
            pastafari.ValidationManager.requireExactIntegerInput(value);

            v = pastafari.BigInt.coerce(value);
            modulus = pastafari.BigInt(720);

            rank1 = (v - pastafari.BigInt(1)).regularMod(modulus) + ...
                pastafari.BigInt(1);
            rank0 = rank1 - pastafari.BigInt(1);
        end
    end
end
