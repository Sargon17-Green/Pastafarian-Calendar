classdef SequentialYearWalkPatch
    % PATCH 18: znajdź target year przez rzeczywisty spacer rok po roku.
    %
    % Startuje dokładnie od anchor year. Gdy target jest po close,
    % przechodzi do numeru +1. Gdy target jest na/before open,
    % przechodzi do numeru -1. Kończy wyłącznie na (open, close].
    methods (Static)
        function [year, telemetry] = apply(anchorYear, targetDay, years)
            pastafari.SequentialYearWalkPatch.requireYear(anchorYear);
            pastafari.ValidationManager.requireExactIntegerInput(targetDay);

            if ~iscell(years)
                error('Pastafari:Years:SequentialYearList', ...
                    'Sequential year walk wymaga cell array lat.');
            end

            anchorNumber = pastafari.BigInt.coerce(anchorYear.number);
            anchorOpen = pastafari.BigInt.coerce(anchorYear.openGateDay);
            anchorClose = pastafari.BigInt.coerce(anchorYear.closeGateDay);
            target = pastafari.BigInt.coerce(targetDay);

            current = pastafari.SequentialYearWalkPatch.findByNumber( ...
                years, anchorNumber);
            if isempty(current)
                error('Pastafari:Years:SequentialAnchorMissing', ...
                    'Łańcuch lat nie zawiera anchor year.');
            end

            if pastafari.BigInt.coerce(current.openGateDay) ~= anchorOpen || ...
                    pastafari.BigInt.coerce(current.closeGateDay) ~= anchorClose
                error('Pastafari:Years:SequentialAnchorMismatch', ...
                    'Anchor year nie zgadza się z rokiem o tym numerze w łańcuchu.');
            end

            forwardSteps = 0;
            backwardSteps = 0;

            while target > pastafari.BigInt.coerce(current.closeGateDay)
                nextNumber = ...
                    pastafari.BigInt.coerce(current.number) + pastafari.BigInt(1);
                nextYear = pastafari.SequentialYearWalkPatch.findByNumber( ...
                    years, nextNumber);

                if isempty(nextYear)
                    error('Pastafari:Years:SequentialNeighborMissing', ...
                        'Brakuje następnego roku wymaganego przez sequential walk.');
                end

                if pastafari.BigInt.coerce(nextYear.openGateDay) ~= ...
                        pastafari.BigInt.coerce(current.closeGateDay)
                    error('Pastafari:Years:SequentialBoundaryGap', ...
                        'Granica następnego roku nie styka się z bieżącym close.');
                end

                current = nextYear;
                forwardSteps = forwardSteps + 1;
            end

            while target <= pastafari.BigInt.coerce(current.openGateDay)
                previousNumber = ...
                    pastafari.BigInt.coerce(current.number) - pastafari.BigInt(1);
                previousYear = ...
                    pastafari.SequentialYearWalkPatch.findByNumber( ...
                        years, previousNumber);

                if isempty(previousYear)
                    error('Pastafari:Years:SequentialNeighborMissing', ...
                        'Brakuje poprzedniego roku wymaganego przez sequential walk.');
                end

                if pastafari.BigInt.coerce(previousYear.closeGateDay) ~= ...
                        pastafari.BigInt.coerce(current.openGateDay)
                    error('Pastafari:Years:SequentialBoundaryGap', ...
                        'Granica poprzedniego roku nie styka się z bieżącym open.');
                end

                current = previousYear;
                backwardSteps = backwardSteps + 1;
            end

            openDay = pastafari.BigInt.coerce(current.openGateDay);
            closeDay = pastafari.BigInt.coerce(current.closeGateDay);
            if ~(openDay < target && target <= closeDay)
                error('Pastafari:Years:SequentialContainment', ...
                    'Sequential walk nie zakończył się w przedziale (open, close].');
            end

            year = current;
            telemetry = struct( ...
                'anchorNumber', anchorNumber, ...
                'targetDay', target, ...
                'forwardSteps', forwardSteps, ...
                'backwardSteps', backwardSteps, ...
                'finalNumber', pastafari.BigInt.coerce(current.number), ...
                'finalOpenDay', openDay, ...
                'finalCloseDay', closeDay);
        end
    end

    methods (Static, Access = private)
        function year = findByNumber(years, number)
            year = [];
            number = pastafari.BigInt.coerce(number);

            for k = 1:numel(years)
                pastafari.SequentialYearWalkPatch.requireYear(years{k});
                if pastafari.BigInt.coerce(years{k}.number) == number
                    year = years{k};
                    return
                end
            end
        end

        function requireYear(year)
            if ~isstruct(year) || ...
                    ~isfield(year, 'number') || ...
                    ~isfield(year, 'openGateDay') || ...
                    ~isfield(year, 'closeGateDay')
                error('Pastafari:Years:SequentialYearShape', ...
                    'Rok wymaga number, openGateDay i closeGateDay.');
            end

            pastafari.ValidationManager.requireExactIntegerInput(year.number);
            pastafari.ValidationManager.requireExactIntegerInput(year.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput(year.closeGateDay);
        end
    end
end
