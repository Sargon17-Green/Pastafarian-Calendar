function varargout = normative_oracle(operation, varargin)
% Czyste, testowe źródło odniesienia wynikające wyłącznie z Appendix A.
% Ten plik nie jest częścią ścieżki produkcyjnej i nie wolno go używać jako ścieżki awaryjnej.

switch operation
    case 'calendar'
        varargout{1} = calendarDate(varargin{1}, varargin{2});
    case 'SAVE'
        varargout{1} = saveValue(varargin{1});
    case 'dayCount'
        varargout{1} = dayCount(varargin{1});
    case 'workCounts'
        varargout{1} = workCounts(varargin{1}, varargin{2});
    case 'stones'
        varargout{1} = stoneTable();
    case 'permutation'
        varargout{1} = bowlOrderFromNumber(varargin{1});
    case 'sauce'
        varargout{1} = sauce(varargin{1}, varargin{2});
    case 'chooseRank'
        varargout{1} = chooseRank(varargin{1}, varargin{2});
    case 'resetGates'
        gateStore('reset');
    otherwise
        error('Pastafari:Oracle:UnknownOperation', 'Nieznana operacja testowego źródła odniesienia.');
end
end

function out = bi(x)
out = pastafari.BigInt.coerce(x);
end

function out = mConst()
out = pastafari.BigInt('170141183460469231731687303715884105727');
end

function out = foundationDay()
out = pastafari.BigInt('-15055671');
end

function out = saveValue(x)
M = mConst();
out = bi(1) + (bi(x) - bi(1)).regularMod(M);
end

function out = ceilDivNonnegative(a, b)
a = bi(a); b = bi(b);
out = (a + b - bi(1)).floorDiv(b);
end

function counts = workCounts(calculationDay, targetDay)
c = dayCount(calculationDay);
t = dayCount(targetDay);
distance = abs(bi(targetDay) - bi(calculationDay)) + bi(1);
connection = c + t;
if bi(targetDay) < bi(calculationDay)
    direction = 1;
elseif bi(targetDay) == bi(calculationDay)
    direction = 2;
else
    direction = 3;
end
counts = struct('action', c, 'target', t, 'distance', distance, ...
    'connection', connection, 'direction', direction);
end

function out = dayCount(day)
d = bi(day);
f = foundationDay();
if d == f
    out = bi(1);
elseif d > f
    out = bi(2) * (d - f) + bi(1);
else
    out = bi(2) * (f - d);
end
end

function stones = stoneTable()
persistent cached
if ~isempty(cached)
    stones = cached;
    return
end
stones = cell(46, 5);
stones(1, :) = {bi(17), bi(29), bi(43), bi(71), bi(101)};
for i = 2:46
    old = stones(i - 1, :);
    stones{i, 1} = saveValue(old{1}.square() + bi(3) * old{2} + bi(i));
    stones{i, 2} = saveValue(old{2}.square() + bi(5) * old{3} + old{1});
    stones{i, 3} = saveValue(old{3}.square() + bi(7) * old{4} + old{2});
    stones{i, 4} = saveValue(old{4}.square() + bi(11) * old{5} + old{3});
    stones{i, 5} = saveValue(old{5}.square() + bi(13) * old{1} + old{4});
end
cached = stones;
end

function hidden = buildHiddenDrops(counts, stones)
coeff = [3 4 6 8; 5 7 10 12; 7 10 14 16; 9 13 18 20; ...
    11 16 22 24; 13 19 26 28; 15 22 30 32];
grindStone = [1 2 3 4 5 1 2];
hidden = cell(1, 7);
for k = 1:7
    a = coeff(k, 1); b = coeff(k, 2); c = coeff(k, 3); d = coeff(k, 4);
    x = counts.action + bi(a) * counts.target + bi(b) * counts.distance + ...
        bi(c) * counts.connection + bi(d) * bi(counts.direction);
    for kind = 1:5
        x = x + stones{k, kind};
    end
    x = saveValue(x);
    for grind = 1:7
        oldX = x;
        x = saveValue(oldX.square() + bi(3) * oldX + stones{k, grindStone(grind)} + bi(grind));
    end
    hidden{k} = x;
end
end

function visible = buildVisibleDrops(counts, stones, hidden)
% Indeksy 1..7 pierwszych komórek osi odpowiadają pozycjom -6..0.
timeline = cell(1, 53);
for k = 1:7
    timeline{8 - k} = hidden{k};
