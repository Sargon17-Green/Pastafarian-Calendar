using System.Numerics;

namespace PastafarianCalendar.Stage01Tests.Normative;

internal sealed partial class NormativeScroll
{
    private const int Wheat = 1;
    private const int Barley = 2;
    private const int Salt = 3;
    private const int Bitter = 4;
    private const int Red = 5;

    private static readonly int[][] HiddenCoeff =
    {
        Array.Empty<int>(),
        new[] { 3, 4, 6, 8 },
        new[] { 5, 7, 10, 12 },
        new[] { 7, 10, 14, 16 },
        new[] { 9, 13, 18, 20 },
        new[] { 11, 16, 22, 24 },
        new[] { 13, 19, 26, 28 },
        new[] { 15, 22, 30, 32 }
    };

    private static readonly int[] HiddenGrindStone = { 0, Wheat, Barley, Salt, Bitter, Red, Wheat, Barley };

    private static readonly (int A, int B, int C, int D, int Kind)[] VisibleGrinds =
    {
        default,
        (3, 5, 7, 11, Wheat),
        (5, 7, 11, 13, Barley),
        (7, 11, 13, 17, Salt),
        (11, 13, 17, 19, Bitter),
        (13, 17, 19, 23, Red),
        (17, 19, 23, 29, Wheat),
        (19, 23, 29, 31, Barley),
        (23, 29, 31, 37, Salt),
        (29, 31, 37, 41, Bitter),
        (31, 37, 41, 43, Red),
        (37, 41, 43, 47, Wheat)
    };

    private static readonly int[] BowlPrime = { 0, 17, 19, 23, 29, 31, 37 };
    private static readonly int[] BowlStirStoneByPosition = { 0, Wheat, Barley, Salt, Bitter, Red, Wheat };
    private static readonly BigInteger[][] Stones = BuildStones();

    internal static BigInteger[][] BuildStones()
    {
        var stone = new BigInteger[47][];
        stone[1] = new[] { BigInteger.Zero, new BigInteger(17), new BigInteger(29), new BigInteger(43), new BigInteger(71), new BigInteger(101) };
        for (var i = 2; i <= 46; i++)
        {
            var old = stone[i - 1];
            var next = new BigInteger[6];
            next[Wheat] = Save(Square(old[Wheat]) + 3 * old[Barley] + i);
            next[Barley] = Save(Square(old[Barley]) + 5 * old[Salt] + old[Wheat]);
            next[Salt] = Save(Square(old[Salt]) + 7 * old[Bitter] + old[Barley]);
            next[Bitter] = Save(Square(old[Bitter]) + 11 * old[Red] + old[Salt]);
            next[Red] = Save(Square(old[Red]) + 13 * old[Wheat] + old[Bitter]);
            stone[i] = next;
        }
        return stone;
    }

    internal static BigInteger[] BuildHiddenDrops(WorkCounts counts)
    {
        var hidden = new BigInteger[8];
        for (var k = 1; k <= 7; k++)
        {
            var coeff = HiddenCoeff[k];
            var x = counts.Action
                    + coeff[0] * counts.Target
                    + coeff[1] * counts.Distance
                    + coeff[2] * counts.Connection
                    + coeff[3] * counts.Direction
                    + Stones[k][Wheat] + Stones[k][Barley] + Stones[k][Salt] + Stones[k][Bitter] + Stones[k][Red];
            x = Save(x);
            for (var grind = 1; grind <= 7; grind++)
            {
                var oldX = x;
                x = Save(Square(oldX) + 3 * oldX + Stones[k][HiddenGrindStone[grind]] + grind);
            }
            hidden[k] = x;
        }
        return hidden;
    }

