using System.Numerics;

namespace PastafarianCalendar.Stage01Tests.Normative;

internal sealed partial class NormativeScroll
{
    internal static readonly BigInteger M = (BigInteger.One << 127) - BigInteger.One;
    internal static readonly BigInteger TabletsDay = new(-278522);
    internal static readonly BigInteger FoundationDay = new(-15055671);
    internal const int GateGapMin = 42;
    internal const int GateGapMax = 963;
    internal const int YearMinDays = 252;
    internal const int YearMaxDays = 5778;
    internal const int MinCutlets = 6;
    internal const int MaxCutlets = 17;
    internal const int MinMonths = 3;
    internal const int MaxMonths = 47;
    internal const int MinMonthDays = 4;
    internal const int MaxMonthDays = 123;

    internal static BigInteger RegularMod(BigInteger x, BigInteger d)
    {
        if (d < 1) throw new ArgumentOutOfRangeException(nameof(d), "يجب أن يكون المقسوم عليه موجبًا.");
        var r = x % d;
        return r.Sign < 0 ? r + d : r;
    }

    internal static BigInteger Save(BigInteger x) => BigInteger.One + RegularMod(x - BigInteger.One, M);
    internal static BigInteger Square(BigInteger x) => x * x;

    internal static BigInteger CeilDiv(BigInteger a, BigInteger b)
    {
        if (a.Sign < 0 || b < 1) throw new ArgumentOutOfRangeException(nameof(a), "القسمة السقفية هنا معرفة للأعداد غير السالبة فقط.");
        return (a + b - 1) / b;
    }

    internal static int Wrap1(int position, int size)
    {
        if (size < 1) throw new ArgumentOutOfRangeException(nameof(size), "الحجم يجب أن يكون موجبًا.");
        var r = (position - 1) % size;
        if (r < 0) r += size;
        return r + 1;
    }

    internal static BigInteger DayCount(BigInteger day)
    {
        if (day == FoundationDay) return BigInteger.One;
        if (day > FoundationDay) return 2 * (day - FoundationDay) + 1;
        return 2 * (FoundationDay - day);
    }

    internal static WorkCounts WorkCountsFor(BigInteger calculationDay, BigInteger targetDay)
    {
        var c = DayCount(calculationDay);
        var t = DayCount(targetDay);
        var distance = BigInteger.Abs(targetDay - calculationDay) + 1;
        var connection = c + t;
        var direction = targetDay < calculationDay ? 1 : targetDay == calculationDay ? 2 : 3;
        return new WorkCounts(c, t, distance, connection, direction);
    }

    internal static BigInteger FallingFactorial(int n, int k)
    {
        if (k < 0 || k > n) return BigInteger.Zero;
        BigInteger result = BigInteger.One;
        for (var j = 0; j < k; j++) result *= n - j;
        return result;
    }

    internal static int[] UnrankDistinctIndices(int masterCount, int k, BigInteger rank1)
    {
        var total = FallingFactorial(masterCount, k);
        if (rank1 < 1 || rank1 > total) throw new ArgumentOutOfRangeException(nameof(rank1), "الرتبة خارج مجال التبديلات الجزئية.");
        var remaining = Enumerable.Range(1, masterCount).ToList();
        var output = new List<int>(k);
        var r = rank1;
        for (var position = 1; position <= k; position++)
        {
            var suffixLength = k - position;
            var block = FallingFactorial(remaining.Count - 1, suffixLength);
            for (var candidate = 0; candidate < remaining.Count; candidate++)
            {
                if (r > block)
                {
                    r -= block;
                    continue;
                }
                output.Add(remaining[candidate]);
                remaining.RemoveAt(candidate);
                break;
            }
        }
        return output.ToArray();
    }
}
