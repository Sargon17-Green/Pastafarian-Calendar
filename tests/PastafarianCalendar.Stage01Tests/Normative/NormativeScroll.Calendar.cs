using System.Numerics;
using PastafarianCalendar;

namespace PastafarianCalendar.Stage01Tests.Normative;

internal sealed partial class NormativeScroll
{
    private const int SealGateGap = 1;
    private const int SealYear5000 = 10;
    private const int SealNextYear = 11;
    private const int SealPreviousYear = 12;
    private const int SealCutletCount = 20;
    private const int SealCutletPartition = 21;
    private const int SealCutletNames = 22;
    private const int SealMonthCount = 30;
    private const int SealMonthLengths = 31;
    private const int SealMonthWeaving = 32;
    private const int SealMonthNames = 33;

    private readonly Dictionary<BigInteger, BigInteger> _gates = new() { [BigInteger.Zero] = FoundationDay };
    private BigInteger _minKnownGateIndex = BigInteger.Zero;
    private BigInteger _maxKnownGateIndex = BigInteger.Zero;

    internal BigInteger PositiveGateGap(BigInteger n)
    {
        if (n < 1) throw new ArgumentOutOfRangeException(nameof(n), "رقم خطوة البوابة الموجبة يجب أن يكون موجبًا.");
        var sauce = Sauce(FoundationDay, FoundationDay + n);
        var stream = AskBowl(sauce, 1, SealGateGap);
        return 41 + ChooseRank(stream, 922);
    }

    internal BigInteger NegativeGateGap(BigInteger n)
    {
        if (n < 1) throw new ArgumentOutOfRangeException(nameof(n), "رقم خطوة البوابة السالبة يجب أن يكون موجب المقدار.");
        var sauce = Sauce(FoundationDay, FoundationDay - n);
        var stream = AskBowl(sauce, 1, SealGateGap);
        return 41 + ChooseRank(stream, 922);
    }

    internal BigInteger EnsureGateIndex(BigInteger k)
    {
        if (k > _maxKnownGateIndex)
        {
            var n = _maxKnownGateIndex + 1;
            while (n <= k)
            {
                _gates[n] = _gates[n - 1] + PositiveGateGap(n);
                _maxKnownGateIndex = n;
                n++;
            }
        }
        if (k < _minKnownGateIndex)
        {
            var n = _minKnownGateIndex - 1;
            while (n >= k)
            {
                _gates[n] = _gates[n + 1] - NegativeGateGap(BigInteger.Abs(n));
                _minKnownGateIndex = n;
                n--;
            }
        }
        return _gates[k];
    }

    internal void EnsureGatesCover(BigInteger lowDay, BigInteger highDay)
    {
        if (lowDay > highDay) throw new ArgumentException("حدود التغطية معكوسة.");
        while (_gates[_minKnownGateIndex] > lowDay) EnsureGateIndex(_minKnownGateIndex - 1);
        while (_gates[_maxKnownGateIndex] < highDay) EnsureGateIndex(_maxKnownGateIndex + 1);
    }

    internal BigInteger GateIndexAtOrBefore(BigInteger day)
    {
        EnsureGatesCover(day, day);
        var lo = _minKnownGateIndex;
        var hi = _maxKnownGateIndex;
        while (lo < hi)
        {
            var mid = lo + (hi - lo + 1) / 2;
            if (_gates[mid] <= day) lo = mid;
            else hi = mid - 1;
        }
        return lo;
    }

    internal BigInteger? ExactGateIndex(BigInteger day)
    {
        var i = GateIndexAtOrBefore(day);
        return _gates[i] == day ? i : null;
    }

    private bool ValidYearPair(BigInteger openIndex, BigInteger closeIndex)
    {
        if (closeIndex - openIndex < 6) return false;
        var length = _gates[closeIndex] - _gates[openIndex];
        return length >= YearMinDays && length <= YearMaxDays;
    }

