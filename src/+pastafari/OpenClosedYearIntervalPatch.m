classdef OpenClosedYearIntervalPatch
    % PATCH 26: finalny resolver roku używa dokładnie (open, close].
    %
    % Opening gate nie należy do roku po prawej stronie granicy. Dlatego
    % spacer wstecz wykonuje się dla target <= open. Closing gate pozostaje
    % domknięty i nadal należy do bieżącego roku.
    methods (Static)
        function [year, telemetry] = apply(anchorYear, targetDay, years)
            pastafari.OpenClosedYearIntervalPatch.requireYear(anchorYear);
            pastafari.ValidationManager.requireExactIntegerInput(targetDay);

            if ~iscell(years)
                error('Pastafari:YearInterval:PatchYearList', ...
                    'Open-closed interval patch wymaga cell array lat.');
            end

            anchorNumber = pastafari.BigInt.coerce(anchorYear.number);
            target = pastafari.BigInt.coerce(targetDay);

            current = pastafari.OpenClosedYearIntervalPatch.findByNumber( ...
                years, anchorNumber);
            if isempty(current)
                error('Pastafari:YearInterval:PatchAnchorMissing', ...
                    'Łańcuch lat nie zawiera anchor year.');
            end

            if pastafari.BigInt.coerce(current.openGateDay) ~= ...
                    pastafari.BigInt.coerce(anchorYear.openGateDay) || ...
                    pastafari.BigInt.coerce(current.closeGateDay) ~= ...
                    pastafari.BigInt.coerce(anchorYear.closeGateDay)
                error('Pastafari:YearInterval:PatchAnchorMismatch', ...
                    'Anchor year nie zgadza się z rokiem w łańcuchu.');
            end

            forwardSteps = 0;
            backwardSteps = 0;

            % PATCH 26: opening gate jest otwarty.
            while target <= pastafari.BigInt.coerce(current.openGateDay)
                previousNumber = ...
                    pastafari.BigInt.coerce(current.number) - pastafari.BigInt(1);
                previousYear = ...
                    pastafari.OpenClosedYearIntervalPatch.findByNumber( ...
                        years, previousNumber);

                if isempty(previousYear)
                    error('Pastafari:YearInterval:PatchNeighborMissing', ...
                        'Brakuje poprzedniego roku dla open-closed walk.');
                end

                if pastafari.BigInt.coerce(previousYear.closeGateDay) ~= ...
                        pastafari.BigInt.coerce(current.openGateDay)
                    error('Pastafari:YearInterval:PatchBoundaryGap', ...
                        'Poprzedni close nie styka się z bieżącym open.');
                end

                current = previousYear;
                backwardSteps = backwardSteps + 1;
            end

            % Closing gate pozostaje domknięty.
            while target > pastafari.BigInt.coerce(current.closeGateDay)
                nextNumber = ...
                    pastafari.BigInt.coerce(current.number) + pastafari.BigInt(1);
                nextYear = ...
                    pastafari.OpenClosedYearIntervalPatch.findByNumber( ...
                        years, nextNumber);

                if isempty(nextYear)
                    error('Pastafari:YearInterval:PatchNeighborMissing', ...
                        'Brakuje następnego roku dla open-closed walk.');
                end

                if pastafari.BigInt.coerce(nextYear.openGateDay) ~= ...
                        pastafari.BigInt.coerce(current.closeGateDay)
                    error('Pastafari:YearInterval:PatchBoundaryGap', ...
                        'Następny open nie styka się z bieżącym close.');
                end

                current = nextYear;
                forwardSteps = forwardSteps + 1;
            end

            openDay = pastafari.BigInt.coerce(current.openGateDay);
            closeDay = pastafari.BigInt.coerce(current.closeGateDay);

            if ~(openDay < target && target <= closeDay)
                error('Pastafari:YearInterval:PatchContainment', ...
                    'PATCH 26 nie zakończył się w przedziale (open, close].');
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
                'interval', '(open,close]');
        end
    end

    methods (Static, Access = private)
        function year = findByNumber(years, number)
            year = [];
            wanted = pastafari.BigInt.coerce(number);

            for k = 1:numel(years)
                pastafari.OpenClosedYearIntervalPatch.requireYear(years{k});
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
                error('Pastafari:YearInterval:PatchYearShape', ...
                    'Rok wymaga number, openGateDay i closeGateDay.');
            end

            pastafari.ValidationManager.requireExactIntegerInput(year.number);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.closeGateDay);

            if pastafari.BigInt.coerce(year.openGateDay) >= ...
                    pastafari.BigInt.coerce(year.closeGateDay)
                error('Pastafari:YearInterval:PatchYearOrder', ...
                    'openGateDay musi być mniejszy od closeGateDay.');
            end
        end
    end
end
