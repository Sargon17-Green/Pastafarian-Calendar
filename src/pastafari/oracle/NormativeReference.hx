package pastafari.oracle;

import haxe.ds.IntMap;
import haxe.ds.StringMap;
import pastafari.math.BigInt;
import pastafari.catalog.SourceLanguageCatalog;

class WorkCounts {
    public final action:BigInt;
    public final target:BigInt;
    public final distance:BigInt;
    public final connection:BigInt;
    public final direction:Int;

    public function new(action:BigInt, target:BigInt, distance:BigInt, connection:BigInt, direction:Int) {
        this.action = action;
        this.target = target;
        this.distance = distance;
        this.connection = connection;
        this.direction = direction;
    }
}

class Stone {
    public final wheat:BigInt;
    public final barley:BigInt;
    public final salt:BigInt;
    public final bitter:BigInt;
    public final red:BigInt;

    public function new(wheat:BigInt, barley:BigInt, salt:BigInt, bitter:BigInt, red:BigInt) {
        this.wheat = wheat;
        this.barley = barley;
        this.salt = salt;
        this.bitter = bitter;
        this.red = red;
    }

    public function byKind(kind:Int):BigInt {
        return switch (kind) {
            case 1: wheat;
            case 2: barley;
            case 3: salt;
            case 4: bitter;
            case 5: red;
            default: throw "Ogiltig stentyp";
        }
    }
}

class SauceResult {
    public final bowls:Array<BigInt>;
    public final orderAtDrop46:Array<Int>;

    public function new(bowls:Array<BigInt>, orderAtDrop46:Array<Int>) {
        this.bowls = bowls;
        this.orderAtDrop46 = orderAtDrop46;
    }
}

class AnswerStream {
    public final first:BigInt;
    public final directionStep:Int;

    public function new(first:BigInt, directionStep:Int) {
        this.first = first;
        this.directionStep = directionStep;
    }
}

class Year {
    public final number:BigInt;
    public final openGateIndex:BigInt;
    public final closeGateIndex:BigInt;
    public final openGateDay:BigInt;
    public final closeGateDay:BigInt;

    public function new(number:BigInt, openGateIndex:BigInt, closeGateIndex:BigInt, openGateDay:BigInt, closeGateDay:BigInt) {
        this.number = number;
        this.openGateIndex = openGateIndex;
        this.closeGateIndex = closeGateIndex;
        this.openGateDay = openGateDay;
        this.closeGateDay = closeGateDay;
    }
}

class Cutlet {
    public final nameIndex:Int;
    public final openGateIndex:BigInt;
    public final closeGateIndex:BigInt;
    public final firstDay:BigInt;
    public final lastDay:BigInt;

    public function new(nameIndex:Int, openGateIndex:BigInt, closeGateIndex:BigInt, firstDay:BigInt, lastDay:BigInt) {
        this.nameIndex = nameIndex;
        this.openGateIndex = openGateIndex;
        this.closeGateIndex = closeGateIndex;
        this.firstDay = firstDay;
        this.lastDay = lastDay;
    }
}

class YearStructure {
    public final cutletCount:Int;
    public final cutletPartition:Array<Int>;
    public final cutletNameIndices:Array<Int>;
    public final cutlets:Array<Cutlet>;
    public final monthCount:Int;
    public final monthLengths:Array<Int>;
    public final monthWeaving:Array<Int>;
    public final monthNameIndices:Array<Int>;

    public function new(
        cutletCount:Int,
        cutletPartition:Array<Int>,
        cutletNameIndices:Array<Int>,
        cutlets:Array<Cutlet>,
        monthCount:Int,
        monthLengths:Array<Int>,
        monthWeaving:Array<Int>,
        monthNameIndices:Array<Int>
    ) {
        this.cutletCount = cutletCount;
        this.cutletPartition = cutletPartition;
        this.cutletNameIndices = cutletNameIndices;
        this.cutlets = cutlets;
        this.monthCount = monthCount;
        this.monthLengths = monthLengths;
        this.monthWeaving = monthWeaving;
        this.monthNameIndices = monthNameIndices;
    }
}

class NormativeDate {
    public final yearNumber:BigInt;
    public final cutletName:String;
    public final dayInCutlet:BigInt;
    public final monthName:String;
    public final dayInMonth:BigInt;

    public function new(yearNumber:BigInt, cutletName:String, dayInCutlet:BigInt, monthName:String, dayInMonth:BigInt) {
        this.yearNumber = yearNumber;
        this.cutletName = cutletName;
        this.dayInCutlet = dayInCutlet;
        this.monthName = monthName;
        this.dayInMonth = dayInMonth;
    }
}

class BoundedCompositionFamily {
    private final total:Int;
    private final slots:Int;
    private final lo:Int;
    private final hi:Int;
    private final memo:StringMap<BigInt>;

    public function new(total:Int, slots:Int, lo:Int, hi:Int) {
        this.total = total;
        this.slots = slots;
        this.lo = lo;
        this.hi = hi;
        this.memo = new StringMap<BigInt>();
    }

    private function countSuffix(rem:Int, k:Int):BigInt {
        if (k == 0) return rem == 0 ? BigInt.one() : BigInt.zero();
        if (rem < k * lo || rem > k * hi) return BigInt.zero();
        var key = rem + ":" + k;
        var cached = memo.get(key);
        if (cached != null) return cached;
        var sum = BigInt.zero();
        var x = lo;
        while (x <= hi) {
            sum = BigInt.add(sum, countSuffix(rem - x, k - 1));
            x++;
        }
        memo.set(key, sum);
        return sum;
    }

    public function count():BigInt {
        return countSuffix(total, slots);
    }

