using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage28Tests;

internal static partial class Program
{
    private static int _passed,_unexpected,_ranks,_synthetic,_matches,_differences;
    private static int _sauces,_productionReads,_productionDifferences,_publicReads;
    private static int _correctQuestionWitnesses;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool condition,string label)
    {
        if(condition){_passed++;return;}
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة في الاكتشاف الرابع عشر: "+label);
    }

    private static BigInteger[] Offsets()
    {
        var m=NormativeScroll.M;
        var giant=BigInteger.One << 8192;
        return new BigInteger[]{0,1,2,m-1,m,m+1,giant,giant+m};
    }

    private static void Synthetic()
    {
        var old=new LegacyOneBasedAnswerStep();
        var offsets=Offsets();
        for(var rank=1;rank<=720;rank++)
        {
            _ranks++;
            for(var bowl=1;bowl<=6;bowl++)
            {
                var first=(BigInteger)(rank*6+bowl);
                foreach(var direction in new[]{-1,1})
                {
                    var stream=new AnswerStream(first,direction);
                    var produced=new LegacyBowlQuestionResult(first,direction);
                    foreach(var k in offsets)
                    {
                        _synthetic++;
                        var correct=NormativeScroll.AnswerAt(stream,k);
                        var observed=old.At(produced,k);
                        Check(observed>=1 && observed<=NormativeScroll.M,
                              "مدى الجواب التاريخي "+rank+"/"+bowl+"/"+direction);
                        Check(observed==NormativeScroll.AnswerAt(stream,k+1),
                              "القديم يقرأ الخطوة اللاحقة بالضبط");
                        Check(observed!=correct,
                              "الانزياح مستقل عن ترتيب الأوعية والاتجاه");
                        if(observed==correct)_matches++;else _differences++;
                    }
                }
            }
        }
        Check(_ranks==720 && _synthetic==69120 && _matches==0 &&
              _differences==69120,
              "جميع الحالات تختلف بخطوة وحيدة لا بخلل سابق");
    }

    private static void Production(BigInteger c,BigInteger t,int sample,BigInteger k)
    {
        _sauces++;
        var reference=NormativeScroll.Sauce(c,t);
        var id=(sample%6)+1;
        var seal=sample%2==0?31:21;
        var normativeStream=NormativeScroll.AskBowl(reference,id,seal);
        var expected=NormativeScroll.AnswerAt(normativeStream,k);
        var shifted=NormativeScroll.AnswerAt(normativeStream,k+1);
        var context=new MonsterManager().ExecuteLegacyOneBasedAnswer(c,t,id,seal,k);
        Contexts.Add(context);
        _productionReads++;
        var observed=context.LegacyOneBasedAnswerAtResult;
        if(observed!=expected)_productionDifferences++;
        var next=NormativeScroll.NextBowlInDrop46Order(reference,id);

        Check(context.Status=="LEGACY_ONE_BASED_ANSWER_STEP_COMPLETE" &&
              context.Phase==context.Status &&
              context.BranchTrace.SequenceEqual(new[]{
                  "BOOTSTRAP_VALIDATION",
                  "LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS",
                  "PROTECTED_DROP46_ORDER_LATCH_WITNESS",
                  "LEGACY_FIXED_NEXT_BOWL_WITNESS",
                  "PATCHED_NEXT_BOWL_ORDER_WITNESS",
                  "LEGACY_UNSEALED_BOWL_QUESTION_WITNESS",
                  "PATCHED_SEALED_BOWL_QUESTION_WITNESS",
                  "LEGACY_ONE_BASED_ANSWER_STEP"}) &&
              context.Metrics["legacy.one.based.answer.step.dispatch"]==1,
              "استدعاء المدير والموزع يمضي من الصلصة حتى السؤال "+sample);
        Check(context.PatchedBowlQuestionResult is not null &&
              context.PatchedBowlQuestionResult.First==normativeStream.First &&
              context.PatchedBowlQuestionResult.DirectionStep==normativeStream.DirectionStep &&
              context.LegacyOneBasedAnswerAtResult==shifted &&
              context.LegacyAnswerStepIndex==k,
              "المسار القديم ينزاح خطوة بعد جواب صحيح "+sample);
        if(context.PatchedBowlQuestionResult is not null &&
           context.PatchedBowlQuestionResult.First==normativeStream.First &&
           context.PatchedBowlQuestionResult.DirectionStep==normativeStream.DirectionStep)
            _correctQuestionWitnesses++;
        Check(context.LegacyQueriedBowlId==id &&
              context.LegacyBowlQuestionSeal==seal &&
              context.PatchedNextBowlResult==next &&
              context.LegacyFixedNextBowlResult==id%6+1,
              "لم تتغير الرقعتان الثانية عشرة والثالثة عشرة "+sample);
        Check(context.PatchedSauceFinalBowls is {Length:7} &&
              context.PatchedSauceFinalBowls.SequenceEqual(reference.Bowls) &&
              context.PatchedOrderAt46Latch is {Length:6} &&
              context.PatchedOrderAt46Latch.SequenceEqual(reference.OrderAtDrop46) &&
              context.LegacySauceFinalBowls is {Length:7} &&
              !ReferenceEquals(context.PatchedSauceFinalBowls,context.LegacySauceFinalBowls),
              "الأوعية والترتيب والشاهد القديم محفوظة بذاكرة مستقلة "+sample);
        Check(observed==shifted && observed!=expected,
              "الشاهد النهائي يفصل الإزاحة عن المصدر الصحيح "+sample);

        _publicReads++;
        var publicValue=CalendarDateSpaghetti.EvaluateLegacyOneBasedAnswer(c,t,id,seal,k);
        Check(publicValue==observed,
              "الواجهة العامة تصل إلى العيب الحقيقي "+sample);
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verify=args.Length==1 && args[0]=="--verify-expected-red";
        if(args.Length!=0&&!verify)return 2;
        Synthetic();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One << 8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        var ks=Offsets();
        for(var i=0;i<cases.Length;i++)
            Production(cases[i].C,cases[i].T,i+1,ks[i]);
        if(verify) CheckOwnershipAndRejection();

        Console.WriteLine("رتب السؤال: "+_ranks);
        Console.WriteLine("القراءات التركيبية: "+_synthetic);
        Console.WriteLine("التطابقات: "+_matches);
        Console.WriteLine("الانزياحات التاريخية: "+_differences);
        Console.WriteLine("الصلصات الحقيقية: "+_sauces);
        Console.WriteLine("القراءات الإنتاجية: "+_productionReads);
        Console.WriteLine("اختلافات الإنتاج: "+_productionDifferences);
        Console.WriteLine("شهود السؤال المصحح: "+_correctQuestionWitnesses);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("المخالفات غير المتوقعة: "+_unexpected);
        var pass=_unexpected==0 && _ranks==720 &&
            _synthetic==69120 && _matches==0 && _differences==69120 &&
            _sauces==8 && _productionReads==8 && _productionDifferences==8 &&
            _correctQuestionWitnesses==8 && _publicReads==8;
        if(verify)
        {
            Console.WriteLine("مدقق توقيع الانزياح الأحمر: "+(pass?"PASS":"FAIL"));
            return pass?0:1;
        }
        // الأحمر التاريخي متعمد ولا يتحول إلى أخضر حتى رقعة الطور التاسع والعشرين.
        return _unexpected==0 && _differences==0?0:1;
    }
}