    internal static BigInteger[] BuildVisibleDrops(WorkCounts counts, BigInteger[] hidden)
    {
        var timeline = new Dictionary<int, BigInteger>();
        for (var k = 1; k <= 7; k++) timeline[1 - k] = hidden[k];
        var visible = new BigInteger[47];
        for (var i = 1; i <= 46; i++)
        {
            var prev1 = timeline[i - 1];
            var prev3 = timeline[i - 3];
            var prev7 = timeline[i - 7];
            var x = Save(
                Stones[i][Wheat] * counts.Action
                + Stones[i][Barley] * counts.Target
                + Stones[i][Salt] * counts.Distance
                + Stones[i][Bitter] * counts.Connection
                + Stones[i][Red] * counts.Direction
                + prev1 + 3 * prev3 + 5 * prev7 + i);
            for (var grind = 1; grind <= 11; grind++)
            {
                var oldX = x;
                var row = VisibleGrinds[grind];
                x = Save(Square(oldX)
                    + row.A * oldX
                    + row.B * prev1
                    + row.C * prev3
                    + row.D * prev7
                    + Stones[i][row.Kind]);
            }
            timeline[i] = x;
            visible[i] = x;
        }
        return visible;
    }

    internal static int[] PermutationUnrank1(int rank1)
    {
        if (rank1 < 1 || rank1 > 720) throw new ArgumentOutOfRangeException(nameof(rank1), "رتبة ترتيب الأوعية خارج المدى.");
        var rank0 = rank1 - 1;
        var remaining = new List<int> { 1, 2, 3, 4, 5, 6 };
        var result = new List<int>(6);
        for (var slotsLeft = remaining.Count; slotsLeft >= 1; slotsLeft--)
        {
            var block = Factorial(slotsLeft - 1);
            var q = rank0 / block;
            rank0 %= block;
            result.Add(remaining[q]);
            remaining.RemoveAt(q);
        }
        return result.ToArray();
    }

    private static int Factorial(int n)
    {
        var result = 1;
        for (var i = 2; i <= n; i++) result *= i;
        return result;
    }

    internal static int[] BowlOrderFromDrop(BigInteger dropValue)
    {
        var orderNumber = (int)RegularMod(dropValue - 1, 720) + 1;
        return PermutationUnrank1(orderNumber);
    }

    internal static BigInteger[] InitialBowls(WorkCounts counts)
    {
        var bowls = new BigInteger[7];
        for (var bowlId = 1; bowlId <= 6; bowlId++)
        {
            var s = counts.Action + counts.Target * bowlId + counts.Distance + counts.Connection + counts.Direction + BowlPrime[bowlId] * BowlPrime[bowlId];
            bowls[bowlId] = Save(Square(s) + bowlId);
        }
        return bowls;
    }

    internal static (BigInteger[] Bowls, int[] OrderAtDrop46) ApplyVisibleDropsToBowls(BigInteger[] bowlsInput, BigInteger[] visible)
    {
        var bowls = (BigInteger[])bowlsInput.Clone();
        int[]? orderAtDrop46 = null;
        for (var i = 1; i <= 46; i++)
        {
            var drop = visible[i];
            var order = BowlOrderFromDrop(drop);
            var old = (BigInteger[])bowls.Clone();
            var pour = new BigInteger[7];
            pour[1] = Save(Square(drop) + Stones[i][Wheat] * old[order[0]] + 3 * i);
            pour[2] = Save(Square(drop) + Stones[i][Barley] * old[order[1]] + 5 * i);
            pour[3] = Save(Square(drop) + Stones[i][Salt] * old[order[2]] + 7 * i);
            var nextBowls = new BigInteger[7];
            for (var position = 1; position <= 6; position++)
            {
                var bowlId = order[position - 1];
                var prevId = order[Wrap1(position - 1, 6) - 1];
                var nextId = order[Wrap1(position + 1, 6) - 1];
                var stoneKind = BowlStirStoneByPosition[position];
                var s = old[bowlId] + 2 * old[prevId] + 3 * old[nextId] + pour[position] + drop + Stones[i][stoneKind];
                nextBowls[bowlId] = Save(Square(s) + 5 * old[prevId] * old[nextId] + i * position);
            }
            bowls = nextBowls;
            if (i == 46) orderAtDrop46 = (int[])order.Clone();
        }
        return (bowls, orderAtDrop46 ?? throw new InvalidOperationException("لم يُحفظ ترتيب القطرة السادسة والأربعين."));
    }

