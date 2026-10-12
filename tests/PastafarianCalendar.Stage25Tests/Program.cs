using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage25Tests;

internal static partial class Program
{
    private static int _passed, _unexpected, _permutations, _choices, _correctChoices;
    private static int _historicalMatches, _historicalDifferences, _sauces;
    private static int _productionQueries, _productionMatches, _productionLegacyDifferences, _publicReads;
    private static readonly List<MonsterContext> Contexts = new();

    private static void Check(bool condition, string label)
    {
        if (condition) {_passed++;return;}
        _unexpected++;
        Console.WriteLine("إخفاق الرقعة الثانية عشرة: " + label);
    }

    private static void AllPermutations()
    {
        var patch = new NextBowlOrderPatchWrapper();
        var old = new LegacyFixedNextBowl();
        for (var rank = 1; rank <= 720; rank++)
        {
            _permutations++;
            var order = NormativeScroll.PermutationUnrank1(rank);
            var before = (int[])order.Clone();
            var sauce = new SauceResult(new BigInteger[7], order);
            var found = new HashSet<int>();
            for (var queried = 1; queried <= 6; queried++)
            {
                _choices++;
                var expected = NormativeScroll.NextBowlInDrop46Order(sauce,queried);
                var corrected = patch.Patch(order,queried);
                var historical = old.SelectByFixedIdentity(queried);
                Check(corrected == expected,
                    "تكافؤ الجار لكل تبديلة مع المرجع " + rank + "/" + queried);
                Check(corrected is >= 1 and <= 6 && corrected != queried,
                    "حدود الجار المصحح " + rank + "/" + queried);
                found.Add(corrected);
                if (corrected == expected) _correctChoices++;
                if (historical == expected) _historicalMatches++;
                else _historicalDifferences++;
            }
            Check(order.SequenceEqual(before) && found.Count==6,
                "الدورة المصححة تحفظ أصل الترتيب وتغطي ستة أوعية " + rank);
        }
        Check(_permutations == 720 && _choices == 4320 && _correctChoices == 4320 &&
              _historicalMatches == 864 && _historicalDifferences == 3456,
              "التوقيع التاريخي محفوظ وتصحيح كل المواضع ناجح");
    }

    private static void AllProduction(BigInteger calculation,BigInteger target,int sample)
    {
        _sauces++;
        var reference = NormativeScroll.Sauce(calculation,target);
        var manager = new MonsterManager();
        for (var queried = 1; queried <= 6; queried++)
        {
            _productionQueries++;
            var context = manager.ExecutePatchedNextBowl(calculation,target,queried);
            if (queried==1) Contexts.Add(context);
            var expected=NormativeScroll.NextBowlInDrop46Order(reference,queried);
            var legacy=queried==6 ? 1 : queried+1;
            if (context.PatchedNextBowlResult==expected) _productionMatches++;
            if (legacy!=expected) _productionLegacyDifferences++;

            Check(context.Phase=="PATCHED_NEXT_BOWL_ORDER_COMPLETE" &&
                  context.Status==context.Phase &&
                  context.BranchTrace.SequenceEqual(new[]{
                    "BOOTSTRAP_VALIDATION",
                    "LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS",
                    "PROTECTED_DROP46_ORDER_LATCH_WITNESS",
                    "LEGACY_FIXED_NEXT_BOWL_WITNESS",
                    "PATCHED_NEXT_BOWL_ORDER"}) &&
                  context.Metrics["legacy.fixed.next.bowl.witness"]==1 &&
                  context.Metrics["patched.next.bowl.order.dispatch"]==1,
                  "مسار المدير والموزع مكتمل " + sample + "/" + queried);
            Check(context.LegacyQueriedBowlId==queried &&
                  context.LegacyFixedNextBowlResult==legacy &&
                  context.PatchedNextBowlResult==expected,
                  "الشاهد القديم والمصحح منفصلان " + sample + "/" + queried);
            Check(context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(reference.OrderAtDrop46) &&
                  context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(reference.Bowls),
                  "نتائج الصلصة السابقة لم تتغير " + sample + "/" + queried);
            Check(context.LegacyOverwrittenQueryOrder is {Length:6} &&
                  context.LegacyDiagnosticDrop46Order is {Length:6} &&
                  context.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(context.LegacySauceFinalBowls,context.PatchedSauceFinalBowls) &&
                  !ReferenceEquals(context.LegacyDiagnosticDrop46Order,context.PatchedOrderAt46Latch),
                  "ملكية ذاكرة الشاهد التاريخي والصلصة الصحيحة " + sample + "/" + queried);
        }
        // وصول فعلي إلى الواجهة العامة؛ لا تحتاج إعادة الحساب لكل ترتيب مفترض.
        _publicReads++;
        var publicValue=CalendarDateSpaghetti.EvaluateNextBowl(calculation,target,6);
        Check(publicValue == NormativeScroll.NextBowlInDrop46Order(reference,6),
              "واجهة القراءة العامة المصححة " + sample);
        var historical=CalendarDateSpaghetti.EvaluateLegacyFixedNextBowl(calculation,target,6);
        Check(historical==1, "الواجهة التاريخية القديمة لم تتغير " + sample);
    }

    private static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        AllPermutations();
        var f=NormativeScroll.FoundationDay;
        var giant=BigInteger.One<<8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (new BigInteger(-278522),f),(giant,-giant),(-giant+f,giant+f)
        };
        for(var i=0;i<cases.Length;i++)
            AllProduction(cases[i].C,cases[i].T,i+1);
        CheckOwnershipAndRejection();
        Console.WriteLine("التبديلات: "+_permutations);
        Console.WriteLine("اختيارات الترتيب: "+_choices);
        Console.WriteLine("الاختيارات المصححة المطابقة: "+_correctChoices);
        Console.WriteLine("مطابقات القديم: "+_historicalMatches);
        Console.WriteLine("مخالفات القديم: "+_historicalDifferences);
        Console.WriteLine("الصلصات الإنتاجية: "+_sauces);
        Console.WriteLine("أسئلة الإنتاج: "+_productionQueries);
        Console.WriteLine("مطابقات الإنتاج: "+_productionMatches);
        Console.WriteLine("فروق الإنتاج التاريخية: "+_productionLegacyDifferences);
        Console.WriteLine("قراءات الواجهة: "+_publicReads);
        Console.WriteLine("تأكيدات الرقعة الثانية عشرة الناجحة: "+_passed);
        Console.WriteLine("إخفاقات غير متوقعة: "+_unexpected);
        return _unexpected==0 && _permutations==720 && _choices==4320 &&
            _correctChoices==4320 && _historicalMatches==864 &&
            _historicalDifferences==3456 && _sauces==8 &&
            _productionQueries==48 && _productionMatches==48 &&
            _productionLegacyDifferences>0 && _publicReads==8 ? 0 : 1;
    }
}
