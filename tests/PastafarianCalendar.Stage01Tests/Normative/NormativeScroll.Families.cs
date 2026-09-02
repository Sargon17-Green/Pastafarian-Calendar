using System.Numerics;

namespace PastafarianCalendar.Stage01Tests.Normative;

internal sealed partial class NormativeScroll
{
    internal sealed class BoundedCompositionFamily
    {
        private readonly int _total;
        private readonly int _slots;
        private readonly int _lo;
        private readonly int _hi;
        private readonly Dictionary<(int Rem, int Slots), BigInteger> _memo = new();

        internal BoundedCompositionFamily(int total, int slots, int lo, int hi)
        {
            _total = total;
            _slots = slots;
            _lo = lo;
            _hi = hi;
        }

        private BigInteger CountSuffix(int rem, int slots)
        {
            if (slots == 0) return rem == 0 ? BigInteger.One : BigInteger.Zero;
            if (rem < slots * _lo || rem > slots * _hi) return BigInteger.Zero;
            if (_memo.TryGetValue((rem, slots), out var cached)) return cached;
            BigInteger sum = 0;
            for (var x = _lo; x <= _hi; x++) sum += CountSuffix(rem - x, slots - 1);
            _memo[(rem, slots)] = sum;
            return sum;
        }

        internal BigInteger Count() => CountSuffix(_total, _slots);

        internal int[] Unrank1(BigInteger rank1)
        {
            var total = Count();
            if (rank1 < 1 || rank1 > total) throw new ArgumentOutOfRangeException(nameof(rank1), "رتبة التركيب المحدود خارج المجال.");
            var r = rank1;
            var rem = _total;
            var output = new List<int>(_slots);
            for (var position = 1; position <= _slots; position++)
            {
                var chosen = false;
                for (var x = _lo; x <= _hi; x++)
                {
                    var block = CountSuffix(rem - x, _slots - position);
                    if (r > block)
                    {
                        r -= block;
                        continue;
                    }
                    output.Add(x);
                    rem -= x;
                    chosen = true;
                    break;
                }
                if (!chosen) throw new InvalidOperationException("تعذر فتح رتبة تركيب محدود صحيح.");
            }
            return output.ToArray();
        }
    }

    internal sealed class CutletPartitionFamily
    {
        private readonly int _gaps;
        private readonly int _cutlets;
        private readonly int? _requiredBoundary;
        private readonly Dictionary<(int Rem, int Slots, int Cumulative, bool Hit), BigInteger> _memo = new();

        internal CutletPartitionFamily(int gaps, int cutlets, int? requiredBoundary)
        {
            _gaps = gaps;
            _cutlets = cutlets;
            _requiredBoundary = requiredBoundary;
        }

        private BigInteger CountState(int rem, int slots, int cumulative, bool hitBoundary)
        {
            if (slots == 0)
            {
                if (rem != 0) return BigInteger.Zero;
                return _requiredBoundary is null || hitBoundary ? BigInteger.One : BigInteger.Zero;
            }
            if (rem < slots) return BigInteger.Zero;
            var key = (rem, slots, cumulative, hitBoundary);
            if (_memo.TryGetValue(key, out var cached)) return cached;
            BigInteger total = 0;
            var maxX = rem - (slots - 1);
            for (var x = 1; x <= maxX; x++)
            {
                var nextCumulative = cumulative + x;
                var nextHit = hitBoundary;
                if (_requiredBoundary is not null && !hitBoundary)
                {
                    if (nextCumulative == _requiredBoundary.Value) nextHit = true;
                    else if (nextCumulative > _requiredBoundary.Value) continue;
                }
                total += CountState(rem - x, slots - 1, nextCumulative, nextHit);
            }
            _memo[key] = total;
            return total;
        }

        internal BigInteger Count() => CountState(_gaps, _cutlets, 0, false);

