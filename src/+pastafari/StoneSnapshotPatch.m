classdef StoneSnapshotPatch
    % PATCH 04: zachowuje wykonanie historycznego mutatora, lecz publikuje
    % wszystkie pięć kamieni obliczone wyłącznie ze snapshotu poprzedniego wiersza.
    methods (Static)
        function [stones, legacyRows] = buildTable()
            stones = cell(46, 5);
            legacyRows = cell(46, 5);

            seed = { ...
                pastafari.BigInt(17), ...
                pastafari.BigInt(29), ...
                pastafari.BigInt(43), ...
                pastafari.BigInt(71), ...
                pastafari.BigInt(101)};

            stones(1, :) = seed;
            legacyRows(1, :) = seed;

            for rowNumber = 2:46
                old = stones(rowNumber - 1, :);

                % Historyczna blizna musi nadal zostać fizycznie wykonana.
                legacyRows(rowNumber, :) = ...
                    pastafari.LegacyStoneMutationAdapter.mutateSequential( ...
                        old, rowNumber);

                % PATCH 04 nadpisuje wszystkie pięć wyników, używając wyłącznie
                % niezmiennego snapshotu `old`.
                stones(rowNumber, :) = ...
                    pastafari.StoneSnapshotPatch.fromSnapshot(old, rowNumber);
            end
        end

        function row = fromSnapshot(old, rowNumber)
            if ~iscell(old) || numel(old) ~= 5
                error('Pastafari:Stones:SnapshotRowShape', ...
                    'PATCH 04 oczekuje snapshotu dokładnie pięciu kamieni.');
            end

            i = pastafari.BigInt(rowNumber);
            row = cell(1, 5);

            row{1} = pastafari.StoneSnapshotPatch.saveHistorical( ...
                old{1}.square() + pastafari.BigInt(3) * old{2} + i);

            row{2} = pastafari.StoneSnapshotPatch.saveHistorical( ...
                old{2}.square() + pastafari.BigInt(5) * old{3} + old{1});

            row{3} = pastafari.StoneSnapshotPatch.saveHistorical( ...
                old{3}.square() + pastafari.BigInt(7) * old{4} + old{2});

            row{4} = pastafari.StoneSnapshotPatch.saveHistorical( ...
                old{4}.square() + pastafari.BigInt(11) * old{5} + old{3});

            row{5} = pastafari.StoneSnapshotPatch.saveHistorical( ...
                old{5}.square() + pastafari.BigInt(13) * old{1} + old{4});
        end
    end

    methods (Static, Access = private)
        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
