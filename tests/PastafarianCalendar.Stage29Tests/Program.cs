using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage29Tests;

internal static partial class Program
{
    private static int _passed,_failed,_ranks,_synthetic,_correct,_legacyDifferences;
    private static int _sauces,_production,_productionCorrect,_productionLegacyDifferences;
    private static int _publicReads,_correctStreams,_zeroOrigin;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool condition,string reason)
    {
        if(condition){_passed++;return;}
        _failed++;
        Console.WriteLine("فشل رقعة الخطوة الصفرية: "+reason);
    }

    private static BigInteger[] Offsets()
    {
        var m=NormativeScroll.M;
        var huge=BigInteger.One << 8192;
        return new BigInteger[]{0,1,2,m-1,m,m+1,huge,huge+m};
    }

    private static void Synthetic()
    {
        var patched=new AnswerStepZeroBasedPatchWrapper();
        var old=new LegacyOneBasedAnswerStep();
        var offsets=Offsets();
        for(var rank=1;rank<=720;rank++)
        {
            _ranks++;
            for(var bowl=1;bowl<=6;bowl++)
            foreach(var direction in new[]{-1,1})
            {
                var first=(BigInteger)(rank*6+bowl);
                var norm=new AnswerStream(first,direction);
                var stream=new LegacyBowlQuestionResult(first,direction);
                foreach(var k in offsets)
                {
                    _synthetic++;
                    var actual=patched.Patch(stream,k);
                    var expected=NormativeScroll.AnswerAt(norm,k);
                    var historical=old.At(stream,k);
                    var historicalExpected=NormativeScroll.AnswerAt(norm,k+1);
                    if(actual==expected)_correct++;
                    if(historical!=expected)_legacyDifferences++;
                    if(k.IsZero&&actual==first)_zeroOrigin++;

                    Check(actual>=1 && actual<=NormativeScroll.M,
                          "المجال المحمي "+rank+"/"+bowl+"/"+direction);
                    Check(actual==expected,
                          "مساواة المرجع المستقل "+rank+"/"+bowl+"/"+direction+"/"+k);
                    Check(historical==historicalExpected && historical!=actual,
                          "الشاهد القديم ما زال يقرأ k+1 "+rank+"/"+bowl+"/"+direction);
                }
            }
        }
        Check(_ranks==720 && _synthetic==69120 && _correct==69120 &&
              _legacyDifferences==69120 && _zeroOrigin==8640,
              "الشهادة الشاملة لجميع التبديلات والاتجاهين وحدود k");
    }

    private static void Boundary()
    {
        var m=NormativeScroll.M;
        var giant=BigInteger.One << 8192;
        var firsts=new BigInteger[]{1,2,m-1,m,m/2,giant%m+1};
        var offsets=Offsets();
        var patched=new AnswerStepZeroBasedPatchWrapper();
        var old=new LegacyOneBasedAnswerStep();
        foreach(var first in firsts)
        foreach(var direction in new[]{-1,1})
        foreach(var k in offsets)
        {
            var stream=new LegacyBowlQuestionResult(first,direction);
            var norm=new AnswerStream(first,direction);
            var actual=patched.Patch(stream,k);
            var historical=old.At(stream,k);
            Check(actual==NormativeScroll.AnswerAt(norm,k),
                  "قيمة حدية أو التفاف 2^127-1");
            Check(historical==NormativeScroll.AnswerAt(norm,k+1) &&
                  historical!=actual,
                  "الندبة ثابتة حتى عند انتقال الدور");
            if(k.IsZero)Check(actual==first,
                            "صفر الخطوة لا يزحزح أول جواب");
        }
    }

    private static void Production(BigInteger calculation,BigInteger target,int sample)
    {
        _sauces++;
        var reference=NormativeScroll.Sauce(calculation,target);
        var manager=new MonsterManager();
        var offsets=Offsets();
        for(var id=1;id<=6;id++)
        for(var index=0;index<2;index++)
        {
            var seal=index==0?21:31;
            var k=offsets[((sample-1)*12+(id-1)*2+index)%offsets.Length];
            var stream=NormativeScroll.AskBowl(reference,id,seal);
            var expected=NormativeScroll.AnswerAt(stream,k);
            var historicalExpected=NormativeScroll.AnswerAt(stream,k+1);
            var context=manager.ExecutePatchedAnswerStep(calculation,target,id,seal,k);
            if(id==1&&index==0)Contexts.Add(context);
            _production++;
            if(context.PatchedAnswerAtResult==expected)_productionCorrect++;
            if(context.LegacyOneBasedAnswerAtResult!=expected)_productionLegacyDifferences++;
            var next=NormativeScroll.NextBowlInDrop46Order(reference,id);

            Check(context.Status=="PATCHED_ZERO_BASED_ANSWER_STEP_COMPLETE" &&
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
                      "PATCHED_ZERO_BASED_ANSWER_STEP"}) &&
                  context.Metrics["legacy.one.based.answer.step.witness"]==1 &&
                  context.Metrics["patched.zero.based.answer.step.dispatch"]==1,
                  "مدير وموزع ورقعة وشاهد قديم "+sample+"/"+id+"/"+seal);
            Check(context.LegacyAnswerStepIndex==k &&
                  context.PatchedAnswerAtResult==expected &&
                  context.LegacyOneBasedAnswerAtResult==historicalExpected &&
                  context.LegacyOneBasedAnswerAtResult!=expected,
                  "الخطوة الصحيحة وشاهد الانزياح منفصلان "+sample+"/"+id+"/"+seal);
            Check(context.PatchedBowlQuestionResult is not null &&
                  context.PatchedBowlQuestionResult.First==stream.First &&
                  context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  context.PatchedNextBowlResult==next &&
                  context.LegacyFixedNextBowlResult==id%6+1,
                  "رقعتا السؤال والجار ما زالتا صحيحتين "+sample+"/"+id+"/"+seal);
            if(context.PatchedBowlQuestionResult is not null &&
               context.PatchedBowlQuestionResult.First==stream.First &&
               context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep)
                _correctStreams++;
            Check(context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(reference.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(reference.OrderAtDrop46) &&
                  context.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(context.PatchedSauceFinalBowls,context.LegacySauceFinalBowls) &&
                  !ReferenceEquals(context.LegacyOverwrittenQueryOrder,context.PatchedOrderAt46Latch),
                  "سلامة أوعية الصلصة والملكية والحفظ "+sample+"/"+id+"/"+seal);
            Check(context.LegacyUnsealedBowlQuestionResult is not null &&
                  context.LegacyUnsealedBowlQuestionResult==new LegacyUnsealedBowlQuestion().Ask(
                      reference.Bowls,id,next,seal),
                  "شاهد حاتم السؤال الثالث عشر لا يزال مستقلاً "+sample+"/"+id+"/"+seal);
        }
        _publicReads++;
        var publicId=(sample%6)+1;
        var publicSeal=sample%2==0?31:21;
        var publicK=offsets[sample-1];
        var normStream=NormativeScroll.AskBowl(reference,publicId,publicSeal);
        var direct=CalendarDateSpaghetti.EvaluateAnswerAt(
            calculation,target,publicId,publicSeal,publicK);
        var oldDirect=CalendarDateSpaghetti.EvaluateLegacyOneBasedAnswer(
            calculation,target,publicId,publicSeal,publicK);
        Check(direct==NormativeScroll.AnswerAt(normStream,publicK) &&
              oldDirect==NormativeScroll.AnswerAt(normStream,publicK+1) &&
              direct!=oldDirect,
              "الواجهة العامة المستقلة وحفظ الندبة "+sample);
    }

    private static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        Synthetic();
        Boundary();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One << 8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<cases.Length;i++)Production(cases[i].C,cases[i].T,i+1);
        ValidationAndOwnership();

        Console.WriteLine("الرتب التركيبية: "+_ranks);
        Console.WriteLine("القراءات التركيبية: "+_synthetic);
        Console.WriteLine("مطابقات الرقعة: "+_correct);
        Console.WriteLine("انزياحات المسار القديم: "+_legacyDifferences);
        Console.WriteLine("الصلصات الإنتاجية: "+_sauces);
        Console.WriteLine("قراءات الإنتاج: "+_production);
        Console.WriteLine("قراءات الإنتاج المصححة: "+_productionCorrect);
        Console.WriteLine("مخالفات الإنتاج التاريخية: "+_productionLegacyDifferences);
        Console.WriteLine("الشواهد للسؤال المختوم: "+_correctStreams);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_failed);
        return _failed==0 && _ranks==720 && _synthetic==69120 &&
            _correct==69120 && _legacyDifferences==69120 &&
            _zeroOrigin==8640 && _sauces==8 && _production==96 &&
            _productionCorrect==96 && _productionLegacyDifferences==96 &&
            _correctStreams==96 && _publicReads==8 ? 0 : 1;
    }
}
