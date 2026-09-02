namespace Pastafari.NormativeOracle {
    import Pastafari.ExactMath.*;
    import Pastafari.SourceLanguageCatalog.*;

    struct WorkCounts {
        Action : BigInt,
        Target : BigInt,
        Distance : BigInt,
        Connection : BigInt,
        Direction : BigInt,
    }

    struct Stone {
        Wheat : BigInt,
        Barley : BigInt,
        Salt : BigInt,
        Bitter : BigInt,
        Red : BigInt,
    }

    struct SauceResult {
        Bowls : BigInt[],
        OrderAt46 : Int[],
    }

    struct AnswerStream {
        First : BigInt,
        Step : Int,
    }

    struct GatePoint {
        Index : Int,
        Day : BigInt,
    }

    struct Year {
        Number : BigInt,
        OpenGateIndex : Int,
        CloseGateIndex : Int,
        OpenDay : BigInt,
        CloseDay : BigInt,
    }

    struct YearCandidate {
        OpenIndex : Int,
        CloseIndex : Int,
        OpenDay : BigInt,
        CloseDay : BigInt,
    }

    struct Cutlet {
        CanonicalNameIndex : Int,
        OpenGateIndex : Int,
        CloseGateIndex : Int,
        FirstDay : BigInt,
        LastDay : BigInt,
    }

    struct YearStructure {
        YearValue : Year,
        CutletCount : Int,
        Partition : Int[],
        CutletNameIndices : Int[],
        Cutlets : Cutlet[],
        MonthCount : Int,
        MonthLengths : Int[],
        Weaving : Int[],
        MonthNameIndices : Int[],
    }

    struct CalendarResult {
        YearNumber : BigInt,
        CutletName : String,
        DayInCutlet : BigInt,
        MonthName : String,
        DayInMonth : BigInt,
    }

    function FoundationDay() : BigInt { return -15055671L; }
    function TabletsDay() : BigInt { return -278522L; }
    function YearMinDays() : BigInt { return 252L; }
    function YearMaxDays() : BigInt { return 5778L; }

    function DayCount(day : BigInt) : BigInt {
        if day == FoundationDay() { return 1L; }
        if day > FoundationDay() { return 2L * (day - FoundationDay()) + 1L; }
        return 2L * (FoundationDay() - day);
    }

    function WorkCountsFor(calculationDay : BigInt, targetDay : BigInt) : WorkCounts {
        let c = DayCount(calculationDay);
        let t = DayCount(targetDay);
        let distance = AbsL(targetDay - calculationDay) + 1L;
        let connection = c + t;
        mutable direction = 2L;
        if targetDay < calculationDay { direction = 1L; }
        elif targetDay > calculationDay { direction = 3L; }
        return WorkCounts(c, t, distance, connection, direction);
    }

    function BuildStoneTable() : Stone[] {
        mutable out : Stone[] = [Stone(17L, 29L, 43L, 71L, 101L)];
        for i in 2..46 {
            let old = out[Length(out) - 1];
            let ib = BI(i);
            let next = Stone(
                Save(old.Wheat * old.Wheat + 3L * old.Barley + ib),
                Save(old.Barley * old.Barley + 5L * old.Salt + old.Wheat),
                Save(old.Salt * old.Salt + 7L * old.Bitter + old.Barley),
                Save(old.Bitter * old.Bitter + 11L * old.Red + old.Salt),
                Save(old.Red * old.Red + 13L * old.Wheat + old.Bitter)
            );
            out += [next];
        }
        return out;
    }

    function StoneByKind(stone : Stone, kind : Int) : BigInt {
        if kind == 1 { return stone.Wheat; }
        elif kind == 2 { return stone.Barley; }
        elif kind == 3 { return stone.Salt; }
        elif kind == 4 { return stone.Bitter; }
        elif kind == 5 { return stone.Red; }
        fail "石種別が不正です。";
    }

    function HiddenCoeff(k : Int) : (BigInt, BigInt, BigInt, BigInt) {
        if k == 1 { return (3L,4L,6L,8L); }
        elif k == 2 { return (5L,7L,10L,12L); }
        elif k == 3 { return (7L,10L,14L,16L); }
        elif k == 4 { return (9L,13L,18L,20L); }
        elif k == 5 { return (11L,16L,22L,24L); }
        elif k == 6 { return (13L,19L,26L,28L); }
        elif k == 7 { return (15L,22L,30L,32L); }
        fail "隠し滴の係数番号が不正です。";
    }

    function HiddenGrindStoneKind(grind : Int) : Int {
        let kinds = [1,2,3,4,5,1,2];
        return kinds[grind - 1];
    }

    function BuildHiddenDrops(counts : WorkCounts, stones : Stone[]) : BigInt[] {
        mutable hidden : BigInt[] = [];
        for k in 1..7 {
            let (a,b,c,d) = HiddenCoeff(k);
            let st = stones[k - 1];
            mutable x = counts.Action
                + a * counts.Target
                + b * counts.Distance
                + c * counts.Connection
                + d * counts.Direction
                + st.Wheat + st.Barley + st.Salt + st.Bitter + st.Red;
            x = Save(x);
            for grind in 1..7 {
                let oldX = x;
                x = Save(oldX * oldX + 3L * oldX + StoneByKind(st, HiddenGrindStoneKind(grind)) + BI(grind));
            }
            hidden += [x];
        }
        return hidden;
    }

    function VisibleGrindRow(grind : Int) : (BigInt, BigInt, BigInt, BigInt, Int) {
        if grind == 1 { return (3L,5L,7L,11L,1); }
        elif grind == 2 { return (5L,7L,11L,13L,2); }
        elif grind == 3 { return (7L,11L,13L,17L,3); }
        elif grind == 4 { return (11L,13L,17L,19L,4); }
        elif grind == 5 { return (13L,17L,19L,23L,5); }
        elif grind == 6 { return (17L,19L,23L,29L,1); }
        elif grind == 7 { return (19L,23L,29L,31L,2); }
        elif grind == 8 { return (23L,29L,31L,37L,3); }
        elif grind == 9 { return (29L,31L,37L,41L,4); }
        elif grind == 10 { return (31L,37L,41L,43L,5); }
        elif grind == 11 { return (37L,41L,43L,47L,1); }
        fail "可視滴の攪拌番号が不正です。";
    }

    function PriorDrop(visible : BigInt[], hidden : BigInt[], i : Int, back : Int) : BigInt {
        let slot = i - back;
        if slot >= 1 { return visible[slot - 1]; }
        let k = 1 - slot;
        return hidden[k - 1];
    }

    function BuildVisibleDrops(counts : WorkCounts, stones : Stone[], hidden : BigInt[]) : BigInt[] {
        mutable visible : BigInt[] = [];
        for i in 1..46 {
            let p1 = PriorDrop(visible, hidden, i, 1);
            let p3 = PriorDrop(visible, hidden, i, 3);
            let p7 = PriorDrop(visible, hidden, i, 7);
            let st = stones[i - 1];
            mutable x = Save(
                st.Wheat * counts.Action
                + st.Barley * counts.Target
                + st.Salt * counts.Distance
                + st.Bitter * counts.Connection
                + st.Red * counts.Direction
                + p1 + 3L*p3 + 5L*p7 + BI(i)
            );
            for grind in 1..11 {
                let oldX = x;
                let (a,b,c,d,kind) = VisibleGrindRow(grind);
                x = Save(oldX*oldX + a*oldX + b*p1 + c*p3 + d*p7 + StoneByKind(st,kind));
            }
            visible += [x];
        }
        return visible;
    }

    function RemoveAt(items : Int[], index : Int) : Int[] {
        mutable out : Int[] = [];
        for i in 0..Length(items)-1 {
            if i != index { out += [items[i]]; }
        }
        return out;
    }

    function PermutationUnrank1(rank1 : BigInt) : Int[] {
        if rank1 < 1L or rank1 > 720L { fail "順列の順位が範囲外です。"; }
        mutable rank0 = rank1 - 1L;
        mutable remaining = [1,2,3,4,5,6];
        mutable out : Int[] = [];
        mutable slotsLeft = 6;
        while slotsLeft >= 1 {
            let block = Factorial(slotsLeft - 1);
            let q = ToIntExact(rank0 / block);
            rank0 = RegularMod(rank0, block);
            out += [remaining[q]];
            remaining = RemoveAt(remaining, q);
            slotsLeft -= 1;
        }
        return out;
    }

    function BowlOrderFromDrop(drop : BigInt) : Int[] {
        let orderNumber = RegularMod(drop - 1L, 720L) + 1L;
        return PermutationUnrank1(orderNumber);
    }

    function InitialBowls(counts : WorkCounts) : BigInt[] {
        let primes = [17,19,23,29,31,37];
        mutable bowls : BigInt[] = [];
        for id in 1..6 {
            let idb = BI(id);
            let pb = BI(primes[id-1]);
            let s = counts.Action + counts.Target*idb + counts.Distance + counts.Connection + counts.Direction + pb*pb;
            bowls += [Save(s*s + idb)];
        }
        return bowls;
    }

    function ApplyVisibleDropsToBowls(initial : BigInt[], visible : BigInt[], stones : Stone[]) : (BigInt[], Int[]) {
        mutable bowls = initial;
        mutable orderAt46 : Int[] = [];
        let stoneByPosition = [1,2,3,4,5,1];
        for i in 1..46 {
            let drop = visible[i-1];
            let order = BowlOrderFromDrop(drop);
            let old = bowls;
            mutable pour = [0L, size = 6];
            let first = order[0];
            let second = order[1];
            let third = order[2];
            let st = stones[i-1];
            pour w/= 0 <- Save(drop*drop + st.Wheat*old[first-1] + 3L*BI(i));
            pour w/= 1 <- Save(drop*drop + st.Barley*old[second-1] + 5L*BI(i));
            pour w/= 2 <- Save(drop*drop + st.Salt*old[third-1] + 7L*BI(i));
            mutable nextBowls = [0L, size = 6];
            for position in 1..6 {
                let bowlId = order[position-1];
                let prevId = order[Wrap1(position-1,6)-1];
                let nextId = order[Wrap1(position+1,6)-1];
                let s = old[bowlId-1] + 2L*old[prevId-1] + 3L*old[nextId-1]
                    + pour[position-1] + drop + StoneByKind(st,stoneByPosition[position-1]);
                nextBowls w/= bowlId-1 <- Save(s*s + 5L*old[prevId-1]*old[nextId-1] + BI(i)*BI(position));
            }
            bowls = nextBowls;
            if i == 46 { orderAt46 = order; }
        }
        return (bowls, orderAt46);
    }

    function PostStir12(initial : BigInt[]) : BigInt[] {
        mutable bowls = initial;
        for stir in 1..12 {
            let old = bowls;
            let saved = Save(old[0]+old[1]+old[2]+old[3]+old[4]+old[5] + 149L*BI(stir));
            let orderNumber = RegularMod(saved - 1L, 720L) + 1L;
            let order = PermutationUnrank1(orderNumber);
            mutable nextBowls = [0L, size = 6];
            for position in 1..6 {
                let bowlId = order[position-1];
                let prevId = order[Wrap1(position-1,6)-1];
                let nextId = order[Wrap1(position+1,6)-1];
                let s = old[bowlId-1] + 3L*old[prevId-1] + 5L*old[nextId-1]
                    + saved + BI(stir) + BI(position)*BI(position);
                nextBowls w/= bowlId-1 <- Save(s*s + 7L*old[prevId-1]*old[nextId-1]);
            }
            bowls = nextBowls;
        }
        return bowls;
    }

    function Sauce(calculationDay : BigInt, targetDay : BigInt) : SauceResult {
        let counts = WorkCountsFor(calculationDay, targetDay);
        let stones = BuildStoneTable();
        let hidden = BuildHiddenDrops(counts, stones);
        let visible = BuildVisibleDrops(counts, stones, hidden);
        let initial = InitialBowls(counts);
        let (afterDrops, orderAt46) = ApplyVisibleDropsToBowls(initial, visible, stones);
        let finalBowls = PostStir12(afterDrops);
        return SauceResult(finalBowls, orderAt46);
    }

    function NextBowlInOrder(result : SauceResult, queriedId : Int) : Int {
        mutable pos = -1;
        for i in 0..5 {
            if result.OrderAt46[i] == queriedId { pos = i; }
        }
        if pos < 0 { fail "質問対象の鉢が順序に存在しません。"; }
        return result.OrderAt46[(pos + 1) % 6];
    }

    function AskBowl(result : SauceResult, queriedId : Int, seal : Int) : AnswerStream {
        let nextId = NextBowlInOrder(result, queriedId);
        let sealB = BI(seal);
        let first = Save((result.Bowls[queriedId-1] + sealB + 181L)^2
            + 179L*result.Bowls[nextId-1] + sealB);
        let directionNumber = Save((first + sealB + 1L + 193L)^2 + 193L*first + 197L*result.Bowls[5]);
        mutable step = -1;
        if RegularMod(directionNumber, 2L) == 1L { step = 1; }
        return AnswerStream(first, step);
    }

    function AnswerAt(stream : AnswerStream, k : Int) : BigInt {
        return 1L + RegularMod(stream.First - 1L + BI(stream.Step)*BI(k), M());
    }

    function ChooseRankShort(stream : AnswerStream, n : BigInt) : BigInt {
        if n < 1L or n > M() { fail "短い選択の範囲が不正です。"; }
        let limit = FloorDiv(M(), n) * n;
        mutable k = 0;
        mutable x = AnswerAt(stream, k);
        while x > limit {
            k += 1;
            x = AnswerAt(stream, k);
        }
        return RegularMod(x - 1L, n) + 1L;
    }

    function ChooseRankWide(stream : AnswerStream, n : BigInt) : BigInt {
        if n <= M() { fail "広い選択の範囲が不正です。"; }
        mutable places = 1;
        mutable space = M();
        while space < n {
            places += 1;
            space *= M();
        }
        mutable wide = 1L;
        mutable weight = 1L;
        for j in 0..places-1 {
            wide += (AnswerAt(stream,j)-1L)*weight;
            weight *= M();
        }
        let limit = FloorDiv(space,n)*n;
        while wide > limit {
            wide = 1L + RegularMod(wide - 1L + BI(stream.Step), space);
        }
        return RegularMod(wide - 1L,n)+1L;
    }

    function ChooseRank(stream : AnswerStream, n : BigInt) : BigInt {
        if n < 1L { fail "選択肢数は正でなければなりません。"; }
        if n <= M() { return ChooseRankShort(stream,n); }
        return ChooseRankWide(stream,n);
    }

    function PositiveGateGap(n : Int) : BigInt {
        if n < 1 { fail "正方向の門番号が不正です。"; }
        let r = Sauce(FoundationDay(), FoundationDay() + BI(n));
        let stream = AskBowl(r,1,1);
        return 41L + ChooseRank(stream,922L);
    }

    function NegativeGateGap(n : Int) : BigInt {
        if n < 1 { fail "負方向の門番号が不正です。"; }
        let r = Sauce(FoundationDay(), FoundationDay() - BI(n));
        let stream = AskBowl(r,1,1);
        return 41L + ChooseRank(stream,922L);
    }

    function BuildGateWindow(lowDay : BigInt, highDay : BigInt) : GatePoint[] {
        if lowDay > highDay { fail "門の生成範囲が逆転しています。"; }
        mutable negative : GatePoint[] = [];
        mutable currentNegative = FoundationDay();
        mutable negIndex = 0;
        mutable magnitude = 1;
        while currentNegative > lowDay {
            currentNegative -= NegativeGateGap(magnitude);
            negIndex -= 1;
            negative += [GatePoint(negIndex,currentNegative)];
            magnitude += 1;
        }

        mutable points : GatePoint[] = [];
        mutable p = Length(negative) - 1;
        while p >= 0 {
            points += [negative[p]];
            p -= 1;
        }
        points += [GatePoint(0,FoundationDay())];

        mutable currentPositive = FoundationDay();
        mutable posIndex = 0;
        mutable n = 1;
        while currentPositive < highDay {
            currentPositive += PositiveGateGap(n);
            posIndex += 1;
            points += [GatePoint(posIndex,currentPositive)];
            n += 1;
        }
        return points;
    }

    function GateDayAt(points : GatePoint[], index : Int) : BigInt {
        for p in points {
            if p.Index == index { return p.Day; }
        }
        fail "必要な門が生成済み範囲に存在しません。";
    }

    function ExactGateIndexIn(points : GatePoint[], day : BigInt) : Int {
        for p in points {
            if p.Day == day { return p.Index; }
        }
        return 2147483647;
    }

    function YearCandidateIsBefore(a : YearCandidate, b : YearCandidate) : Bool {
        let la = a.CloseDay - a.OpenDay;
        let lb = b.CloseDay - b.OpenDay;
        if la < lb { return true; }
        if la > lb { return false; }
        return a.OpenDay < b.OpenDay;
    }

    function InsertYearCandidateSorted(items : YearCandidate[], item : YearCandidate, withOpeningTie : Bool) : YearCandidate[] {
        mutable out : YearCandidate[] = [];
        mutable inserted = false;
        let li = item.CloseDay - item.OpenDay;
        for old in items {
            let lo = old.CloseDay - old.OpenDay;
            mutable shouldInsert = li < lo;
            if withOpeningTie and li == lo and item.OpenDay < old.OpenDay { shouldInsert = true; }
            if not inserted and shouldInsert {
                out += [item];
                inserted = true;
            }
            out += [old];
        }
        if not inserted { out += [item]; }
        return out;
    }

    function ValidYearCandidate(openIndex : Int, closeIndex : Int, openDay : BigInt, closeDay : BigInt) : Bool {
        if closeIndex - openIndex < 6 { return false; }
        let length = closeDay - openDay;
        return length >= YearMinDays() and length <= YearMaxDays();
    }

    function Year5000(calculationDay : BigInt) : Year {
        let points = BuildGateWindow(calculationDay-YearMaxDays(), calculationDay+YearMaxDays());
        mutable candidates : YearCandidate[] = [];
        for i in 0..Length(points)-1 {
            for j in i+1..Length(points)-1 {
                let open = points[i];
                let close = points[j];
                if ValidYearCandidate(open.Index,close.Index,open.Day,close.Day)
                    and open.Day < calculationDay and calculationDay <= close.Day {
                    candidates = InsertYearCandidateSorted(candidates,YearCandidate(open.Index,close.Index,open.Day,close.Day),true);
                }
            }
        }
        if Length(candidates) == 0 { fail "5000年の候補が存在しません。"; }
        let r = Sauce(calculationDay,calculationDay);
        let stream = AskBowl(r,1,10);
        let rank = ToIntExact(ChooseRank(stream,BI(Length(candidates))));
        let c = candidates[rank-1];
        return Year(5000L,c.OpenIndex,c.CloseIndex,c.OpenDay,c.CloseDay);
    }

    function NextYear(calculationDay : BigInt, known : Year) : Year {
        let points = BuildGateWindow(known.CloseDay, known.CloseDay+YearMaxDays()+963L);
        let openIndex = known.CloseGateIndex;
        let openDay = known.CloseDay;
        mutable candidates : YearCandidate[] = [];
        for p in points {
            if p.Index > openIndex {
                let length = p.Day - openDay;
                if length <= YearMaxDays() and ValidYearCandidate(openIndex,p.Index,openDay,p.Day) {
                    candidates = InsertYearCandidateSorted(candidates,YearCandidate(openIndex,p.Index,openDay,p.Day),false);
                }
            }
        }
        if Length(candidates) == 0 { fail "次年の候補が存在しません。"; }
        let r = Sauce(calculationDay,openDay);
        let stream = AskBowl(r,1,11);
        let rank = ToIntExact(ChooseRank(stream,BI(Length(candidates))));
        let c = candidates[rank-1];
        return Year(known.Number+1L,c.OpenIndex,c.CloseIndex,c.OpenDay,c.CloseDay);
    }

    function PreviousYear(calculationDay : BigInt, known : Year) : Year {
        let points = BuildGateWindow(known.OpenDay-YearMaxDays()-963L, known.OpenDay);
        let closeIndex = known.OpenGateIndex;
        let closeDay = known.OpenDay;
        mutable candidates : YearCandidate[] = [];
        mutable i = Length(points)-1;
        while i >= 0 {
            let p = points[i];
            if p.Index < closeIndex {
                let length = closeDay - p.Day;
                if length <= YearMaxDays() and ValidYearCandidate(p.Index,closeIndex,p.Day,closeDay) {
                    candidates = InsertYearCandidateSorted(candidates,YearCandidate(p.Index,closeIndex,p.Day,closeDay),false);
                }
            }
            i -= 1;
        }
        if Length(candidates) == 0 { fail "前年の候補が存在しません。"; }
        let r = Sauce(calculationDay,closeDay);
        let stream = AskBowl(r,1,12);
        let rank = ToIntExact(ChooseRank(stream,BI(Length(candidates))));
        let c = candidates[rank-1];
        return Year(known.Number-1L,c.OpenIndex,c.CloseIndex,c.OpenDay,c.CloseDay);
    }

    function FindTargetYear(calculationDay : BigInt, targetDay : BigInt) : Year {
        mutable y = Year5000(calculationDay);
        while targetDay > y.CloseDay {
            y = NextYear(calculationDay,y);
        }
        while targetDay <= y.OpenDay {
            y = PreviousYear(calculationDay,y);
        }
        if not (y.OpenDay < targetDay and targetDay <= y.CloseDay) {
            fail "対象日が年の開閉区間に入りません。";
        }
        return y;
    }

    function CountCutletPartitions(rem : Int, slots : Int, cumulative : Int, required : Int, hit : Bool) : BigInt {
        if slots == 0 {
            if rem != 0 { return 0L; }
            if required < 0 { return 1L; }
            if hit { return 1L; }
            return 0L;
        }
        if rem < slots { return 0L; }
        mutable total = 0L;
        let maxX = rem - (slots - 1);
        for x in 1..maxX {
            let nextCumulative = cumulative + x;
            mutable nextHit = hit;
            mutable allowed = true;
            if required >= 0 and not hit {
                if nextCumulative == required { nextHit = true; }
                elif nextCumulative > required { allowed = false; }
            }
            if allowed {
                total += CountCutletPartitions(rem-x,slots-1,nextCumulative,required,nextHit);
            }
        }
        return total;
    }

    function UnrankCutletPartition(gaps : Int, slotsInput : Int, required : Int, rank1 : BigInt) : Int[] {
        let total = CountCutletPartitions(gaps,slotsInput,0,required,false);
        if rank1 < 1L or rank1 > total { fail "カツレツ分割の順位が範囲外です。"; }
        mutable r = rank1;
        mutable rem = gaps;
        mutable slots = slotsInput;
        mutable cumulative = 0;
        mutable hit = false;
        mutable out : Int[] = [];
        while slots > 0 {
            let maxX = rem - (slots - 1);
            mutable chosen = 0;
            for x in 1..maxX {
                if chosen == 0 {
                    let nextCumulative = cumulative + x;
                    mutable nextHit = hit;
                    mutable allowed = true;
                    if required >= 0 and not hit {
                        if nextCumulative == required { nextHit = true; }
                        elif nextCumulative > required { allowed = false; }
                    }
                    if allowed {
                        let block = CountCutletPartitions(rem-x,slots-1,nextCumulative,required,nextHit);
                        if r > block { r -= block; }
                        else {
                            chosen = x;
                            cumulative = nextCumulative;
                            hit = nextHit;
                        }
                    }
                }
            }
            if chosen == 0 { fail "カツレツ分割の unrank に失敗しました。"; }
            out += [chosen];
            rem -= chosen;
            slots -= 1;
        }
        return out;
    }

    function RangeIndices(n : Int) : Int[] {
        mutable out : Int[] = [];
        for i in 1..n { out += [i]; }
        return out;
    }

    function UnrankDistinctNameIndices(masterCount : Int, k : Int, rank1 : BigInt) : Int[] {
        let total = FallingFactorial(masterCount,k);
        if rank1 < 1L or rank1 > total { fail "重複なし名称の順位が範囲外です。"; }
        mutable remaining = RangeIndices(masterCount);
        mutable out : Int[] = [];
        mutable r = rank1;
        for position in 1..k {
            let suffixLength = k - position;
            let block = FallingFactorial(Length(remaining)-1,suffixLength);
            mutable chosenPos = -1;
            for candidate in 0..Length(remaining)-1 {
                if chosenPos < 0 {
                    if r > block { r -= block; }
                    else { chosenPos = candidate; }
                }
            }
            if chosenPos < 0 { fail "名称 unrank に失敗しました。"; }
            out += [remaining[chosenPos]];
            remaining = RemoveAt(remaining,chosenPos);
        }
        return out;
    }

    function CountBoundedCompositions(total : Int, slots : Int, lo : Int, hi : Int) : BigInt {
        if slots == 0 {
            if total == 0 { return 1L; }
            return 0L;
        }
        if total < slots*lo or total > slots*hi { return 0L; }
        mutable count = 0L;
        for x in lo..hi {
            count += CountBoundedCompositions(total-x,slots-1,lo,hi);
        }
        return count;
    }

    function UnrankBoundedComposition(totalInput : Int, slotsInput : Int, lo : Int, hi : Int, rank1 : BigInt) : Int[] {
        let totalCount = CountBoundedCompositions(totalInput,slotsInput,lo,hi);
        if rank1 < 1L or rank1 > totalCount { fail "有界合成の順位が範囲外です。"; }
        mutable r = rank1;
        mutable total = totalInput;
        mutable slots = slotsInput;
        mutable out : Int[] = [];
        while slots > 0 {
            mutable chosen = lo - 1;
            for x in lo..hi {
                if chosen < lo {
                    let block = CountBoundedCompositions(total-x,slots-1,lo,hi);
                    if r > block { r -= block; }
                    else { chosen = x; }
                }
            }
            if chosen < lo { fail "有界合成の unrank に失敗しました。"; }
            out += [chosen];
            total -= chosen;
            slots -= 1;
        }
        return out;
    }

    function AllZero(values : Int[]) : Bool {
        for value in values {
            if value != 0 { return false; }
        }
        return true;
    }

    function LegalWeaveMove(remaining : Int[], lengths : Int[], openedUpTo : Int, closedUpTo : Int, monthId : Int) : Bool {
        if monthId < 1 or monthId > Length(lengths) { return false; }
        let r = remaining[monthId-1];
        if r == 0 { return false; }
        let alreadyOpened = r < lengths[monthId-1];
        if not alreadyOpened and monthId != openedUpTo + 1 { return false; }
        let willClose = r == 1;
        if willClose and monthId != closedUpTo + 1 { return false; }
        return true;
    }

    function ApplyWeaveMove(remaining : Int[], lengths : Int[], openedUpTo : Int, closedUpTo : Int, monthId : Int) : (Int[], Int, Int) {
        mutable nextRemaining = remaining;
        mutable nextOpened = openedUpTo;
        mutable nextClosed = closedUpTo;
        if nextRemaining[monthId-1] == lengths[monthId-1] {
            nextOpened = monthId;
        }
        nextRemaining w/= monthId-1 <- nextRemaining[monthId-1] - 1;
        if nextRemaining[monthId-1] == 0 {
            nextClosed = monthId;
        }
        return (nextRemaining,nextOpened,nextClosed);
    }

    function CountWeavings(remaining : Int[], lengths : Int[], openedUpTo : Int, closedUpTo : Int) : BigInt {
        if AllZero(remaining) { return 1L; }
        mutable total = 0L;
        for monthId in 1..Length(lengths) {
            if LegalWeaveMove(remaining,lengths,openedUpTo,closedUpTo,monthId) {
                let (nextRemaining,nextOpened,nextClosed) = ApplyWeaveMove(remaining,lengths,openedUpTo,closedUpTo,monthId);
                total += CountWeavings(nextRemaining,lengths,nextOpened,nextClosed);
            }
        }
        return total;
    }

    function UnrankWeaving(lengths : Int[], rank1 : BigInt) : Int[] {
        let total = CountWeavings(lengths,lengths,0,0);
        if rank1 < 1L or rank1 > total { fail "月の織り順の順位が範囲外です。"; }
        mutable remaining = lengths;
        mutable opened = 0;
        mutable closed = 0;
        mutable r = rank1;
        mutable out : Int[] = [];
        mutable placed = 0;
        mutable wantedLength = 0;
        for x in lengths { wantedLength += x; }
        while placed < wantedLength {
            mutable chosen = 0;
            for monthId in 1..Length(lengths) {
                if chosen == 0 and LegalWeaveMove(remaining,lengths,opened,closed,monthId) {
                    let (nextRemaining,nextOpened,nextClosed) = ApplyWeaveMove(remaining,lengths,opened,closed,monthId);
                    let block = CountWeavings(nextRemaining,lengths,nextOpened,nextClosed);
                    if r > block { r -= block; }
                    else {
                        chosen = monthId;
                        remaining = nextRemaining;
                        opened = nextOpened;
                        closed = nextClosed;
                    }
                }
            }
            if chosen == 0 { fail "月の織り順の unrank に失敗しました。"; }
            out += [chosen];
            placed += 1;
        }
        return out;
    }

    function ChooseCutletCount(structureSauce : SauceResult, year : Year) : Int {
        let gapCount = year.CloseGateIndex - year.OpenGateIndex;
        mutable candidates : Int[] = [];
        for k in 6..17 {
            if k <= gapCount { candidates += [k]; }
        }
        if Length(candidates) == 0 { fail "カツレツ数の候補が存在しません。"; }
        let stream = AskBowl(structureSauce,2,20);
        let rank = ToIntExact(ChooseRank(stream,BI(Length(candidates))));
        return candidates[rank-1];
    }

    function RequiredCutletBoundary(calculationDay : BigInt, year : Year) : Int {
        if calculationDay <= year.OpenDay or calculationDay >= year.CloseDay { return -1; }
        let points = BuildGateWindow(year.OpenDay,year.CloseDay);
        let g = ExactGateIndexIn(points,calculationDay);
        if g == 2147483647 { return -1; }
        return g - year.OpenGateIndex;
    }

    function ChooseCutletPartition(calculationDay : BigInt, structureSauce : SauceResult, year : Year, cutletCount : Int) : Int[] {
        let gaps = year.CloseGateIndex - year.OpenGateIndex;
        let required = RequiredCutletBoundary(calculationDay,year);
        let count = CountCutletPartitions(gaps,cutletCount,0,required,false);
        if count < 1L { fail "カツレツ分割の候補が存在しません。"; }
        let stream = AskBowl(structureSauce,2,21);
        let rank = ChooseRank(stream,count);
        return UnrankCutletPartition(gaps,cutletCount,required,rank);
    }

    function ChooseCutletNameIndices(structureSauce : SauceResult, cutletCount : Int) : Int[] {
        let count = FallingFactorial(17,cutletCount);
        let stream = AskBowl(structureSauce,5,22);
        let rank = ChooseRank(stream,count);
        return UnrankDistinctNameIndices(17,cutletCount,rank);
    }

    function MaterializeCutlets(year : Year, partition : Int[], nameIndices : Int[]) : Cutlet[] {
        let points = BuildGateWindow(year.OpenDay,year.CloseDay);
        mutable cursor = year.OpenGateIndex;
        mutable out : Cutlet[] = [];
        for i in 0..Length(partition)-1 {
            let openIndex = cursor;
            let closeIndex = cursor + partition[i];
            let firstDay = GateDayAt(points,openIndex)+1L;
            let lastDay = GateDayAt(points,closeIndex);
            out += [Cutlet(nameIndices[i],openIndex,closeIndex,firstDay,lastDay)];
            cursor = closeIndex;
        }
        return out;
    }

    function ChooseMonthCount(structureSauce : SauceResult, year : Year) : Int {
        let length = ToIntExact(year.CloseDay-year.OpenDay);
        let minMonths = (length + 122) / 123;
        let maxMonths = MinI(47,length / 4);
        if minMonths < 3 or minMonths > maxMonths or maxMonths > 47 {
            fail "月数の範囲が不正です。";
        }
        let count = maxMonths-minMonths+1;
        let stream = AskBowl(structureSauce,3,30);
        let rank = ToIntExact(ChooseRank(stream,BI(count)));
        return minMonths + rank - 1;
    }

    function ChooseMonthLengths(structureSauce : SauceResult, year : Year, monthCount : Int) : Int[] {
        let length = ToIntExact(year.CloseDay-year.OpenDay);
        let count = CountBoundedCompositions(length,monthCount,4,123);
        if count < 1L { fail "月長配列の候補が存在しません。"; }
        let stream = AskBowl(structureSauce,3,31);
        let rank = ChooseRank(stream,count);
        return UnrankBoundedComposition(length,monthCount,4,123,rank);
    }

    function ChooseMonthWeaving(structureSauce : SauceResult, monthLengths : Int[]) : Int[] {
        let count = CountWeavings(monthLengths,monthLengths,0,0);
        if count < 1L { fail "月の織り順の候補が存在しません。"; }
        let stream = AskBowl(structureSauce,4,32);
        let rank = ChooseRank(stream,count);
        return UnrankWeaving(monthLengths,rank);
    }

    function ChooseMonthNameIndices(structureSauce : SauceResult, monthCount : Int) : Int[] {
        let count = FallingFactorial(47,monthCount);
        let stream = AskBowl(structureSauce,5,33);
        let rank = ChooseRank(stream,count);
        return UnrankDistinctNameIndices(47,monthCount,rank);
    }

    function BuildYearStructure(calculationDay : BigInt, year : Year) : YearStructure {
        let firstDay = year.OpenDay + 1L;
        let r = Sauce(calculationDay,firstDay);
        let cutletCount = ChooseCutletCount(r,year);
        let partition = ChooseCutletPartition(calculationDay,r,year,cutletCount);
        let cutletNames = ChooseCutletNameIndices(r,cutletCount);
        let cutlets = MaterializeCutlets(year,partition,cutletNames);
        let monthCount = ChooseMonthCount(r,year);
        let monthLengths = ChooseMonthLengths(r,year,monthCount);
        let weaving = ChooseMonthWeaving(r,monthLengths);
        let monthNames = ChooseMonthNameIndices(r,monthCount);
        return YearStructure(year,cutletCount,partition,cutletNames,cutlets,monthCount,monthLengths,weaving,monthNames);
    }

    function CalendarDateOracle(calculationDay : BigInt, targetDay : BigInt) : CalendarResult {
        let year = FindTargetYear(calculationDay,targetDay);
        let structure = BuildYearStructure(calculationDay,year);
        mutable cutletPos = -1;
        for i in 0..Length(structure.Cutlets)-1 {
            let c = structure.Cutlets[i];
            if cutletPos < 0 and c.FirstDay <= targetDay and targetDay <= c.LastDay {
                cutletPos = i;
            }
        }
        if cutletPos < 0 { fail "対象日を含むカツレツが見つかりません。"; }
        let cutlet = structure.Cutlets[cutletPos];
        let dayInCutlet = targetDay-cutlet.FirstDay+1L;
        let offset = ToIntExact(targetDay-(year.OpenDay+1L));
        if offset < 0 or offset >= Length(structure.Weaving) { fail "年内オフセットが不正です。"; }
        let monthId = structure.Weaving[offset];
        mutable dayInMonth = 0L;
        for p in 0..offset {
            if structure.Weaving[p] == monthId { dayInMonth += 1L; }
        }
        let cutletCanonical = structure.CutletNameIndices[cutletPos];
        let monthCanonical = structure.MonthNameIndices[monthId-1];
        return CalendarResult(
            year.Number,
            ResolveCutlet(cutletCanonical),
            dayInCutlet,
            ResolveMonth(monthCanonical),
            dayInMonth
        );
    }
}
