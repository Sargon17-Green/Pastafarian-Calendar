classdef SentinelGrindRowPatch
    % PATCH 07: dodaje sentinel row pod logicznym indeksem 0.
    % Historyczne indeksowanie grindNumber+1 pozostaje bez zmian.
    methods (Static)
        function rows = rowsWithSentinel()
            canonical = pastafari.LegacyGrindTableAdapter.rowsWithoutSentinel();
            rows = [zeros(1, 5); canonical];
        end
    end
end
