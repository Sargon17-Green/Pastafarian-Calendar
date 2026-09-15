classdef LegacyYearNumberStructureCache
    % Historyczna wada Discovery 19.
    %
    % Fizyczny map jest keyed wyłącznie przez year.number.
    % Entry przechowuje przyszłe dane guard, ale surowy getRaw ich nie
    % sprawdza i zwraca value wyłącznie na podstawie numeru roku.
    methods (Static)
        function clear()
            pastafari.LegacyYearNumberStructureCache.store( ...
                'clear', '', []);
        end

        function put(year, calculationDay, value)
            pastafari.LegacyYearNumberStructureCache.requireYear(year);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                calculationDay);

            key = char(pastafari.BigInt.coerce(year.number));
            entry = struct( ...
                'calculationDayFingerprint', ...
                    pastafari.BigInt.coerce(calculationDay), ...
                'openGate', pastafari.BigInt.coerce(year.openGateDay), ...
                'closeGate', pastafari.BigInt.coerce(year.closeGateDay), ...
                'value', value);

            pastafari.LegacyYearNumberStructureCache.store( ...
                'put', key, entry);
        end

        function [value, hit, entry] = getRaw(year)
            pastafari.LegacyYearNumberStructureCache.requireYear(year);
            key = char(pastafari.BigInt.coerce(year.number));

            [entry, hit] = ...
                pastafari.LegacyYearNumberStructureCache.store( ...
                    'get', key, []);

            if hit
                value = entry.value;
            else
                value = [];
                entry = [];
            end
        end

        function [entry, hit] = getEntry(year)
            % Udostępnia pełny entry dla przyszłego guard patch.
            % Nadal wyszukuje go przez ten sam zły key year.number.
            pastafari.LegacyYearNumberStructureCache.requireYear(year);
            key = char(pastafari.BigInt.coerce(year.number));
            [entry, hit] = ...
                pastafari.LegacyYearNumberStructureCache.store( ...
                    'get', key, []);
        end
    end

    methods (Static, Access = private)
        function [entry, hit] = store(action, key, newEntry)
            persistent cacheKeys cacheEntries
            if isempty(cacheKeys)
                cacheKeys = {};
                cacheEntries = {};
            end

            entry = [];
            hit = false;

            switch action
                case 'clear'
                    cacheKeys = {};
                    cacheEntries = {};
                    return

                case 'put'
                    position = find(strcmp(cacheKeys, key), 1, 'first');
                    if isempty(position)
                        cacheKeys{end + 1} = key;
                        cacheEntries{end + 1} = newEntry;
                    else
                        cacheEntries{position} = newEntry;
                    end
                    return

                case 'get'
                    position = find(strcmp(cacheKeys, key), 1, 'first');
                    if ~isempty(position)
                        entry = cacheEntries{position};
                        hit = true;
                    end
                    return

                otherwise
                    error('Pastafari:Cache:LegacyAction', ...
                        'Nieznana operacja historycznego cache.');
            end
        end

        function requireYear(year)
            if ~isstruct(year) || ...
                    ~isfield(year, 'number') || ...
                    ~isfield(year, 'openGateDay') || ...
                    ~isfield(year, 'closeGateDay')
                error('Pastafari:Cache:YearShape', ...
                    'Cache roku wymaga number, openGateDay i closeGateDay.');
            end

            pastafari.ValidationManager.requireExactIntegerInput(year.number);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.closeGateDay);
        end
    end
end
