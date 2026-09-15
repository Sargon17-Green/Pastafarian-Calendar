using System.Numerics;

namespace PastafarianCalendar.Core;

public sealed record CalendarYear(BigInteger Number, BigInteger OpenGateIndex, BigInteger CloseGateIndex, BigInteger OpenGateDay, BigInteger CloseGateDay);

public sealed class YearSelection
{
    private const int Year5000Seal = 10;
    private const int NextYearSeal = 11;
    private const int PreviousYearSeal = 12;
    public const int MinimumYearDays = 252;
    public const int MaximumYearDays = 5778;

    private readonly GateDiscovery _gates;

    public YearSelection(GateDiscovery? gates = null) => _gates = gates ?? new GateDiscovery();

    public CalendarYear Year5000(BigInteger calculationDay)
    {
        var lowDay = calculationDay - MaximumYearDays;
        var highDay = calculationDay + MaximumYearDays;
        _gates.EnsureGatesCover(lowDay, highDay);
        var lowIndex = _gates.GateIndexAtOrBefore(lowDay);
        var highIndex = _gates.GateIndexAtOrBefore(highDay);
        if (_gates.GateDay(highIndex) < highDay) highIndex += BigInteger.One;

        var candidates = new List<(BigInteger Open, BigInteger Close)>();
        for (var open = lowIndex; open < highIndex; open++)
        {
            for (var close = open + BigInteger.One; close <= highIndex; close++)
            {
                if (!IsValidPair(open, close)) continue;
                if (_gates.GateDay(open) < calculationDay && calculationDay <= _gates.GateDay(close))
                    candidates.Add((open, close));
            }
        }
        if (candidates.Count == 0)
            throw new InvalidOperationException("لم توجد سنة مرشحة للعام خمسة آلاف.");

        candidates.Sort((left, right) =>
        {
            var length = (_gates.GateDay(left.Close) - _gates.GateDay(left.Open)).CompareTo(_gates.GateDay(right.Close) - _gates.GateDay(right.Open));
            return length != 0 ? length : _gates.GateDay(left.Open).CompareTo(_gates.GateDay(right.Open));
        });
        var stream = SauceCore.AskBowl(SauceCore.Brew(calculationDay, calculationDay), 1, Year5000Seal);
        var chosen = candidates[checked((int)SauceCore.ChooseRank(stream, candidates.Count)) - 1];
        return Materialize(BigInteger.Parse("5000"), chosen.Open, chosen.Close);
    }

    public CalendarYear NextYear(BigInteger calculationDay, CalendarYear known)
    {
        var open = known.CloseGateIndex;
        var candidates = new List<BigInteger>();
        for (var close = open + BigInteger.One; ; close++)
        {
            var length = _gates.GateDay(close) - _gates.GateDay(open);
            if (length > MaximumYearDays) break;
            if (IsValidPair(open, close)) candidates.Add(close);
        }
        if (candidates.Count == 0)
            throw new InvalidOperationException("لم توجد سنة تالية صالحة.");
        candidates.Sort((left, right) => (_gates.GateDay(left) - _gates.GateDay(open)).CompareTo(_gates.GateDay(right) - _gates.GateDay(open)));
        var stream = SauceCore.AskBowl(SauceCore.Brew(calculationDay, _gates.GateDay(open)), 1, NextYearSeal);
        var closeIndex = candidates[checked((int)SauceCore.ChooseRank(stream, candidates.Count)) - 1];
        return Materialize(known.Number + BigInteger.One, open, closeIndex);
    }

    public CalendarYear PreviousYear(BigInteger calculationDay, CalendarYear known)
    {
        var close = known.OpenGateIndex;
        var candidates = new List<BigInteger>();
        for (var open = close - BigInteger.One; ; open--)
        {
            var length = _gates.GateDay(close) - _gates.GateDay(open);
            if (length > MaximumYearDays) break;
            if (IsValidPair(open, close)) candidates.Add(open);
        }
        if (candidates.Count == 0)
            throw new InvalidOperationException("لم توجد سنة سابقة صالحة.");
        candidates.Sort((left, right) => (_gates.GateDay(close) - _gates.GateDay(left)).CompareTo(_gates.GateDay(close) - _gates.GateDay(right)));
        var stream = SauceCore.AskBowl(SauceCore.Brew(calculationDay, _gates.GateDay(close)), 1, PreviousYearSeal);
        var openIndex = candidates[checked((int)SauceCore.ChooseRank(stream, candidates.Count)) - 1];
        return Materialize(known.Number - BigInteger.One, openIndex, close);
    }

    public CalendarYear FindTargetYear(BigInteger calculationDay, BigInteger targetDay)
    {
        var year = Year5000(calculationDay);
        while (targetDay > year.CloseGateDay) year = NextYear(calculationDay, year);
        while (targetDay <= year.OpenGateDay) year = PreviousYear(calculationDay, year);
        if (year.OpenGateDay >= targetDay || targetDay > year.CloseGateDay)
            throw new InvalidOperationException("فشل ثابت انتماء اليوم إلى الفترة المفتوحة المغلقة للسنة.");
        return year;
    }

    private bool IsValidPair(BigInteger open, BigInteger close)
    {
        if (close - open < 6) return false;
        var length = _gates.GateDay(close) - _gates.GateDay(open);
        return length >= MinimumYearDays && length <= MaximumYearDays;
    }

    private CalendarYear Materialize(BigInteger number, BigInteger open, BigInteger close)
        => new(number, open, close, _gates.GateDay(open), _gates.GateDay(close));
}
