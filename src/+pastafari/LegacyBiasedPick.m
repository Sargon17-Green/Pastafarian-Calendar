classdef LegacyBiasedPick
    % Historyczna wada Discovery 13.
    % Bez żadnego rejection mapuje bieżącą odpowiedź przez modulo N.
    methods (Static)
        function rank = pick(x, N)
            pastafari.ValidationManager.requireExactIntegerInput(x);
            pastafari.ValidationManager.requireExactIntegerInput(N);

            x = pastafari.BigInt.coerce(x);
            N = pastafari.BigInt.coerce(N);
            if N < pastafari.BigInt(1)
                error('Pastafari:Selection:LegacySize', ...
                    'Historyczny wybór modulo wymaga dodatniego N.');
            end

            rank = (x - pastafari.BigInt(1)).regularMod(N) + ...
                pastafari.BigInt(1);
        end
    end
end
