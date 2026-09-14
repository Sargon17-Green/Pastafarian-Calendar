classdef LegacyFixedBowlPourAdapter
    % Historyczna wada Discovery 09.
    % Trzy pours są związane z fizycznymi bowl IDs 1,2,3 zamiast
    % z positions 1,2,3 bieżącego order.
    methods (Static)
        function pours = compute(oldBowls, drop, stoneRow, dropNumber)
            if ~iscell(oldBowls) || numel(oldBowls) ~= 6
                error('Pastafari:Bowls:LegacyShape', ...
                    'Historyczne pours wymagają sześciu mis.');
            end
            if ~iscell(stoneRow) || numel(stoneRow) ~= 5
                error('Pastafari:Bowls:LegacyStoneRow', ...
                    'Historyczne pours wymagają pięciu kamieni.');
            end
            pastafari.ValidationManager.requireExactIntegerInput(drop);

            d = pastafari.BigInt.coerce(drop);
            i = pastafari.BigInt(dropNumber);
            pours = { ...
                pastafari.BigInt(0), pastafari.BigInt(0), ...
                pastafari.BigInt(0), pastafari.BigInt(0), ...
                pastafari.BigInt(0), pastafari.BigInt(0)};

            pours{1} = pastafari.LegacyFixedBowlPourAdapter.saveHistorical( ...
                d.square() + stoneRow{1} * oldBowls{1} + ...
                pastafari.BigInt(3) * i);
            pours{2} = pastafari.LegacyFixedBowlPourAdapter.saveHistorical( ...
                d.square() + stoneRow{2} * oldBowls{2} + ...
                pastafari.BigInt(5) * i);
            pours{3} = pastafari.LegacyFixedBowlPourAdapter.saveHistorical( ...
                d.square() + stoneRow{3} * oldBowls{3} + ...
                pastafari.BigInt(7) * i);
        end
    end

    methods (Static, Access = private)
        function value = saveHistorical(x)
            raw = pastafari.LegacyRemainderAdapter.oldRemainder(x);
            value = pastafari.SavePatch.apply(raw);
        end
    end
end