    public function unrank1(rank1:BigInt):Array<Int> {
        var all = count();
        if (BigInt.compare(rank1, BigInt.one()) < 0 || BigInt.compare(rank1, all) > 0) {
            throw "Rang utanför kompositionsfamiljen";
        }
        var r = rank1.copy();
        var rem = total;
        var out = new Array<Int>();
        var position = 0;
        while (position < slots) {
            var chosen = false;
            var x = lo;
            while (x <= hi) {
                var block = countSuffix(rem - x, slots - position - 1);
                if (BigInt.compare(r, block) > 0) {
                    r = BigInt.sub(r, block);
                } else {
                    out.push(x);
                    rem -= x;
                    chosen = true;
                    break;
                }
                x++;
            }
            if (!chosen) throw "Ingen komposition motsvarar rangen";
            position++;
        }
        return out;
    }
}

class CutletPartitionFamily {
    private final total:Int;
    private final slots:Int;
    private final required:Null<Int>;
    private final memo:StringMap<BigInt>;

    public function new(total:Int, slots:Int, required:Null<Int>) {
        this.total = total;
        this.slots = slots;
        this.required = required;
        this.memo = new StringMap<BigInt>();
    }

    private function countState(rem:Int, k:Int, cumulative:Int, hit:Bool):BigInt {
        if (k == 0) {
            if (rem != 0) return BigInt.zero();
            if (required == null) return BigInt.one();
            return hit ? BigInt.one() : BigInt.zero();
        }
        if (rem < k) return BigInt.zero();
        var key = rem + ":" + k + ":" + cumulative + ":" + (hit ? "1" : "0");
        var cached = memo.get(key);
        if (cached != null) return cached;
        var totalCount = BigInt.zero();
        var maxX = rem - (k - 1);
        var x = 1;
        while (x <= maxX) {
            var nextCumulative = cumulative + x;
            var nextHit = hit;
            if (required != null && !hit) {
                if (nextCumulative == required) {
                    nextHit = true;
                } else if (nextCumulative > required) {
                    x++;
                    continue;
                }
            }
            totalCount = BigInt.add(totalCount, countState(rem - x, k - 1, nextCumulative, nextHit));
            x++;
        }
        memo.set(key, totalCount);
        return totalCount;
    }

    public function count():BigInt {
        return countState(total, slots, 0, false);
    }

    public function unrank1(rank1:BigInt):Array<Int> {
        var all = count();
        if (BigInt.compare(rank1, BigInt.one()) < 0 || BigInt.compare(rank1, all) > 0) {
            throw "Rang utanför kotlettpartitionens familj";
        }
        var r = rank1.copy();
        var rem = total;
        var k = slots;
        var cumulative = 0;
        var hit = false;
        var out = new Array<Int>();
        while (k > 0) {
            var maxX = rem - (k - 1);
            var chosen = false;
            var x = 1;
            while (x <= maxX) {
                var nextCumulative = cumulative + x;
                var nextHit = hit;
                if (required != null && !hit) {
                    if (nextCumulative == required) {
                        nextHit = true;
                    } else if (nextCumulative > required) {
                        x++;
                        continue;
                    }
                }
                var block = countState(rem - x, k - 1, nextCumulative, nextHit);
                if (BigInt.compare(r, block) > 0) {
                    r = BigInt.sub(r, block);
                } else {
                    out.push(x);
                    rem -= x;
                    k--;
                    cumulative = nextCumulative;
                    hit = nextHit;
                    chosen = true;
                    break;
                }
                x++;
            }
            if (!chosen) throw "Ingen kotlettpartition motsvarar rangen";
        }
        return out;
    }
}

class WeaveState {
    public final remaining:Array<Int>;
    public final openedUpTo:Int;
    public final closedUpTo:Int;

    public function new(remaining:Array<Int>, openedUpTo:Int, closedUpTo:Int) {
        this.remaining = remaining;
        this.openedUpTo = openedUpTo;
        this.closedUpTo = closedUpTo;
    }
}

class WeavingCounter {
    private final lengths:Array<Int>;
    private final memo:StringMap<BigInt>;

    public function new(lengths:Array<Int>) {
        this.lengths = lengths.copy();
        this.memo = new StringMap<BigInt>();
    }

    private function key(state:WeaveState):String {
        return state.openedUpTo + ":" + state.closedUpTo + ":" + state.remaining.join(",");
    }

    private function legalMove(state:WeaveState, j:Int):Bool {
        var idx = j - 1;
        if (state.remaining[idx] == 0) return false;
        var alreadyOpened = state.remaining[idx] < lengths[idx];
        if (!alreadyOpened && j != state.openedUpTo + 1) return false;
        var willClose = state.remaining[idx] == 1;
        if (willClose && j != state.closedUpTo + 1) return false;
        return true;
    }

    private function applyMove(state:WeaveState, j:Int):WeaveState {
        var nextRemaining = state.remaining.copy();
        var opened = state.openedUpTo;
        var closed = state.closedUpTo;
        var idx = j - 1;
        if (nextRemaining[idx] == lengths[idx]) opened = j;
        nextRemaining[idx]--;
        if (nextRemaining[idx] == 0) closed = j;
        return new WeaveState(nextRemaining, opened, closed);
    }

    public function initialState():WeaveState {
        return new WeaveState(lengths.copy(), 0, 0);
    }

    public function countState(state:WeaveState):BigInt {
        var any = false;
        for (x in state.remaining) {
            if (x != 0) {
                any = true;
                break;
            }
        }
        if (!any) return BigInt.one();
        var k = key(state);
        var cached = memo.get(k);
        if (cached != null) return cached;
        var total = BigInt.zero();
        var j = 1;
        while (j <= lengths.length) {
            if (legalMove(state, j)) {
                total = BigInt.add(total, countState(applyMove(state, j)));
            }
            j++;
        }
        memo.set(k, total);
        return total;
    }

    public function count():BigInt {
        return countState(initialState());
    }