end
visible = cell(1, 46);
grinds = [ ...
    3 5 7 11 1; ...
    5 7 11 13 2; ...
    7 11 13 17 3; ...
    11 13 17 19 4; ...
    13 17 19 23 5; ...
    17 19 23 29 1; ...
    19 23 29 31 2; ...
    23 29 31 37 3; ...
    29 31 37 41 4; ...
    31 37 41 43 5; ...
    37 41 43 47 1];
for i = 1:46
    p1 = timeline{i + 6};
    p3 = timeline{i + 4};
    p7 = timeline{i};
    x = saveValue(stones{i, 1} * counts.action + stones{i, 2} * counts.target + ...
        stones{i, 3} * counts.distance + stones{i, 4} * counts.connection + ...
        stones{i, 5} * bi(counts.direction) + p1 + bi(3) * p3 + bi(5) * p7 + bi(i));
    for grind = 1:11
        oldX = x;
        row = grinds(grind, :);
        x = saveValue(oldX.square() + bi(row(1)) * oldX + bi(row(2)) * p1 + ...
            bi(row(3)) * p3 + bi(row(4)) * p7 + stones{i, row(5)});
    end
    visible{i} = x;
    timeline{i + 7} = x;
end
end

function order = permutationUnrank1(rank1, itemsAscending)
if isa(rank1, 'pastafari.BigInt')
    rank1 = rank1.toDoubleExact();
end
rank0 = rank1 - 1;
remaining = itemsAscending;
order = zeros(1, numel(itemsAscending));
for pos = 1:numel(itemsAscending)
    slotsLeft = numel(remaining);
    block = factorial(slotsLeft - 1);
    q = floor(rank0 / block);
    rank0 = mod(rank0, block);
    order(pos) = remaining(q + 1);
    remaining(q + 1) = [];
end
end

function order = bowlOrderFromNumber(orderNumber)
if isa(orderNumber, 'pastafari.BigInt')
    orderNumber = orderNumber.toDoubleExact();
end
if orderNumber < 1 || orderNumber > 720 || fix(orderNumber) ~= orderNumber
    error('Pastafari:Oracle:BowlOrder', 'Numer porządku mis musi należeć do zakresu 1..720.');
end
order = permutationUnrank1(orderNumber, 1:6);
end

function order = bowlOrderFromDrop(dropValue)
number = (bi(dropValue) - bi(1)).regularMod(bi(720)) + bi(1);
order = bowlOrderFromNumber(number);
end

function bowls = initialBowls(counts)
primes = [17 19 23 29 31 37];
bowls = cell(1, 6);
for id = 1:6
    s = counts.action + counts.target * bi(id) + counts.distance + counts.connection + ...
        bi(counts.direction) + bi(primes(id) * primes(id));
    bowls{id} = saveValue(s.square() + bi(id));
end
end

function [bowls, orderAt46] = applyVisibleDropsToBowls(bowls, visible, stones)
stoneByPosition = [1 2 3 4 5 1];
orderAt46 = [];
for i = 1:46
    drop = visible{i};
    order = bowlOrderFromDrop(drop);
    old = bowls;
    pours = {bi(0), bi(0), bi(0), bi(0), bi(0), bi(0)};
    pours{1} = saveValue(drop.square() + stones{i, 1} * old{order(1)} + bi(3 * i));
    pours{2} = saveValue(drop.square() + stones{i, 2} * old{order(2)} + bi(5 * i));
    pours{3} = saveValue(drop.square() + stones{i, 3} * old{order(3)} + bi(7 * i));
    nextBowls = cell(1, 6);
    for position = 1:6
        id = order(position);
        prev = order(wrap1(position - 1, 6));
        next = order(wrap1(position + 1, 6));
        s = old{id} + bi(2) * old{prev} + bi(3) * old{next} + pours{position} + ...
            drop + stones{i, stoneByPosition(position)};
        nextBowls{id} = saveValue(s.square() + bi(5) * old{prev} * old{next} + bi(i * position));
    end
    bowls = nextBowls;
    if i == 46
        orderAt46 = order;
    end
end
end

function bowls = postStir12(bowls)
for stir = 1:12
    old = bowls;
    savedStirSum = bi(0);
    for id = 1:6
        savedStirSum = savedStirSum + old{id};
    end
    savedStirSum = saveValue(savedStirSum + bi(149 * stir));
    orderNumber = (savedStirSum - bi(1)).regularMod(bi(720)) + bi(1);
    order = bowlOrderFromNumber(orderNumber);
    nextBowls = cell(1, 6);
    for position = 1:6
        id = order(position);
        prev = order(wrap1(position - 1, 6));
        next = order(wrap1(position + 1, 6));
        s = old{id} + bi(3) * old{prev} + bi(5) * old{next} + savedStirSum + ...
            bi(stir) + bi(position * position);
        nextBowls{id} = saveValue(s.square() + bi(7) * old{prev} * old{next});
    end
    bowls = nextBowls;
