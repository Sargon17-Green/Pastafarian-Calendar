classdef LegacyStoneMutationAdapter
    % Historyczna, celowo błędna warstwa Discovery 04.
    % Pięć kamieni w każdym nowym wierszu jest mutowanych sekwencyjnie
    % w miejscu, więc późniejsze kamienie widzą już wcześniejsze aktualizacje.
    methods (Static)
        function stones = buildTable()
            stones = cell(46, 5);
            stones(1, :) = { ...
                pastafari.BigInt(17), ...
                pastafari.BigInt(29), ...
                pastafari.BigInt(43), ...
                pastafari.BigInt(71), ...
                pastafari.BigInt(101)};

            for rowNumber = 2:46
                stones(rowNumber, :) = ...
                    pastafari.LegacyStoneMutationAdapter.mutateSequential( ...
                        stones(rowNumber - 1, :), rowNumber);
            end
        end

        function row = mutateSequential(previousRow, rowNumber)
            if ~iscell(previousRow) || numel(previousRow) ~= 5
                error('Pastafari:Stones:LegacyRowShape', ...
                    'Historyczny mutator oczekuje dokładnie pięciu kamieni.');
            end

            row = previousRow;
            i = pastafari.BigInt(rowNumber);

            row{1} = pastafari.LegacyStoneMutationAdapter.saveLegacy( ...
                row{1}.square() + pastafari.BigInt(3) * row{2} + i);

            row{2} = pastafari.LegacyStoneMutationAdapter.saveLegacy( ...
                row{2}.square() + pastafari.BigInt(5) * row{3} + row{1});

            row{3} = pastafari.LegacyStoneMutationAdapter.saveLegacy( ...
                row{3}.square() + pastafari.BigInt(7) * row{4} + row{2});

            row{4} = pastafari.LegacyStoneMutationAdapter.saveLegacy( ...
                row{4}.square() + pastafari.BigInt(11) * row{5} + row{3});

            row{5} = pastafari.LegacyStoneMutationAdapter.saveLegacy( ...
                row{5}.square() + pastafari.BigInt(13) * row{1} + row{4});
        end
    end

    methods (Static, Access = private)
        function value = saveLegacy(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
