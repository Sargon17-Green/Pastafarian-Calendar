classdef LegacyClosedOpeningYearResolver
    % Historyczna wada Discovery 26.
    %
    % Rok jest traktowany jako domknięty z obu stron: [open, close].
    % Przy wspólnej granicy dwóch lat opening gate bieżącego roku może więc
    % zostać błędnie przypisany do tego roku zamiast do poprzedniego.
    methods (Static)
        function [year, telemetry] = apply(anchorYear, targetDay, years)
            pastafari.LegacyClosedOpeningYearResolver.requireYear(anchorYear);
            pastafari.ValidationManager.requireExactIntegerInput(targetDay);

            if ~iscell(years)
                error('Pastafari:YearInterval:LegacyYearList', ...
                    'Legacy closed-opening resolver wymaga cell array lat.');
            end

            anchorNumber = pastafari.BigInt.coerce(anchorYear.number);
            target = pastafari.BigInt.coerce(targetDay);

            current = ...
                pastafari.LegacyClosedOpeningYearResolver.findByNumber( ...
                    years, anchorNumber);
            if isempty(current)
                error('Pastafari:YearInterval:LegacyAnchorMissing', ...
                    'Łańcuch lat nie zawiera anchor year.');
            end

            if pastafari.BigInt.coerce(current.openGateDay) ~= ...
                    pastafari.BigInt.coerce(anchorYear.openGateDay) || ...
                    pastafari.BigInt.coerce(current.closeGateDay) ~= ...
                    pastafari.BigInt.coerce(anchorYear.closeGateDay)
                error('Pastafari:YearInterval:LegacyAnchorMismatch', ...
                    'Anchor year nie zgadza się z rokiem w łańcuchu.');
            end

            forwardSteps = 0;
            backwardSteps = 0;

            % Historyczna wada: idziemy wstecz tylko dla target < open,
            % zamiast target <= open.
            while target < pastafari.BigInt.coerce(current.openGateDay)
                previousNumber = ...
                    pastafari.BigInt.coerce(current.number) - pastafari.BigInt(1);
                previousYear = ...
                    pastafari.LegacyClosedOpeningYearResolver.findByNumber( ...
                        years, previousNumber);

                if isempty(previousYear)
                    error('Pastafari:YearInterval:LegacyNeighborMissing', ...
                        'Brakuje poprzedniego roku dla legacy interval walk.');
                end

                if pastafari.BigInt.coerce(previousYear.closeGateDay) ~= ...
                        pastafari.BigInt.coerce(current.openGateDay)
                    error('Pastafari:YearInterval:LegacyBoundaryGap', ...
                        'Poprzedni close nie styka się z bieżącym open.');
                end

                current = previousYear;
                backwardSteps = backwardSteps + 1;
            end

            while target > pastafari.BigInt.coerce(current.closeGateDay)
                nextNumber = ...
                    pastafari.BigInt.coerce(current.number) + pastafari.BigInt(1);
                nextYear = ...
                    pastafari.LegacyClosedOpeningYearResolver.findByNumber( ...
                        years, nextNumber);

                if isempty(nextYear)
                    error('Pastafari:YearInterval:LegacyNeighborMissing', ...
                        'Brakuje następnego roku dla legacy interval walk.');
                end

                if pastafari.BigInt.coerce(nextYear.openGateDay) ~= ...
                        pastafari.BigInt.coerce(current.closeGateDay)
                    error('Pastafari:YearInterval:LegacyBoundaryGap', ...
                        'Następny open nie styka się z bieżącym close.');
                end

                current = nextYear;
                forwardSteps = forwardSteps + 1;
            end

            openDay = pastafari.BigInt.coerce(current.openGateDay);
            closeDay = pastafari.BigInt.coerce(current.closeGateDay);

            if ~(openDay <= target && target <= closeDay)
                error('Pastafari:YearInterval:LegacyContainment', ...
                    'Legacy resolver nie zakończył się w [open, close].');
            end

            year = current;
            telemetry = struct( ...
                'anchorNumber', anchorNumber, ...
                'targetDay', target, ...
                'forwardSteps', forwardSteps, ...
                'backwardSteps', backwardSteps, ...
                'finalNumber', pastafari.BigInt.coerce(current.number), ...
                'finalOpenDay', openDay, ...
                'finalCloseDay', closeDay, ...
                'interval', '[open,close]');
        end
    end

    methods (Static, Access = private)
        function year = findByNumber(years, number)
            year = [];
            wanted = pastafari.BigInt.coerce(number);

            for k = 1:numel(years)
                pastafari.LegacyClosedOpeningYearResolver.requireYear(years{k});
                if pastafari.BigInt.coerce(years{k}.number) == wanted
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
                error('Pastafari:YearInterval:LegacyYearShape', ...
                    'Rok wymaga number, openGateDay i closeGateDay.');
            end

            pastafari.ValidationManager.requireExactIntegerInput(year.number);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.closeGateDay);

            if pastafari.BigInt.coerce(year.openGateDay) >= ...
                    pastafari.BigInt.coerce(year.closeGateDay)
                error('Pastafari:YearInterval:LegacyYearOrder', ...
                    'openGateDay musi być mniejszy od closeGateDay.');
            end
        end
    end
end
