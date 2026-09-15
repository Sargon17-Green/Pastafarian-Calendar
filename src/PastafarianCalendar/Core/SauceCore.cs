using System.Numerics;

namespace PastafarianCalendar.Core;

public sealed record SauceResult(BigInteger[] Bowls, int[] OrderAtDrop46);
public sealed record AnswerStream(BigInteger First, int DirectionStep);

public static class SauceCore
{
    private const int Wheat = 1;
    private const int Barley = 2;
    private const int Salt = 3;
    private const int Bitter = 4;
    private const int Red = 5;

    private static readonly int[][] HiddenCoeff =
    {
        Array.Empty<int>(), new[] { 3, 4, 6, 8 }, new[] { 5, 7, 10, 12 }, new[] { 7, 10, 14, 16 },
        new[] { 9, 13, 18, 20 }, new[] { 11, 16, 22, 24 }, new[] { 13, 19, 26, 28 }, new[] { 15, 22, 30, 32 }
    };

    private static readonly int[] HiddenGrindStone = { 0, Wheat, Barley, Salt, Bitter, Red, Wheat, Barley };
    private static readonly (int A, int B, int C, int D, int Kind)[] VisibleGrinds =
    {
        default, (3, 5, 7, 11, Wheat), (5, 7, 11, 13, Barley), (7, 11, 13, 17, Salt),
        (11, 13, 17, 19, Bitter), (13, 17, 19, 23, Red), (17, 19, 23, 29, Wheat),
        (19, 23, 29, 31, Barley), (23, 29, 31, 37, Salt), (29, 31, 37, 41, Bitter),
        (31, 37, 41, 43, Red), (37, 41, 43, 47, Wheat)
    };

    private static readonly int[] BowlPrime = { 0, 17, 19, 23, 29, 31, 37 };
    private static readonly int[] BowlStirStoneByPosition = { 0, Wheat, Barley, Salt, Bitter, Red, Wheat };
    private static readonly BigInteger[][] Stones = BuildStones();

    public static SauceResult Brew(BigInteger calculationDay, BigInteger targetDay)
    {
        var counts = CanonicalArithmetic.WorkCountsFor(calculationDay, targetDay);
        var hidden = BuildHiddenDrops(counts);
        var visible = BuildVisibleDrops(counts, hidden);
        var afterDrops = ApplyVisibleDropsToBowls(InitialBowls(counts), visible);
        return new SauceResult(PostStir12(afterDrops.Bowls), afterDrops.OrderAtDrop46);
    }

    public static int NextBowlInDrop46Order(SauceResult sauce, int queriedBowlId)
    {
        var position = Array.IndexOf(sauce.OrderAtDrop46, queriedBowlId);
        if (position < 0)
            throw new ArgumentOutOfRangeException(nameof(queriedBowlId), "معرّف الوعاء غير موجود في ترتيب القطرة السادسة والأربعين.");
        return sauce.OrderAtDrop46[(position + 1) % 6];
    }

    public static AnswerStream AskBowl(SauceResult sauce, int queriedBowlId, int seal)
    {
        var next = NextBowlInDrop46Order(sauce, queriedBowlId);
        var first = CanonicalArithmetic.Save(CanonicalArithmetic.Square(sauce.Bowls[queriedBowlId] + seal + 181) + 179 * sauce.Bowls[next] + seal);
        var directionNumber = CanonicalArithmetic.Save(CanonicalArithmetic.Square(first + seal + 194) + 193 * first + 197 * sauce.Bowls[6]);
        return new AnswerStream(first, CanonicalArithmetic.RegularMod(directionNumber, 2) == 1 ? 1 : -1);
    }

    public static BigInteger AnswerAt(AnswerStream stream, BigInteger position)
        => BigInteger.One + CanonicalArithmetic.RegularMod(stream.First - BigInteger.One + stream.DirectionStep * position, CanonicalArithmetic.SauceModulus);

    public static BigInteger ChooseRank(AnswerStream stream, BigInteger familySize)
    {
        if (familySize < BigInteger.One)
            throw new ArgumentOutOfRangeException(nameof(familySize), "حجم العائلة يجب أن يكون موجبًا.");
        return familySize <= CanonicalArithmetic.SauceModulus ? ChooseRankShort(stream, familySize) : ChooseRankWide(stream, familySize);
    }

