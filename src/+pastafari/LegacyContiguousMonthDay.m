classdef LegacyContiguousMonthDay
    % Historyczna wada Discovery 25.
    %
    % Zakłada, że wszystkie wystąpienia wybranego miesiąca są contiguous.
    % dayInMonth jest więc różnicą między targetDay a pierwszym dniem, na
    % którym month id pojawił się w whole weave, plus jeden.
    methods (Static)
        function ghost = compute(weaving, yearOpenDay, targetDay)
            if ~(isnumeric(weaving) && isvector(weaving) && ...
                    ~isempty(weaving) && all(isfinite(weaving)) && ...
                    all(fix(weaving) == weaving) && all(weaving >= 1))
                error('Pastafari:MonthDay:LegacyWeavingShape', ...
                    'weaving musi być niepustym dodatnim wektorem month ids.');
            end

            pastafari.ValidationManager.requireExactIntegerInput(yearOpenDay);
            pastafari.ValidationManager.requireExactIntegerInput(targetDay);

            openDay = pastafari.BigInt.coerce(yearOpenDay);
            target = pastafari.BigInt.coerce(targetDay);
            position1 = target - openDay;

            if position1 < pastafari.BigInt(1) || ...
                    position1 > pastafari.BigInt(numel(weaving))
                error('Pastafari:MonthDay:TargetOutsideYear', ...
                    'targetDay musi należeć do przedziału (yearOpenDay, closeDay].');
            end

            position = position1.toDoubleExact();
            row = double(weaving(:).');
            monthId = row(position);

            firstPosition = find(row == monthId, 1, 'first');
            if isempty(firstPosition)
                error('Pastafari:MonthDay:LegacyFirstOccurrence', ...
                    'Nie znaleziono pierwszego wystąpienia wybranego miesiąca.');
            end

            firstDay = openDay + pastafari.BigInt(firstPosition);
            dayInMonth = target - firstDay + pastafari.BigInt(1);

            ghost = struct( ...
                'monthId', monthId, ...
                'targetPosition1', position1, ...
                'firstPosition1', pastafari.BigInt(firstPosition), ...
                'firstDay', firstDay, ...
                'dayInMonth', dayInMonth);
        end
    end
end
