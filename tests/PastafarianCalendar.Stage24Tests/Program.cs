using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage24Tests;

internal static partial class Program
{
    private static int _passed, _unexpected, _permutations, _choices;
    private static int _matches, _differences, _sauces, _productionReads, _productionDifferences;
    private static readonly int[] Histogram = new int[7];
    private static readonly List<MonsterContext> Contexts = new();

    private static void Check(bool condition, string label)
    {
        if (condition) { _passed++; return; }
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة في اكتشاف 12: " + label);
    }

    private static void CheckAllPermutations()
    {
        var old = new LegacyFixedNextBowl();
        for (var rank = 1; rank <= 720; rank++)
        {
            var order = NormativeScroll.PermutationUnrank1(rank);
            var sauce = new SauceResult(new BigInteger[7], order);
            var localMatches = 0;
            _permutations++;
            for (var id = 1; id <= 6; id++)
            {
                _choices++;
                var expected = NormativeScroll.NextBowlInDrop46Order(sauce, id);
                var actual = old.SelectByFixedIdentity(id);
                Check(actual == id % 6 + 1, "هوية الجار التاريخي " + rank + "/" + id);
                if (actual == expected) { _matches++; localMatches++; }
                else _differences++;
            }
            Histogram[localMatches]++;
        }
        // جميع الإمكانات: 720*6، مع ست دورات حلقية لا يظهر فيها الفرق.
        Check(_permutations == 720 && _choices == 4320 &&
              _matches == 864 && _differences == 3456,
              "توزيع الفرق بين الجار الثابت والجار بحسب الترتيب");
        Check(Histogram[0] == 216 && Histogram[1] == 288 &&
              Histogram[2] == 90 && Histogram[3] == 120 &&
              Histogram[4] == 0 && Histogram[5] == 0 &&
              Histogram[6] == 6,
              "المدرج الكامل للتباديل الستة");
    }

    private static void CheckProduction(BigInteger c, BigInteger t, int sample)
    {
        _sauces++;
        var normative = NormativeScroll.Sauce(c, t);
        // طلب واحد فقط لكل صلصة لتجنّب تكرار بناء آلاف الأعداد الضخمة.
        var id = Enumerable.Range(1, 6).FirstOrDefault(b =>
            NormativeScroll.NextBowlInDrop46Order(normative, b) != b % 6 + 1);
        if (id == 0) id = 1;

        var context = new MonsterManager().ExecuteLegacyFixedNextBowl(c, t, id);
        Contexts.Add(context);
        _productionReads++;
        var result = CalendarDateSpaghetti.EvaluateLegacyFixedNextBowl(c, t, id);
        var expected = NormativeScroll.NextBowlInDrop46Order(normative, id);
        var actual = context.LegacyFixedNextBowlResult;
        if (actual != expected) _productionDifferences++;

        Check(context.Status == "LEGACY_FIXED_NEXT_BOWL_COMPLETE" &&
              context.Phase == context.Status &&
              context.BranchTrace.SequenceEqual(new[]{
                "BOOTSTRAP_VALIDATION",
                "LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS",
                "PROTECTED_DROP46_ORDER_LATCH_WITNESS",
                "LEGACY_FIXED_NEXT_BOWL"}) &&
              context.Metrics["legacy.fixed.next.bowl.dispatch"] == 1,
              "المدير والموزّع يستعملان المسار التاريخي " + sample);
        Check(result == id % 6 + 1 && actual == result &&
              context.LegacyQueriedBowlId == id,
              "الخلل في المسار العام وليس في الاختبار فقط " + sample);
        Check(context.PatchedOrderAt46Latch is {Length:6} &&
              context.PatchedOrderAt46Latch.SequenceEqual(normative.OrderAtDrop46) &&
              context.PatchedSauceFinalBowls is {Length:7} &&
              context.PatchedSauceFinalBowls.SequenceEqual(normative.Bowls),
              "الرقعة 11 والصلصة لا تتغيران باكتشاف 12 " + sample);
        Check(context.LegacyOverwrittenQueryOrder is {Length:6} &&
              context.LegacySauceFinalBowls is {Length:7} &&
              !ReferenceEquals(context.LegacySauceFinalBowls,
                              context.PatchedSauceFinalBowls) &&
              !ReferenceEquals(context.LegacyDiagnosticDrop46Order,
                              context.PatchedOrderAt46Latch),
              "شهود الأخطاء السابقة محفوظة بذاكرة مستقلة " + sample);
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var verify = args.Length == 1 && args[0] == "--verify-expected-red";
        if (args.Length != 0 && !verify) return 2;
        CheckAllPermutations();
        var f = NormativeScroll.FoundationDay;
        var huge = BigInteger.One << 8192;
        var cases = new (BigInteger c, BigInteger t)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),
            (1,0),(new BigInteger(-278522),f),
            (huge,-huge),(-huge+f,huge+f)
        };
        for (var i = 0; i < cases.Length; i++)
            CheckProduction(cases[i].c, cases[i].t, i + 1);
        if (verify) CheckOwnershipAndRejection();

        Console.WriteLine("التباديل: " + _permutations);
        Console.WriteLine("اختيارات الأوعية: " + _choices);
        Console.WriteLine("الموافقات التاريخية: " + _matches);
        Console.WriteLine("المخالفات التاريخية: " + _differences);
        Console.WriteLine("الصلصات الكاملة: " + _sauces);
        Console.WriteLine("قراءات الإنتاج: " + _productionReads);
        Console.WriteLine("اختلافات الإنتاج عن المرجع: " + _productionDifferences);
        Console.WriteLine("التحققات الناجحة: " + _passed);
        Console.WriteLine("المخالفات غير المتوقعة: " + _unexpected);
        if (verify)
        {
            var pass = _unexpected == 0 && _permutations == 720 &&
                _choices == 4320 && _matches == 864 && _differences == 3456 &&
                _sauces == 8 && _productionReads == 8 &&
                _productionDifferences >= 1;
            Console.WriteLine("مدقق اكتشاف 12 الأحمر: " + (pass ? "PASS" : "FAIL"));
            return pass ? 0 : 1;
        }
        // الاكتشاف المباشر أحمر عن قصد ولا يحوّل اختلاف التاريخ إلى إصلاح.
        return _unexpected == 0 && _differences == 0 ? 0 : 1;
    }
}