end
end

function result = sauce(calculationDay, targetDay)
counts = workCounts(calculationDay, targetDay);
stones = stoneTable();
hidden = buildHiddenDrops(counts, stones);
visible = buildVisibleDrops(counts, stones, hidden);
bowls = initialBowls(counts);
[bowls, orderAt46] = applyVisibleDropsToBowls(bowls, visible, stones);
finalBowls = postStir12(bowls);
result = struct('bowls', {finalBowls}, 'orderAtDrop46', orderAt46);
end

function idx = wrap1(position, sizeValue)
idx = mod(position - 1, sizeValue) + 1;
end

function nextId = nextBowlInDrop46Order(sauceResult, queriedBowlId)
order = sauceResult.orderAtDrop46;
p = find(order == queriedBowlId, 1, 'first');
if isempty(p)
    error('Pastafari:Oracle:QueriedBowl', 'Nie znaleziono pytanej misy w porządku kropli 46.');
end
nextId = order(wrap1(p + 1, 6));
end

function stream = askBowl(sauceResult, queriedBowlId, seal)
nextId = nextBowlInDrop46Order(sauceResult, queriedBowlId);
first = saveValue((sauceResult.bowls{queriedBowlId} + bi(seal) + bi(181)).square() + ...
    bi(179) * sauceResult.bowls{nextId} + bi(seal));
directionNumber = saveValue((first + bi(seal) + bi(1) + bi(193)).square() + ...
    bi(193) * first + bi(197) * sauceResult.bowls{6});
if directionNumber.regularMod(bi(2)) == bi(1)
    step = 1;
else
    step = -1;
end
stream = struct('first', first, 'directionStep', step);
end

function answer = answerAt(stream, k)
answer = bi(1) + (stream.first - bi(1) + bi(stream.directionStep) * bi(k)).regularMod(mConst());
end

function rank = chooseRankShort(stream, N)
N = bi(N);
M = mConst();
if N < bi(1) || N > M
    error('Pastafari:Oracle:ShortChoice', 'Krótki wybór wymaga 1 <= N <= M.');
end
acceptanceLimit = M.floorDiv(N) * N;
k = bi(0);
while true
    x = answerAt(stream, k);
    if x <= acceptanceLimit
        rank = (x - bi(1)).regularMod(N) + bi(1);
        return
    end
    k = k + bi(1);
end
end

function rank = chooseRankWide(stream, N)
N = bi(N);
M = mConst();
if N <= M
    error('Pastafari:Oracle:WideChoice', 'Szeroki wybór wymaga N > M.');
end
places = 1;
space = M;
while space < N
    places = places + 1;
    space = space * M;
end
wide = bi(1);
weight = bi(1);
for j = 0:places-1
    digit = answerAt(stream, j) - bi(1);
    wide = wide + digit * weight;
    weight = weight * M;
end
acceptanceLimit = space.floorDiv(N) * N;
w = wide;
while true
    if w <= acceptanceLimit
        rank = (w - bi(1)).regularMod(N) + bi(1);
        return
    end
    w = bi(1) + (w - bi(1) + bi(stream.directionStep)).regularMod(space);
end
end

function rank = chooseRank(stream, N)
N = bi(N);
if N < bi(1)
    error('Pastafari:Oracle:ChoiceSize', 'Liczba dróg wyboru musi być dodatnia.');
end
if N <= mConst()
    rank = chooseRankShort(stream, N);
else
    rank = chooseRankWide(stream, N);
end
end

function result = fallingFactorial(n, k)
result = bi(1);
for j = 0:k-1
    result = result * bi(n - j);
end
end

function out = unrankDistinctIndices(masterCount, k, rank1)
remaining = 1:masterCount;
out = zeros(1, k);
r = bi(rank1);
for position = 1:k
    suffixLength = k - position;
    block = fallingFactorial(numel(remaining) - 1, suffixLength);
    for candidate = 1:numel(remaining)
        if r > block
            r = r - block;
        else
            out(position) = remaining(candidate);
            remaining(candidate) = [];
            break
        end
    end
end
end

function gap = positiveGateGap(n)
r = sauce(foundationDay(), foundationDay() + bi(n));
stream = askBowl(r, 1, 1);
chosen = chooseRank(stream, 922);
gap = bi(41) + chosen;
end