    internal static BigInteger[] PostStir12(BigInteger[] bowlsInput)
    {
        var bowls = (BigInteger[])bowlsInput.Clone();
        for (var stir = 1; stir <= 12; stir++)
        {
            var old = (BigInteger[])bowls.Clone();
            var savedBowlSum = Save(old[1] + old[2] + old[3] + old[4] + old[5] + old[6] + 149 * stir);
            var orderNumber = (int)RegularMod(savedBowlSum - 1, 720) + 1;
            var order = PermutationUnrank1(orderNumber);
            var nextBowls = new BigInteger[7];
            for (var position = 1; position <= 6; position++)
            {
                var bowlId = order[position - 1];
                var prevId = order[Wrap1(position - 1, 6) - 1];
                var nextId = order[Wrap1(position + 1, 6) - 1];
                var s = old[bowlId] + 3 * old[prevId] + 5 * old[nextId] + savedBowlSum + stir + position * position;
                nextBowls[bowlId] = Save(Square(s) + 7 * old[prevId] * old[nextId]);
            }
            bowls = nextBowls;
        }
        return bowls;
    }

    internal static SauceResult Sauce(BigInteger calculationDay, BigInteger targetDay)
    {
        var counts = WorkCountsFor(calculationDay, targetDay);
        var hidden = BuildHiddenDrops(counts);
        var visible = BuildVisibleDrops(counts, hidden);
        var bowls = InitialBowls(counts);
        var afterDrops = ApplyVisibleDropsToBowls(bowls, visible);
        var finalBowls = PostStir12(afterDrops.Bowls);
        return new SauceResult(finalBowls, afterDrops.OrderAtDrop46);
    }

    internal static int NextBowlInDrop46Order(SauceResult sauceResult, int queriedBowlId)
    {
        var position = Array.IndexOf(sauceResult.OrderAtDrop46, queriedBowlId);
        if (position < 0) throw new ArgumentOutOfRangeException(nameof(queriedBowlId), "معرّف الوعاء غير موجود في ترتيب القطرة السادسة والأربعين.");
        return sauceResult.OrderAtDrop46[(position + 1) % 6];
    }

    internal static AnswerStream AskBowl(SauceResult sauceResult, int queriedBowlId, int seal)
    {
        var nextId = NextBowlInDrop46Order(sauceResult, queriedBowlId);
        var first = Save(Square(sauceResult.Bowls[queriedBowlId] + seal + 181) + 179 * sauceResult.Bowls[nextId] + seal);
        var directionNumber = Save(Square(first + seal + 1 + 193) + 193 * first + 197 * sauceResult.Bowls[6]);
        var step = RegularMod(directionNumber, 2) == 1 ? 1 : -1;
        return new AnswerStream(first, step);
    }

    internal static BigInteger AnswerAt(AnswerStream stream, BigInteger k)
        => 1 + RegularMod(stream.First - 1 + stream.DirectionStep * k, M);

    internal static BigInteger ChooseRankShort(AnswerStream stream, BigInteger n)
    {
        if (n < 1 || n > M) throw new ArgumentOutOfRangeException(nameof(n), "حجم العائلة القصيرة غير صحيح.");
        var acceptanceLimit = M / n * n;
        BigInteger k = 0;
        while (true)
        {
            var x = AnswerAt(stream, k);
            if (x <= acceptanceLimit) return RegularMod(x - 1, n) + 1;
            k += 1;
        }
    }

    internal static BigInteger ChooseRankWide(AnswerStream stream, BigInteger n)
    {
        if (n <= M) throw new ArgumentOutOfRangeException(nameof(n), "المسار الواسع لا يقبل عائلة قصيرة.");
        var places = 1;
        var space = M;
        while (space < n)
        {
            places++;
            space *= M;
        }
        BigInteger wide = 1;
        BigInteger weight = 1;
        for (var j = 0; j < places; j++)
        {
            wide += (AnswerAt(stream, j) - 1) * weight;
            weight *= M;
        }
        var limit = space / n * n;
        while (wide > limit) wide = 1 + RegularMod(wide - 1 + stream.DirectionStep, space);
        return RegularMod(wide - 1, n) + 1;
    }

    internal static BigInteger ChooseRank(AnswerStream stream, BigInteger n)
    {
        if (n < 1) throw new ArgumentOutOfRangeException(nameof(n), "حجم العائلة يجب أن يكون موجبًا.");
        return n <= M ? ChooseRankShort(stream, n) : ChooseRankWide(stream, n);
    }
}
