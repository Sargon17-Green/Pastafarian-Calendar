classdef Year5000TieRunSortPatch
    % PATCH 17: porządkuje wyłącznie contiguous equal-length runs.
    %
    % Wejście ma być już wynikiem historycznego stable length-only sort.
    % Kandydaci o różnych długościach nie są globalnie przemieszczani.
    % W obrębie każdego run rośnie opening gate day.
    methods (Static)
        function ordered = apply(legacyLengthOrdered)
            if ~iscell(legacyLengthOrdered)
                error('Pastafari:Years:Year5000TieRunList', ...
                    'PATCH 17 wymaga cell array kandydatów.');
            end

            ordered = legacyLengthOrdered;
            if numel(ordered) < 2
                return
            end

            % Potwierdź, że wejście rzeczywiście jest już posortowane
            % niemalejąco po długości przez warstwę legacy.
            previousLength = ...
                pastafari.Year5000TieRunSortPatch.lengthDays(ordered{1});
            for k = 2:numel(ordered)
                currentLength = ...
                    pastafari.Year5000TieRunSortPatch.lengthDays(ordered{k});
                if currentLength < previousLength
                    error('Pastafari:Years:TieRunInputNotLengthSorted', ...
                        ['PATCH 17 może działać dopiero po historycznym ', ...
                         'stable length-only sort.']);
                end
                previousLength = currentLength;
            end

            runStart = 1;
            while runStart <= numel(ordered)
                runLength = ...
                    pastafari.Year5000TieRunSortPatch.lengthDays( ...
                        ordered{runStart});

                runEnd = runStart;
                while runEnd < numel(ordered) && ...
                        pastafari.Year5000TieRunSortPatch.lengthDays( ...
                            ordered{runEnd + 1}) == runLength
                    runEnd = runEnd + 1;
                end

                % Stabilny insertion sort tylko wewnątrz bieżącego run,
                % po opening gate day rosnąco.
                for i = (runStart + 1):runEnd
                    current = ordered{i};
                    currentOpen = ...
                        pastafari.Year5000TieRunSortPatch.openingDay(current);
                    j = i - 1;

                    while j >= runStart
                        priorOpen = ...
                            pastafari.Year5000TieRunSortPatch.openingDay( ...
                                ordered{j});
                        if priorOpen <= currentOpen
                            break
                        end
                        ordered{j + 1} = ordered{j};
                        j = j - 1;
                    end

                    ordered{j + 1} = current;
                end

                runStart = runEnd + 1;
            end
        end
    end

    methods (Static, Access = private)
        function lengthDays = lengthDays(candidate)
            pastafari.Year5000TieRunSortPatch.requireCandidate(candidate);

            openDay = pastafari.BigInt.coerce(candidate.openGateDay);
            closeDay = pastafari.BigInt.coerce(candidate.closeGateDay);
            lengthDays = closeDay - openDay;
        end

        function openDay = openingDay(candidate)
            pastafari.Year5000TieRunSortPatch.requireCandidate(candidate);
            openDay = pastafari.BigInt.coerce(candidate.openGateDay);
        end

        function requireCandidate(candidate)
            if ~isstruct(candidate) || ...
                    ~isfield(candidate, 'openGateDay') || ...
                    ~isfield(candidate, 'closeGateDay')
                error('Pastafari:Years:Year5000TieRunCandidateShape', ...
                    'Kandydat wymaga openGateDay i closeGateDay.');
            end

            pastafari.ValidationManager.requireExactIntegerInput( ...
                candidate.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                candidate.closeGateDay);
        end
    end
end
