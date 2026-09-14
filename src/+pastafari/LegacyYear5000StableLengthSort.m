classdef LegacyYear5000StableLengthSort
    % Historyczna wada Discovery 17.
    %
    % Kandydaci roku 5000 są sortowani stabilnie wyłącznie po długości.
    % Dla równych długości zachowana zostaje kolejność wejściowa, zamiast
    % normatywnego porządku po opening gate.
    methods (Static)
        function ordered = apply(candidates)
            if ~iscell(candidates)
                error('Pastafari:Years:Year5000CandidateList', ...
                    'Lista kandydatów roku 5000 musi być cell array.');
            end

            ordered = candidates;

            % Jawny stabilny insertion sort tylko po lengthDays.
            for i = 2:numel(ordered)
                current = ordered{i};
                currentLength = ...
                    pastafari.LegacyYear5000StableLengthSort.lengthDays(current);
                j = i - 1;

                while j >= 1
                    priorLength = ...
                        pastafari.LegacyYear5000StableLengthSort.lengthDays( ...
                            ordered{j});
                    if priorLength <= currentLength
                        break
                    end
                    ordered{j + 1} = ordered{j};
                    j = j - 1;
                end

                ordered{j + 1} = current;
            end
        end
    end

    methods (Static, Access = private)
        function lengthDays = lengthDays(candidate)
            if ~isstruct(candidate) || ...
                    ~isfield(candidate, 'openGateDay') || ...
                    ~isfield(candidate, 'closeGateDay')
                error('Pastafari:Years:Year5000CandidateShape', ...
                    'Kandydat roku 5000 wymaga openGateDay i closeGateDay.');
            end

            pastafari.ValidationManager.requireExactIntegerInput( ...
                candidate.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                candidate.closeGateDay);

            openDay = pastafari.BigInt.coerce(candidate.openGateDay);
            closeDay = pastafari.BigInt.coerce(candidate.closeGateDay);
            lengthDays = closeDay - openDay;
        end
    end
end