    public function unrank1(rank1:BigInt):Array<Int> {
        var all = count();
        if (BigInt.compare(rank1, BigInt.one()) < 0 || BigInt.compare(rank1, all) > 0) {
            throw "Rang utanför vävningsfamiljen";
        }
        var state = initialState();
        var r = rank1.copy();
        var out = new Array<Int>();
        var targetLength = 0;
        for (x in lengths) targetLength += x;
        while (out.length < targetLength) {
            var chosen = false;
            var j = 1;
            while (j <= lengths.length) {
                if (legalMove(state, j)) {
                    var next = applyMove(state, j);
                    var block = countState(next);
                    if (BigInt.compare(r, block) > 0) {
                        r = BigInt.sub(r, block);
                    } else {
                        out.push(j);
                        state = next;
                        chosen = true;
                        break;
                    }
                }
                j++;
            }
            if (!chosen) throw "Ingen vävning motsvarar rangen";
        }
        return out;
    }
}

class NormativeReference {
    public static final M:BigInt = BigInt.fromString("170141183460469231731687303715884105727");
    public static final TABLETS_DAY:BigInt = BigInt.fromInt(-278522);
    public static final FOUNDATION_DAY:BigInt = BigInt.fromInt(-15055671);
    public static final YEAR_MIN_DAYS:Int = 252;
    public static final YEAR_MAX_DAYS:Int = 5778;

    private static final ONE:BigInt = BigInt.one();
    private static final TWO:BigInt = BigInt.fromInt(2);
    private static final SIX:BigInt = BigInt.fromInt(6);
    private static final DAY_5778:BigInt = BigInt.fromInt(5778);

    private final stones:Array<Stone>;
    private final gates:StringMap<BigInt>;
    private var minKnownGateIndex:BigInt;
    private var maxKnownGateIndex:BigInt;

    public function new() {
        stones = buildStones();
        gates = new StringMap<BigInt>();
        gates.set("0", FOUNDATION_DAY.copy());
        minKnownGateIndex = BigInt.zero();
        maxKnownGateIndex = BigInt.zero();
    }

    public static function regularMod(x:BigInt, d:BigInt):BigInt {
        return BigInt.modEuclid(x, d);
    }

    public static function save(x:BigInt):BigInt {
        return BigInt.add(ONE, regularMod(BigInt.sub(x, ONE), M));
    }

    public static function ceilDivNonNegative(a:BigInt, b:BigInt):BigInt {
        if (BigInt.compare(a, BigInt.zero()) < 0 || BigInt.compare(b, BigInt.one()) < 0) {
            throw "Ogiltiga argument till takdivision";
        }
        return BigInt.floorDiv(BigInt.add(a, BigInt.sub(b, ONE)), b);
    }

    public static function wrap1(position:Int, size:Int):Int {
        if (size < 1) throw "Ogiltig ringstorlek";
        var r = (position - 1) % size;
        if (r < 0) r += size;
        return r + 1;
    }

    public static function dayCount(day:BigInt):BigInt {
        var cmp = BigInt.compare(day, FOUNDATION_DAY);
        if (cmp == 0) return BigInt.one();
        if (cmp > 0) {
            return BigInt.add(BigInt.mulInt(BigInt.sub(day, FOUNDATION_DAY), 2), ONE);
        }
        return BigInt.mulInt(BigInt.sub(FOUNDATION_DAY, day), 2);
    }

    public static function workCounts(calculationDay:BigInt, targetDay:BigInt):WorkCounts {
        var c = dayCount(calculationDay);
        var t = dayCount(targetDay);
        var distance = BigInt.add(BigInt.absDiff(targetDay, calculationDay), ONE);
        var connection = BigInt.add(c, t);
        var direction = BigInt.compare(targetDay, calculationDay) < 0 ? 1 : (BigInt.compare(targetDay, calculationDay) == 0 ? 2 : 3);
        return new WorkCounts(c, t, distance, connection, direction);
    }

    public static function buildStones():Array<Stone> {
        var table = new Array<Stone>();
        var current = new Stone(BigInt.fromInt(17), BigInt.fromInt(29), BigInt.fromInt(43), BigInt.fromInt(71), BigInt.fromInt(101));
        table.push(current);
        var i = 2;
        while (i <= 46) {
            var nextWheat = save(BigInt.add(BigInt.add(BigInt.square(current.wheat), BigInt.mulInt(current.barley, 3)), BigInt.fromInt(i)));
            var nextBarley = save(BigInt.add(BigInt.add(BigInt.square(current.barley), BigInt.mulInt(current.salt, 5)), current.wheat));
            var nextSalt = save(BigInt.add(BigInt.add(BigInt.square(current.salt), BigInt.mulInt(current.bitter, 7)), current.barley));
            var nextBitter = save(BigInt.add(BigInt.add(BigInt.square(current.bitter), BigInt.mulInt(current.red, 11)), current.salt));
            var nextRed = save(BigInt.add(BigInt.add(BigInt.square(current.red), BigInt.mulInt(current.wheat, 13)), current.bitter));
            current = new Stone(nextWheat, nextBarley, nextSalt, nextBitter, nextRed);
            table.push(current);
            i++;
        }
        return table;
    }

    private static function hiddenCoeff(k:Int):Array<Int> {
        return switch (k) {
            case 1: [3, 4, 6, 8];
            case 2: [5, 7, 10, 12];
            case 3: [7, 10, 14, 16];
            case 4: [9, 13, 18, 20];
            case 5: [11, 16, 22, 24];
            case 6: [13, 19, 26, 28];
            case 7: [15, 22, 30, 32];
            default: throw "Ogiltig dold droppe";
        }
    }

    private static function hiddenGrindStone(grind:Int):Int {
        return switch (grind) {
            case 1: 1;
            case 2: 2;
            case 3: 3;
            case 4: 4;
            case 5: 5;
            case 6: 1;
            case 7: 2;
            default: throw "Ogiltig dold malning";
        }
    }

