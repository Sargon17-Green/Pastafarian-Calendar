classdef PriorPatch
    % PATCH 06: mapuje logiczne sloty 0..-6 na hidden 1..7.
    % Historyczny LegacyPriorAdapter pozostaje niezmieniony i nadal zna
    % wyłącznie dodatnie indeksy visible drops.
    methods (Static)
        function value = resolveMissing(slot, hidden)
            if ~(isnumeric(slot) && isscalar(slot) && isfinite(slot) && ...
                    fix(slot) == slot && slot <= 0 && slot >= -6)
                error('Pastafari:Prior:PatchSlot', ...
                    'priorPatch obsługuje wyłącznie logiczne sloty 0..-6.');
            end
            if ~iscell(hidden) || numel(hidden) ~= 7
                error('Pastafari:Prior:PatchHiddenShape', ...
                    'priorPatch wymaga dokładnie siedmiu logicznych hidden.');
            end

            hiddenIndex = 1 - slot;
            value = hidden{hiddenIndex};
        end
    end
end
