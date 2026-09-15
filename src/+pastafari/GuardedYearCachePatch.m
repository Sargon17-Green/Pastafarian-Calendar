classdef GuardedYearCachePatch
    % PATCH 19: semantic reuse guard nad historycznym key year.number.
    %
    % Fizyczny key cache pozostaje bez zmian. Hit jest semantycznie ważny
    % tylko wtedy, gdy zgadzają się fingerprint oraz oba gate days.
    % Przy mismatch najpierw obliczana jest nowa wartość, a dopiero potem
    % ten sam historyczny key zostaje nadpisany.
    methods (Static)
        function [value, guardHit, recomputed, committedEntry] = ...
                apply(year, calculationDay, producer, rawHit, rawEntry)
            pastafari.ValidationManager.requireExactIntegerInput( ...
                calculationDay);

            if ~isa(producer, 'function_handle')
                error('Pastafari:Cache:Producer', ...
                    'Guarded cache wymaga function handle producenta.');
            end

            if ~isstruct(year) || ...
                    ~isfield(year, 'number') || ...
                    ~isfield(year, 'openGateDay') || ...
                    ~isfield(year, 'closeGateDay')
                error('Pastafari:Cache:YearShape', ...
                    'Guarded cache wymaga number, openGateDay i closeGateDay.');
            end

            pastafari.ValidationManager.requireExactIntegerInput(year.number);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.closeGateDay);

            cDay = pastafari.BigInt.coerce(calculationDay);
            requestedOpen = pastafari.BigInt.coerce(year.openGateDay);
            requestedClose = pastafari.BigInt.coerce(year.closeGateDay);

            guardHit = false;
            if rawHit
                pastafari.GuardedYearCachePatch.requireEntry(rawEntry);
                guardHit = ...
                    rawEntry.calculationDayFingerprint == cDay && ...
                    rawEntry.openGate == requestedOpen && ...
                    rawEntry.closeGate == requestedClose;
            end

            if guardHit
                value = rawEntry.value;
                recomputed = false;
                committedEntry = rawEntry;
                return
            end

            % Transactional ordering: producer musi zakończyć się poprawnie
            % zanim historyczny entry zostanie nadpisany.
            newValue = producer();

            pastafari.LegacyYearNumberStructureCache.put( ...
                year, cDay, newValue);

            [committedEntry, committed] = ...
                pastafari.LegacyYearNumberStructureCache.getEntry(year);

            if ~committed
                error('Pastafari:Cache:GuardedCommitLost', ...
                    'Guarded cache utracił właśnie zapisany entry.');
            end

            pastafari.GuardedYearCachePatch.requireEntry(committedEntry);
            if committedEntry.calculationDayFingerprint ~= cDay || ...
                    committedEntry.openGate ~= requestedOpen || ...
                    committedEntry.closeGate ~= requestedClose
                error('Pastafari:Cache:GuardedCommitMismatch', ...
                    'Guarded cache zapisał entry z błędnymi guard fields.');
            end

            value = newValue;
            recomputed = true;
        end
    end

    methods (Static, Access = private)
        function requireEntry(entry)
            if ~isstruct(entry) || ...
                    ~isfield(entry, 'calculationDayFingerprint') || ...
                    ~isfield(entry, 'openGate') || ...
                    ~isfield(entry, 'closeGate') || ...
                    ~isfield(entry, 'value')
                error('Pastafari:Cache:GuardedEntryShape', ...
                    ['Guarded cache entry wymaga calculationDayFingerprint, ', ...
                     'openGate, closeGate i value.']);
            end

            pastafari.ValidationManager.requireExactIntegerInput( ...
                entry.calculationDayFingerprint);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                entry.openGate);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                entry.closeGate);
        end
    end
end