function gap = negativeGateGap(n)
r = sauce(foundationDay(), foundationDay() - bi(n));
stream = askBowl(r, 1, 1);
chosen = chooseRank(stream, 922);
gap = bi(41) + chosen;
end

function varargout = gateStore(action, varargin)
persistent map minKnown maxKnown
if isempty(map) || strcmp(action, 'reset')
    map = containers.Map('KeyType', 'char', 'ValueType', 'any');
    map('0') = foundationDay();
    minKnown = bi(0);
    maxKnown = bi(0);
    if strcmp(action, 'reset')
        return
    end
end
switch action
    case 'get'
        key = char(bi(varargin{1}));
        if ~isKey(map, key)
            error('Pastafari:Oracle:GateMissing', 'Żądana brama nie została jeszcze wyznaczona.');
        end
        varargout{1} = map(key);
    case 'set'
        idx = bi(varargin{1});
        map(char(idx)) = bi(varargin{2});
        if idx < minKnown, minKnown = idx; end
        if idx > maxKnown, maxKnown = idx; end
    case 'bounds'
        varargout{1} = minKnown;
        varargout{2} = maxKnown;
    otherwise
        error('Pastafari:Oracle:GateStoreAction', 'Nieznana operacja magazynu bram.');
end
end

function day = ensureGateIndex(k)
k = bi(k);
[minKnown, maxKnown] = gateStore('bounds');
if k > maxKnown
    n = maxKnown + bi(1);
    while n <= k
        prev = gateStore('get', n - bi(1));
        gateStore('set', n, prev + positiveGateGap(n));
        n = n + bi(1);
    end
elseif k < minKnown
    n = minKnown - bi(1);
    while n >= k
        next = gateStore('get', n + bi(1));
        gateStore('set', n, next - negativeGateGap(abs(n)));
        n = n - bi(1);
    end
end
day = gateStore('get', k);
end

function ensureGatesCover(lowDay, highDay)
lowDay = bi(lowDay); highDay = bi(highDay);
if lowDay > highDay
    error('Pastafari:Oracle:GateCover', 'Dolna granica zakresu bram nie może przekraczać górnej.');
end
while true
    [minKnown, maxKnown] = gateStore('bounds');
    if gateStore('get', minKnown) > lowDay
        ensureGateIndex(minKnown - bi(1));
        continue
    end
    if gateStore('get', maxKnown) < highDay
        ensureGateIndex(maxKnown + bi(1));
        continue
    end
    break
end
end

function idx = gateIndexAtOrBefore(day)
day = bi(day);
ensureGatesCover(day, day);
[lo, hi] = gateStore('bounds');
while lo < hi
    mid = lo + (hi - lo + bi(1)).floorDiv(bi(2));
    if gateStore('get', mid) <= day
        lo = mid;
    else
        hi = mid - bi(1);
    end
end
idx = lo;
end

function idx = exactGateIndex(day)
i = gateIndexAtOrBefore(day);
if gateStore('get', i) == bi(day)
    idx = i;
else
    idx = [];
end
end

function tf = validYearPair(openIndex, closeIndex)
openIndex = bi(openIndex); closeIndex = bi(closeIndex);
if closeIndex - openIndex < bi(6)
    tf = false;
    return
end
L = gateStore('get', closeIndex) - gateStore('get', openIndex);
tf = L >= bi(252) && L <= bi(5778);
end

function candidates = sortYearCandidates(candidates, tieByOpening)
for i = 2:numel(candidates)
    x = candidates{i};
    j = i - 1;
    while j >= 1 && yearCandidateGreater(candidates{j}, x, tieByOpening)
        candidates{j + 1} = candidates{j};
        j = j - 1;
    end
    candidates{j + 1} = x;
end
end

function tf = yearCandidateGreater(a, b, tieByOpening)
la = gateStore('get', a.close) - gateStore('get', a.open);
lb = gateStore('get', b.close) - gateStore('get', b.open);
if la > lb
    tf = true;
elseif la < lb
    tf = false;
elseif tieByOpening
    tf = gateStore('get', a.open) > gateStore('get', b.open);
else
    tf = false;
end
end

function year = year5000(calculationDay)
c = bi(calculationDay);
ensureGatesCover(c - bi(5778), c + bi(5778));
[minKnown, maxKnown] = gateStore('bounds');
candidates = {};
i = minKnown;
while i < maxKnown
    j = i + bi(1);
    while j <= maxKnown
        if gateStore('get', j) - gateStore('get', i) > bi(5778)
            break
        end
        if validYearPair(i, j) && gateStore('get', i) < c && c <= gateStore('get', j)
            candidates{end + 1} = struct('open', i, 'close', j); %#ok<AGROW>
        end
        j = j + bi(1);
    end
    i = i + bi(1);
