using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage31Tests;

internal static partial class Program
{
    private static int _passed,_unexpected,_permutations,_synthetic;
    private static int _correct,_historicalMatches,_historicalDifferences,_singleton;
    private static int _sauces,_production,_productionCorrect,_productionOldMatches,_productionOldDifferences;
    private static int _correctFirstAnswers,_publicReads;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string message)
    {
        if(ok){_passed++;return;}
        _unexpected++;
        Console.WriteLine("فشل غير متوقع في رقعة الرتبة الخامسة عشرة: "+message);
    }

    private static BigInteger[] FamilySizes()
        => new BigInteger[]{1,2,3,5,7,31,97,65537,NormativeScroll.M};

    private static void Synthetic()
    {
        var sizes=FamilySizes();
        var patch=new ShortRankOffsetPatchWrapper();
        var old=new LegacyUnshiftedShortRank();
        for(var rank=1;rank<=720;rank++)
        {
            _permutations++;
            for(var bowl=1;bowl<=6;bowl++)
            foreach(var direction in new[]{-1,1})
            {
                var first=(BigInteger)(rank*6+bowl);
                var normative=new AnswerStream(first,direction);
                var answer=new LegacyBowlQuestionResult(first,direction);
                foreach(var size in sizes)
                {
                    _synthetic++;
                    var expected=NormativeScroll.ChooseRankShort(normative,size);
                    var historic=old.Choose(answer,size);
                    var actual=patch.Patch(historic,size);
                    if(actual==expected)_correct++;
                    if(historic==expected)_historicalMatches++;
                    else _historicalDifferences++;
                    if(size==1&&actual==historic)_singleton++;

                    Check(actual>=1 && actual<=size,
                          "مجال الأسرة المصحح "+rank+"/"+bowl+"/"+direction+"/"+size);
                    Check(actual==expected,
                          "التكافؤ المستقل للمرتبة القصيرة "+rank+"/"+bowl+"/"+direction+"/"+size);
                    Check(actual==(historic==1?size:historic-1),
                          "تدوير الرتبة القديمة دون إخفاء النتيجة "+rank+"/"+bowl+"/"+direction);
                    Check((size==1&&historic==actual)||(size>1&&historic!=actual),
                          "الندبة التاريخية تُحفظ مع استثناء الأسرة الأحادية");
                }
            }
        }
        Check(_permutations==720 && _synthetic==77760 && _correct==77760 &&
              _historicalMatches==8640 && _historicalDifferences==69120 &&
              _singleton==8640,
              "التوقيع الكامل لجميع الأحجام والرتب والاتجاهين");
    }

    private static void Boundary()
    {
        var m=NormativeScroll.M;
        var patch=new ShortRankOffsetPatchWrapper();
        var old=new LegacyUnshiftedShortRank();
        var streams=new[]{
            new LegacyBowlQuestionResult(1,-1),
            new LegacyBowlQuestionResult(1,1),
            new LegacyBowlQuestionResult(m-1,-1),
            new LegacyBowlQuestionResult(m-1,1),
            new LegacyBowlQuestionResult(m,-1),
            new LegacyBowlQuestionResult(m,1),
            new LegacyBowlQuestionResult(m/2,-1),
            new LegacyBowlQuestionResult(m/2,1)};
        foreach(var stream in streams)
        foreach(var size in new BigInteger[]{1,2,3,m-1,m})
        {
            var norm=new AnswerStream(stream.First,stream.DirectionStep);
            var expected=NormativeScroll.ChooseRankShort(norm,size);
            var oldRank=old.Choose(stream,size);
            var actual=patch.Patch(oldRank,size);
            Check(actual==expected,
                  "حدود الباقي والقبول والاتجاه وعائلة قريبة من M");
            Check(size==1 ? oldRank==actual : oldRank!=actual,
                  "فرق الشاهد القديم حتى عند الحد");
        }

        // العبور فوق ذيل الرفض في كلا الاتجاهين؛ لا نعيد التنفيذ بحلقة قد تستغرق دهوراً.
        var rising=new LegacyBowlQuestionResult(m,1);
        var falling=new LegacyBowlQuestionResult(m,-1);
        Check(patch.Patch(old.Choose(rising,m-1),m-1)==1,
              "عبور حد القبول المرفوض في الاتجاه الموجب");
        Check(patch.Patch(old.Choose(falling,m-1),m-1)==m-1,
              "عبور حد القبول المرفوض في الاتجاه السالب");
        Check(patch.Patch(old.Choose(rising,m),m)==m,
              "الحالة M مع أسرة بحجم M تحافظ على الدرجة الأخيرة");
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        _sauces++;
        var reference=NormativeScroll.Sauce(c,t);
        var manager=new MonsterManager();
        var sizes=FamilySizes();
        for(var id=1;id<=6;id++)
        for(var sealIndex=0;sealIndex<2;sealIndex++)
        {
            var index=(sample-1)*12+(id-1)*2+sealIndex;
            var n=sizes[index%sizes.Length];
            var seal=sealIndex==0?21:31;
            var stream=NormativeScroll.AskBowl(reference,id,seal);
            var expected=NormativeScroll.ChooseRankShort(stream,n);
            var context=manager.ExecutePatchedShortRank(c,t,id,seal,n);
            if(id==1&&sealIndex==0)Contexts.Add(context);
            _production++;
            var actual=context.PatchedShortFamilyRankResult;
            var historic=context.LegacyShortFamilyRankResult;
            if(actual==expected)_productionCorrect++;
            if(historic==expected)_productionOldMatches++;
            else _productionOldDifferences++;
            var next=NormativeScroll.NextBowlInDrop46Order(reference,id);

            Check(context.Status=="PATCHED_SHORT_FAMILY_RANK_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.SequenceEqual(new[]{
                      "BOOTSTRAP_VALIDATION",
                      "LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS",
                      "PROTECTED_DROP46_ORDER_LATCH_WITNESS",
                      "LEGACY_FIXED_NEXT_BOWL_WITNESS",
                      "PATCHED_NEXT_BOWL_ORDER_WITNESS",
                      "LEGACY_UNSEALED_BOWL_QUESTION_WITNESS",
                      "PATCHED_SEALED_BOWL_QUESTION_WITNESS",
                      "LEGACY_ONE_BASED_ANSWER_STEP_WITNESS",
                      "PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS",
                      "LEGACY_UNSHIFTED_SHORT_FAMILY_RANK_WITNESS",
                      "PATCHED_SHORT_FAMILY_RANK"}) &&
                  context.Metrics["legacy.unshifted.short.family.rank.witness"]==1 &&
                  context.Metrics["patched.short.family.rank.dispatch"]==1,
                  "المسار العام والقياسات ينفذان الرقعة وشاهدها "+index);
            Check(actual==expected && actual is BigInteger rank &&
                  rank>=1 && rank<=n && context.LegacyShortFamilySize==n &&
                  historic is BigInteger priorRank &&
                  actual==(priorRank==1?n:priorRank-1),
                  "الجواب المصحح ومالك الرتبة القديمة مستقلان "+index);
            Check((n==1&&historic==actual)||(n>1&&historic!=actual),
                  "التصحيح لا يمحو اختلافات العائلة غير الأحادية "+index);
            Check(context.PatchedBowlQuestionResult is not null &&
                  context.PatchedBowlQuestionResult.First==stream.First &&
                  context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  context.PatchedAnswerAtResult==stream.First &&
                  context.LegacyOneBasedAnswerAtResult==
                      NormativeScroll.AnswerAt(stream,BigInteger.One) &&
                  context.PatchedNextBowlResult==next,
                  "سلامة الجواب المختوم وعداد k=0 والجار المصحح "+index);
            if(context.PatchedBowlQuestionResult is not null &&
               context.PatchedBowlQuestionResult.First==stream.First &&
               context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep)
                _correctFirstAnswers++;
            Check(context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(reference.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(reference.OrderAtDrop46) &&
                  context.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(context.PatchedSauceFinalBowls,context.LegacySauceFinalBowls) &&
                  !ReferenceEquals(context.PatchedOrderAt46Latch,context.LegacyDiagnosticDrop46Order),
                  "مصدر الصلصة وترتيب القطرة محميان داخل السياق "+index);
            Check(context.LegacyFixedNextBowlResult==id%6+1 &&
                  context.LegacyUnsealedBowlQuestionResult==
                      new LegacyUnsealedBowlQuestion().Ask(reference.Bowls,id,next,seal),
                  "شواهد الندوب السابقة 12 و13 محفوظة دون إعادة كتابة "+index);
        }

        _publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var publicN=sizes[(sample-1)%sizes.Length];
        var answerStream=NormativeScroll.AskBowl(reference,publicId,publicSeal);
        var api=CalendarDateSpaghetti.EvaluateShortFamilyRank(c,t,publicId,publicSeal,publicN);
        var oldApi=CalendarDateSpaghetti.EvaluateLegacyUnshiftedShortRank(
            c,t,publicId,publicSeal,publicN);
        Check(api==NormativeScroll.ChooseRankShort(answerStream,publicN) &&
              (publicN==1?api==oldApi:api!=oldApi),
              "الواجهة العامة والواجهة التاريخية مستقلتان "+sample);
    }

    private static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        Synthetic();
        Boundary();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var dates=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<dates.Length;i++)Production(dates[i].C,dates[i].T,i+1);
        ValidationAndOwnership();

        Console.WriteLine("رتب التبديلات: "+_permutations);
        Console.WriteLine("الأسئلة التركيبية: "+_synthetic);
        Console.WriteLine("المطابقات المصححة: "+_correct);
        Console.WriteLine("التطابقات التاريخية: "+_historicalMatches);
        Console.WriteLine("المخالفات التاريخية: "+_historicalDifferences);
        Console.WriteLine("الصلصات الحقيقية: "+_sauces);
        Console.WriteLine("أسئلة الإنتاج: "+_production);
        Console.WriteLine("إجابات الإنتاج المصححة: "+_productionCorrect);
        Console.WriteLine("تطابقات الإنتاج التاريخية: "+_productionOldMatches);
        Console.WriteLine("مخالفات الإنتاج التاريخية: "+_productionOldDifferences);
        Console.WriteLine("شواهد الجواب الأول الصحيح: "+_correctFirstAnswers);
        Console.WriteLine("قراءات الواجهة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        return _unexpected==0 && _permutations==720 &&
               _synthetic==77760 && _correct==77760 &&
               _historicalMatches==8640 && _historicalDifferences==69120 &&
               _singleton==8640 && _sauces==8 && _production==96 &&
               _productionCorrect==96 && _productionOldMatches==11 &&
               _productionOldDifferences==85 && _correctFirstAnswers==96 &&
               _publicReads==8 ? 0 : 1;
    }
}
