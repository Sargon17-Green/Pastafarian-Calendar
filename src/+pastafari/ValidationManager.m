classdef ValidationManager
    % Bazowa warstwa walidacji bez wiedzy o przyszłych błędach historycznych.
    methods (Static)
        function requireContext(ctx)
            if ~isa(ctx, 'pastafari.MonsterContext')
                error('Pastafari:Validation:Context', 'Oczekiwano neutralnego kontekstu wywołania.');
            end
        end
        function requireExactIntegerInput(value)
            if isa(value, 'pastafari.BigInt')
                return
            end
            if ~(isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && fix(value) == value && abs(double(value)) <= flintmax)
                error('Pastafari:Validation:IntegerInput', ...
                    'Dzień musi być dokładną liczbą całkowitą albo obiektem pastafari.BigInt.');
            end
        end
    end
end
