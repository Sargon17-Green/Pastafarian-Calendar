classdef LegacyFixedNameSuccessor
    % Historyczna wada Discovery 12.
    % Successor jest wyznaczany według stałej numerycznej obręczy nazw:
    % 1->2->3->4->5->6->1, bez oglądania orderAt46Latch.
    methods (Static)
        function successor = next(queriedBowlId)
            if ~(isnumeric(queriedBowlId) && isscalar(queriedBowlId) && ...
                    isfinite(queriedBowlId) && fix(queriedBowlId) == queriedBowlId && ...
                    queriedBowlId >= 1 && queriedBowlId <= 6)
                error('Pastafari:Successor:LegacyBowlId', ...
                    'Historyczny successor wymaga bowl ID z zakresu 1..6.');
            end

            successor = mod(queriedBowlId, 6) + 1;
        end
    end
end