    private function buildHiddenDrops(counts:WorkCounts):Array<BigInt> {
        var hidden = new Array<BigInt>();
        var k = 1;
        while (k <= 7) {
            var coeff = hiddenCoeff(k);
            var stone = stones[k - 1];
            var x = counts.action.copy();
            x = BigInt.add(x, BigInt.mulInt(counts.target, coeff[0]));
            x = BigInt.add(x, BigInt.mulInt(counts.distance, coeff[1]));
            x = BigInt.add(x, BigInt.mulInt(counts.connection, coeff[2]));
            x = BigInt.add(x, BigInt.fromInt(coeff[3] * counts.direction));
            x = BigInt.add(x, stone.wheat);
            x = BigInt.add(x, stone.barley);
            x = BigInt.add(x, stone.salt);
            x = BigInt.add(x, stone.bitter);
            x = BigInt.add(x, stone.red);
            x = save(x);
            var grind = 1;
            while (grind <= 7) {
                var oldX = x;
                var v = BigInt.square(oldX);
                v = BigInt.add(v, BigInt.mulInt(oldX, 3));
                v = BigInt.add(v, stone.byKind(hiddenGrindStone(grind)));
                v = BigInt.add(v, BigInt.fromInt(grind));
                x = save(v);
                grind++;
            }
            hidden.push(x);
            k++;
        }
        return hidden;
    }

    private static function visibleGrind(grind:Int):Array<Int> {
        return switch (grind) {
            case 1: [3, 5, 7, 11, 1];
            case 2: [5, 7, 11, 13, 2];
            case 3: [7, 11, 13, 17, 3];
            case 4: [11, 13, 17, 19, 4];
            case 5: [13, 17, 19, 23, 5];
            case 6: [17, 19, 23, 29, 1];
            case 7: [19, 23, 29, 31, 2];
            case 8: [23, 29, 31, 37, 3];
            case 9: [29, 31, 37, 41, 4];
            case 10: [31, 37, 41, 43, 5];
            case 11: [37, 41, 43, 47, 1];
            default: throw "Ogiltig synlig malning";
        }
    }

    private function buildVisibleDrops(counts:WorkCounts, hidden:Array<BigInt>):Array<BigInt> {
        var timeline = new IntMap<BigInt>();
        var k = 1;
        while (k <= 7) {
            timeline.set(1 - k, hidden[k - 1]);
            k++;
        }
        var visible = new Array<BigInt>();
        var i = 1;
        while (i <= 46) {
            var prev1 = timeline.get(i - 1);
            var prev3 = timeline.get(i - 3);
            var prev7 = timeline.get(i - 7);
            if (prev1 == null || prev3 == null || prev7 == null) throw "Ofullständig dropphistorik";
            var stone = stones[i - 1];
            var x = BigInt.mul(stone.wheat, counts.action);
            x = BigInt.add(x, BigInt.mul(stone.barley, counts.target));
            x = BigInt.add(x, BigInt.mul(stone.salt, counts.distance));
            x = BigInt.add(x, BigInt.mul(stone.bitter, counts.connection));
            x = BigInt.add(x, BigInt.mulInt(stone.red, counts.direction));
            x = BigInt.add(x, prev1);
            x = BigInt.add(x, BigInt.mulInt(prev3, 3));
            x = BigInt.add(x, BigInt.mulInt(prev7, 5));
            x = BigInt.add(x, BigInt.fromInt(i));
            x = save(x);
            var grind = 1;
            while (grind <= 11) {
                var row = visibleGrind(grind);
                var oldX = x;
                var v = BigInt.square(oldX);
                v = BigInt.add(v, BigInt.mulInt(oldX, row[0]));
                v = BigInt.add(v, BigInt.mulInt(prev1, row[1]));
                v = BigInt.add(v, BigInt.mulInt(prev3, row[2]));
                v = BigInt.add(v, BigInt.mulInt(prev7, row[3]));
                v = BigInt.add(v, stone.byKind(row[4]));
                x = save(v);
                grind++;
            }
            timeline.set(i, x);
            visible.push(x);
            i++;
        }
        return visible;
    }

    public static function permutationUnrank1(rank1:Int):Array<Int> {
        if (rank1 < 1 || rank1 > 720) throw "Ogiltig permutationsrang";
        var rank0 = rank1 - 1;
        var remaining = [1, 2, 3, 4, 5, 6];
        var result = new Array<Int>();
        var slotsLeft = remaining.length;
        while (slotsLeft >= 1) {
            var block = factorialInt(slotsLeft - 1);
            var q = intFloorDivPositive(rank0, block);
            rank0 = rank0 % block;
            result.push(remaining[q]);
            remaining.splice(q, 1);
            slotsLeft--;
        }
        return result;
    }

    private static function intFloorDivPositive(a:Int, b:Int):Int {
        if (a < 0 || b <= 0) throw "Ogiltig heltalsdivision";
        var q = 0;
        var r = a;
        while (r >= b) {
            r -= b;
            q++;
        }
        return q;
    }

    private static function factorialInt(n:Int):Int {
        var r = 1;
        var i = 2;
        while (i <= n) {
            r *= i;
            i++;
        }
        return r;
    }

    public static function bowlOrderFromDrop(dropValue:BigInt):Array<Int> {
        var rank = BigInt.add(BigInt.modEuclid(BigInt.sub(dropValue, ONE), BigInt.fromInt(720)), ONE).toIntExact();
        return permutationUnrank1(rank);
    }

    private static function initialBowls(counts:WorkCounts):Array<BigInt> {
        var primes = [17, 19, 23, 29, 31, 37];
        var bowls = new Array<BigInt>();
        var id = 1;
        while (id <= 6) {
            var s = counts.action.copy();
            s = BigInt.add(s, BigInt.mulInt(counts.target, id));
            s = BigInt.add(s, counts.distance);
            s = BigInt.add(s, counts.connection);
            s = BigInt.add(s, BigInt.fromInt(counts.direction));
            s = BigInt.add(s, BigInt.fromInt(primes[id - 1] * primes[id - 1]));
            bowls.push(save(BigInt.add(BigInt.square(s), BigInt.fromInt(id))));
            id++;
        }
        return bowls;
    }

