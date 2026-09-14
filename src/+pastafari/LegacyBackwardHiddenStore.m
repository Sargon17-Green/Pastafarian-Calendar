classdef LegacyBackwardHiddenStore
    % Historyczna warstwa Discovery 05.
    % Wartości hidden są obliczane poprawnie, lecz fizycznie zapisywane jako:
    % hidden7, hidden6, ..., hidden1.
    % W tym etapie nie istnieje jeszcze translator indeksu 8-k.
    methods (Static)
        function storage = build(counts, stones)
            canonical = pastafari.LegacyBackwardHiddenStore.computeCanonical( ...
                counts, stones);
            storage = canonical(7:-1:1);
        end

        function value = readNaive(storage, hiddenIndex)
            if ~iscell(storage) || numel(storage) ~= 7
                error('Pastafari:Hidden:LegacyStorageShape', ...
                    'Historyczny magazyn hidden musi zawierać dokładnie siedem pól.');
            end
            if ~(isnumeric(hiddenIndex) && isscalar(hiddenIndex) && ...
                    isfinite(hiddenIndex) && fix(hiddenIndex) == hiddenIndex && ...
                    hiddenIndex >= 1 && hiddenIndex <= 7)
                error('Pastafari:Hidden:LegacyIndex', ...
                    'Historyczny indeks hidden musi należeć do zakresu 1..7.');
            end
            value = storage{hiddenIndex};
        end
    end

    methods (Static, Access = private)
        function hidden = computeCanonical(counts, stones)
            coeff = [ ...
                3 4 6 8; ...
                5 7 10 12; ...
                7 10 14 16; ...
                9 13 18 20; ...
                11 16 22 24; ...
                13 19 26 28; ...
                15 22 30 32];
            grindStone = [1 2 3 4 5 1 2];
            hidden = cell(1, 7);

            for k = 1:7
                a = coeff(k, 1);
                b = coeff(k, 2);
                c = coeff(k, 3);
                d = coeff(k, 4);

                x = counts.action + ...
                    pastafari.BigInt(a) * counts.target + ...
                    pastafari.BigInt(b) * counts.distance + ...
                    pastafari.BigInt(c) * counts.connection + ...
                    pastafari.BigInt(d) * pastafari.BigInt(counts.direction);

                for kind = 1:5
                    x = x + stones{k, kind};
                end

                x = pastafari.LegacyBackwardHiddenStore.saveHistorical(x);

                for grind = 1:7
                    oldX = x;
                    x = pastafari.LegacyBackwardHiddenStore.saveHistorical( ...
                        oldX.square() + pastafari.BigInt(3) * oldX + ...
                        stones{k, grindStone(grind)} + pastafari.BigInt(grind));
                end

                hidden{k} = x;
            end
        end

        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
