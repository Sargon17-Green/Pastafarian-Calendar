classdef LegacyOldYearJumpGuess
    % Historyczna wada Discovery 18.
    %
    % Zamiast chodzić po rzeczywistych kolejnych latach, stara ścieżka
    % zakłada 365 dni na rok i wybiera numer bezpośrednio:
    %
    % floor((targetDay-anchor.openGateDay)/365) + anchor.number.
    methods (Static)
        function [guessedYear, telemetry] = apply(anchorYear, targetDay, years)
            pastafari.LegacyOldYearJumpGuess.requireYear(anchorYear);
            pastafari.ValidationManager.requireExactIntegerInput(targetDay);

            if ~iscell(years)
                error('Pastafari:Years:JumpYearList', ...
                    'Historyczny jump guess wymaga cell array lat.');
            end

            anchorNumber = pastafari.BigInt.coerce(anchorYear.number);
            anchorOpenDay = pastafari.BigInt.coerce(anchorYear.openGateDay);
            target = pastafari.BigInt.coerce(targetDay);

            deltaDays = target - anchorOpenDay;
            guessOffset365 = deltaDays.floorDiv(pastafari.BigInt(365));
            guessedNumber = anchorNumber + guessOffset365;

            guessedYear = [];
            for k = 1:numel(years)
                pastafari.LegacyOldYearJumpGuess.requireYear(years{k});
                if pastafari.BigInt.coerce(years{k}.number) == guessedNumber
                    guessedYear = years{k};
                    break
                end
            end

            telemetry = struct( ...
                'anchorNumber', anchorNumber, ...
                'anchorOpenDay', anchorOpenDay, ...
                'targetDay', target, ...
                'deltaDays', deltaDays, ...
                'guessOffset365', guessOffset365, ...
                'guessedNumber', guessedNumber, ...
                'found', ~isempty(guessedYear));
        end
    end

    methods (Static, Access = private)
        function requireYear(year)
            if ~isstruct(year) || ...
                    ~isfield(year, 'number') || ...
                    ~isfield(year, 'openGateDay') || ...
                    ~isfield(year, 'closeGateDay')
                error('Pastafari:Years:JumpYearShape', ...
                    'Rok wymaga number, openGateDay i closeGateDay.');
            end

            pastafari.ValidationManager.requireExactIntegerInput(year.number);
            pastafari.ValidationManager.requireExactIntegerInput(year.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput(year.closeGateDay);
        end
    end
end