    private static BigInteger[][] BuildStones()
    {
        var stone = new BigInteger[47][];
        stone[1] = new[] { BigInteger.Zero, new BigInteger(17), new BigInteger(29), new BigInteger(43), new BigInteger(71), new BigInteger(101) };
        for (var i = 2; i <= 46; i++)
        {
            var old = stone[i - 1];
            stone[i] = new[]
            {
                BigInteger.Zero,
                CanonicalArithmetic.Save(CanonicalArithmetic.Square(old[Wheat]) + 3 * old[Barley] + i),
                CanonicalArithmetic.Save(CanonicalArithmetic.Square(old[Barley]) + 5 * old[Salt] + old[Wheat]),
                CanonicalArithmetic.Save(CanonicalArithmetic.Square(old[Salt]) + 7 * old[Bitter] + old[Barley]),
                CanonicalArithmetic.Save(CanonicalArithmetic.Square(old[Bitter]) + 11 * old[Red] + old[Salt]),
                CanonicalArithmetic.Save(CanonicalArithmetic.Square(old[Red]) + 13 * old[Wheat] + old[Bitter])
            };
        }
        return stone;
    }

    private static BigInteger[] BuildHiddenDrops(CalendarWorkCounts counts)
    {
        var hidden = new BigInteger[8];
        for (var k = 1; k <= 7; k++)
        {
            var coeff = HiddenCoeff[k];
            var value = CanonicalArithmetic.Save(counts.CalculationCount + coeff[0] * counts.TargetCount + coeff[1] * counts.DistanceCount + coeff[2] * counts.ConnectionCount + coeff[3] * counts.Direction + Stones[k][Wheat] + Stones[k][Barley] + Stones[k][Salt] + Stones[k][Bitter] + Stones[k][Red]);
            for (var grind = 1; grind <= 7; grind++)
                value = CanonicalArithmetic.Save(CanonicalArithmetic.Square(value) + 3 * value + Stones[k][HiddenGrindStone[grind]] + grind);
            hidden[k] = value;
        }
        return hidden;
    }

    private static BigInteger[] BuildVisibleDrops(CalendarWorkCounts counts, BigInteger[] hidden)
    {
        var timeline = new Dictionary<int, BigInteger>();
        for (var k = 1; k <= 7; k++) timeline[1 - k] = hidden[k];
        var visible = new BigInteger[47];
        for (var i = 1; i <= 46; i++)
        {
            var previous1 = timeline[i - 1];
            var previous3 = timeline[i - 3];
            var previous7 = timeline[i - 7];
            var value = CanonicalArithmetic.Save(Stones[i][Wheat] * counts.CalculationCount + Stones[i][Barley] * counts.TargetCount + Stones[i][Salt] * counts.DistanceCount + Stones[i][Bitter] * counts.ConnectionCount + Stones[i][Red] * counts.Direction + previous1 + 3 * previous3 + 5 * previous7 + i);
            for (var grind = 1; grind <= 11; grind++)
            {
                var row = VisibleGrinds[grind];
                value = CanonicalArithmetic.Save(CanonicalArithmetic.Square(value) + row.A * value + row.B * previous1 + row.C * previous3 + row.D * previous7 + Stones[i][row.Kind]);
            }
            timeline[i] = value;
            visible[i] = value;
        }
        return visible;
    }

    private static BigInteger[] InitialBowls(CalendarWorkCounts counts)
    {
        var bowls = new BigInteger[7];
        for (var bowl = 1; bowl <= 6; bowl++)
        {
            var sum = counts.CalculationCount + counts.TargetCount * bowl + counts.DistanceCount + counts.ConnectionCount + counts.Direction + BowlPrime[bowl] * BowlPrime[bowl];
            bowls[bowl] = CanonicalArithmetic.Save(CanonicalArithmetic.Square(sum) + bowl);
        }
        return bowls;
    }

