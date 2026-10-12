using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage27Tests;

internal static partial class Program
{
    private static int _passed,_unexpected,_permutations,_syntheticQuestions;
    private static int _syntheticCorrect,_historicalMatches,_historicalDifferences;
    private static int _sauces,_productionQuestions,_productionCorrect,_productionLegacyDifferences;
    private static int _publicReads,_correctNext,_directionChecks;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool condition,string label)
    {
        if(condition){_passed++;return;}
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة في الرقعة الثالثة عشرة: "+label);
    }

    private static void SyntheticComparisons()
    {
        var patch=new BowlQuestionSealPatchWrapper();
        var old=new LegacyUnsealedBowlQuestion();
        var nextPatch=new NextBowlOrderPatchWrapper();
        for(var rank=1;rank<=720;rank++)
        {
            var order=NormativeScroll.PermutationUnrank1(rank);
            var bowls=new BigInteger[7];
            for(var id=1;id<=6;id++)
                bowls[id]=new BigInteger(17*id+rank+1);
            var originalOrder=(int[])order.Clone();
            var originalBowls=(BigInteger[])bowls.Clone();
            var normativeSauce=new SauceResult(bowls,order);
            _permutations++;
            for(var id=1;id<=6;id++)
            {
                var next=nextPatch.Patch(order,id);
                var referenceNext=NormativeScroll.NextBowlInDrop46Order(normativeSauce,id);
                if(next==referenceNext)_correctNext++;
                for(var j=0;j<3;j++)
                {
                    var seal=j==0?0:j==1?21:31;
                    _syntheticQuestions++;
                    var reference=NormativeScroll.AskBowl(normativeSauce,id,seal);
                    var actual=patch.Patch(bowls,id,next,seal);
                    var historical=old.Ask(bowls,id,next,seal);
                    if(actual.First==reference.First &&
                       actual.DirectionStep==reference.DirectionStep)_syntheticCorrect++;
                    if(historical.First==reference.First)_historicalMatches++;
                    else _historicalDifferences++;
                    Check(actual.First>=1 && actual.First<=NormativeScroll.M &&
                          actual.DirectionStep is 1 or -1,
                          "حدود جواب الرقعة "+rank+"/"+id+"/"+seal);
                    Check(actual.First==reference.First &&
                          actual.DirectionStep==reference.DirectionStep,
                          "تكافؤ الجواب والاتجاه "+rank+"/"+id+"/"+seal);
                    Check(historical==old.Ask(bowls,id,next,seal),
                          "ثبات المسار القديم "+rank+"/"+id+"/"+seal);
                    if(actual.DirectionStep==reference.DirectionStep)_directionChecks++;
                }
            }
            Check(originalOrder.SequenceEqual(order) &&
                  originalBowls.SequenceEqual(bowls),
                  "عدم تحوير مدخلات الصلصة "+rank);
        }
        Check(_permutations==720 && _syntheticQuestions==12960 &&
              _syntheticCorrect==12960 && _directionChecks==12960 &&
              _correctNext==4320 && _historicalMatches==4320 &&
              _historicalDifferences==8640,
              "توقيع التصحيح والعيب القديم على كل التبديلات");
    }

    private static void BoundaryWitness()
    {
        // تغطية الصفر الدوري وكِبر الأعداد في الغلاف دون تضاعف حساب الصلصة.
        var patch=new BowlQuestionSealPatchWrapper();
        var old=new LegacyUnsealedBowlQuestion();
        var max=NormativeScroll.M;
        var giant=BigInteger.One<<8192;
        var values=new[]{BigInteger.One,new BigInteger(2),max-1,max,max+1,
                         2*max,giant,giant+max};
        foreach(var value in values)
        {
            var bowls=new BigInteger[7];
            for(var id=1;id<=6;id++)bowls[id]=value+id;
            var order=new[]{6,3,1,5,2,4};
            var sauce=new SauceResult(bowls,order);
            for(var id=1;id<=6;id++)
            for(var j=0;j<2;j++)
            {
                var seal=j==0?21:31;
                var next=NormativeScroll.NextBowlInDrop46Order(sauce,id);
                var expected=NormativeScroll.AskBowl(sauce,id,seal);
                var actual=patch.Patch(bowls,id,next,seal);
                var historic=old.Ask(bowls,id,next,seal);
                Check(actual.First==expected.First &&
                      actual.DirectionStep==expected.DirectionStep,
                      "قيم حدودية واسعة "+value.ToString().Length+"/"+id+"/"+seal);
                Check(historic.First>=1 && historic.First<=max,
                      "الحفاظ على مدى القديم في الحدود");
            }
        }
    }

    private static void ProductionComparisons(BigInteger c,BigInteger t,int sample)
    {
        _sauces++;
        var reference=NormativeScroll.Sauce(c,t);
        var manager=new MonsterManager();
        for(var id=1;id<=6;id++)
        for(var j=0;j<2;j++)
        {
            var seal=j==0?21:31;
            var context=manager.ExecutePatchedBowlQuestion(c,t,id,seal);
            _productionQuestions++;
            if(id==1 && j==0) Contexts.Add(context);
            var norm=NormativeScroll.AskBowl(reference,id,seal);
            var actual=context.PatchedBowlQuestionResult!;
            var old=context.LegacyUnsealedBowlQuestionResult!;
            var next=NormativeScroll.NextBowlInDrop46Order(reference,id);
            if(actual.First==norm.First && actual.DirectionStep==norm.DirectionStep)
                _productionCorrect++;
            if(old.First!=norm.First) _productionLegacyDifferences++;

            Check(context.Status=="PATCHED_SEALED_BOWL_QUESTION_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.SequenceEqual(new[]{
                      "BOOTSTRAP_VALIDATION",
                      "LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS",
                      "PROTECTED_DROP46_ORDER_LATCH_WITNESS",
                      "LEGACY_FIXED_NEXT_BOWL_WITNESS",
                      "PATCHED_NEXT_BOWL_ORDER_WITNESS",
                      "LEGACY_UNSEALED_BOWL_QUESTION_WITNESS",
                      "PATCHED_SEALED_BOWL_QUESTION"}) &&
                  context.Metrics["legacy.unsealed.bowl.question.witness"]==1 &&
                  context.Metrics["patched.sealed.bowl.question.dispatch"]==1,
                  "سلسلة المدير والموزع "+sample+"/"+id+"/"+seal);
            Check(context.LegacyBowlQuestionSeal==seal &&
                  context.LegacyQueriedBowlId==id &&
                  context.PatchedNextBowlResult==next &&
                  context.LegacyFixedNextBowlResult==id%6+1,
                  "الجار المحمي وشاهده القديم "+sample+"/"+id+"/"+seal);
            Check(actual.First==norm.First &&
                  actual.DirectionStep==norm.DirectionStep &&
                  old==new LegacyUnsealedBowlQuestion().Ask(reference.Bowls,id,next,seal),
                  "الجواب الصحيح مع عدم محو الشاهد الخاطئ "+sample+"/"+id+"/"+seal);
            Check(context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(reference.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(reference.OrderAtDrop46),
                  "الأوعية والترتيب المحمي مطابقان للمرجع "+sample+"/"+id+"/"+seal);
            Check(context.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(context.PatchedSauceFinalBowls,
                                   context.LegacySauceFinalBowls) &&
                  !ReferenceEquals(context.PatchedOrderAt46Latch,
                                   context.LegacyDiagnosticDrop46Order),
                  "سجلات الأوعية التاريخية لا تُشارك ذاكرة الرقعة "+sample+"/"+id+"/"+seal);
        }
        _publicReads++;
        var api=CalendarDateSpaghetti.EvaluateBowlQuestion(c,t,6,21);
        var expectedApi=NormativeScroll.AskBowl(reference,6,21);
        Check(api.First==expectedApi.First &&
              api.DirectionStep==expectedApi.DirectionStep,
              "الواجهة العامة المصححة "+sample);
        var viaOld=CalendarDateSpaghetti.EvaluateLegacyUnsealedBowlQuestion(c,t,6,21);
        Check(viaOld==new LegacyUnsealedBowlQuestion().Ask(
              reference.Bowls,6,NormativeScroll.NextBowlInDrop46Order(reference,6),21),
              "واجهة التاريخ مستقلة "+sample);
    }

    private static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        SyntheticComparisons();
        BoundaryWitness();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<cases.Length;i++)ProductionComparisons(cases[i].C,cases[i].T,i+1);
        CheckOwnershipAndRejection();
        Console.WriteLine("التباديل: "+_permutations);
        Console.WriteLine("الأسئلة التركيبية: "+_syntheticQuestions);
        Console.WriteLine("التطابقات المصححة: "+_syntheticCorrect);
        Console.WriteLine("الجار المصحح المطابق: "+_correctNext);
        Console.WriteLine("المطابقات التاريخية: "+_historicalMatches);
        Console.WriteLine("الاختلافات التاريخية: "+_historicalDifferences);
        Console.WriteLine("الصلصات: "+_sauces);
        Console.WriteLine("أسئلة الإنتاج: "+_productionQuestions);
        Console.WriteLine("الأسئلة الإنتاجية الصحيحة: "+_productionCorrect);
        Console.WriteLine("اختلافات الإنتاج التاريخية: "+_productionLegacyDifferences);
        Console.WriteLine("قراءات الواجهة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        return _unexpected==0 && _permutations==720 &&
               _syntheticQuestions==12960 && _syntheticCorrect==12960 &&
               _historicalMatches==4320 && _historicalDifferences==8640 &&
               _correctNext==4320 && _sauces==8 &&
               _productionQuestions==96 && _productionCorrect==96 &&
               _productionLegacyDifferences==96 && _publicReads==8 ? 0 : 1;
    }
}