end
if isempty(candidates)
    error('Pastafari:Oracle:Year5000Candidates', 'Nie znaleziono kandydata na rok 5000.');
end
candidates = sortYearCandidates(candidates, true);
r = sauce(c, c);
stream = askBowl(r, 1, 10);
rank = chooseRank(stream, numel(candidates)).toDoubleExact();
chosen = candidates{rank};
year = makeYear(5000, chosen.open, chosen.close);
end

function year = makeYear(number, openIndex, closeIndex)
year = struct('number', bi(number), 'openGateIndex', bi(openIndex), ...
    'closeGateIndex', bi(closeIndex), 'openGateDay', gateStore('get', openIndex), ...
    'closeGateDay', gateStore('get', closeIndex));
end

function year = nextYear(calculationDay, knownYear)
openIndex = knownYear.closeGateIndex;
ensureGatesCover(gateStore('get', openIndex), gateStore('get', openIndex) + bi(5778));
candidates = {};
closeIndex = openIndex + bi(1);
while true
    ensureGateIndex(closeIndex);
    if gateStore('get', closeIndex) - gateStore('get', openIndex) > bi(5778)
        break
    end
    if validYearPair(openIndex, closeIndex)
        candidates{end + 1} = struct('open', openIndex, 'close', closeIndex); %#ok<AGROW>
    end
    closeIndex = closeIndex + bi(1);
end
if isempty(candidates)
    error('Pastafari:Oracle:NextYearCandidates', 'Nie znaleziono kandydata na następny rok.');
end
candidates = sortYearCandidates(candidates, false);
r = sauce(calculationDay, gateStore('get', openIndex));
stream = askBowl(r, 1, 11);
rank = chooseRank(stream, numel(candidates)).toDoubleExact();
chosen = candidates{rank};
year = makeYear(knownYear.number + bi(1), chosen.open, chosen.close);
end

function year = previousYear(calculationDay, knownYear)
closeIndex = knownYear.openGateIndex;
ensureGatesCover(gateStore('get', closeIndex) - bi(5778), gateStore('get', closeIndex));
candidates = {};
openIndex = closeIndex - bi(1);
while true
    ensureGateIndex(openIndex);
    if gateStore('get', closeIndex) - gateStore('get', openIndex) > bi(5778)
        break
    end
    if validYearPair(openIndex, closeIndex)
        candidates{end + 1} = struct('open', openIndex, 'close', closeIndex); %#ok<AGROW>
    end
    openIndex = openIndex - bi(1);
end
if isempty(candidates)
    error('Pastafari:Oracle:PreviousYearCandidates', 'Nie znaleziono kandydata na poprzedni rok.');
end
candidates = sortYearCandidates(candidates, false);
r = sauce(calculationDay, gateStore('get', closeIndex));
stream = askBowl(r, 1, 12);
rank = chooseRank(stream, numel(candidates)).toDoubleExact();
chosen = candidates{rank};
year = makeYear(knownYear.number - bi(1), chosen.open, chosen.close);
end

function year = findTargetYear(calculationDay, targetDay)
year = year5000(calculationDay);
t = bi(targetDay);
while t > year.closeGateDay
    year = nextYear(calculationDay, year);
end
while t <= year.openGateDay
    year = previousYear(calculationDay, year);
end
if ~(year.openGateDay < t && t <= year.closeGateDay)
    error('Pastafari:Oracle:TargetYearInvariant', 'Dzień pytany nie należy do wyznaczonego przedziału roku.');
end
end

function cutletCount = chooseCutletCount(structureSauce, year)
gateGaps = year.closeGateIndex - year.openGateIndex;
candidates = [];
for k = 6:17
    if bi(k) <= gateGaps
        candidates(end + 1) = k; %#ok<AGROW>
    end
end
if isempty(candidates)
    error('Pastafari:Oracle:CutletCountCandidates', 'Brak dopuszczalnej liczby kotletów.');
end
stream = askBowl(structureSauce, 2, 20);
rank = chooseRank(stream, numel(candidates)).toDoubleExact();
cutletCount = candidates(rank);
end

function family = makeCutletPartitionFamily(G, K, requiredBoundary)
G = double(G);
K = double(K);
if isempty(requiredBoundary)
    requiredValue = -1;
else
    requiredValue = double(requiredBoundary);
