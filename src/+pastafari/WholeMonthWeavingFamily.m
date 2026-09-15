classdef WholeMonthWeavingFamily < handle
    % PATCH 24: exact whole-month weaving family.
    %
    % Legalny splot zachowuje:
    % 1) dokładne multiplicities monthLengths,
    % 2) kolejność pierwszego otwarcia miesięcy 1,2,...,
    % 3) kolejność ostatecznego zamknięcia miesięcy 1,2,...
    %
    % Rodzina nie materializuje splotów. Buduje DAG stanów oraz exact
    % BigInt completion counts, a itemAt1 wykonuje lexicographic unrank.
    properties (SetAccess = private)
        monthLengths
        monthCount
        totalDays
    end

    properties (Access = private)
        layers
        completionCounts
        initialStateKey
    end

    methods
        function obj = WholeMonthWeavingFamily(monthLengths)
            if ~(isnumeric(monthLengths) && isvector(monthLengths) && ...
                    ~isempty(monthLengths) && all(isfinite(monthLengths)) && ...
                    all(fix(monthLengths) == monthLengths) && ...
                    all(monthLengths > 0))
                error('Pastafari:MonthWeaving:WholeFamilyLengths', ...
                    'monthLengths musi być niepustym dodatnim wektorem całkowitym.');
            end

            obj.monthLengths = double(monthLengths(:).');
            obj.monthCount = numel(obj.monthLengths);
            obj.totalDays = sum(obj.monthLengths);

            [obj.layers, obj.completionCounts, obj.initialStateKey] = ...
                obj.buildExactStateDP();
        end

        function total = count(obj)
            total = obj.completionCounts(obj.initialStateKey);
        end

        function weaving = itemAt1(obj, rank1)
            pastafari.ValidationManager.requireExactIntegerInput(rank1);

            rank = pastafari.BigInt.coerce(rank1);
            total = obj.count();
            if rank < pastafari.BigInt(1) || rank > total
                error('Pastafari:MonthWeaving:WholeFamilyRank', ...
                    'Rank musi należeć do 1..count whole-weave family.');
            end

            state = struct( ...
                'remaining', obj.monthLengths, ...
                'openedUpTo', 0, ...
                'closedUpTo', 0);
            weaving = zeros(1, obj.totalDays);
            r = rank;

            for position = 1:obj.totalDays
                children = obj.legalChildren(state);
                selected = false;

                for k = 1:numel(children)
                    child = children{k};
                    key = obj.stateKey( ...
                        child.remaining, child.openedUpTo, child.closedUpTo);
                    block = obj.completionCounts(key);

                    if r > block
                        r = r - block;
                    else
                        weaving(position) = child.selectedMonth;
                        state = child;
                        selected = true;
                        break
                    end
                end

                if ~selected
                    error('Pastafari:MonthWeaving:WholeFamilyUnrank', ...
                        'Nie udało się odnaleźć lexicographic child block.');
                end
            end

            if any(state.remaining ~= 0) || ...
                    state.openedUpTo ~= obj.monthCount || ...
                    state.closedUpTo ~= obj.monthCount
                error('Pastafari:MonthWeaving:WholeFamilyInvariant', ...
                    'Whole-weave unrank nie zakończył się poprawnym stanem terminalnym.');
            end
        end
    end

    methods (Access = private)
        function [layers, counts, initialKey] = buildExactStateDP(obj)
            layers = cell(1, obj.totalDays + 1);

            initial = struct( ...
                'remaining', obj.monthLengths, ...
                'openedUpTo', 0, ...
                'closedUpTo', 0, ...
                'selectedMonth', 0);

            initialKey = obj.stateKey( ...
                initial.remaining, initial.openedUpTo, initial.closedUpTo);

            firstLayer = containers.Map('KeyType', 'char', 'ValueType', 'any');
            firstLayer(initialKey) = initial;
            layers{1} = firstLayer;

            % Forward pass: reachable-state DAG grouped by consumed days.
            for day = 0:(obj.totalDays - 1)
                current = layers{day + 1};
                next = containers.Map('KeyType', 'char', 'ValueType', 'any');
                currentKeys = keys(current);

                for i = 1:numel(currentKeys)
                    state = current(currentKeys{i});
                    children = obj.legalChildren(state);

                    for k = 1:numel(children)
                        child = children{k};
                        key = obj.stateKey( ...
                            child.remaining, ...
                            child.openedUpTo, ...
                            child.closedUpTo);

                        if ~isKey(next, key)
                            next(key) = child;
                        end
                    end
                end

                layers{day + 2} = next;
            end

            counts = containers.Map('KeyType', 'char', 'ValueType', 'any');

            % Terminal layer: all legal paths end at the single all-zero state.
            terminal = layers{obj.totalDays + 1};
            terminalKeys = keys(terminal);
            for i = 1:numel(terminalKeys)
                state = terminal(terminalKeys{i});
                if all(state.remaining == 0) && ...
                        state.openedUpTo == obj.monthCount && ...
                        state.closedUpTo == obj.monthCount
                    counts(terminalKeys{i}) = pastafari.BigInt(1);
                else
                    counts(terminalKeys{i}) = pastafari.BigInt(0);
                end
            end

            % Reverse pass: exact number of completions from every state.
            for day = (obj.totalDays - 1):-1:0
                current = layers{day + 1};
                currentKeys = keys(current);

                for i = 1:numel(currentKeys)
                    state = current(currentKeys{i});
                    children = obj.legalChildren(state);
                    total = pastafari.BigInt(0);

                    for k = 1:numel(children)
                        child = children{k};
                        childKey = obj.stateKey( ...
                            child.remaining, ...
                            child.openedUpTo, ...
                            child.closedUpTo);

                        if ~isKey(counts, childKey)
                            error('Pastafari:MonthWeaving:WholeFamilyDPOrder', ...
                                'Brakuje completion count dla osiągalnego child state.');
                        end

                        total = total + counts(childKey);
                    end

                    counts(currentKeys{i}) = total;
                end
            end
        end

        function children = legalChildren(obj, state)
            children = {};

            for monthId = 1:obj.monthCount
                if state.remaining(monthId) == 0
                    continue
                end

                alreadyOpened = ...
                    state.remaining(monthId) < obj.monthLengths(monthId);

                if ~alreadyOpened && ...
                        monthId ~= state.openedUpTo + 1
                    continue
                end

                willClose = state.remaining(monthId) == 1;
                if willClose && ...
                        monthId ~= state.closedUpTo + 1
                    continue
                end

                nextRemaining = state.remaining;
                nextOpened = state.openedUpTo;
                nextClosed = state.closedUpTo;

                if nextRemaining(monthId) == obj.monthLengths(monthId)
                    nextOpened = monthId;
                end

                nextRemaining(monthId) = nextRemaining(monthId) - 1;

                if nextRemaining(monthId) == 0
                    nextClosed = monthId;
                end

                children{end + 1} = struct( ... %#ok<AGROW>
                    'remaining', nextRemaining, ...
                    'openedUpTo', nextOpened, ...
                    'closedUpTo', nextClosed, ...
                    'selectedMonth', monthId);
            end
        end

        function key = stateKey(~, remaining, openedUpTo, closedUpTo)
            key = [ ...
                sprintf('%d,', remaining), ...
                '|O', num2str(openedUpTo), ...
                '|C', num2str(closedUpTo)];
        end
    end
end
