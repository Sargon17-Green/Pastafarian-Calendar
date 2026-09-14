classdef YearMax5778LateFilter
    % PATCH 16: późny filtr maksymalnej długości roku.
    %
    % Otrzymuje już surową listę historycznego generatora max-5781.
    % Nie regeneruje kandydatów, nie sortuje i nie wybiera roku.
    % Zachowuje kolejność, odrzucając wyłącznie lengthDays > 5778.
    methods (Static)
        function [accepted, rejected] = apply(legacyCandidates)
            if ~iscell(legacyCandidates)
                error('Pastafari:Years:LateFilterList', ...
                    'Late filter wymaga cell array kandydatów legacy.');
            end

            accepted = {};
            rejected = {};

            for k = 1:numel(legacyCandidates)
                candidate = legacyCandidates{k};
                lengthDays = ...
                    pastafari.YearMax5778LateFilter.lengthDays(candidate);

                if lengthDays <= pastafari.BigInt(5778)
                    accepted{end + 1} = candidate; %#ok<AGROW>
                else
                    rejected{end + 1} = candidate; %#ok<AGROW>
                end
            end
        end
    end

    methods (Static, Access = private)
        function lengthDays = lengthDays(candidate)
            if ~isstruct(candidate) || ...
                    ~isfield(candidate, 'openGateDay') || ...
                    ~isfield(candidate, 'closeGateDay')
                error('Pastafari:Years:LateFilterCandidateShape', ...
                    'Late filter wymaga openGateDay i closeGateDay.');
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
