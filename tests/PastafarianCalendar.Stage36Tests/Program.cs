using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage36Tests;

internal static partial class Program
{
    private static int _passes,_unexpected,_controls,_controlMatches;
    private static int _rejected,_rejectedWrong,_ascendingMatches,_descendingDifferent;
    private static int _sauces,_production,_productionMatches,_productionDifferent,_productionRejections;
    private static int _correctFirstAnswers,_publicReads;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string label)
    {
        if(ok){_passes++;return;}
        _unexpected++;
        Console.WriteLine("خطأ غير متوقع في اكتشاف رفض الاتجاه النازل: "+label);
    }

    private static BigInteger[] Sizes()
    {
        var m=NormativeScroll.M;
        return new BigInteger[]{m+1,2*m+1,m*m-1,m*m+1};
    }

    private static BigInteger TwoDigitWide(AnswerStream stream)
        => stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-BigInteger.One)*NormativeScroll.M;

    private static void Synthetic()
    {
        var m=NormativeScroll.M;
        var historical=new LegacyWideRejectionDirection();
        var correct=new WideDigitOrderPatchWrapper();
        foreach(var rank in Enumerable.Range(1,720))
        for(var bowl=1;bowl<=6;bowl++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+bowl);
            var stream=new AnswerStream(first,direction);
            var production=new LegacyBowlQuestionResult(first,direction);
            foreach(var n in Sizes())
            {
                _controls++;
                var reference=NormativeScroll.ChooseRankWide(stream,n);
                var corrected=correct.Patch(production,n);
                var observed=historical.Choose(production,n);
                if(observed==reference)_controlMatches++;
                Check(corrected==reference && observed==reference &&
                      observed>=1 && observed<=n,
                      "نطاق غير مرفوض: الندبة لا تمس القبول "+rank+"/"+bowl);
            }

            // يجبر n=wide-1 (حين wide>M²/2) على رفض الجواب الأول؛
            // أول جواب مقبول إلى الأمام هو 1، وإلى الخلف هو n.
            var high=m-BigInteger.One-first;
            var witness=new AnswerStream(high,direction);
            var actual=new LegacyBowlQuestionResult(high,direction);
            var nWitness=TwoDigitWide(witness)-BigInteger.One;
            _rejected++;
            Check(nWitness>m*m/2 && nWitness<m*m,
                  "شاهد الرفض داخل نطاق خانتين");
            var obtained=historical.Choose(actual,nWitness);
            var correctedWitness=correct.Patch(actual,nWitness);
            var independent=direction==1
                ? BigInteger.One
                : NormativeScroll.ChooseRankWide(witness,nWitness);
            if(obtained!=independent)_rejectedWrong++;
            if(direction==1 && obtained==independent)_ascendingMatches++;
            if(direction==-1 && obtained!=independent)_descendingDifferent++;
            Check(correctedWitness==independent &&
                  independent==(direction==1?BigInteger.One:nWitness),
                  "الإجابة المرجعية التالية حسب اتجاه السؤال");
            Check(obtained==BigInteger.One &&
                  (direction==1?obtained==independent:obtained!=independent),
                  "العيب التاريخي يقفز إلى أول رتبة في الاتجاهين");
        }
        Check(_controls==34560 && _controlMatches==34560 &&
              _rejected==8640 && _rejectedWrong==4320 &&
              _ascendingMatches==4320 && _descendingDifferent==4320,
              "التوقيع التركيبي الدقيق للعيب الثامن عشر");
    }

    private static void Boundary()
    {
        var m=NormativeScroll.M;
        var old=new LegacyWideRejectionDirection();
        var norm=new WideDigitOrderPatchWrapper();
        foreach(var first in new BigInteger[]{1,2,m/2,m-2,m-1,m})
        foreach(var direction in new[]{-1,1})
        foreach(var n in Sizes())
        {
            var stream=new AnswerStream(first,direction);
            var source=new LegacyBowlQuestionResult(first,direction);
            var reference=NormativeScroll.ChooseRankWide(stream,n);
            Check(norm.Patch(source,n)==reference,
                  "حدود مصدر الأجوبة المصحح");
            var historic=old.Choose(source,n);
            Check(historic>=1 && historic<=n && historic==reference,
                  "نتائج التاريخ دون رفض عند طرف المجال");
        }
        // فضاء مرتبة الأسرة الأكبر من آلاف البتات: أول إجابة مقبولة قطعاً.
        var huge=(BigInteger.One<<8192)+m*m+1;
        var streamHuge=new AnswerStream(BigInteger.One,1);
        var oldHuge=old.Choose(new LegacyBowlQuestionResult(1,1),huge);
        Check(oldHuge==NormativeScroll.ChooseRankWide(streamHuge,huge),
              "أكثر من 8192 بت من دون إعادة استخدام مخزن معياري عام");
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        _sauces++;
        var sauce=NormativeScroll.Sauce(c,t);
        var m=NormativeScroll.M;
        var manager=new MonsterManager();
        for(var id=1;id<=6;id++)
        for(var sealIndex=0;sealIndex<2;sealIndex++)
        {
            var seal=sealIndex==0?21:31;
            var question=NormativeScroll.AskBowl(sauce,id,seal);
            var wide=TwoDigitWide(question);
            // لا נוליך את האורקל לתוך איזור דחייה עצום:
            // בחירת n=wide-1 נעשית רק כשהשאלה יורדת, ואז צעד אחד מספיק.
            var mustReject=question.DirectionStep==-1 &&
                wide>m*m/2+BigInteger.One && wide<m*m;
            var n=mustReject?wide-BigInteger.One:m+BigInteger.One;
            var reference=NormativeScroll.ChooseRankWide(question,n);
            var context=manager.ExecuteLegacyWideRejectionDirection(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            _production++;
            var observed=context.LegacyRejectionDirectionRankResult;
            if(observed==reference)_productionMatches++;
            else _productionDifferent++;
            if(mustReject)_productionRejections++;
            Check(context.Status=="LEGACY_WIDE_REJECTION_DIRECTION_COMPLETE" &&
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
                    "LEGACY_REVERSED_WIDE_DIGITS_WITNESS",
                    "PATCHED_WIDE_DIGIT_ORDER_WITNESS",
                    "LEGACY_INCLUSIVE_WIDE_LIMIT_WITNESS",
                    "PATCHED_INCLUSIVE_WIDE_LIMIT_WITNESS",
                    "LEGACY_WIDE_REJECTION_DIRECTION"}) &&
                  context.Metrics["legacy.wide.rejection.direction.dispatch"]==1 &&
                  context.Metrics["patched.inclusive.wide.limit.witness"]==1,
                  "سلسلة إنتاج حقيقية للمراحل السابقة "+sample+"/"+id+"/"+seal);
            Check(context.PatchedInclusiveWideLimitRankResult==reference &&
                  context.LegacyWideFamilySize==n &&
                  (mustReject ?
                    observed==BigInteger.One && reference==n && observed!=reference :
                    observed==reference),
                  "خطأ الاتجاه النازل وحده هو موضع الانحراف");
            Check(context.PatchedBowlQuestionResult is not null &&
                  context.PatchedBowlQuestionResult.First==question.First &&
                  context.PatchedBowlQuestionResult.DirectionStep==question.DirectionStep &&
                  context.PatchedAnswerAtResult==question.First &&
                  context.LegacyOneBasedAnswerAtResult==
                    NormativeScroll.AnswerAt(question,BigInteger.One) &&
                  context.PatchedNextBowlResult==
                    NormativeScroll.NextBowlInDrop46Order(sauce,id),
                  "صحة الجار والسؤال المختوم وأول جواب");
            if(context.PatchedAnswerAtResult==question.First &&
               context.PatchedBowlQuestionResult is not null &&
               context.PatchedBowlQuestionResult.First==question.First)
                _correctFirstAnswers++;
            Check(context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
                  context.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(context.PatchedSauceFinalBowls,
                                   context.LegacySauceFinalBowls),
                  "ملكية الصلصة وترتيب القطرة مستقلان");
        }
        _publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var publicQuestion=NormativeScroll.AskBowl(sauce,publicId,publicSeal);
        var publicN=m+1;
        var via=CalendarDateSpaghetti.EvaluateLegacyWideRejectionDirection(
            c,t,publicId,publicSeal,publicN);
        Check(via==NormativeScroll.ChooseRankWide(publicQuestion,publicN),
              "واجهة تاريخية عامة تمر بمسار الإنتاج الفعلي "+sample);
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verify=args.Length==1&&args[0]=="--verify-expected-red";
        if(args.Length!=0&&!verify)return 2;
        Synthetic();
        Boundary();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<cases.Length;i++)Production(cases[i].C,cases[i].T,i+1);
        if(verify)ValidationAndOwnership();

        Console.WriteLine("الضوابط التركيبية: "+_controls);
        Console.WriteLine("مطابقات الضوابط: "+_controlMatches);
        Console.WriteLine("شواهد الرفض: "+_rejected);
        Console.WriteLine("الاختلافات التاريخية: "+_rejectedWrong);
        Console.WriteLine("مطابقات الاتجاه الصاعد: "+_ascendingMatches);
        Console.WriteLine("مخالفات الاتجاه النازل: "+_descendingDifferent);
        Console.WriteLine("الصلصات الحقيقية: "+_sauces);
        Console.WriteLine("أسئلة الإنتاج: "+_production);
        Console.WriteLine("اختلافات الإنتاج: "+_productionDifferent);
        Console.WriteLine("مطابقات الإنتاج: "+_productionMatches);
        Console.WriteLine("حالات رفض إنتاجية: "+_productionRejections);
        Console.WriteLine("الشواهد للجواب الأول: "+_correctFirstAnswers);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passes);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        var ok=_unexpected==0 && _controls==34560 && _controlMatches==34560 &&
            _rejected==8640 && _rejectedWrong==4320 &&
            _ascendingMatches==4320 && _descendingDifferent==4320 &&
            _sauces==8 && _production==96 &&
            _productionRejections>0 && _productionRejections==_productionDifferent &&
            _productionMatches+_productionDifferent==_production &&
            _correctFirstAnswers==96 && _publicReads==8;
        if(verify)
        {
            Console.WriteLine("تحقق الندبة الثامنة عشرة: "+(ok?"PASS":"FAIL"));
            return ok?0:1;
        }
        return _unexpected==0&&_rejectedWrong==0?0:1;
    }
}