        internal int[] Unrank1(BigInteger rank1)
        {
            var count = Count();
            if (rank1 < 1 || rank1 > count) throw new ArgumentOutOfRangeException(nameof(rank1), "رتبة تقسيم الكُتَيْلات خارج المجال.");
            var r = rank1;
            var rem = _gaps;
            var slots = _cutlets;
            var cumulative = 0;
            var hit = false;
            var output = new List<int>(_cutlets);
            while (slots > 0)
            {
                var maxX = rem - (slots - 1);
                var chosen = false;
                for (var x = 1; x <= maxX; x++)
                {
                    var nextCumulative = cumulative + x;
                    var nextHit = hit;
                    if (_requiredBoundary is not null && !hit)
                    {
                        if (nextCumulative == _requiredBoundary.Value) nextHit = true;
                        else if (nextCumulative > _requiredBoundary.Value) continue;
                    }
                    var block = CountState(rem - x, slots - 1, nextCumulative, nextHit);
                    if (r > block)
                    {
                        r -= block;
                        continue;
                    }
                    output.Add(x);
                    rem -= x;
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
    }

    internal sealed class WeavingFamily
    {
        private readonly int[] _lengths;
        private readonly Dictionary<string, BigInteger> _memo = new(StringComparer.Ordinal);

        internal WeavingFamily(int[] lengths)
        {
            if (lengths.Length == 0 || lengths.Any(x => x <= 0))
                throw new ArgumentException("أطوال الأشهر يجب أن تكون موجبة.", nameof(lengths));
            _lengths = (int[])lengths.Clone();
        }

        private static string Key(int[] remaining, int openedUpTo, int closedUpTo)
            => openedUpTo.ToString(System.Globalization.CultureInfo.InvariantCulture)
               + ":" + closedUpTo.ToString(System.Globalization.CultureInfo.InvariantCulture)
               + ":" + string.Join(',', remaining);

        private bool LegalMove(int[] remaining, int openedUpTo, int closedUpTo, int j)
        {
            var index = j - 1;
            if (remaining[index] == 0) return false;
            var alreadyOpened = remaining[index] < _lengths[index];
            if (!alreadyOpened && j != openedUpTo + 1) return false;
            var willClose = remaining[index] == 1;
            if (willClose && j != closedUpTo + 1) return false;
            return true;
        }

        private (int[] Remaining, int Opened, int Closed) ApplyMove(int[] remaining, int openedUpTo, int closedUpTo, int j)
        {
            var next = (int[])remaining.Clone();
            var index = j - 1;
            var opened = openedUpTo;
            var closed = closedUpTo;
            if (next[index] == _lengths[index]) opened = j;
            next[index]--;
            if (next[index] == 0) closed = j;
            return (next, opened, closed);
        }

        private BigInteger CountState(int[] remaining, int openedUpTo, int closedUpTo)
        {
            if (remaining.All(x => x == 0)) return BigInteger.One;
            var key = Key(remaining, openedUpTo, closedUpTo);
            if (_memo.TryGetValue(key, out var cached)) return cached;
            BigInteger total = 0;
            for (var j = 1; j <= _lengths.Length; j++)
            {
                if (!LegalMove(remaining, openedUpTo, closedUpTo, j)) continue;
                var next = ApplyMove(remaining, openedUpTo, closedUpTo, j);
                total += CountState(next.Remaining, next.Opened, next.Closed);
            }
            _memo[key] = total;
            return total;
        }

        internal BigInteger Count()
        {
            var remaining = (int[])_lengths.Clone();
            return CountState(remaining, 0, 0);
        }

        internal int[] Unrank1(BigInteger rank1)
        {
            var count = Count();
            if (rank1 < 1 || rank1 > count) throw new ArgumentOutOfRangeException(nameof(rank1), "رتبة النسيج خارج المجال.");
            var remaining = (int[])_lengths.Clone();
            var opened = 0;
            var closed = 0;
            var r = rank1;
            var output = new List<int>(_lengths.Sum());
            while (output.Count < _lengths.Sum())
            {
                var chosen = false;
                for (var j = 1; j <= _lengths.Length; j++)
                {
                    if (!LegalMove(remaining, opened, closed, j)) continue;
                    var next = ApplyMove(remaining, opened, closed, j);
                    var block = CountState(next.Remaining, next.Opened, next.Closed);
                    if (r > block)
                    {
                        r -= block;
                        continue;
                    }
                    output.Add(j);
                    remaining = next.Remaining;
                    opened = next.Opened;
                    closed = next.Closed;
                    chosen = true;
                    break;
                }
                if (!chosen) throw new InvalidOperationException("تعذر فتح رتبة نسيج صحيحة.");
            }
            return output.ToArray();
        }
    }
}
