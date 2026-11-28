classdef GateQuestionEngine
    % Wspólna, semantycznie neutralna maszyna pytania o długość przerwy bramy.
    % Otrzymuje już konkretny target day; sama nie interpretuje znaku indeksu.
    methods (Static)
        function gap = gapForQuestionDay(questionDay)
            pastafari.ValidationManager.requireExactIntegerInput(questionDay);

            foundation = pastafari.BigInt('-15055671');
            target = pastafari.BigInt.coerce(questionDay);
            % QA candidate: only the private, value-only gap result is memoized.
            % Both outer historical/signed question routes remain unchanged.
            key = char(target);
            [gap, hit] = pastafari.GateQuestionEngine.memo('get', key, []);
            if hit
                return
            end
            inner = pastafari.MonsterContext(foundation, target);

            [inner, counts] = pastafari.WorkCountsCompatibilityRoute.call( ...
                inner, foundation, target);
            [inner, stones] = pastafari.StoneTableCompatibilityRoute.call(inner);
            [inner, hidden] = pastafari.HiddenCompatibilityRoute.call( ...
                inner, counts, stones);
            [inner, priorVisible] = ...
                pastafari.VisibleDropCompatibilityRoute.call( ...
                    inner, counts, stones, hidden);
            [inner, visible] = pastafari.GrindTableCompatibilityRoute.call( ...
                inner, counts, stones, hidden, priorVisible);
            [inner, preInPlaceBowls] = ...
                pastafari.BowlPourCompatibilityRoute.call( ...
                    inner, counts, stones, visible);
            [inner, bowlsAfterDrop46] = ...
                pastafari.BowlStirCompatibilityRoute.call( ...
                    inner, counts, stones, visible, preInPlaceBowls);
            [inner, finalBowls, orderAt46] = ...
                pastafari.OrderAt46CompatibilityRoute.call( ...
                    inner, visible, bowlsAfterDrop46);

            queriedBowlId = 1;
            nextBowlId = pastafari.LatchedSuccessorPatch.apply( ...
                orderAt46, queriedBowlId);
            stream = pastafari.AnswerRingStreamFactory.fromSauce( ...
                finalBowls, queriedBowlId, nextBowlId, 1);

            [inner, chosen] = ...
                pastafari.GeneralSelectionCompatibilityRoute.call( ...
                    inner, stream, pastafari.BigInt(922)); %#ok<ASGLU>

            gap = pastafari.BigInt(41) + chosen;
            pastafari.GateQuestionEngine.memo('put', key, gap);
        end

        function clearCache()
            pastafari.GateQuestionEngine.memo('clear', '', []);
        end

        function info = cacheInfo()
            [info, ~] = pastafari.GateQuestionEngine.memo('info', '', []);
        end
    end

    methods (Static, Access = private)
        function [value, hit] = memo(action, key, newValue)
            persistent keys values hits misses
            if isempty(hits)
                keys = {};
                values = {};
                hits = 0;
                misses = 0;
            end
            value = [];
            hit = false;
            switch action
                case 'clear'
                    keys = {};
                    values = {};
                    hits = 0;
                    misses = 0;
                case 'info'
                    value = struct('entries',numel(keys),'hits',hits,'misses',misses);
                case 'get'
                    if numel(key) <= 128
                        position = find(strcmp(keys,key),1);
                        if ~isempty(position)
                            value = values{position};
                            hit = true;
                            hits = hits + 1;
                            return
                        end
                    end
                    misses = misses + 1;
                case 'put'
                    if numel(key) > 128
                        return
                    end
                    if any(strcmp(keys,key))
                        error('Pastafari:GateMemo:Duplicate','Unexpected duplicate gate memo entry.');
                    end
                    if numel(keys) == 128
                        keys(1) = [];
                        values(1) = [];
                    end
                    keys{end+1} = key;
                    values{end+1} = newValue;
                otherwise
                    error('Pastafari:GateMemo:Action','Unknown gate memo action.');
            end
        end
    end
end