    private function applyVisibleDropsToBowls(start:Array<BigInt>, visible:Array<BigInt>):{bowls:Array<BigInt>, order:Array<Int>} {
        var bowls = copyBigArray(start);
        var orderAt46:Array<Int> = null;
        var stoneByPosition = [1, 2, 3, 4, 5, 1];
        var i = 1;
        while (i <= 46) {
            var drop = visible[i - 1];
            var order = bowlOrderFromDrop(drop);
            var old = copyBigArray(bowls);
            var pour = [BigInt.zero(), BigInt.zero(), BigInt.zero(), BigInt.zero(), BigInt.zero(), BigInt.zero()];
            pour[0] = save(BigInt.add(BigInt.add(BigInt.square(drop), BigInt.mul(stones[i - 1].wheat, old[order[0] - 1])), BigInt.fromInt(3 * i)));
            pour[1] = save(BigInt.add(BigInt.add(BigInt.square(drop), BigInt.mul(stones[i - 1].barley, old[order[1] - 1])), BigInt.fromInt(5 * i)));
            pour[2] = save(BigInt.add(BigInt.add(BigInt.square(drop), BigInt.mul(stones[i - 1].salt, old[order[2] - 1])), BigInt.fromInt(7 * i)));
            var next = copyBigArray(bowls);
            var position = 1;
            while (position <= 6) {
                var bowlId = order[position - 1];
                var prevId = order[wrap1(position - 1, 6) - 1];
                var nextId = order[wrap1(position + 1, 6) - 1];
                var s = old[bowlId - 1];
                var mix = s.copy();
                mix = BigInt.add(mix, BigInt.mulInt(old[prevId - 1], 2));
                mix = BigInt.add(mix, BigInt.mulInt(old[nextId - 1], 3));
                mix = BigInt.add(mix, pour[position - 1]);
                mix = BigInt.add(mix, drop);
                mix = BigInt.add(mix, stones[i - 1].byKind(stoneByPosition[position - 1]));
                var v = BigInt.square(mix);
                v = BigInt.add(v, BigInt.mulInt(BigInt.mul(old[prevId - 1], old[nextId - 1]), 5));
                v = BigInt.add(v, BigInt.fromInt(i * position));
                next[bowlId - 1] = save(v);
                position++;
            }
            bowls = next;
            if (i == 46) orderAt46 = order.copy();
            i++;
        }
        if (orderAt46 == null) throw "Ordningen vid droppe 46 saknas";
        return {bowls: bowls, order: orderAt46};
    }

    private static function postStir12(start:Array<BigInt>):Array<BigInt> {
        var bowls = copyBigArray(start);
        var stir = 1;
        while (stir <= 12) {
            var old = copyBigArray(bowls);
            var sum = BigInt.zero();
            for (b in old) sum = BigInt.add(sum, b);
            var savedBowlSum = save(BigInt.add(sum, BigInt.fromInt(149 * stir)));
            var orderNumber = BigInt.add(BigInt.modEuclid(BigInt.sub(savedBowlSum, ONE), BigInt.fromInt(720)), ONE).toIntExact();
            var order = permutationUnrank1(orderNumber);
            var next = copyBigArray(bowls);
            var position = 1;
            while (position <= 6) {
                var bowlId = order[position - 1];
                var prevId = order[wrap1(position - 1, 6) - 1];
                var nextId = order[wrap1(position + 1, 6) - 1];
                var s = old[bowlId - 1];
                var mix = s.copy();
                mix = BigInt.add(mix, BigInt.mulInt(old[prevId - 1], 3));
                mix = BigInt.add(mix, BigInt.mulInt(old[nextId - 1], 5));
                mix = BigInt.add(mix, savedBowlSum);
                mix = BigInt.add(mix, BigInt.fromInt(stir));
                mix = BigInt.add(mix, BigInt.fromInt(position * position));
                var v = BigInt.square(mix);
                v = BigInt.add(v, BigInt.mulInt(BigInt.mul(old[prevId - 1], old[nextId - 1]), 7));
                next[bowlId - 1] = save(v);
                position++;
            }
            bowls = next;
            stir++;
        }
        return bowls;
    }

    public function sauce(calculationDay:BigInt, targetDay:BigInt):SauceResult {
        var counts = workCounts(calculationDay, targetDay);
        var hidden = buildHiddenDrops(counts);
        var visible = buildVisibleDrops(counts, hidden);
        var afterDrops = applyVisibleDropsToBowls(initialBowls(counts), visible);
        var finalBowls = postStir12(afterDrops.bowls);
        return new SauceResult(finalBowls, afterDrops.order);
    }

    public static function nextBowlInDrop46Order(result:SauceResult, queriedBowlId:Int):Int {
        var p = result.orderAtDrop46.indexOf(queriedBowlId);
        if (p < 0) throw "Frågad skål saknas i ordningen";
        return result.orderAtDrop46[(p + 1) % 6];
    }

    public static function askBowl(result:SauceResult, queriedBowlId:Int, seal:Int):AnswerStream {
        var nextId = nextBowlInDrop46Order(result, queriedBowlId);
        var firstBase = BigInt.add(BigInt.add(result.bowls[queriedBowlId - 1], BigInt.fromInt(seal)), BigInt.fromInt(181));
        var first = BigInt.square(firstBase);
        first = BigInt.add(first, BigInt.mulInt(result.bowls[nextId - 1], 179));
        first = BigInt.add(first, BigInt.fromInt(seal));
        first = save(first);
        var directionBase = BigInt.add(BigInt.add(first, BigInt.fromInt(seal + 1)), BigInt.fromInt(193));
        var directionNumber = BigInt.square(directionBase);
        directionNumber = BigInt.add(directionNumber, BigInt.mulInt(first, 193));
        directionNumber = BigInt.add(directionNumber, BigInt.mulInt(result.bowls[5], 197));
        directionNumber = save(directionNumber);
        var odd = BigInt.modEuclid(directionNumber, TWO).toIntExact() == 1;
        return new AnswerStream(first, odd ? 1 : -1);
    }

    public static function answerAt(stream:AnswerStream, k:BigInt):BigInt {
        var v = BigInt.sub(stream.first, ONE);
        v = BigInt.add(v, stream.directionStep == 1 ? k : k.negated());
        return BigInt.add(ONE, BigInt.modEuclid(v, M));
    }

