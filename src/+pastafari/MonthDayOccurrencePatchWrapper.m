classdef MonthDayOccurrencePatchWrapper
    % PATCH 25: dayInMonth jako liczba wystąpień month id do targetu.
    %
    % Historyczny ghost musi zostać wykonany wcześniej. Wrapper nie zmienia
    % month id ani target position. Nadpisuje wyłącznie semantic dayInMonth
    % exact prefix occurrence count.
    methods (Static)
        function [dayInMonth, reusedLegacy] = apply(weaving, ghost)
            if ~(isnumeric(weaving) && isvector(weaving) && ...
                    ~isempty(weaving) && all(isfinite(weaving)) && ...
                    all(fix(weaving) == weaving) && all(weaving >= 1))
                error('Pastafari:MonthDay:OccurrenceWeavingShape', ...
                    'weaving musi być niepustym dodatnim wektorem month ids.');
            end

            required = { ...
                'monthId', ...
                'targetPosition1', ...
                'dayInMonth'};
            if ~isstruct(ghost) || ...
                    ~all(cellfun(@(name) isfield(ghost, name), required))
                error('Pastafari:MonthDay:OccurrenceGhostShape', ...
                    'Occurrence patch wymaga kompletnego legacy ghost.');
            end

            pastafari.ValidationManager.requireExactIntegerInput( ...
                ghost.targetPosition1);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                ghost.dayInMonth);

            position1 = pastafari.BigInt.coerce(ghost.targetPosition1);
            legacyDay = pastafari.BigInt.coerce(ghost.dayInMonth);

            if position1 < pastafari.BigInt(1) || ...
                    position1 > pastafari.BigInt(numel(weaving))
                error('Pastafari:MonthDay:OccurrenceTargetPosition', ...
                    'targetPosition1 musi wskazywać element whole weave.');
            end

            if ~(isnumeric(ghost.monthId) && isscalar(ghost.monthId) && ...
                    isfinite(ghost.monthId) && ...
                    fix(ghost.monthId) == ghost.monthId && ...
                    ghost.monthId >= 1)
                error('Pastafari:MonthDay:OccurrenceMonthId', ...
                    'Legacy ghost ma niepoprawny monthId.');
            end

            row = double(weaving(:).');
            position = position1.toDoubleExact();
            monthId = double(ghost.monthId);

            if row(position) ~= monthId
                error('Pastafari:MonthDay:OccurrenceGhostMismatch', ...
                    'Legacy ghost monthId nie zgadza się z target position.');
            end

            count = sum(row(1:position) == monthId);
            dayInMonth = pastafari.BigInt(count);
            reusedLegacy = dayInMonth == legacyDay;
        end
    end
end