end
memo = containers.Map('KeyType', 'char', 'ValueType', 'any');
family = struct();
family.count = @countAll;
family.unrank1 = @unrank1;

    function total = countAll()
        total = countState(G, K, 0, false);
    end

    function total = countState(rem, slots, cumulative, hitBoundary)
        if slots == 0
            if rem ~= 0
                total = bi(0);
            elseif requiredValue < 0 || hitBoundary
                total = bi(1);
            else
                total = bi(0);
            end
            return
        end
        if rem < slots
            total = bi(0);
            return
        end
        key = sprintf('%d|%d|%d|%d', rem, slots, cumulative, hitBoundary);
        if isKey(memo, key)
            total = memo(key);
            return
        end
        total = bi(0);
        maxX = rem - (slots - 1);
        for x = 1:maxX
            nextCumulative = cumulative + x;
            nextHit = hitBoundary;
            if requiredValue >= 0 && ~hitBoundary
                if nextCumulative == requiredValue
                    nextHit = true;
                elseif nextCumulative > requiredValue
                    continue
                end
            end
            total = total + countState(rem - x, slots - 1, nextCumulative, nextHit);
        end
        memo(key) = total;
    end

    function out = unrank1(rank1)
        total = countAll();
        r = bi(rank1);
        if r < bi(1) || r > total
            error('Pastafari:Oracle:CutletPartitionRank', 'Ranga podziału kotletów jest poza zakresem.');
        end
        rem = G;
        slots = K;
        cumulative = 0;
        hit = false;
        out = zeros(1, K);
        position = 1;
        while slots > 0
            maxX = rem - (slots - 1);
            selected = false;
            for x = 1:maxX
                nextCumulative = cumulative + x;
                nextHit = hit;
                if requiredValue >= 0 && ~hit
                    if nextCumulative == requiredValue
                        nextHit = true;
                    elseif nextCumulative > requiredValue
                        continue
                    end
                end
                block = countState(rem - x, slots - 1, nextCumulative, nextHit);
                if r > block
                    r = r - block;
                else
                    out(position) = x;
                    rem = rem - x;
                    slots = slots - 1;
                    cumulative = nextCumulative;
                    hit = nextHit;
                    position = position + 1;
                    selected = true;
                    break
                end
            end
            if ~selected
                error('Pastafari:Oracle:CutletPartitionUnrank', 'Nie udało się rozwinąć rangi podziału kotletów.');
            end
        end
    end
end

function partition = chooseCutletPartition(calculationDay, structureSauce, year, cutletCount)
Gbi = year.closeGateIndex - year.openGateIndex;
G = Gbi.toDoubleExact();
g = exactGateIndex(calculationDay);
required = [];
if ~isempty(g) && year.openGateIndex < g && g < year.closeGateIndex
    required = (g - year.openGateIndex).toDoubleExact();
end
family = makeCutletPartitionFamily(G, cutletCount, required);
count = family.count();
if count < bi(1)
    error('Pastafari:Oracle:CutletPartitionEmpty', 'Rodzina podziałów kotletów jest pusta.');
end
stream = askBowl(structureSauce, 2, 21);
rank = chooseRank(stream, count);
partition = family.unrank1(rank);
end

function nameIndices = chooseCutletNames(structureSauce, cutletCount)
N = fallingFactorial(17, cutletCount);
stream = askBowl(structureSauce, 5, 22);
rank = chooseRank(stream, N);
nameIndices = unrankDistinctIndices(17, cutletCount, rank);
end

function cutlets = materializeCutlets(year, partition, nameIndices)
cursorGate = year.openGateIndex;
cutlets = repmat(struct('nameIndex', 0, 'openGateIndex', bi(0), ...
    'closeGateIndex', bi(0), 'firstDay', bi(0), 'lastDay', bi(0)), 1, numel(partition));
for k = 1:numel(partition)
    openGateIndex = cursorGate;
    closeGateIndex = cursorGate + bi(partition(k));
    cutlets(k).nameIndex = nameIndices(k);
    cutlets(k).openGateIndex = openGateIndex;
    cutlets(k).closeGateIndex = closeGateIndex;
    cutlets(k).firstDay = gateStore('get', openGateIndex) + bi(1);
    cutlets(k).lastDay = gateStore('get', closeGateIndex);
    cursorGate = closeGateIndex;
end
end

function monthCount = chooseMonthCount(structureSauce, year)
L = year.closeGateDay - year.openGateDay;
minMonths = ceilDivNonnegative(L, 123).toDoubleExact();
maxMonths = min(47, L.floorDiv(bi(4)).toDoubleExact());
if minMonths < 3 || minMonths > maxMonths || maxMonths > 47
    error('Pastafari:Oracle:MonthCountBounds', 'Granice liczby miesięcy naruszają specyfikację.');
