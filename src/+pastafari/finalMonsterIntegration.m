function [ctx, result] = finalMonsterIntegration(ctx, calculationDay, targetDay)
% Etap 54: końcowa integracja całego historycznego potwora.
%
% Ta funkcja nie omija żadnej naprawionej warstwy produkcyjnej. Defekty
% historyczne pozostają wykonywane w istniejących CompatibilityRoute, a
% wynik semantyczny przechodzi przez odpowiadające im PATCH 01..26.
% Testowy normative_oracle nie jest dostępny z tej ścieżki i nie jest
% używany ani jako implementacja, ani jako fallback.

pastafari.ValidationManager.requireContext(ctx);
pastafari.ValidationManager.requireExactIntegerInput(calculationDay);
pastafari.ValidationManager.requireExactIntegerInput(targetDay);

cDay = pastafari.BigInt.coerce(calculationDay);
tDay = pastafari.BigInt.coerce(targetDay);
if pastafari.BigInt.coerce(ctx.calculationDay) ~= cDay || ...
        pastafari.BigInt.coerce(ctx.targetDay) ~= tDay
    error('Pastafari:Integration:ContextInputMismatch', ...
        'MonsterContext musi należeć do tej samej pary calculation/target.');
end

foundation = pastafari.BigInt('-15055671');
legacyMaxYearDays = pastafari.BigInt(5781);
semanticMaxYearDays = pastafari.BigInt(5778);

gateMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
gateMap('0') = foundation;
minKnownGate = pastafari.BigInt(0);
maxKnownGate = pastafari.BigInt(0);

ctx.phase = 'INTEGRATION_FINAL';
ctx.subPhase = 54;
ctx.mode = 'FULL_MONSTER_INTEGRATION';
ctx.status = 'INTEGRATING';
ctx.branchTrace{end + 1} = 'STAGE_54_FINAL_MONSTER_INTEGRATION_BEGIN';
ctx.metrics = pastafari.MetricsShell.bump( ...
    ctx.metrics, 'stage54.finalMonsterIntegration.calls');

% PATCH 01 nie jest osobną częścią sauce API, dlatego wykonujemy jego
% fizyczną bliznę jawnie również na finalnej trasie.
[ctx, ~] = pastafari.SaveCompatibilityRoute.call(ctx, cDay); %#ok<ASGLU>

[anchorYear, years] = buildYearChainContainingTarget();

% Zachowaj obie historyczne warstwy przypisania targetu do roku.
[ctx, walkedYear] = pastafari.TargetYearCompatibilityRoute.call( ...
    ctx, anchorYear, tDay, years);
[ctx, year] = pastafari.YearIntervalCompatibilityRoute.call( ...
    ctx, anchorYear, tDay, years);

if pastafari.BigInt.coerce(walkedYear.number) ~= ...
        pastafari.BigInt.coerce(year.number) || ...
        pastafari.BigInt.coerce(walkedYear.openGateDay) ~= ...
        pastafari.BigInt.coerce(year.openGateDay) || ...
        pastafari.BigInt.coerce(walkedYear.closeGateDay) ~= ...
        pastafari.BigInt.coerce(year.closeGateDay)
    error('Pastafari:Integration:YearResolverDisagreement', ...
        ['PATCH 18 i PATCH 26 muszą wskazywać ten sam ', ...
         'autorytatywny rok.']);
end

producer = @() buildYearStructure(year);
[ctx, structure] = pastafari.YearStructureCacheCompatibilityRoute.call( ...
    ctx, year, cDay, producer);

[cutlet, cutletId] = cutletAtTarget(structure.cutlets, tDay);
dayInCutlet = tDay - cutlet.firstDay + pastafari.BigInt(1);

[ctx, monthId, dayInMonth] = pastafari.MonthDayCompatibilityRoute.call( ...
    ctx, structure.monthWeaving, year.openGateDay, tDay);

catalog = pastafari.sourceLanguageCatalog();
cutletNameIndex = structure.cutletNameIndices(cutletId);
monthNameIndex = structure.monthNameIndices(monthId);
cutletName = catalog.cutlets(cutletNameIndex).text;
monthName = catalog.months(monthNameIndex).text;

result = {year.number, cutletName, dayInCutlet, monthName, dayInMonth};
if numel(result) ~= 5
    error('Pastafari:Integration:FiveFields', ...
        'Końcowa trasa musi zwracać dokładnie pięć pól.');
end

