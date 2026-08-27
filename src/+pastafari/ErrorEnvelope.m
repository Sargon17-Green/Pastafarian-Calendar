classdef ErrorEnvelope
    % Bazowe opakowanie błędu; nie wykonuje odzyskiwania ani alternatywnej semantyki.
    methods (Static)
        function wrapped = wrap(err, phase)
            wrapped = struct('identifier', err.identifier, 'message', err.message, 'phase', phase);
        end
    end
end
