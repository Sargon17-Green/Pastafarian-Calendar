using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage37Tests;

internal static partial class Program
{
    private static int _passed,_failed,_controls,_controlCorrect,_controlHistorical;
    private static int _rejected,_rejectedCorrect,_rejectedHistoricalWrong;
    private static int _ascendingHistoricalMatches,_descendingHistoricalWrong;
    private static int _sauces,_production,_productionCorrect,_productionHistoricalDifferent;
    private static int _productionHistoricalMatches,_realRejections,_publicReads,_correctStreams;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string label)
    {
        if(ok){_passed++;return;}
        _failed++;
        Console.WriteLine("إخفاق غير متوقع في رقعة اتجاه الرفض الثامنة عشرة: "+label);
    }

    private static BigInteger[] Sizes()
    {
        var m=NormativeScroll.M;
        return new BigInteger[]{m+1,2*m+1,m*m-1,m*m+1};
    }

    private static BigInteger TwoDigitWide(AnswerStream stream)
        => stream.First+
           (NormativeScroll.AnswerAt(stream,BigInteger.One)-BigInteger.One)*NormativeScroll.M;

    private static void Synthetic()
    {
        var m=NormativeScroll.M;
        var old=new LegacyWideRejectionDirection();
        var correct=new WideDigitOrderPatchWrapper();

        for(var rank=1;rank<=720;rank++)
        for(var bowl=1;bowl<=6;bowl++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+bowl);
            var normative=new AnswerStream(first,direction);
            var stream=new LegacyBowlQuestionResult(first,direction);
            foreach(var size in Sizes())
            {
                _controls++;
                var reference=NormativeScroll.ChooseRankWide(normative,size);
                var before=correct.Patch(stream,size);
                var historic=old.Choose(stream,size);
                if(before==reference)_controlCorrect++;
                if(historic==reference)_controlHistorical++;
                Check(before==reference && historic==reference &&
                      before>=1 && before<=size,
                      "القيمة المقبولة لا تتغير "+rank+"/"+bowl+"/"+direction+"/"+size);
            }

            // wide-1 يضمن رفض الإجابة الأولى في فضاء M².
            // تتوافق الرتبة الأولى بعد الرفض مع اتجاه +1 والأخيرة مع -1.
            var high=m-BigInteger.One-first;
            var witness=new AnswerStream(high,direction);
            var source=new LegacyBowlQuestionResult(high,direction);
            var n=TwoDigitWide(witness)-BigInteger.One;
            _rejected++;
            Check(n>m*m/2 && n<m*m,
                  "حالة الرفض الاصطناعية تقبل موضعين");
            var actual=correct.Patch(source,n);
            var historicalWitness=old.Choose(source,n);
            var expected=direction==1?BigInteger.One:
                         NormativeScroll.ChooseRankWide(witness,n);
            if(actual==expected)_rejectedCorrect++;
            if(historicalWitness!=expected)_rejectedHistoricalWrong++;
            if(direction==1 && historicalWitness==expected)_ascendingHistoricalMatches++;
            if(direction==-1 && historicalWitness!=expected)_descendingHistoricalWrong++;
            Check(actual==expected && expected==(direction==1?BigInteger.One:n),
                  "المرجع المستقل يثبت اختيار أول أو آخر رتبة حسب الإشارة");
            Check(historicalWitness==BigInteger.One &&
                  (direction==1?historicalWitness==actual:historicalWitness!=actual),
                  "الشاهد القديم باق على الرتبة الأولى بغض النظر عن الاتجاه");
        }
        Check(_controls==34560 && _controlCorrect==34560 &&
              _controlHistorical==34560 && _rejected==8640 &&
              _rejectedCorrect==8640 && _rejectedHistoricalWrong==4320 &&
              _ascendingHistoricalMatches==4320 && _descendingHistoricalWrong==4320,
              "شهادة الرقعة واتجاه الخطأ على كامل البنية التركيبية");
    }

    private static void Boundaries()
    {
        var m=NormativeScroll.M;
        var prior=new WideDigitOrderPatchWrapper();
        var historical=new LegacyWideRejectionDirection();
        foreach(var first in new BigInteger[]{1,2,m/2,m-2,m-1,m})
        foreach(var direction in new[]{-1,1})
        foreach(var n in Sizes())
        {
            var stream=new AnswerStream(first,direction);
            var source=new LegacyBowlQuestionResult(first,direction);
            // الحالة الآتية كانت تتطلب حلقة مرجعية بطول هائل.
            var expected=first==m-2 && direction==1 && n==m*m+1
                ? BigInteger.One : NormativeScroll.ChooseRankWide(stream,n);
            Check(prior.Patch(source,n)==expected,
                  "حالة حدية وتصحيح سابق دون حلقة غير منتهية عملياً");
            Check(historical.Choose(source,n)>=1 && historical.Choose(source,n)<=n,
                  "الشاهد التاريخي لا يخرج عن حدود الأسرة");
        }
        // بيانات ذات أكثر من ثمانية آلاف بت، من بداية تضمن إجابة مقبولة.
        var huge=(BigInteger.One<<8192)+m*m+1;
        var hugeStream=new AnswerStream(BigInteger.One,1);
        Check(prior.Patch(new LegacyBowlQuestionResult(1,1),huge)==
              NormativeScroll.ChooseRankWide(hugeStream,huge),
              "عائلة عريضة بآلاف البتات دون فقدان الدقة");
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        _sauces++;
        var normativeSauce=NormativeScroll.Sauce(c,t);
        var manager=new MonsterManager();
        var m=NormativeScroll.M;
        for(var id=1;id<=6;id++)
        for(var sealIndex=0;sealIndex<2;sealIndex++)
        {
            var seal=sealIndex==0?21:31;
            var stream=NormativeScroll.AskBowl(normativeSauce,id,seal);
            var wide=TwoDigitWide(stream);
            // الرفض الحقيقي بفهرس سالب ينتقل خطوة واحدة إلى الرتبة الأخيرة.
            var mustReject=stream.DirectionStep==-1 &&
                           wide>m*m/2+BigInteger.One && wide<m*m;
            var size=mustReject?wide-BigInteger.One:m+BigInteger.One;
            var expected=NormativeScroll.ChooseRankWide(stream,size);
            var ctx=manager.ExecutePatchedRejectionDirection(c,t,id,seal,size);
            if(Contexts.Count<2)Contexts.Add(ctx);
            _production++;
            if(ctx.PatchedRejectionDirectionRankResult==expected)_productionCorrect++;
            if(ctx.LegacyRejectionDirectionRankResult!=expected)
                _productionHistoricalDifferent++;
            else _productionHistoricalMatches++;
            if(mustReject)_realRejections++;

            Check(ctx.Status=="PATCHED_REJECTION_DIRECTION_COMPLETE" &&
                  ctx.Phase==ctx.Status &&
                  ctx.BranchTrace.SequenceEqual(new[]{
                    "BOOTSTRAP_VALIDATION",
                    "LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS",
                    "PROTECTED_DROP46_ORDER_LATCH_WITNESS",
                    "LEGACY_FIXED_NEXT_BOWL_WITNESS",
                    "PATCHED_NEXT_BOWL_ORDER_WITNESS",
                    "LEGACY_UNSEALED_BOWL_QUESTION_WITNESS",
                    "PATCHED_SEALED_BOWL_QUESTION_WITNESS",
                    "LEGACY_ONE_BASED_ANSWER_STEP_WITNESS",
                    "PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS",
                    "LEGACY_REVERSED_WIDE_DIGITS_WITNESS",
                    "PATCHED_WIDE_DIGIT_ORDER_WITNESS",
                    "LEGACY_INCLUSIVE_WIDE_LIMIT_WITNESS",
                    "PATCHED_INCLUSIVE_WIDE_LIMIT_WITNESS",
                    "LEGACY_WIDE_REJECTION_DIRECTION_WITNESS",
                    "PATCHED_REJECTION_DIRECTION"}) &&
                  ctx.Metrics["legacy.wide.rejection.direction.witness"]==1 &&
                  ctx.Metrics["patched.rejection.direction.dispatch"]==1 &&
                  ctx.Metrics["patched.inclusive.wide.limit.witness"]==1,
                  "المسار الإنتاجي الكامل للرقعة الثامنة عشرة "+sample+"/"+id+"/"+seal);
            Check(ctx.PatchedRejectionDirectionRankResult==expected &&
                  ctx.PatchedInclusiveWideLimitRankResult==expected &&
                  ctx.LegacyWideFamilySize==size &&
                  (mustReject
                      ? ctx.LegacyRejectionDirectionRankResult==BigInteger.One &&
                        expected==size && ctx.LegacyRejectionDirectionRankResult!=expected
                      : ctx.LegacyRejectionDirectionRankResult==expected),
                  "تطابق الرقعة والمرجع وحفظ الخطأ التاريخي");
            Check(ctx.PatchedBowlQuestionResult is not null &&
                  ctx.PatchedBowlQuestionResult.First==stream.First &&
                  ctx.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  ctx.PatchedAnswerAtResult==stream.First &&
                  ctx.LegacyOneBasedAnswerAtResult==NormativeScroll.AnswerAt(stream,BigInteger.One) &&
                  ctx.PatchedNextBowlResult==
                      NormativeScroll.NextBowlInDrop46Order(normativeSauce,id),
                  "سلامة ترتيب الوعاء والخطوة الصفرية والجواب المختوم");
            if(ctx.PatchedBowlQuestionResult is not null &&
               ctx.PatchedBowlQuestionResult.First==stream.First &&
               ctx.PatchedAnswerAtResult==stream.First)_correctStreams++;
            Check(ctx.PatchedSauceFinalBowls is {Length:7} &&
                  ctx.PatchedSauceFinalBowls.SequenceEqual(normativeSauce.Bowls) &&
                  ctx.PatchedOrderAt46Latch is {Length:6} &&
                  ctx.PatchedOrderAt46Latch.SequenceEqual(normativeSauce.OrderAtDrop46) &&
                  ctx.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(ctx.PatchedSauceFinalBowls,ctx.LegacySauceFinalBowls),
                  "ملكية الصلصة والتصحيح والشواهد مستقلة");
        }
        _publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var q=NormativeScroll.AskBowl(normativeSauce,publicId,publicSeal);
        var n=m+1;
        var actual=CalendarDateSpaghetti.EvaluateRejectionDirection(
            c,t,publicId,publicSeal,n);
        var old=CalendarDateSpaghetti.EvaluateLegacyWideRejectionDirection(
            c,t,publicId,publicSeal,n);
        var expectedPublic=NormativeScroll.ChooseRankWide(q,n);
        Check(actual==expectedPublic && old==expectedPublic,
              "واجهة عامة صحيحة مع حفظ واجهة الشاهد القديم "+sample);
    }

    private static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        Synthetic();
        Boundaries();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<cases.Length;i++)Production(cases[i].C,cases[i].T,i+1);
        ValidationAndOwnership();

        Console.WriteLine("حالات التحكم: "+_controls);
        Console.WriteLine("حالات التحكم المصححة: "+_controlCorrect);
        Console.WriteLine("التطابقات التاريخية للضوابط: "+_controlHistorical);
        Console.WriteLine("حالات الرفض: "+_rejected);
        Console.WriteLine("مساواة الرقعة للمرجع عند الرفض: "+_rejectedCorrect);
        Console.WriteLine("مخالفات التاريخ عند الرفض: "+_rejectedHistoricalWrong);
        Console.WriteLine("مطابقات الزيادة: "+_ascendingHistoricalMatches);
        Console.WriteLine("اختلافات النقصان: "+_descendingHistoricalWrong);
        Console.WriteLine("الصلصات: "+_sauces);
        Console.WriteLine("قراءات الإنتاج: "+_production);
        Console.WriteLine("قراءات الإنتاج المصححة: "+_productionCorrect);
        Console.WriteLine("المخالفات التاريخية في الإنتاج: "+_productionHistoricalDifferent);
        Console.WriteLine("المطابقات التاريخية في الإنتاج: "+_productionHistoricalMatches);
        Console.WriteLine("رفض الإنتاج: "+_realRejections);
        Console.WriteLine("الشواهد للجواب الأول: "+_correctStreams);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_failed);
        return _failed==0 && _controls==34560 &&
            _controlCorrect==34560 && _controlHistorical==34560 &&
            _rejected==8640 && _rejectedCorrect==8640 &&
            _rejectedHistoricalWrong==4320 && _ascendingHistoricalMatches==4320 &&
            _descendingHistoricalWrong==4320 && _sauces==8 &&
            _production==96 && _productionCorrect==96 &&
            _productionHistoricalDifferent==28 && _productionHistoricalMatches==68 &&
            _realRejections==28 && _correctStreams==96 && _publicReads==8?0:1;
    }
}
