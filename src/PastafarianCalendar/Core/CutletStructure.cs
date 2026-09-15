using System.Numerics;

namespace PastafarianCalendar.Core;

public sealed record CutletRecord(int CanonicalNameIndex, BigInteger OpenGateIndex, BigInteger CloseGateIndex, BigInteger FirstDay, BigInteger LastDay);
public sealed record CutletStructure(int Count, int[] Partition, int[] CanonicalNameIndices, CutletRecord[] Cutlets);

public sealed class CutletPartitionFamily
{
    private readonly int _gaps;
    private readonly int _cutlets;
    private readonly int? _requiredBoundary;
    private readonly Dictionary<(int Remaining, int Slots, int Cumulative, bool Hit), BigInteger> _memo = new();

    public CutletPartitionFamily(int gaps, int cutlets, int? requiredBoundary)
    {
        _gaps = gaps;
        _cutlets = cutlets;
        _requiredBoundary = requiredBoundary;
    }

    public BigInteger Count() => CountState(_gaps, _cutlets, 0, false);

    public int[] Unrank1(BigInteger rank1)
    {
        if (rank1 < BigInteger.One || rank1 > Count())
            throw new ArgumentOutOfRangeException(nameof(rank1), "رتبة تقسيم الكُتَيْلات خارج المجال.");
        var rank = rank1;
        var remaining = _gaps;
        var slots = _cutlets;
        var cumulative = 0;
        var hit = false;
        var output = new List<int>(_cutlets);
        while (slots > 0)
        {
            var chosen = false;
            for (var item = 1; item <= remaining - (slots - 1); item++)
            {
                var nextCumulative = cumulative + item;
                var nextHit = BoundaryState(nextCumulative, hit, out var allowed);
                if (!allowed) continue;
                var block = CountState(remaining - item, slots - 1, nextCumulative, nextHit);
                if (rank > block) { rank -= block; continue; }
                output.Add(item);
                remaining -= item;
                slots--;
                cumulative = nextCumulative;
                hit = nextHit;
                chosen = true;
                break;
            }
            if (!chosen) throw new InvalidOperationException("تعذر فتح رتبة تقسيم كُتَيْلات صحيح.");
        }
        return output.ToArray();
    }

    private BigInteger CountState(int remaining, int slots, int cumulative, bool hit)
    {
        if (slots == 0)
            return remaining == 0 && (_requiredBoundary is null || hit) ? BigInteger.One : BigInteger.Zero;
        if (remaining < slots) return BigInteger.Zero;
        var key = (remaining, slots, cumulative, hit);
        if (_memo.TryGetValue(key, out var cached)) return cached;
        BigInteger total = BigInteger.Zero;
        for (var item = 1; item <= remaining - (slots - 1); item++)
        {
            var nextCumulative = cumulative + item;
            var nextHit = BoundaryState(nextCumulative, hit, out var allowed);
            if (allowed) total += CountState(remaining - item, slots - 1, nextCumulative, nextHit);
        }
        return _memo[key] = total;
    }

    private bool BoundaryState(int cumulative, bool hit, out bool allowed)
    {
        allowed = true;
        if (_requiredBoundary is null || hit) return hit;
        if (cumulative == _requiredBoundary.Value) return true;
        if (cumulative > _requiredBoundary.Value) allowed = false;
        return false;
    }
}

public sealed class CutletSelection
{
    private const int CutletCountSeal = 20;
    private const int CutletPartitionSeal = 21;
    private const int CutletNamesSeal = 22;
    private readonly GateDiscovery _gates;

    public CutletSelection(GateDiscovery gates) => _gates = gates;

    public CutletStructure Select(BigInteger calculationDay, CalendarYear year)
    {
        var sauce = SauceCore.Brew(calculationDay, year.OpenGateDay + BigInteger.One);
        var count = ChooseCount(sauce, year);
        var partition = ChoosePartition(calculationDay, sauce, year, count);
        var names = ChooseNames(sauce, count);
        return new CutletStructure(count, partition, names, Materialize(year, partition, names));
    }

    private int ChooseCount(SauceResult sauce, CalendarYear year)
    {
        var gaps = ToSmallInt(year.CloseGateIndex - year.OpenGateIndex);
        var candidates = Enumerable.Range(6, 12).Where(count => count <= gaps).ToArray();
        if (candidates.Length == 0) throw new InvalidOperationException("لا يوجد عدد صالح من الكُتَيْلات.");
        var rank = SauceCore.ChooseRank(SauceCore.AskBowl(sauce, 2, CutletCountSeal), candidates.Length);
        return candidates[checked((int)rank) - 1];
    }

    private int[] ChoosePartition(BigInteger calculationDay, SauceResult sauce, CalendarYear year, int count)
    {
        int? required = null;
        var gate = _gates.ExactGateIndex(calculationDay);
        if (gate is not null && year.OpenGateIndex < gate.Value && gate.Value < year.CloseGateIndex)
            required = ToSmallInt(gate.Value - year.OpenGateIndex);
        var family = new CutletPartitionFamily(ToSmallInt(year.CloseGateIndex - year.OpenGateIndex), count, required);
        return family.Unrank1(SauceCore.ChooseRank(SauceCore.AskBowl(sauce, 2, CutletPartitionSeal), family.Count()));
    }

    private static int[] ChooseNames(SauceResult sauce, int count)
    {
        var rank = SauceCore.ChooseRank(SauceCore.AskBowl(sauce, 5, CutletNamesSeal), CanonicalArithmetic.FallingFactorial(17, count));
        return CanonicalArithmetic.UnrankDistinctIndices(17, count, rank);
    }

    private CutletRecord[] Materialize(CalendarYear year, int[] partition, int[] names)
    {
        var output = new CutletRecord[partition.Length];
        var open = year.OpenGateIndex;
        for (var index = 0; index < partition.Length; index++)
        {
            var close = open + partition[index];
            output[index] = new CutletRecord(names[index], open, close, _gates.GateDay(open) + BigInteger.One, _gates.GateDay(close));
            open = close;
        }
        return output;
    }

    private static int ToSmallInt(BigInteger value)
    {
        if (value < int.MinValue || value > int.MaxValue) throw new OverflowException("القيمة أكبر من المجال المحلي المسموح.");
        return (int)value;
    }
}