end
candidates = minMonths:maxMonths;
stream = askBowl(structureSauce, 3, 30);
rank = chooseRank(stream, numel(candidates)).toDoubleExact();
monthCount = candidates(rank);
end

function family = makeBoundedCompositionFamily(total, slots, lo, hi)
total = double(total);
slots = double(slots);
lo = double(lo);
hi = double(hi);
memo = containers.Map('KeyType', 'char', 'ValueType', 'any');
family = struct();
family.count = @countAll;
family.unrank1 = @unrank1;

    function totalCount = countAll()
        totalCount = countState(total, slots);
    end

    function totalCount = countState(rem, k)
        if k == 0
            if rem == 0
                totalCount = bi(1);
            else
                totalCount = bi(0);
            end
            return
        end
        if rem < k * lo || rem > k * hi
            totalCount = bi(0);
            return
        end
        key = sprintf('%d|%d', rem, k);
        if isKey(memo, key)
            totalCount = memo(key);
            return
        end
        totalCount = bi(0);
        for x = lo:hi
            totalCount = totalCount + countState(rem - x, k - 1);
        end
        memo(key) = totalCount;
    end

    function out = unrank1(rank1)
        r = bi(rank1);
        allCount = countAll();
        if r < bi(1) || r > allCount
            error('Pastafari:Oracle:BoundedCompositionRank', 'Ranga kompozycji ograniczonej jest poza zakresem.');
        end
        rem = total;
        out = zeros(1, slots);
        for position = 1:slots
            selected = false;
            for x = lo:hi
                block = countState(rem - x, slots - position);
                if r > block
                    r = r - block;
                else
                    out(position) = x;
                    rem = rem - x;
                    selected = true;
                    break
                end
            end
            if ~selected
                error('Pastafari:Oracle:BoundedCompositionUnrank', 'Nie udało się rozwinąć rangi kompozycji ograniczonej.');
            end
        end
    end
end

function monthLengths = chooseMonthLengths(structureSauce, year, monthCount)
L = year.closeGateDay - year.openGateDay;
Lsmall = L.toDoubleExact();
family = makeBoundedCompositionFamily(Lsmall, monthCount, 4, 123);
count = family.count();
if count < bi(1)
    error('Pastafari:Oracle:MonthLengthFamilyEmpty', 'Rodzina długości miesięcy jest pusta.');
end
stream = askBowl(structureSauce, 3, 31);
rank = chooseRank(stream, count);
monthLengths = family.unrank1(rank);
end

