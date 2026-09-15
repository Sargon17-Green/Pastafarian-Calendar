using System.Numerics;

namespace PastafarianCalendar.Core;

public sealed class GateDiscovery
{
    private const int GateGapSeal = 1;
    private readonly Dictionary<BigInteger, BigInteger> _gates = new() { [BigInteger.Zero] = CanonicalArithmetic.FoundationDay };
    private BigInteger _minimumKnownIndex = BigInteger.Zero;
    private BigInteger _maximumKnownIndex = BigInteger.Zero;

    public BigInteger PositiveGateGap(BigInteger step)
    {
        if (step < BigInteger.One)
            throw new ArgumentOutOfRangeException(nameof(step), "رقم خطوة البوابة الموجبة يجب أن يكون موجبًا.");
        return BigInteger.Parse("41") + SauceCore.ChooseRank(SauceCore.AskBowl(SauceCore.Brew(CanonicalArithmetic.FoundationDay, CanonicalArithmetic.FoundationDay + step), 1, GateGapSeal), 922);
    }

    public BigInteger NegativeGateGap(BigInteger step)
    {
        if (step < BigInteger.One)
            throw new ArgumentOutOfRangeException(nameof(step), "رقم خطوة البوابة السالبة يجب أن يكون موجب المقدار.");
        return BigInteger.Parse("41") + SauceCore.ChooseRank(SauceCore.AskBowl(SauceCore.Brew(CanonicalArithmetic.FoundationDay, CanonicalArithmetic.FoundationDay - step), 1, GateGapSeal), 922);
    }

    public BigInteger GateDay(BigInteger index)
    {
        EnsureGateIndex(index);
        return _gates[index];
    }

    public BigInteger GateIndexAtOrBefore(BigInteger day)
    {
        EnsureGatesCover(day, day);
        var low = _minimumKnownIndex;
        var high = _maximumKnownIndex;
        while (low < high)
        {
            var middle = low + (high - low + BigInteger.One) / 2;
            if (_gates[middle] <= day) low = middle;
            else high = middle - BigInteger.One;
        }
        return low;
    }

    public BigInteger? ExactGateIndex(BigInteger day)
    {
        var index = GateIndexAtOrBefore(day);
        return _gates[index] == day ? index : null;
    }

    public void EnsureGatesCover(BigInteger lowDay, BigInteger highDay)
    {
        if (lowDay > highDay)
            throw new ArgumentException("حدود التغطية معكوسة.");
        while (_gates[_minimumKnownIndex] > lowDay) EnsureGateIndex(_minimumKnownIndex - BigInteger.One);
        while (_gates[_maximumKnownIndex] < highDay) EnsureGateIndex(_maximumKnownIndex + BigInteger.One);
    }

    private void EnsureGateIndex(BigInteger index)
    {
        if (index > _maximumKnownIndex)
        {
            for (var step = _maximumKnownIndex + BigInteger.One; step <= index; step++)
            {
                _gates[step] = _gates[step - BigInteger.One] + PositiveGateGap(step);
                _maximumKnownIndex = step;
            }
        }
        if (index < _minimumKnownIndex)
        {
            for (var step = _minimumKnownIndex - BigInteger.One; step >= index; step--)
            {
                _gates[step] = _gates[step + BigInteger.One] - NegativeGateGap(BigInteger.Abs(step));
                _minimumKnownIndex = step;
            }
        }
    }
}