    internal Year Year5000(BigInteger calculationDay)
    {
        EnsureGatesCover(calculationDay - YearMaxDays, calculationDay + YearMaxDays);
        var candidates = new List<(BigInteger Open, BigInteger Close)>();
        for (var i = _minKnownGateIndex; i < _maxKnownGateIndex; i++)
        {
            for (var j = i + 1; j <= _maxKnownGateIndex; j++)
            {
                if (!ValidYearPair(i, j)) continue;
                if (!(_gates[i] < calculationDay && calculationDay <= _gates[j])) continue;
                candidates.Add((i, j));
            }
        }
        if (candidates.Count == 0) throw new InvalidOperationException("لم توجد سنة مرشحة للعام خمسة آلاف.");
        candidates.Sort((a, b) =>
        {
            var lengthComparison = (_gates[a.Close] - _gates[a.Open]).CompareTo(_gates[b.Close] - _gates[b.Open]);
            return lengthComparison != 0 ? lengthComparison : _gates[a.Open].CompareTo(_gates[b.Open]);
        });
        var sauce = Sauce(calculationDay, calculationDay);
        var stream = AskBowl(sauce, 1, SealYear5000);
        var rank = checked((int)ChooseRank(stream, candidates.Count));
        var chosen = candidates[rank - 1];
        return new Year(5000, chosen.Open, chosen.Close, _gates[chosen.Open], _gates[chosen.Close]);
    }

    internal Year NextYear(BigInteger calculationDay, Year knownYear)
    {
        var openIndex = knownYear.CloseGateIndex;
        while (_gates[_maxKnownGateIndex] < _gates[openIndex] + YearMaxDays) EnsureGateIndex(_maxKnownGateIndex + 1);
        var candidates = new List<BigInteger>();
        var closeIndex = openIndex + 1;
        while (true)
        {
            EnsureGateIndex(closeIndex);
            if (_gates[closeIndex] - _gates[openIndex] > YearMaxDays) break;
            if (ValidYearPair(openIndex, closeIndex)) candidates.Add(closeIndex);
            closeIndex++;
        }
        candidates.Sort((a, b) => (_gates[a] - _gates[openIndex]).CompareTo(_gates[b] - _gates[openIndex]));
        if (candidates.Count == 0) throw new InvalidOperationException("لم توجد سنة تالية صالحة.");
        var sauce = Sauce(calculationDay, _gates[openIndex]);
        var stream = AskBowl(sauce, 1, SealNextYear);
        var rank = checked((int)ChooseRank(stream, candidates.Count));
        var chosen = candidates[rank - 1];
        return new Year(knownYear.Number + 1, openIndex, chosen, _gates[openIndex], _gates[chosen]);
    }

    internal Year PreviousYear(BigInteger calculationDay, Year knownYear)
    {
        var closeIndex = knownYear.OpenGateIndex;
        while (_gates[_minKnownGateIndex] > _gates[closeIndex] - YearMaxDays) EnsureGateIndex(_minKnownGateIndex - 1);
        var candidates = new List<BigInteger>();
        var openIndex = closeIndex - 1;
        while (true)
        {
            EnsureGateIndex(openIndex);
            if (_gates[closeIndex] - _gates[openIndex] > YearMaxDays) break;
            if (ValidYearPair(openIndex, closeIndex)) candidates.Add(openIndex);
            openIndex--;
        }
        candidates.Sort((a, b) => (_gates[closeIndex] - _gates[a]).CompareTo(_gates[closeIndex] - _gates[b]));
        if (candidates.Count == 0) throw new InvalidOperationException("لم توجد سنة سابقة صالحة.");
        var sauce = Sauce(calculationDay, _gates[closeIndex]);
        var stream = AskBowl(sauce, 1, SealPreviousYear);
        var rank = checked((int)ChooseRank(stream, candidates.Count));
        var chosen = candidates[rank - 1];
        return new Year(knownYear.Number - 1, chosen, closeIndex, _gates[chosen], _gates[closeIndex]);
    }

