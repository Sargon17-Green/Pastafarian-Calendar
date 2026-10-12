using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage26Tests;

internal static partial class Program
{
    private static int _passed, _unexpected, _permutations, _syntheticQuestions;
    private static int _matches, _differences, _directionDifferences, _correctNext;
    private static int _sauces, _productionQuestions, _productionDifferences, _publicReads;
    private static readonly List<MonsterContext> Contexts = new();

    private static void Check(bool value,string name)
    {
        if(value){_passed++;return;}
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة في الاكتشاف الثالث عشر: "+name);
    }

    private static void SyntheticWitness()
    {
        var legacy=new LegacyUnsealedBowlQuestion();
        var correctedNext=new NextBowlOrderPatchWrapper();
        foreach(var rank in Enumerable.Range(1,720))
        {
            var order=NormativeScroll.PermutationUnrank1(rank);
            var bowls=new BigInteger[7];
            for(var b=1;b<=6;b++) bowls[b]=new BigInteger(17*b+rank+1);
            var sauce=new SauceResult(bowls,order);
            var savedOrder=(int[])order.Clone();
            var savedBowls=(BigInteger[])bowls.Clone();
            _permutations++;
            for(var queried=1;queried<=6;queried++)
            {
                var expectedNext=NormativeScroll.NextBowlInDrop46Order(sauce,queried);
                var actualNext=correctedNext.Patch(order,queried);
                if(expectedNext==actualNext) _correctNext++;
                for(var sealIndex=0;sealIndex<3;sealIndex++)
                {
                    var seal=sealIndex==0?0:sealIndex==1?21:31;
                    _syntheticQuestions++;
                    var expected=NormativeScroll.AskBowl(sauce,queried,seal);
                    var actual=legacy.Ask(bowls,queried,actualNext,seal);
                    Check(actual.First>=1 && actual.First<=NormativeScroll.M &&
                          actual.DirectionStep is 1 or -1,
                          "مدى الجواب التاريخي "+rank+"/"+queried+"/"+seal);
                    Check(actualNext==expectedNext,
                          "الجار المصحح لا يتأثر بحساب السؤال "+rank+"/"+queried);
                    if(actual.First==expected.First) _matches++;else _differences++;
                    if(actual.DirectionStep!=expected.DirectionStep) _directionDifferences++;
                }
            }
            Check(order.SequenceEqual(savedOrder) && bowls.SequenceEqual(savedBowls),
                  "السؤال التاريخي لا يلوّث المدخلات "+rank);
        }
        Check(_permutations==720 && _syntheticQuestions==12960 &&
              _correctNext==4320 && _matches==4320 && _differences==8640,
              "الاختلاف الوحيد مُقيَّد بالحاتم داخل المربع");
    }

    private static void ProductionWitness(BigInteger c,BigInteger t,int sample)
    {
        _sauces++;
        var sauce=NormativeScroll.Sauce(c,t);
        for(var j=0;j<2;j++)
        {
            var seal=j==0?21:31;
            var id=(sample+j)%6+1;
            _productionQuestions++;
            var context=new MonsterManager().ExecuteLegacyUnsealedBowlQuestion(c,t,id,seal);
            if(j==0)Contexts.Add(context);
            var normative=NormativeScroll.AskBowl(sauce,id,seal);
            var actual=context.LegacyUnsealedBowlQuestionResult!;
            if(actual.First!=normative.First) _productionDifferences++;
            var next=NormativeScroll.NextBowlInDrop46Order(sauce,id);

            Check(context.Status=="LEGACY_UNSEALED_BOWL_QUESTION_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.SequenceEqual(new[]{
                      "BOOTSTRAP_VALIDATION",
                      "LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS",
                      "PROTECTED_DROP46_ORDER_LATCH_WITNESS",
                      "LEGACY_FIXED_NEXT_BOWL_WITNESS",
                      "PATCHED_NEXT_BOWL_ORDER_WITNESS",
                      "LEGACY_UNSEALED_BOWL_QUESTION"}) &&
                  context.Metrics["legacy.unsealed.bowl.question.dispatch"]==1,
                  "المدير والموزع يشغلان السؤال الخاطئ "+sample+"/"+seal);
            Check(context.LegacyQueriedBowlId==id &&
                  context.LegacyBowlQuestionSeal==seal &&
                  context.PatchedNextBowlResult==next &&
                  context.LegacyFixedNextBowlResult==id%6+1,
                  "هوية الجار القديمة والمصححة لا تزالان مستقلتين "+sample+"/"+seal);
            Check(context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46),
                  "الصلصة والالتقاط المحمي يطابقان المرجع "+sample+"/"+seal);
            Check(context.LegacySauceFinalBowls is {Length:7} &&
                  context.LegacyOverwrittenQueryOrder is {Length:6} &&
                  !ReferenceEquals(context.LegacySauceFinalBowls,context.PatchedSauceFinalBowls) &&
                  !ReferenceEquals(context.LegacyDiagnosticDrop46Order,context.PatchedOrderAt46Latch),
                  "ملكية شواهد الصلصة والالتقاط مستقلة "+sample+"/"+seal);
            var expectedOld=new LegacyUnsealedBowlQuestion().Ask(
                sauce.Bowls,id,next,seal);
            Check(actual==expectedOld && actual.First>=1 &&
                  actual.First<=NormativeScroll.M &&
                  actual.DirectionStep is 1 or -1,
                  "خطأ السؤال قادم من المعالج العام نفسه "+sample+"/"+seal);
            if(j==0)
            {
                _publicReads++;
                var viaApi=CalendarDateSpaghetti.EvaluateLegacyUnsealedBowlQuestion(c,t,id,seal);
                Check(viaApi==actual,
                      "واجهة السؤال العامة تقرأ المسار التاريخي "+sample);
            }
        }
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verify=args.Length==1 && args[0]=="--verify-expected-red";
        if(args.Length!=0 && !verify)return 2;
        SyntheticWitness();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<cases.Length;i++) ProductionWitness(cases[i].C,cases[i].T,i+1);
        if(verify) CheckOwnershipAndRejection();
        Console.WriteLine("تباديل السؤال: "+_permutations);
        Console.WriteLine("أسئلة القيم الاصطناعية: "+_syntheticQuestions);
        Console.WriteLine("الجار المصحح المطابق: "+_correctNext);
        Console.WriteLine("التطابق دون حاتم: "+_matches);
        Console.WriteLine("مخالفات الحاتم: "+_differences);
        Console.WriteLine("اختلافات الاتجاه: "+_directionDifferences);
        Console.WriteLine("الصلصات الكاملة: "+_sauces);
        Console.WriteLine("أسئلة الإنتاج: "+_productionQuestions);
        Console.WriteLine("اختلافات الإنتاج: "+_productionDifferences);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("المخالفات غير المتوقعة: "+_unexpected);
        var passed=_unexpected==0 && _permutations==720 &&
            _syntheticQuestions==12960 && _correctNext==4320 &&
            _matches==4320 && _differences==8640 &&
            _sauces==8 && _productionQuestions==16 &&
            _productionDifferences>=1 && _publicReads==8;
        if(verify)
        {
            Console.WriteLine("التحقق المستقل لتوقيع الأحمر: "+(passed?"PASS":"FAIL"));
            return passed?0:1;
        }
        // المسار المباشر RED عن قصد؛ لا يصبح GREEN إلا في الرقعة 13 بالطور 27.
        return _unexpected==0 && _differences==0?0:1;
    }
}
