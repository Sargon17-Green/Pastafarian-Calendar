classdef LegacyYearMax5781Filter
    % Historyczna wada Discovery 16.
    %
    % Generator kandydatów roku zachowuje normatywne minimum 252 dni
    % i minimum sześciu odstępów bram, lecz błędnie dopuszcza maksimum 5781.
    methods (Static)
        function [accepted, acceptedLengths] = apply(candidates)
            if ~iscell(candidates)
                error('Pastafari:Years:CandidateList', ...
                    'Lista kandydatów roku musi być cell array.');
            end

            accepted = {};
            acceptedLengths = {};

            for k = 1:numel(candidates)
                candidate = candidates{k};
                [gateSpan, lengthDays] = ...
                    pastafari.LegacyYearMax5781Filter.measure(candidate);

                if gateSpan >= pastafari.BigInt(6) && ...
                        lengthDays >= pastafari.BigInt(252) && ...
                        lengthDays <= pastafari.BigInt(5781)
                    accepted{end + 1} = candidate; %#ok<AGROW>
                    acceptedLengths{end + 1} = lengthDays; %#ok<AGROW>
                end
            end
        end
    end

    methods (Static, Access = private)
        function [gateSpan, lengthDays] = measure(candidate)
            if ~isstruct(candidate) || ...
                    ~isfield(candidate, 'openGateIndex') || ...
                    ~isfield(candidate, 'closeGateIndex') || ...
                    ~isfield(candidate, 'openGateDay') || ...
                    ~isfield(candidate, 'closeGateDay')
                error('Pastafari:Years:CandidateShape', ...
                    ['Kandydat roku wymaga openGateIndex, closeGateIndex, ', ...
                     'openGateDay i closeGateDay.']);
            end

            pastafari.ValidationManager.requireExactIntegerInput( ...
                candidate.openGateIndex);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                candidate.closeGateIndex);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                candidate.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                candidate.closeGateDay);

            openIndex = pastafari.BigInt.coerce(candidate.openGateIndex);
            closeIndex = pastafari.BigInt.coerce(candidate.closeGateIndex);
            openDay = pastafari.BigInt.coerce(candidate.openGateDay);
            closeDay = pastafari.BigInt.coerce(candidate.closeGateDay);

            gateSpan = closeIndex - openIndex;
            lengthDays = closeDay - openDay;
        end
    end
end