    internal Year FindTargetYear(BigInteger calculationDay, BigInteger targetDay)
    {
        var year = Year5000(calculationDay);
        while (targetDay > year.CloseGateDay) year = NextYear(calculationDay, year);
        while (targetDay <= year.OpenGateDay) year = PreviousYear(calculationDay, year);
        if (!(year.OpenGateDay < targetDay && targetDay <= year.CloseGateDay))
            throw new InvalidOperationException("فشل ثابت انتماء اليوم إلى الفترة المفتوحة المغلقة للسنة.");
        return year;
    }

    private static int ToSmallInt(BigInteger value, string field)
    {
        if (value < int.MinValue || value > int.MaxValue) throw new OverflowException("القيمة في الحقل " + field + " أكبر من المجال المحلي المسموح.");
        return (int)value;
    }

    internal int ChooseCutletCount(SauceResult structureSauce, Year year)
    {
        var gateGaps = ToSmallInt(year.CloseGateIndex - year.OpenGateIndex, "عدد فجوات البوابات");
        var candidates = Enumerable.Range(MinCutlets, MaxCutlets - MinCutlets + 1).Where(k => k <= gateGaps).ToArray();
        if (candidates.Length == 0) throw new InvalidOperationException("لا يوجد عدد صالح من الكُتَيْلات.");
        var stream = AskBowl(structureSauce, 2, SealCutletCount);
        var rank = checked((int)ChooseRank(stream, candidates.Length));
        return candidates[rank - 1];
    }

    internal int[] ChooseCutletPartition(BigInteger calculationDay, SauceResult structureSauce, Year year, int cutletCount)
    {
        var gaps = ToSmallInt(year.CloseGateIndex - year.OpenGateIndex, "عدد فجوات البوابات");
        int? required = null;
        var gateIndex = ExactGateIndex(calculationDay);
        if (gateIndex is not null && year.OpenGateIndex < gateIndex.Value && gateIndex.Value < year.CloseGateIndex)
            required = ToSmallInt(gateIndex.Value - year.OpenGateIndex, "إزاحة بوابة يوم العمل");
        var family = new CutletPartitionFamily(gaps, cutletCount, required);
        var stream = AskBowl(structureSauce, 2, SealCutletPartition);
        var rank = ChooseRank(stream, family.Count());
        return family.Unrank1(rank);
    }

    internal int[] ChooseCutletNames(SauceResult structureSauce, int cutletCount)
    {
        var count = FallingFactorial(17, cutletCount);
        var stream = AskBowl(structureSauce, 5, SealCutletNames);
        var rank = ChooseRank(stream, count);
        return UnrankDistinctIndices(17, cutletCount, rank);
    }

    internal CutletRecord[] MaterializeCutlets(Year year, int[] partition, int[] names)
    {
        var result = new CutletRecord[partition.Length];
        var cursorGate = year.OpenGateIndex;
        for (var k = 0; k < partition.Length; k++)
        {
            var openGateIndex = cursorGate;
            var closeGateIndex = cursorGate + partition[k];
            EnsureGateIndex(openGateIndex);
            EnsureGateIndex(closeGateIndex);
            result[k] = new CutletRecord(names[k], openGateIndex, closeGateIndex, _gates[openGateIndex] + 1, _gates[closeGateIndex]);
            cursorGate = closeGateIndex;
        }
        return result;
    }

    internal int ChooseMonthCount(SauceResult structureSauce, Year year)
    {
        var length = year.CloseGateDay - year.OpenGateDay;
        var minMonths = ToSmallInt(CeilDiv(length, MaxMonthDays), "الحد الأدنى لعدد الأشهر");
        var maxMonths = Math.Min(MaxMonths, ToSmallInt(length / MinMonthDays, "الحد الأعلى لعدد الأشهر"));
        if (minMonths < MinMonths || minMonths > maxMonths || maxMonths > MaxMonths)
            throw new InvalidOperationException("حدود عدد الأشهر غير صالحة.");
        var stream = AskBowl(structureSauce, 3, SealMonthCount);
        var rank = checked((int)ChooseRank(stream, maxMonths - minMonths + 1));
        return minMonths + rank - 1;
    }

