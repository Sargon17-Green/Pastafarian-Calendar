using System.Numerics;

namespace PastafarianCalendar.Core;

public sealed record CalendarWorkCounts(
    BigInteger CalculationCount,
    BigInteger TargetCount,
    BigInteger DistanceCount,
    BigInteger ConnectionCount,
    int Direction);

public static class CanonicalArithmetic
{
    public static readonly BigInteger SauceModulus = (BigInteger.One << 127) - BigInteger.One;
    public static readonly BigInteger TabletsDay = new(-278522);
    public static readonly BigInteger FoundationDay = new(-15055671);

    public static BigInteger RegularMod(BigInteger value, BigInteger divisor)
    {
        if (divisor < BigInteger.One)
            throw new ArgumentOutOfRangeException(nameof(divisor), "يجب أن يكون المقسوم عليه موجبًا.");

        var remainder = value % divisor;
        return remainder.Sign < 0 ? remainder + divisor : remainder;
    }

    public static BigInteger Save(BigInteger value) => BigInteger.One + RegularMod(value - BigInteger.One, SauceModulus);

    public static BigInteger Square(BigInteger value) => value * value;

    public static BigInteger CeilingDivide(BigInteger dividend, BigInteger divisor)
    {
        if (dividend.Sign < 0 || divisor < BigInteger.One)
            throw new ArgumentOutOfRangeException(nameof(dividend), "القسمة السقفية هنا معرفة للأعداد غير السالبة فقط.");

        return (dividend + divisor - BigInteger.One) / divisor;
    }

    public static int Wrap1(int position, int size)
    {
        if (size < 1)
            throw new ArgumentOutOfRangeException(nameof(size), "الحجم يجب أن يكون موجبًا.");

        var remainder = (position - 1) % size;
        if (remainder < 0)
            remainder += size;
        return remainder + 1;
    }

    public static BigInteger DayCount(BigInteger day)
    {
        if (day == FoundationDay)
            return BigInteger.One;
        return day > FoundationDay
            ? 2 * (day - FoundationDay) + BigInteger.One
            : 2 * (FoundationDay - day);
    }

    public static CalendarWorkCounts WorkCountsFor(BigInteger calculationDay, BigInteger targetDay)
    {
        var calculation = DayCount(calculationDay);
        var target = DayCount(targetDay);
        var distance = BigInteger.Abs(targetDay - calculationDay) + BigInteger.One;
        var direction = targetDay < calculationDay ? 1 : targetDay == calculationDay ? 2 : 3;
        return new CalendarWorkCounts(calculation, target, distance, calculation + target, direction);
    }

    public static BigInteger FallingFactorial(int n, int k)
    {
        if (k < 0 || k > n)
            return BigInteger.Zero;

        BigInteger result = BigInteger.One;
        for (var offset = 0; offset < k; offset++)
            result *= n - offset;
        return result;
    }

    public static int[] UnrankDistinctIndices(int masterCount, int length, BigInteger rank1)
    {
        var total = FallingFactorial(masterCount, length);
        if (rank1 < BigInteger.One || rank1 > total)
            throw new ArgumentOutOfRangeException(nameof(rank1), "الرتبة خارج مجال التبديلات الجزئية.");

        var remaining = Enumerable.Range(1, masterCount).ToList();
        var output = new List<int>(length);
        var rank = rank1;

        for (var position = 1; position <= length; position++)
        {
            var block = FallingFactorial(remaining.Count - 1, length - position);
            for (var candidate = 0; candidate < remaining.Count; candidate++)
            {
                if (rank > block)
                {
                    rank -= block;
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
