using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage32Tests;

internal static partial class Program
{
    private static int _passed,_unexpected,_synthetic,_syntheticDiff,_syntheticMatch,_twoPlace,_threePlace;
    private static int _realSauces,_production,_productionDiff,_productionMatch,_correctStreams,_publicReads;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string label)
    {
        if(ok){_passed++;return;}
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة في اكتشاف الأرقام الواسعة: "+label);
    }

    private static BigInteger[] Sizes()
    {
        var m=NormativeScroll.M;
        return new BigInteger[]{m+1,2*m+1,m*m-1,m*m+1};
    }

    // مرجع الاختبار المستقل لشكل الندبة، باستخدام أرقام المرجع لا معالج الإنتاج.
    // يُميز هذا الشاهد عكس أوزان التعبئة من خطأ اختيار الوعاء أو حفظ الأجوبة.
    private static BigInteger ExpectedReversed(AnswerStream stream,BigInteger n)
    {
        var m=NormativeScroll.M;
        var space=m;
        var places=1;
        while(space<n){space*=m;places++;}
        var weight=space/m;
        BigInteger wide=1;
        for(var i=0;i<places;i++)
        {
            wide+=(NormativeScroll.AnswerAt(stream,i)-1)*weight;
            weight/=m;
        }
        var limit=space/n*n;
        if(wide>limit)
        {
            var steps=stream.DirectionStep==1?space-wide+1:wide-limit;
            var q=(wide-1+stream.DirectionStep*steps)%space;
            if(q<0)q+=space;
            wide=q+1;
        }
        return (wide-1)%n+1;
    }

    private static void Synthetic()
    {
        var sizes=Sizes();
        var old=new LegacyReversedWideDigits();
        for(var rank=1;rank<=720;rank++)
        for(var id=1;id<=6;id++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+id);
            var normal=new AnswerStream(first,direction);
            var actualStream=new LegacyBowlQuestionResult(first,direction);
            for(var i=0;i<sizes.Length;i++)
            {
                var n=sizes[i];
                var correct=NormativeScroll.ChooseRankWide(normal,n);
                var historical=old.Choose(actualStream,n);
                var oldSignature=ExpectedReversed(normal,n);
                _synthetic++;
                if(i==3)_threePlace++;else _twoPlace++;
                if(historical==correct)_syntheticMatch++;else _syntheticDiff++;

                Check(historical>=1 && historical<=n,
                    "مجال رتبة الأسرة الواسعة");
                Check(historical==oldSignature,
                    "التعبئة التاريخية تعكس الأوزان لا ترتيب الإجابات");
                Check(historical!=correct,
                    "الموضع الأعلى القديم يخالف المرجع المعياري");
                Check(NormativeScroll.AnswerAt(normal,0)==first,
                    "الخطوة الصفرية المصححة لم تتغير");
            }
        }
        Check(_synthetic==34560 && _syntheticDiff==34560 &&
              _syntheticMatch==0 && _twoPlace==25920 && _threePlace==8640,
              "الندبة تختلف في الأوزان الثنائية والثلاثية لكل اتجاه");
    }

    private static void Boundaries()
    {
        var m=NormativeScroll.M;
        var old=new LegacyReversedWideDigits();
        foreach(var first in new BigInteger[]{1,2,m-1,m,m/2})
        foreach(var direction in new[]{-1,1})
        foreach(var n in Sizes())
        {
            var normative=new AnswerStream(first,direction);
            var got=old.Choose(new LegacyBowlQuestionResult(first,direction),n);
            Check(got==ExpectedReversed(normative,n),
                "الشاهد التاريخي عند حدود الإجابة الأولى");
            Check(got>=1 && got<=n,
                "نطاق الدرجة مع التفاف الاتجاه");
        }
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        _realSauces++;
        var sauce=NormativeScroll.Sauce(c,t);
        var sizes=Sizes();
        for(var i=0;i<sizes.Length;i++)
        {
            var id=(sample+i)%6+1;
            var seal=i%2==0?21:31;
            var n=sizes[i];
            var reference=NormativeScroll.AskBowl(sauce,id,seal);
            var context=new MonsterManager().ExecuteLegacyReversedWideRank(c,t,id,seal,n);
            if(i==0)Contexts.Add(context);
            _production++;
            var correct=NormativeScroll.ChooseRankWide(reference,n);
            var expectedLegacy=ExpectedReversed(reference,n);
            if(context.LegacyReversedWideRankResult==correct)_productionMatch++;
            else _productionDiff++;
            if(context.PatchedBowlQuestionResult is not null &&
                context.PatchedBowlQuestionResult.First==reference.First &&
                context.PatchedBowlQuestionResult.DirectionStep==reference.DirectionStep &&
                context.PatchedAnswerAtResult==reference.First)_correctStreams++;

            Check(context.Status=="LEGACY_REVERSED_WIDE_DIGITS_COMPLETE" &&
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
                    "LEGACY_REVERSED_WIDE_DIGITS"}) &&
                  context.Metrics["legacy.reversed.wide.digits.dispatch"]==1,
                "كل طبقات المدير والموزع والقياسات حاضرة");
            Check(context.LegacyWideFamilySize==n &&
                  context.LegacyReversedWideRankResult==expectedLegacy &&
                  context.PatchedAnswerAtResult==reference.First &&
                  context.LegacyOneBasedAnswerAtResult==
                      NormativeScroll.AnswerAt(reference,BigInteger.One),
                "النتيجة القديمة تمثل الأرقام المعكوسة بعد جواب أول صحيح");
            Check(context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
                  context.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(context.PatchedSauceFinalBowls,context.LegacySauceFinalBowls),
                "الملكية وترتيب القطرة والأوعية الصحيحة محفوظة");
            Check(context.PatchedNextBowlResult==
                  NormativeScroll.NextBowlInDrop46Order(sauce,id) &&
                  context.LegacyFixedNextBowlResult==id%6+1 &&
                  context.LegacyUnsealedBowlQuestionResult is not null,
                "الشواهد السابقة ولا سيما الجار والسؤال المختوم لم تتغير");
        }
        _publicReads++;
        var chosenId=sample%6+1;
        var chosenSeal=sample%2==0?31:21;
        var chosenSize=sizes[(sample-1)%sizes.Length];
        var stream=NormativeScroll.AskBowl(sauce,chosenId,chosenSeal);
        var through=CalendarDateSpaghetti.EvaluateLegacyReversedWideRank(
            c,t,chosenId,chosenSeal,chosenSize);
        Check(through==ExpectedReversed(stream,chosenSize),
              "الواجهة العامة تمر بالموزع التاريخي الحقيقي");
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verify=args.Length==1&&args[0]=="--verify-expected-red";
        if(args.Length!=0&&!verify)return 2;
        Synthetic();
        Boundaries();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<cases.Length;i++)Production(cases[i].C,cases[i].T,i+1);
        if(verify)ValidationAndOwnership();

        Console.WriteLine("الأسئلة التركيبية: "+_synthetic);
        Console.WriteLine("المخالفات التركيبية: "+_syntheticDiff);
        Console.WriteLine("التطابقات التركيبية: "+_syntheticMatch);
        Console.WriteLine("التعبئة ثنائية المواضع: "+_twoPlace);
        Console.WriteLine("التعبئة ثلاثية المواضع: "+_threePlace);
        Console.WriteLine("الصلصات الحقيقية: "+_realSauces);
        Console.WriteLine("أسئلة الإنتاج: "+_production);
        Console.WriteLine("مخالفات الإنتاج: "+_productionDiff);
        Console.WriteLine("تطابقات الإنتاج: "+_productionMatch);
        Console.WriteLine("شهود الإجابة الأولى الصحيحة: "+_correctStreams);
        Console.WriteLine("قراءات الواجهة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        var pass=_unexpected==0 && _synthetic==34560 &&
            _syntheticDiff==34560 && _syntheticMatch==0 &&
            _twoPlace==25920 && _threePlace==8640 &&
            _realSauces==8 && _production==32 &&
            _correctStreams==32 && _publicReads==8;
        if(verify)
        {
            Console.WriteLine("تحقق الأحمر التاريخي لترتيب الأرقام الواسعة: "+(pass?"PASS":"FAIL"));
            return pass?0:1;
        }
        return _unexpected==0&&_syntheticDiff==0?0:1;
    }
}
