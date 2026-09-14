classdef LegacyPriorAdapter
    % Historyczny dostęp poprzedników dla Discovery 06.
    % Rozumie wyłącznie dodatnie indeksy widocznych kropli.
    % Sloty 0..-6 nie są jeszcze tłumaczone na hidden 1..7.
    methods (Static)
        function [value, found, slot] = legacyPrior(visible, currentDrop, distanceBack)
            if ~(isnumeric(currentDrop) && isscalar(currentDrop) && ...
                    isfinite(currentDrop) && fix(currentDrop) == currentDrop && ...
                    currentDrop >= 1)
                error('Pastafari:Prior:CurrentDrop', ...
                    'Numer bieżącej kropli musi być dodatnią liczbą całkowitą.');
            end
            if ~(isnumeric(distanceBack) && isscalar(distanceBack) && ...
                    isfinite(distanceBack) && fix(distanceBack) == distanceBack && ...
                    distanceBack >= 1)
                error('Pastafari:Prior:Distance', ...
                    'Odległość poprzednika musi być dodatnią liczbą całkowitą.');
            end

            slot = currentDrop - distanceBack;

            if slot < 1
                value = [];
                found = false;
                return
            end

            if slot > numel(visible) || isempty(visible{slot})
                value = [];
                found = false;
                return
            end

            value = visible{slot};
            found = true;
        end
    end
end