function family = makeWeavingFamily(lengths)
lengths = double(lengths(:).');
m = numel(lengths);
memo = containers.Map('KeyType', 'char', 'ValueType', 'any');
initialRemaining = lengths;
family = struct();
family.count = @countAll;
family.unrank1 = @unrank1;

    function key = stateKey(remaining, openedUpTo, closedUpTo)
        key = sprintf('%d,', remaining);
        key = [key, '|', sprintf('%d|%d', openedUpTo, closedUpTo)];
    end

    function tf = legalMove(remaining, openedUpTo, closedUpTo, j)
        if remaining(j) == 0
            tf = false;
            return
        end
        alreadyOpened = remaining(j) < lengths(j);
        if ~alreadyOpened && j ~= openedUpTo + 1
            tf = false;
            return
        end
        willClose = remaining(j) == 1;
        if willClose && j ~= closedUpTo + 1
            tf = false;
            return
        end
        tf = true;
    end

    function [nextRemaining, nextOpened, nextClosed] = applyMove(remaining, openedUpTo, closedUpTo, j)
        nextRemaining = remaining;
        nextOpened = openedUpTo;
        nextClosed = closedUpTo;
        if nextRemaining(j) == lengths(j)
            nextOpened = j;
        end
        nextRemaining(j) = nextRemaining(j) - 1;
        if nextRemaining(j) == 0
            nextClosed = j;
        end
    end

    function totalCount = countAll()
        totalCount = countState(initialRemaining, 0, 0);
    end

    function totalCount = countState(remaining, openedUpTo, closedUpTo)
        if all(remaining == 0)
            totalCount = bi(1);
            return
        end
        key = stateKey(remaining, openedUpTo, closedUpTo);
        if isKey(memo, key)
            totalCount = memo(key);
            return
        end
        totalCount = bi(0);
        for j = 1:m
            if legalMove(remaining, openedUpTo, closedUpTo, j)
                [nr, no, nc] = applyMove(remaining, openedUpTo, closedUpTo, j);
                totalCount = totalCount + countState(nr, no, nc);
            end
        end
        memo(key) = totalCount;
    end

    function out = unrank1(rank1)
        r = bi(rank1);
        allCount = countAll();
        if r < bi(1) || r > allCount
            error('Pastafari:Oracle:WeavingRank', 'Ranga splotu miesięcy jest poza zakresem.');
        end
        remaining = initialRemaining;
        openedUpTo = 0;
        closedUpTo = 0;
        out = zeros(1, sum(lengths));
        position = 1;
        while position <= numel(out)
            selected = false;
            for j = 1:m
                if ~legalMove(remaining, openedUpTo, closedUpTo, j)
                    continue
                end
                [nr, no, nc] = applyMove(remaining, openedUpTo, closedUpTo, j);
                block = countState(nr, no, nc);
                if r > block
                    r = r - block;
                else
                    out(position) = j;
                    remaining = nr;
                    openedUpTo = no;
                    closedUpTo = nc;
                    position = position + 1;
                    selected = true;
                    break
                end
            end
            if ~selected
                error('Pastafari:Oracle:WeavingUnrank', 'Nie udało się rozwinąć rangi splotu miesięcy.');
            end
        end
    end
end

function weaving = chooseMonthWeaving(structureSauce, monthLengths)
family = makeWeavingFamily(monthLengths);
count = family.count();
if count < bi(1)
    error('Pastafari:Oracle:WeavingFamilyEmpty', 'Rodzina splotów miesięcy jest pusta.');
end
stream = askBowl(structureSauce, 4, 32);
rank = chooseRank(stream, count);
weaving = family.unrank1(rank);
end

function nameIndices = chooseMonthNames(structureSauce, monthCount)
N = fallingFactorial(47, monthCount);
stream = askBowl(structureSauce, 5, 33);
rank = chooseRank(stream, N);
nameIndices = unrankDistinctIndices(47, monthCount, rank);
end

function structure = buildYearStructure(calculationDay, year)
firstDay = year.openGateDay + bi(1);
r = sauce(calculationDay, firstDay);
cutletCount = chooseCutletCount(r, year);
cutletPartition = chooseCutletPartition(calculationDay, r, year, cutletCount);
cutletNameIndices = chooseCutletNames(r, cutletCount);
cutlets = materializeCutlets(year, cutletPartition, cutletNameIndices);
monthCount = chooseMonthCount(r, year);
monthLengths = chooseMonthLengths(r, year, monthCount);
monthWeaving = chooseMonthWeaving(r, monthLengths);
monthNameIndices = chooseMonthNames(r, monthCount);
structure = struct('cutletCount', cutletCount, 'cutletPartition', cutletPartition, ...
    'cutletNameIndices', cutletNameIndices, 'cutlets', cutlets, 'monthCount', monthCount, ...
    'monthLengths', monthLengths, 'monthWeaving', monthWeaving, ...
    'monthNameIndices', monthNameIndices);
end

function result = calendarDate(calculationDay, targetDay)
calculationDay = bi(calculationDay);
targetDay = bi(targetDay);
year = findTargetYear(calculationDay, targetDay);
structure = buildYearStructure(calculationDay, year);
chosenCutlet = [];
chosenCutletId = 0;
for k = 1:numel(structure.cutlets)
    c = structure.cutlets(k);
    if c.firstDay <= targetDay && targetDay <= c.lastDay
        chosenCutlet = c;
        chosenCutletId = k;
        break
    end
end
if isempty(chosenCutlet)
    error('Pastafari:Oracle:CutletMissing', 'Nie znaleziono kotleta zawierającego dzień pytany.');
end
dayInCutlet = targetDay - chosenCutlet.firstDay + bi(1);
yearOffset0 = targetDay - (year.openGateDay + bi(1));
offset = yearOffset0.toDoubleExact();
monthId = structure.monthWeaving(offset + 1);
dayInMonth = 0;
for p = 1:offset + 1
    if structure.monthWeaving(p) == monthId
        dayInMonth = dayInMonth + 1;
    end
end
catalog = pastafari.sourceLanguageCatalog();
cutletName = catalog.cutlets(structure.cutletNameIndices(chosenCutletId)).text;
monthName = catalog.months(structure.monthNameIndices(monthId)).text;
result = {year.number, cutletName, dayInCutlet, monthName, bi(dayInMonth)};
if numel(result) ~= 5
    error('Pastafari:Oracle:FiveFields', 'Źródło odniesienia musi zwracać dokładnie pięć pól.');
end
end