    private static SauceResult ApplyVisibleDropsToBowls(BigInteger[] input, BigInteger[] visible)
    {
        var bowls = (BigInteger[])input.Clone();
        int[]? finalOrder = null;
        for (var dropIndex = 1; dropIndex <= 46; dropIndex++)
        {
            var drop = visible[dropIndex];
            var order = BowlOrderFromDrop(drop);
            var old = (BigInteger[])bowls.Clone();
            var pour = new BigInteger[7];
            pour[1] = CanonicalArithmetic.Save(CanonicalArithmetic.Square(drop) + Stones[dropIndex][Wheat] * old[order[0]] + 3 * dropIndex);
            pour[2] = CanonicalArithmetic.Save(CanonicalArithmetic.Square(drop) + Stones[dropIndex][Barley] * old[order[1]] + 5 * dropIndex);
            pour[3] = CanonicalArithmetic.Save(CanonicalArithmetic.Square(drop) + Stones[dropIndex][Salt] * old[order[2]] + 7 * dropIndex);
            var next = new BigInteger[7];
            for (var position = 1; position <= 6; position++)
            {
                var bowl = order[position - 1];
                var previous = order[CanonicalArithmetic.Wrap1(position - 1, 6) - 1];
                var following = order[CanonicalArithmetic.Wrap1(position + 1, 6) - 1];
                var sum = old[bowl] + 2 * old[previous] + 3 * old[following] + pour[position] + drop + Stones[dropIndex][BowlStirStoneByPosition[position]];
                next[bowl] = CanonicalArithmetic.Save(CanonicalArithmetic.Square(sum) + 5 * old[previous] * old[following] + dropIndex * position);
            }
            bowls = next;
            if (dropIndex == 46) finalOrder = (int[])order.Clone();
        }
        return new SauceResult(bowls, finalOrder ?? throw new InvalidOperationException("لم يُحفظ ترتيب القطرة السادسة والأربعين."));
    }

    private static BigInteger[] PostStir12(BigInteger[] input)
    {
        var bowls = (BigInteger[])input.Clone();
        for (var stir = 1; stir <= 12; stir++)
        {
            var old = (BigInteger[])bowls.Clone();
            var savedSum = CanonicalArithmetic.Save(old[1] + old[2] + old[3] + old[4] + old[5] + old[6] + 149 * stir);
            var order = BowlOrderFromDrop(savedSum);
            var next = new BigInteger[7];
            for (var position = 1; position <= 6; position++)
            {
                var bowl = order[position - 1];
                var previous = order[CanonicalArithmetic.Wrap1(position - 1, 6) - 1];
                var following = order[CanonicalArithmetic.Wrap1(position + 1, 6) - 1];
                var sum = old[bowl] + 3 * old[previous] + 5 * old[following] + savedSum + stir + position * position;
                next[bowl] = CanonicalArithmetic.Save(CanonicalArithmetic.Square(sum) + 7 * old[previous] * old[following]);
            }
            bowls = next;
        }
        return bowls;
    }

    private static int[] BowlOrderFromDrop(BigInteger drop)
        => PermutationUnrank1((int)CanonicalArithmetic.RegularMod(drop - BigInteger.One, 720) + 1);

    private static int[] PermutationUnrank1(int rank1)
    {
        if (rank1 < 1 || rank1 > 720)
            throw new ArgumentOutOfRangeException(nameof(rank1), "رتبة ترتيب الأوعية خارج المدى.");
        var rank0 = rank1 - 1;
        var remaining = new List<int> { 1, 2, 3, 4, 5, 6 };
        var result = new int[6];
        for (var position = 0; position < 6; position++)
        {
            var block = Factorial(remaining.Count - 1);
            var index = rank0 / block;
            rank0 %= block;
            result[position] = remaining[index];
            remaining.RemoveAt(index);
        }
        return result;
    }

    private static int Factorial(int n)
    {
        var result = 1;
        for (var i = 2; i <= n; i++) result *= i;
        return result;
    }

    private static BigInteger ChooseRankShort(AnswerStream stream, BigInteger size)
    {
        var acceptanceLimit = CanonicalArithmetic.SauceModulus / size * size;
        for (BigInteger position = 0; ; position++)
        {
            var value = AnswerAt(stream, position);
            if (value <= acceptanceLimit) return CanonicalArithmetic.RegularMod(value - BigInteger.One, size) + BigInteger.One;
        }
    }

    private static BigInteger ChooseRankWide(AnswerStream stream, BigInteger size)
    {
        var places = 1;
        var space = CanonicalArithmetic.SauceModulus;
        while (space < size) { places++; space *= CanonicalArithmetic.SauceModulus; }
        BigInteger wide = BigInteger.One;
        BigInteger weight = BigInteger.One;
        for (var index = 0; index < places; index++)
        {
            wide += (AnswerAt(stream, index) - BigInteger.One) * weight;
            weight *= CanonicalArithmetic.SauceModulus;
        }
        var limit = space / size * size;
        while (wide > limit) wide = BigInteger.One + CanonicalArithmetic.RegularMod(wide - BigInteger.One + stream.DirectionStep, space);
        return CanonicalArithmetic.RegularMod(wide - BigInteger.One, size) + BigInteger.One;
    }
}