    public static function chooseRankShort(stream:AnswerStream, n:BigInt):BigInt {
        if (BigInt.compare(n, ONE) < 0 || BigInt.compare(n, M) > 0) throw "Ogiltig kort familjestorlek";
        var limit = BigInt.mul(BigInt.floorDiv(M, n), n);
        var k = BigInt.zero();
        while (true) {
            var x = answerAt(stream, k);
            if (BigInt.compare(x, limit) <= 0) return BigInt.add(BigInt.modEuclid(BigInt.sub(x, ONE), n), ONE);
            k = BigInt.add(k, ONE);
        }
        return BigInt.zero();
    }

    public static function chooseRankWide(stream:AnswerStream, n:BigInt):BigInt {
        if (BigInt.compare(n, M) <= 0) throw "Ogiltig bred familjestorlek";
        var places = 1;
        var space = M.copy();
        while (BigInt.compare(space, n) < 0) {
            places++;
            space = BigInt.mul(space, M);
        }
        var wide = ONE.copy();
        var weight = ONE.copy();
        var j = 0;
        while (j < places) {
            var digit = BigInt.sub(answerAt(stream, BigInt.fromInt(j)), ONE);
            wide = BigInt.add(wide, BigInt.mul(digit, weight));
            weight = BigInt.mul(weight, M);
            j++;
        }
        var limit = BigInt.mul(BigInt.floorDiv(space, n), n);
        while (true) {
            if (BigInt.compare(wide, limit) <= 0) return BigInt.add(BigInt.modEuclid(BigInt.sub(wide, ONE), n), ONE);
            var delta = stream.directionStep == 1 ? ONE : ONE.negated();
            wide = BigInt.add(ONE, BigInt.modEuclid(BigInt.add(BigInt.sub(wide, ONE), delta), space));
        }
        return BigInt.zero();
    }

    public static function chooseRank(stream:AnswerStream, n:BigInt):BigInt {
        if (BigInt.compare(n, ONE) < 0) throw "Tom familj kan inte väljas";
        return BigInt.compare(n, M) <= 0 ? chooseRankShort(stream, n) : chooseRankWide(stream, n);
    }

    public static function fallingFactorial(n:Int, k:Int):BigInt {
        if (k < 0 || k > n) throw "Ogiltig fallande fakultet";
        var r = ONE.copy();
        var j = 0;
        while (j < k) {
            r = BigInt.mulInt(r, n - j);
            j++;
        }
        return r;
    }

    public static function unrankDistinctIndices(n:Int, k:Int, rank1:BigInt):Array<Int> {
        var total = fallingFactorial(n, k);
        if (BigInt.compare(rank1, ONE) < 0 || BigInt.compare(rank1, total) > 0) throw "Ogiltig namnrang";
        var remaining = new Array<Int>();
        var i = 1;
        while (i <= n) {
            remaining.push(i);
            i++;
        }
        var out = new Array<Int>();
        var r = rank1.copy();
        var position = 1;
        while (position <= k) {
            var suffixLength = k - position;
            var block = fallingFactorial(remaining.length - 1, suffixLength);
            var candidate = 0;
            while (candidate < remaining.length) {
                if (BigInt.compare(r, block) > 0) {
                    r = BigInt.sub(r, block);
                } else {
                    out.push(remaining[candidate]);
                    remaining.splice(candidate, 1);
                    break;
                }
                candidate++;
            }
            position++;
        }
        return out;
    }

    private static function copyBigArray(values:Array<BigInt>):Array<BigInt> {
        var out = new Array<BigInt>();
        for (v in values) out.push(v.copy());
        return out;
    }

    private function gateKey(index:BigInt):String {
        return index.toString();
    }

    private function gate(index:BigInt):BigInt {
        var v = gates.get(gateKey(index));
        if (v == null) throw "Efterfrågad port är inte genererad";
        return v;
    }

    private function positiveGateGap(n:BigInt):Int {
        var r = sauce(FOUNDATION_DAY, BigInt.add(FOUNDATION_DAY, n));
        var stream = askBowl(r, 1, 1);
        return 41 + chooseRank(stream, BigInt.fromInt(922)).toIntExact();
    }

    private function negativeGateGap(n:BigInt):Int {
        var r = sauce(FOUNDATION_DAY, BigInt.sub(FOUNDATION_DAY, n));
        var stream = askBowl(r, 1, 1);
        return 41 + chooseRank(stream, BigInt.fromInt(922)).toIntExact();
    }

    public function ensureGateIndex(index:BigInt):BigInt {
        if (BigInt.compare(index, maxKnownGateIndex) > 0) {
            var n = BigInt.add(maxKnownGateIndex, ONE);
            while (BigInt.compare(n, index) <= 0) {
                var previous = gate(BigInt.sub(n, ONE));
                gates.set(gateKey(n), BigInt.add(previous, BigInt.fromInt(positiveGateGap(n))));
                maxKnownGateIndex = n.copy();
                n = BigInt.add(n, ONE);
            }
        }
        if (BigInt.compare(index, minKnownGateIndex) < 0) {
            var n = BigInt.sub(minKnownGateIndex, ONE);
            while (BigInt.compare(n, index) >= 0) {
                var next = gate(BigInt.add(n, ONE));
                gates.set(gateKey(n), BigInt.sub(next, BigInt.fromInt(negativeGateGap(n.abs()))));
                minKnownGateIndex = n.copy();
                n = BigInt.sub(n, ONE);
            }
        }
        return gate(index);
    }

    public function ensureGatesCover(lowDay:BigInt, highDay:BigInt):Void {
        if (BigInt.compare(lowDay, highDay) > 0) throw "Omvänt portintervall";
        while (BigInt.compare(gate(minKnownGateIndex), lowDay) > 0) ensureGateIndex(BigInt.sub(minKnownGateIndex, ONE));
        while (BigInt.compare(gate(maxKnownGateIndex), highDay) < 0) ensureGateIndex(BigInt.add(maxKnownGateIndex, ONE));
    }

    private function ensureGatesForwardThroughDay(day:BigInt):Void {
        ensureGatesCover(gate(minKnownGateIndex), day);
    }

