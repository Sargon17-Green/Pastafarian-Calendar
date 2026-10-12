using System.Numerics;
using PastafarianCalendar.Monster;

namespace PastafarianCalendar.Stage16Tests;

// مرجع مستقل يسرد التباديل معجمياً بلا نسخ المفكك القديم.
internal static partial class Program
{
    private static int _unexpected, _cases, _matches, _shifted, _faults, _linked;
    private static readonly List<int[]> All = new();

    private static void Check(bool ok, string description)
    {
        if (ok) return;
        _unexpected++;
        Console.WriteLine("مخالفة: " + description);
    }

    private static void Enumerate(List<int> prefix, List<int> available)
    {
        if (available.Count == 0) { All.Add(prefix.ToArray()); return; }
        foreach (var x in available)
        {
            var next = new List<int>(available);
            next.Remove(x);
            var p = new List<int>(prefix) { x };
            Enumerate(p, next);
        }
    }

    private static int OneBasedRank(BigInteger value)
    {
        var r = (value - 1) % 720;
        if (r.Sign < 0) r += 720;
        return (int)r + 1;
    }

    private static void Observe(BigInteger value, int oneBased)
    {
        _cases++;
        Check(LegacyBowlPermutation.WrongOneBasedRank(value) == oneBased,
            "رتبة القطرة الواحدية");
        try
        {
            var got = CalendarDateSpaghetti.EvaluateLegacyBowlOrder(0,1,value);
            if (got.SequenceEqual(All[oneBased-1]))
            {
                _matches++;
                Check(false,"تطابق قديم غير مقصود");
            }
            else if (oneBased < 720 && got.SequenceEqual(All[oneBased]))
                _shifted++;
            else
                Check(false,"انزياح خارج التوقيع");
        }
        catch (ArgumentOutOfRangeException)
        {
            if (oneBased == 720) _faults++;
            else Check(false,"استثناء في رتبة غير أخيرة");
        }
        catch (Exception ex)
        {
            Check(false,"استثناء آخر " + ex.GetType().Name);
        }
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var verify = args.Length == 1 && args[0] == "--verify-expected-red";
        if (args.Length > 0 && !verify) return 2;
        Enumerate(new List<int>(), new List<int> {1,2,3,4,5,6});
        VerifyZeroBasedUnrank();
        var giant = BigInteger.One << 8192;
        var offsets = new BigInteger[] {0,1,-1,720,giant,-giant};
        foreach (var offset in offsets)
        for (var rank = 1; rank <= 720; rank++)
            Observe(rank + 720*offset,rank);
        if (verify)
        {
            VerifyProductionLink();
            VerifyContextOwnership();
        }
        Console.WriteLine("الحالات: " + _cases);
        Console.WriteLine("المطابقات: " + _matches);
        Console.WriteLine("الانزياحات: " + _shifted);
        Console.WriteLine("استثناءات النهاية: " + _faults);
        Console.WriteLine("فحوص الربط: " + _linked);
        Console.WriteLine("المخالفات: " + _unexpected);
        if (verify)
        {
            var ok = _cases == 4320 && _matches == 0 &&
                _shifted == 4314 && _faults == 6 &&
                _linked == 16 && _unexpected == 0;
            Console.WriteLine("مدقق الاكتشاف الثامن: " + (ok ? "PASS" : "FAIL"));
            return ok ? 0 : 1;
        }
        return _unexpected == 0 && _shifted == 0 && _faults == 0 ? 0 : 1;
    }
}