    internal int[] ChooseMonthLengths(SauceResult structureSauce, Year year, int monthCount)
    {
        var length = ToSmallInt(year.CloseGateDay - year.OpenGateDay, "طول السنة");
        var family = new BoundedCompositionFamily(length, monthCount, MinMonthDays, MaxMonthDays);
        var stream = AskBowl(structureSauce, 3, SealMonthLengths);
        var rank = ChooseRank(stream, family.Count());
        return family.Unrank1(rank);
    }

    internal int[] ChooseMonthWeaving(SauceResult structureSauce, int[] monthLengths)
    {
        var family = new WeavingFamily(monthLengths);
        var count = family.Count();
        var stream = AskBowl(structureSauce, 4, SealMonthWeaving);
        var rank = ChooseRank(stream, count);
        return family.Unrank1(rank);
    }

    internal int[] ChooseMonthNames(SauceResult structureSauce, int monthCount)
    {
        var count = FallingFactorial(47, monthCount);
        var stream = AskBowl(structureSauce, 5, SealMonthNames);
        var rank = ChooseRank(stream, count);
        return UnrankDistinctIndices(47, monthCount, rank);
    }

    internal YearStructure BuildYearStructure(BigInteger calculationDay, Year year)
    {
        var firstDay = year.OpenGateDay + 1;
        var sauce = Sauce(calculationDay, firstDay);
        var cutletCount = ChooseCutletCount(sauce, year);
        var partition = ChooseCutletPartition(calculationDay, sauce, year, cutletCount);
        var cutletNames = ChooseCutletNames(sauce, cutletCount);
        var cutlets = MaterializeCutlets(year, partition, cutletNames);
        var monthCount = ChooseMonthCount(sauce, year);
        var monthLengths = ChooseMonthLengths(sauce, year, monthCount);
        var weaving = ChooseMonthWeaving(sauce, monthLengths);
        var monthNames = ChooseMonthNames(sauce, monthCount);
        return new YearStructure(cutletCount, partition, cutletNames, cutlets, monthCount, monthLengths, weaving, monthNames);
    }

    internal NormativeDate CalendarDate(BigInteger calculationDay, BigInteger targetDay)
    {
        var year = FindTargetYear(calculationDay, targetDay);
        var structure = BuildYearStructure(calculationDay, year);
        CutletRecord? chosenCutlet = null;
        foreach (var cutlet in structure.Cutlets)
        {
            if (cutlet.FirstDay <= targetDay && targetDay <= cutlet.LastDay)
            {
                chosenCutlet = cutlet;
                break;
            }
        }
        if (chosenCutlet is null) throw new InvalidOperationException("لم توجد كُتَيْلة تحتوي اليوم المطلوب.");
        var dayInCutlet = targetDay - chosenCutlet.FirstDay + 1;
        var yearOffset0 = ToSmallInt(targetDay - (year.OpenGateDay + 1), "إزاحة اليوم في السنة");
        var monthId = structure.MonthWeaving[yearOffset0];
        var monthNameIndex = structure.MonthNameIndices[monthId - 1];
        var dayInMonth = 0;
        for (var p = 0; p <= yearOffset0; p++) if (structure.MonthWeaving[p] == monthId) dayInMonth++;
        return new NormativeDate(year.Number, chosenCutlet.CanonicalNameIndex, dayInCutlet, monthNameIndex, dayInMonth);
    }

    internal static (BigInteger YearNumber, string CutletName, BigInteger DayInCutlet, string MonthName, int DayInMonth) Present(NormativeDate date)
        => (date.YearNumber, SourceLanguageCatalog.ResolveCutlet(date.CutletCanonicalIndex), date.DayInCutlet, SourceLanguageCatalog.ResolveMonth(date.MonthCanonicalIndex), date.DayInMonth);
}