    private function ensureGatesBackwardThroughDay(day:BigInt):Void {
        ensureGatesCover(day, gate(maxKnownGateIndex));
    }

    public function gateIndexAtOrBefore(day:BigInt):BigInt {
        ensureGatesCover(day, day);
        var lo = minKnownGateIndex.copy();
        var hi = maxKnownGateIndex.copy();
        while (BigInt.compare(lo, hi) < 0) {
            var span = BigInt.add(BigInt.sub(hi, lo), ONE);
            var mid = BigInt.add(lo, BigInt.floorDiv(span, TWO));
            if (BigInt.compare(gate(mid), day) <= 0) lo = mid; else hi = BigInt.sub(mid, ONE);
        }
        return lo;
    }

    public function gateIndexAtOrAfter(day:BigInt):BigInt {
        var i = gateIndexAtOrBefore(day);
        if (BigInt.compare(gate(i), day) == 0) return i;
        var next = BigInt.add(i, ONE);
        ensureGateIndex(next);
        return next;
    }

    public function exactGateIndex(day:BigInt):Null<BigInt> {
        var i = gateIndexAtOrBefore(day);
        return BigInt.compare(gate(i), day) == 0 ? i : null;
    }

    private function yearLength(openIndex:BigInt, closeIndex:BigInt):BigInt {
        return BigInt.sub(gate(closeIndex), gate(openIndex));
    }

    private function validYearPair(openIndex:BigInt, closeIndex:BigInt):Bool {
        if (BigInt.compare(BigInt.sub(closeIndex, openIndex), SIX) < 0) return false;
        var length = yearLength(openIndex, closeIndex);
        return BigInt.compare(length, BigInt.fromInt(YEAR_MIN_DAYS)) >= 0 && BigInt.compare(length, DAY_5778) <= 0;
    }

    private function makeYear(number:BigInt, openIndex:BigInt, closeIndex:BigInt):Year {
        return new Year(number, openIndex, closeIndex, gate(openIndex), gate(closeIndex));
    }

    public function year5000(calculationDay:BigInt):Year {
        ensureGatesCover(BigInt.sub(calculationDay, DAY_5778), BigInt.add(calculationDay, DAY_5778));
        var candidates = new Array<{open:BigInt, close:BigInt}>();
        var i = minKnownGateIndex.copy();
        while (BigInt.compare(i, maxKnownGateIndex) < 0) {
            var j = BigInt.add(i, ONE);
            while (BigInt.compare(j, maxKnownGateIndex) <= 0) {
                if (validYearPair(i, j) && BigInt.compare(gate(i), calculationDay) < 0 && BigInt.compare(calculationDay, gate(j)) <= 0) {
                    candidates.push({open: i.copy(), close: j.copy()});
                }
                j = BigInt.add(j, ONE);
            }
            i = BigInt.add(i, ONE);
        }
        candidates.sort(function(a, b) {
            var la = yearLength(a.open, a.close);
            var lb = yearLength(b.open, b.close);
            var c = BigInt.compare(la, lb);
            if (c != 0) return c;
            return BigInt.compare(gate(a.open), gate(b.open));
        });
        if (candidates.length == 0) throw "Ingen kandidat för år 5000";
        var r = sauce(calculationDay, calculationDay);
        var rank = chooseRank(askBowl(r, 1, 10), BigInt.fromInt(candidates.length)).toIntExact();
        var chosen = candidates[rank - 1];
        return makeYear(BigInt.fromInt(5000), chosen.open, chosen.close);
    }

    public function nextYear(calculationDay:BigInt, known:Year):Year {
        var openIndex = known.closeGateIndex;
        ensureGatesForwardThroughDay(BigInt.add(gate(openIndex), DAY_5778));
        var candidates = new Array<BigInt>();
        var closeIndex = BigInt.add(openIndex, ONE);
        while (true) {
            ensureGateIndex(closeIndex);
            if (BigInt.compare(yearLength(openIndex, closeIndex), DAY_5778) > 0) break;
            if (validYearPair(openIndex, closeIndex)) candidates.push(closeIndex.copy());
            closeIndex = BigInt.add(closeIndex, ONE);
        }
        candidates.sort(function(a, b) return BigInt.compare(yearLength(openIndex, a), yearLength(openIndex, b)));
        if (candidates.length == 0) throw "Ingen kandidat för nästa år";
        var r = sauce(calculationDay, gate(openIndex));
        var rank = chooseRank(askBowl(r, 1, 11), BigInt.fromInt(candidates.length)).toIntExact();
        return makeYear(BigInt.add(known.number, ONE), openIndex, candidates[rank - 1]);
    }

    public function previousYear(calculationDay:BigInt, known:Year):Year {
        var closeIndex = known.openGateIndex;
        ensureGatesBackwardThroughDay(BigInt.sub(gate(closeIndex), DAY_5778));
        var candidates = new Array<BigInt>();
        var openIndex = BigInt.sub(closeIndex, ONE);
        while (true) {
            ensureGateIndex(openIndex);
            if (BigInt.compare(yearLength(openIndex, closeIndex), DAY_5778) > 0) break;
            if (validYearPair(openIndex, closeIndex)) candidates.push(openIndex.copy());
            openIndex = BigInt.sub(openIndex, ONE);
        }
        candidates.sort(function(a, b) return BigInt.compare(yearLength(a, closeIndex), yearLength(b, closeIndex)));
        if (candidates.length == 0) throw "Ingen kandidat för föregående år";
        var r = sauce(calculationDay, gate(closeIndex));
        var rank = chooseRank(askBowl(r, 1, 12), BigInt.fromInt(candidates.length)).toIntExact();
        return makeYear(BigInt.sub(known.number, ONE), candidates[rank - 1], closeIndex);
    }

    public function findTargetYear(calculationDay:BigInt, targetDay:BigInt):Year {
        var y = year5000(calculationDay);
        while (BigInt.compare(targetDay, y.closeGateDay) > 0) y = nextYear(calculationDay, y);
        while (BigInt.compare(targetDay, y.openGateDay) <= 0) y = previousYear(calculationDay, y);
        return y;
    }