ctx.phase = 'INTEGRATION_FINAL';
ctx.subPhase = 54;
ctx.mode = 'FULL_MONSTER_INTEGRATION';
ctx.status = 'GREEN_CANDIDATE_NATIVE_RERUN_DEFERRED';
ctx.branchTrace{end + 1} = 'STAGE_54_FINAL_MONSTER_INTEGRATION_END';
ctx.metrics = pastafari.MetricsShell.bump( ...
    ctx.metrics, 'stage54.finalMonsterIntegration.completed');
ctx.diagnostics{end + 1} = ...
    ['Etap 54 połączył wszystkie 26 par defect/patch w jedną ', ...
     'trasę zwracającą rok, kotlet, dzień kotleta, miesiąc i dzień miesiąca.'];

    function [anchor, chain] = buildYearChainContainingTarget()
        anchor = chooseYear5000();
        chain = {anchor};
        current = anchor;

        while tDay > pastafari.BigInt.coerce(current.closeGateDay)
            current = chooseNextYear(current);
            chain{end + 1} = current; %#ok<AGROW>
        end

        while tDay <= pastafari.BigInt.coerce(current.openGateDay)
            current = choosePreviousYear(current);
            chain{end + 1} = current; %#ok<AGROW>
        end
    end

    function year5000 = chooseYear5000()
        ensureGatesCover(cDay - legacyMaxYearDays, ...
            cDay + legacyMaxYearDays);

        rawCandidates = {};
        openIndex = minKnownGate;
        while openIndex < maxKnownGate
            openDay = gateDay(openIndex);
            closeIndex = openIndex + pastafari.BigInt(1);

            while closeIndex <= maxKnownGate
                closeDay = gateDay(closeIndex);
                lengthDays = closeDay - openDay;
                if lengthDays > legacyMaxYearDays
                    break
                end

                if openDay < cDay && cDay <= closeDay
                    rawCandidates{end + 1} = ...
                        makeCandidate(openIndex, closeIndex); %#ok<AGROW>
                end
                closeIndex = closeIndex + pastafari.BigInt(1);
            end
            openIndex = openIndex + pastafari.BigInt(1);
        end

        [ctx, candidates] = ...
            pastafari.YearCandidateCompatibilityRoute.call( ...
                ctx, rawCandidates);
        if isempty(candidates)
            error('Pastafari:Integration:Year5000Candidates', ...
                'Nie znaleziono kandydata na rok 5000.');
        end

        [ctx, ordered] = ...
            pastafari.Year5000OrderingCompatibilityRoute.call( ...
                ctx, candidates);

        sauceResult = sauceOnCurrentContext(cDay, cDay);
        rank = chooseFromSauce(sauceResult, 1, 10, ...
            pastafari.BigInt(numel(ordered)));
        chosen = ordered{rank.toDoubleExact()};
        year5000 = makeYear(pastafari.BigInt(5000), ...
            chosen.openGateIndex, chosen.closeGateIndex);
    end

    function year = chooseNextYear(knownYear)
        openIndex = pastafari.BigInt.coerce(knownYear.closeGateIndex);
        openDay = gateDay(openIndex);
        ensureGatesCover(openDay, openDay + legacyMaxYearDays);

        rawCandidates = {};
        closeIndex = openIndex + pastafari.BigInt(1);
        while true
            ensureGateIndex(closeIndex);
            closeDay = gateDay(closeIndex);
            if closeDay - openDay > legacyMaxYearDays
                break
            end
            rawCandidates{end + 1} = ...
                makeCandidate(openIndex, closeIndex); %#ok<AGROW>
            closeIndex = closeIndex + pastafari.BigInt(1);
        end

        [ctx, candidates] = ...
            pastafari.YearCandidateCompatibilityRoute.call( ...
                ctx, rawCandidates);
        if isempty(candidates)
            error('Pastafari:Integration:NextYearCandidates', ...
                'Nie znaleziono kandydata na następny rok.');
        end
        candidates = stableLengthSort(candidates);

        sauceResult = sauceOnCurrentContext(cDay, openDay);
        rank = chooseFromSauce(sauceResult, 1, 11, ...
            pastafari.BigInt(numel(candidates)));
        chosen = candidates{rank.toDoubleExact()};
        year = makeYear(pastafari.BigInt.coerce(knownYear.number) + ...
            pastafari.BigInt(1), chosen.openGateIndex, chosen.closeGateIndex);
    end

    function year = choosePreviousYear(knownYear)
        closeIndex = pastafari.BigInt.coerce(knownYear.openGateIndex);
        closeDay = gateDay(closeIndex);
        ensureGatesCover(closeDay - legacyMaxYearDays, closeDay);

        rawCandidates = {};
        openIndex = closeIndex - pastafari.BigInt(1);
        while true
            ensureGateIndex(openIndex);
            openDay = gateDay(openIndex);
            if closeDay - openDay > legacyMaxYearDays
                break
            end
            rawCandidates{end + 1} = ...
                makeCandidate(openIndex, closeIndex); %#ok<AGROW>
            openIndex = openIndex - pastafari.BigInt(1);
        end

        [ctx, candidates] = ...
            pastafari.YearCandidateCompatibilityRoute.call( ...
                ctx, rawCandidates);
        if isempty(candidates)
            error('Pastafari:Integration:PreviousYearCandidates', ...
                'Nie znaleziono kandydata na poprzedni rok.');
        end
        candidates = stableLengthSort(candidates);

        sauceResult = sauceOnCurrentContext(cDay, closeDay);
        rank = chooseFromSauce(sauceResult, 1, 12, ...
            pastafari.BigInt(numel(candidates)));
        chosen = candidates{rank.toDoubleExact()};
        year = makeYear(pastafari.BigInt.coerce(knownYear.number) - ...
            pastafari.BigInt(1), chosen.openGateIndex, chosen.closeGateIndex);
    end

    function structure = buildYearStructure(yearValue)
        [ctx, structureSauce] = ...
            pastafari.StructureSauceCompatibilityRoute.call( ...
                ctx, cDay, tDay, yearValue);

        gapCount = pastafari.BigInt.coerce(yearValue.closeGateIndex) - ...
            pastafari.BigInt.coerce(yearValue.openGateIndex);
        cutletCandidates = [];
        for k = 6:17
            if pastafari.BigInt(k) <= gapCount
                cutletCandidates(end + 1) = k; %#ok<AGROW>
            end
        end
        if isempty(cutletCandidates)
            error('Pastafari:Integration:CutletCountCandidates', ...
                'Brak dopuszczalnej liczby kotletów.');
        end

        cutletCountRank = chooseFromSauce( ...
            structureSauce, 2, 20, ...
            pastafari.BigInt(numel(cutletCandidates)));
        cutletCount = cutletCandidates(cutletCountRank.toDoubleExact());

        internalGateOffset = [];
        exactGate = exactGateIndex(cDay);
        if ~isempty(exactGate) && ...
                pastafari.BigInt.coerce(yearValue.openGateIndex) < exactGate && ...
                exactGate < pastafari.BigInt.coerce(yearValue.closeGateIndex)
            internalGateOffset = exactGate - ...
                pastafari.BigInt.coerce(yearValue.openGateIndex);
        end

        partitionStream = streamFromSauce(structureSauce, 2, 21);
        [ctx, cutletPartition] = ...
            pastafari.CutletPartitionCompatibilityRoute.call( ...
                ctx, partitionStream, gapCount, ...
                pastafari.BigInt(cutletCount), internalGateOffset);

        [ctx, cutletNameIndices] = ...
            pastafari.CutletNameCompatibilityRoute.call( ...
                ctx, structureSauce, pastafari.BigInt(cutletCount));
        cutlets = materializeCutlets( ...
            yearValue, cutletPartition, cutletNameIndices);

        totalDays = pastafari.BigInt.coerce(yearValue.closeGateDay) - ...
            pastafari.BigInt.coerce(yearValue.openGateDay);
        minMonths = ceilDivNonnegative( ...
            totalDays, pastafari.BigInt(123)).toDoubleExact();
        maxMonths = min(47, ...
            totalDays.floorDiv(pastafari.BigInt(4)).toDoubleExact());
        if minMonths < 3 || minMonths > maxMonths || maxMonths > 47
            error('Pastafari:Integration:MonthCountBounds', ...
                'Granice liczby miesięcy naruszają specyfikację.');
        end
        monthCandidates = minMonths:maxMonths;
        monthCountRank = chooseFromSauce( ...
            structureSauce, 3, 30, ...
            pastafari.BigInt(numel(monthCandidates)));
        monthCount = monthCandidates(monthCountRank.toDoubleExact());

        [ctx, monthLengths] = ...
            pastafari.MonthLengthCompatibilityRoute.call( ...
                ctx, structureSauce, totalDays, ...
                pastafari.BigInt(monthCount));
        [ctx, monthWeaving] = ...
            pastafari.MonthWeavingCompatibilityRoute.call( ...
                ctx, structureSauce, monthLengths);
        [ctx, monthNameIndices] = ...
            pastafari.MonthNameCompatibilityRoute.call( ...
                ctx, structureSauce, pastafari.BigInt(monthCount));

        structure = struct( ...
            'cutletCount', cutletCount, ...
            'cutletPartition', cutletPartition, ...
            'cutletNameIndices', cutletNameIndices, ...
            'cutlets', cutlets, ...
            'monthCount', monthCount, ...
            'monthLengths', monthLengths, ...
            'monthWeaving', monthWeaving, ...
            'monthNameIndices', monthNameIndices);
    end

    function sauceResult = sauceOnCurrentContext(c, t)
        [ctx, counts] = pastafari.WorkCountsCompatibilityRoute.call( ...
            ctx, c, t);
        [ctx, stones] = pastafari.StoneTableCompatibilityRoute.call(ctx);
        [ctx, hidden] = pastafari.HiddenCompatibilityRoute.call( ...
            ctx, counts, stones);
        [ctx, priorVisible] = ...
            pastafari.VisibleDropCompatibilityRoute.call( ...
                ctx, counts, stones, hidden);
        [ctx, visible] = pastafari.GrindTableCompatibilityRoute.call( ...
            ctx, counts, stones, hidden, priorVisible);

        % PATCH 08 ma pozostać obserwowalny również w zintegrowanej trasie.
        [ctx, ~] = pastafari.PermutationCompatibilityRoute.call( ...
            ctx, visible{1}); %#ok<ASGLU>

        [ctx, preInPlaceBowls] = ...
            pastafari.BowlPourCompatibilityRoute.call( ...
                ctx, counts, stones, visible);
        [ctx, bowlsAfterDrop46] = ...
            pastafari.BowlStirCompatibilityRoute.call( ...
                ctx, counts, stones, visible, preInPlaceBowls);
        [ctx, finalBowls, orderAt46] = ...
            pastafari.OrderAt46CompatibilityRoute.call( ...
                ctx, visible, bowlsAfterDrop46);

        sauceResult = struct( ...
            'calculationDay', pastafari.BigInt.coerce(c), ...
            'targetDay', pastafari.BigInt.coerce(t), ...
            'bowls', {finalBowls}, ...
            'orderAt46Latch', orderAt46, ...
            'bowl2', finalBowls{2});
    end

    function stream = streamFromSauce(sauceResult, bowlId, seal)
        [ctx, nextBowlId] = pastafari.NextBowlCompatibilityRoute.call( ...
            ctx, sauceResult.orderAt46Latch, bowlId);
        stream = pastafari.AnswerRingStreamFactory.fromSauce( ...
            sauceResult.bowls, bowlId, nextBowlId, seal);
    end

    function rank = chooseFromSauce(sauceResult, bowlId, seal, N)
        stream = streamFromSauce(sauceResult, bowlId, seal);
        [ctx, rank] = pastafari.GeneralSelectionCompatibilityRoute.call( ...
            ctx, stream, N);
    end

    function ensureGatesCover(lowDay, highDay)
        low = pastafari.BigInt.coerce(lowDay);
        high = pastafari.BigInt.coerce(highDay);
        if low > high
            error('Pastafari:Integration:GateCoverOrder', ...
                'Dolna granica zakresu bram nie może przekraczać górnej.');
        end

        while true
            if gateDay(minKnownGate) > low
                ensureGateIndex(minKnownGate - pastafari.BigInt(1));
                continue
            end
            if gateDay(maxKnownGate) < high
                ensureGateIndex(maxKnownGate + pastafari.BigInt(1));
                continue
            end
            break
        end
    end

    function ensureGateIndex(index)
        index = pastafari.BigInt.coerce(index);
        if index > maxKnownGate
            n = maxKnownGate + pastafari.BigInt(1);
            while n <= index
                [ctx, gap] = pastafari.GateGapCompatibilityRoute.call(ctx, n);
                gateMap(char(n)) = gateDay(n - pastafari.BigInt(1)) + gap;
                maxKnownGate = n;
                n = n + pastafari.BigInt(1);
            end
        elseif index < minKnownGate
            n = minKnownGate - pastafari.BigInt(1);
            while n >= index
                [ctx, gap] = pastafari.GateGapCompatibilityRoute.call(ctx, n);
                gateMap(char(n)) = gateDay(n + pastafari.BigInt(1)) - gap;
                minKnownGate = n;
                n = n - pastafari.BigInt(1);
            end
        end
    end

    function day = gateDay(index)
        index = pastafari.BigInt.coerce(index);
        key = char(index);
        if ~isKey(gateMap, key)
            ensureGateIndex(index);
        end
        day = gateMap(key);
    end

    function index = gateIndexAtOrBefore(dayValue)
        dayValue = pastafari.BigInt.coerce(dayValue);
        ensureGatesCover(dayValue, dayValue);
        lo = minKnownGate;
        hi = maxKnownGate;
        while lo < hi
            mid = lo + (hi - lo + pastafari.BigInt(1)).floorDiv( ...
                pastafari.BigInt(2));
            if gateDay(mid) <= dayValue
                lo = mid;
            else
                hi = mid - pastafari.BigInt(1);
            end
        end
        index = lo;
    end

    function index = exactGateIndex(dayValue)
        candidateIndex = gateIndexAtOrBefore(dayValue);
        if gateDay(candidateIndex) == pastafari.BigInt.coerce(dayValue)
            index = candidateIndex;
        else
            index = [];
        end
    end

    function candidate = makeCandidate(openIndex, closeIndex)
        candidate = struct( ...
            'openGateIndex', pastafari.BigInt.coerce(openIndex), ...
            'closeGateIndex', pastafari.BigInt.coerce(closeIndex), ...
            'openGateDay', gateDay(openIndex), ...
            'closeGateDay', gateDay(closeIndex));
    end

    function yearValue = makeYear(number, openIndex, closeIndex)
        yearValue = makeCandidate(openIndex, closeIndex);
        yearValue.number = pastafari.BigInt.coerce(number);
    end

    function ordered = stableLengthSort(candidates)
        ordered = candidates;
        for i = 2:numel(ordered)
            current = ordered{i};
            currentLength = pastafari.BigInt.coerce(current.closeGateDay) - ...
                pastafari.BigInt.coerce(current.openGateDay);
            j = i - 1;
            while j >= 1
                priorLength = ...
                    pastafari.BigInt.coerce(ordered{j}.closeGateDay) - ...
                    pastafari.BigInt.coerce(ordered{j}.openGateDay);
                if priorLength <= currentLength
                    break
                end
                ordered{j + 1} = ordered{j};
                j = j - 1;
            end
            ordered{j + 1} = current;
        end
    end

    function cutlets = materializeCutlets(yearValue, partition, nameIndices)
        cursorGate = pastafari.BigInt.coerce(yearValue.openGateIndex);
        count = numel(partition);
        cutlets = repmat(struct( ...
            'nameIndex', 0, ...
            'openGateIndex', pastafari.BigInt(0), ...
            'closeGateIndex', pastafari.BigInt(0), ...
            'firstDay', pastafari.BigInt(0), ...
            'lastDay', pastafari.BigInt(0)), 1, count);

        for k = 1:count
            openIndex = cursorGate;
            closeIndex = cursorGate + pastafari.BigInt(partition(k));
            cutlets(k).nameIndex = nameIndices(k);
            cutlets(k).openGateIndex = openIndex;
            cutlets(k).closeGateIndex = closeIndex;
            cutlets(k).firstDay = gateDay(openIndex) + pastafari.BigInt(1);
            cutlets(k).lastDay = gateDay(closeIndex);
            cursorGate = closeIndex;
        end

        if cursorGate ~= pastafari.BigInt.coerce(yearValue.closeGateIndex)
            error('Pastafari:Integration:CutletCoverage', ...
                'Podział kotletów nie kończy się na closing gate roku.');
        end
    end

    function [cutlet, cutletId] = cutletAtTarget(cutlets, target)
        cutlet = [];
        cutletId = 0;
        for k = 1:numel(cutlets)
            if cutlets(k).firstDay <= target && target <= cutlets(k).lastDay
                cutlet = cutlets(k);
                cutletId = k;
                return
            end
        end
        error('Pastafari:Integration:CutletMissing', ...
            'Nie znaleziono kotleta zawierającego dzień pytany.');
    end

    function q = ceilDivNonnegative(a, b)
        a = pastafari.BigInt.coerce(a);
        b = pastafari.BigInt.coerce(b);
        if a < pastafari.BigInt(0) || b <= pastafari.BigInt(0)
            error('Pastafari:Integration:CeilDivDomain', ...
                'ceilDivNonnegative wymaga a>=0 i b>0.');
        end
        q = (a + b - pastafari.BigInt(1)).floorDiv(b);
    end
end