    private function chooseCutletCount(structureSauce:SauceResult, year:Year):Int {
        var gateGaps = BigInt.sub(year.closeGateIndex, year.openGateIndex);
        var candidates = new Array<Int>();
        var k = 6;
        while (k <= 17) {
            if (BigInt.compare(BigInt.fromInt(k), gateGaps) <= 0) candidates.push(k);
            k++;
        }
        var rank = chooseRank(askBowl(structureSauce, 2, 20), BigInt.fromInt(candidates.length)).toIntExact();
        return candidates[rank - 1];
    }

    private function chooseCutletPartition(calculationDay:BigInt, structureSauce:SauceResult, year:Year, cutletCount:Int):Array<Int> {
        var gaps = BigInt.sub(year.closeGateIndex, year.openGateIndex).toIntExact();
        var exact = exactGateIndex(calculationDay);
        var required:Null<Int> = null;
        if (exact != null && BigInt.compare(exact, year.openGateIndex) > 0 && BigInt.compare(exact, year.closeGateIndex) < 0) {
            required = BigInt.sub(exact, year.openGateIndex).toIntExact();
        }
        var family = new CutletPartitionFamily(gaps, cutletCount, required);
        var rank = chooseRank(askBowl(structureSauce, 2, 21), family.count());
        return family.unrank1(rank);
    }

    private function chooseCutletNames(structureSauce:SauceResult, cutletCount:Int):Array<Int> {
        var n = fallingFactorial(17, cutletCount);
        var rank = chooseRank(askBowl(structureSauce, 5, 22), n);
        return unrankDistinctIndices(17, cutletCount, rank);
    }

    private function materializeCutlets(year:Year, partition:Array<Int>, names:Array<Int>):Array<Cutlet> {
        var out = new Array<Cutlet>();
        var cursor = year.openGateIndex.copy();
        var k = 0;
        while (k < partition.length) {
            var open = cursor.copy();
            var close = BigInt.add(cursor, BigInt.fromInt(partition[k]));
            out.push(new Cutlet(names[k], open, close, BigInt.add(gate(open), ONE), gate(close)));
            cursor = close;
            k++;
        }
        return out;
    }

    private function chooseMonthCount(structureSauce:SauceResult, year:Year):Int {
        var length = BigInt.sub(year.closeGateDay, year.openGateDay).toIntExact();
        var minMonths = intFloorDivPositive(length + 122, 123);
        var maxMonths = intFloorDivPositive(length, 4);
        if (maxMonths > 47) maxMonths = 47;
        if (minMonths < 3 || minMonths > maxMonths) throw "Ogiltigt intervall för månadsantal";
        var count = maxMonths - minMonths + 1;
        var rank = chooseRank(askBowl(structureSauce, 3, 30), BigInt.fromInt(count)).toIntExact();
        return minMonths + rank - 1;
    }

    private function chooseMonthLengths(structureSauce:SauceResult, year:Year, monthCount:Int):Array<Int> {
        var length = BigInt.sub(year.closeGateDay, year.openGateDay).toIntExact();
        var family = new BoundedCompositionFamily(length, monthCount, 4, 123);
        var rank = chooseRank(askBowl(structureSauce, 3, 31), family.count());
        return family.unrank1(rank);
    }

    private function chooseMonthWeaving(structureSauce:SauceResult, lengths:Array<Int>):Array<Int> {
        var family = new WeavingCounter(lengths);
        var rank = chooseRank(askBowl(structureSauce, 4, 32), family.count());
        return family.unrank1(rank);
    }

    private function chooseMonthNames(structureSauce:SauceResult, monthCount:Int):Array<Int> {
        var n = fallingFactorial(47, monthCount);
        var rank = chooseRank(askBowl(structureSauce, 5, 33), n);
        return unrankDistinctIndices(47, monthCount, rank);
    }

    public function buildYearStructure(calculationDay:BigInt, year:Year):YearStructure {
        var firstDay = BigInt.add(year.openGateDay, ONE);
        var r = sauce(calculationDay, firstDay);
        var cutletCount = chooseCutletCount(r, year);
        var partition = chooseCutletPartition(calculationDay, r, year, cutletCount);
        var cutletNames = chooseCutletNames(r, cutletCount);
        var cutlets = materializeCutlets(year, partition, cutletNames);
        var monthCount = chooseMonthCount(r, year);
        var monthLengths = chooseMonthLengths(r, year, monthCount);
        var weave = chooseMonthWeaving(r, monthLengths);
        var monthNames = chooseMonthNames(r, monthCount);
        return new YearStructure(cutletCount, partition, cutletNames, cutlets, monthCount, monthLengths, weave, monthNames);
    }

    public function calendarDate(calculationDay:BigInt, targetDay:BigInt):NormativeDate {
        var year = findTargetYear(calculationDay, targetDay);
        var structure = buildYearStructure(calculationDay, year);
        var chosen:Cutlet = null;
        for (c in structure.cutlets) {
            if (BigInt.compare(c.firstDay, targetDay) <= 0 && BigInt.compare(targetDay, c.lastDay) <= 0) {
                chosen = c;
                break;
            }
        }
        if (chosen == null) throw "Måldagen saknar kotlett";
        var dayInCutlet = BigInt.add(BigInt.sub(targetDay, chosen.firstDay), ONE);
        var offset = BigInt.sub(targetDay, BigInt.add(year.openGateDay, ONE)).toIntExact();
        var monthId = structure.monthWeaving[offset];
        var dayInMonth = 0;
        var p = 0;
        while (p <= offset) {
            if (structure.monthWeaving[p] == monthId) dayInMonth++;
            p++;
        }
        return new NormativeDate(
            year.number,
            SourceLanguageCatalog.cutlet(chosen.nameIndex).text,
            dayInCutlet,
            SourceLanguageCatalog.month(structure.monthNameIndices[monthId - 1]).text,
            BigInt.fromInt(dayInMonth)
        );
    }
}
