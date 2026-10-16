using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage33Tests;

internal static partial class Program
{
    private static int _passed,_unexpected,_synthetic,_correct,_legacyDifferences,_legacyMatches;
    private static int _twoPlaces,_threePlaces,_sauces,_production,_productionCorrect;
    private static int _productionLegacyDifferences,_publicReads,_correctFirstAnswers;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool condition,string name)
    {
        if(condition){_passed++;return;}
        _unexpected++;
        Console.WriteLine("إخفاق غير متوقع في الرقعة السادسة عشرة: "+name);
    }

    private static BigInteger[] Sizes()
    {
        var m=NormativeScroll.M;
        return new BigInteger[]{m+1,2*m+1,m*m-1,m*m+1};
    }

    private static void Synthetic()
    {
        var sizes=Sizes();
        var patch=new WideDigitOrderPatchWrapper();
        var legacy=new LegacyReversedWideDigits();
        for(var rank=1;rank<=720;rank++)
        for(var bowl=1;bowl<=6;bowl++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+bowl);
            var normative=new AnswerStream(first,direction);
            var stream=new LegacyBowlQuestionResult(first,direction);
            for(var i=0;i<sizes.Length;i++)
            {
                var n=sizes[i];
                var expected=NormativeScroll.ChooseRankWide(normative,n);
                var actual=patch.Patch(stream,n);
                var historical=legacy.Choose(stream,n);
                _synthetic++;
                if(i==3)_threePlaces++;else _twoPlaces++;
                if(actual==expected)_correct++;
                if(historical!=expected)_legacyDifferences++;else _legacyMatches++;
                Check(actual>=1 && actual<=n,
                      "النطاق القانوني للمرتبة المصححة "+rank+"/"+bowl+"/"+i);
                Check(actual==expected,
                      "التكافؤ المستقل للعائلة الواسعة "+rank+"/"+bowl+"/"+i);
                Check(historical!=actual,
                      "الشاهد القديم لا يُستبدل أو يُعاد ترتيبه "+rank+"/"+bowl+"/"+i);
                Check(NormativeScroll.AnswerAt(normative,BigInteger.Zero)==first,
                      "الخطوة الصفرية لا تُحرَّف");
            }
        }
        Check(_synthetic==34560 && _correct==34560 &&
              _legacyDifferences==34560 && _legacyMatches==0 &&
              _twoPlaces==25920 && _threePlaces==8640,
              "التكافؤ الكامل والتوقيع القديم لجميع الأسر");
    }

    private static void Boundaries()
    {
        var m=NormativeScroll.M;
        var patch=new WideDigitOrderPatchWrapper();
        var legacy=new LegacyReversedWideDigits();
        foreach(var first in new BigInteger[]{1,2,m/2,m-1,m})
        foreach(var direction in new[]{-1,1})
        foreach(var size in Sizes())
        {
            var normative=new AnswerStream(first,direction);
            var source=new LegacyBowlQuestionResult(first,direction);
            var actual=patch.Patch(source,size);
            var historical=legacy.Choose(source,size);
            Check(actual==NormativeScroll.ChooseRankWide(normative,size),
                  "الحدود 1 وM واتجاه ±1 والقبول");
            Check(actual>=1 && actual<=size &&
                  historical>=1 && historical<=size,
                  "رتب صالحة حتى عند التفاف خانة السؤال");
        }

        // التحقق من عبور منطقة الرفض، لا من مثال عادي فقط.
        var hugeSpace=m*m;
        var near=new[]{new LegacyBowlQuestionResult(m,1),
                       new LegacyBowlQuestionResult(m,-1)};
        foreach(var stream in near)
        {
            var n=hugeSpace-1;
            Check(patch.Patch(stream,n)==NormativeScroll.ChooseRankWide(
                  new AnswerStream(stream.First,stream.DirectionStep),n),
                  "حد القبول عند M^2-1");
        }
        // أرقام بعرض كبير حتى مع عدم وجود مصفوفة أوعية مشتركة.
        var huge=BigInteger.One<<8192;
        var wanted=huge+(m*m)+1;
        // لا نختار بدايةً داخل منطقة رفض طولها أرقام فلكية؛
        // مرجع الاختبار يمشي فيها خطوة خطوة. هنا تقع البداية قطعاً تحت الحد.
        var normalStream=new AnswerStream(BigInteger.One,1);
        var wide=patch.Patch(new LegacyBowlQuestionResult(BigInteger.One,1),wanted);
        Check(wide==NormativeScroll.ChooseRankWide(normalStream,wanted),
              "حجم أسرة عريض للغاية ومواضع عديدة دون اجتياز رفض هائل");
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        _sauces++;
        var sauce=NormativeScroll.Sauce(c,t);
        var sizes=Sizes();
        var manager=new MonsterManager();
        for(var i=0;i<sizes.Length;i++)
        {
            var id=(sample+i)%6+1;
            var seal=i%2==0?21:31;
            var n=sizes[i];
            var stream=NormativeScroll.AskBowl(sauce,id,seal);
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            var result=manager.ExecutePatchedWideRank(c,t,id,seal,n);
            if(i==0)Contexts.Add(result);
            _production++;
            if(result.PatchedWideRankResult==expected)_productionCorrect++;
            if(result.LegacyReversedWideRankResult!=expected)_productionLegacyDifferences++;
            var historical=new LegacyReversedWideDigits().Choose(
                new LegacyBowlQuestionResult(stream.First,stream.DirectionStep),n);
            var next=NormativeScroll.NextBowlInDrop46Order(sauce,id);

            Check(result.Status=="PATCHED_WIDE_DIGIT_ORDER_COMPLETE" &&
                  result.Phase==result.Status &&
                  result.BranchTrace.SequenceEqual(new[]{
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
                      "PATCHED_WIDE_DIGIT_ORDER"}) &&
                  result.Metrics["legacy.reversed.wide.digits.witness"]==1 &&
                  result.Metrics["patched.wide.digit.order.dispatch"]==1,
                  "سلسلة المدير والموزع والشواهد "+sample+"/"+i);
            Check(result.PatchedWideRankResult==expected &&
                  result.LegacyReversedWideRankResult==historical &&
                  result.LegacyWideFamilySize==n &&
                  result.LegacyAnswerStepIndex==BigInteger.Zero &&
                  result.PatchedWideRankResult is BigInteger x && x>=1 && x<=n,
                  "الرتبة الصحيحة والشاهد القديم محفوظان معاً");
            Check(result.PatchedBowlQuestionResult is not null &&
                  result.PatchedBowlQuestionResult.First==stream.First &&
                  result.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  result.PatchedAnswerAtResult==stream.First &&
                  result.LegacyOneBasedAnswerAtResult==
                      NormativeScroll.AnswerAt(stream,BigInteger.One) &&
                  result.PatchedNextBowlResult==next &&
                  result.LegacyFixedNextBowlResult==id%6+1,
                  "الجرن والجواب المختوم والخطوة الصفرية لا تتغيّر");
            if(result.PatchedBowlQuestionResult is not null &&
               result.PatchedBowlQuestionResult.First==stream.First &&
               result.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
               result.PatchedAnswerAtResult==stream.First)_correctFirstAnswers++;
            Check(result.PatchedSauceFinalBowls is {Length:7} &&
                  result.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  result.PatchedOrderAt46Latch is {Length:6} &&
                  result.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
                  result.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(result.LegacySauceFinalBowls,
                                   result.PatchedSauceFinalBowls) &&
                  !ReferenceEquals(result.LegacyDiagnosticDrop46Order,
                                   result.PatchedOrderAt46Latch),
                  "الأوعية والترتيب المحمي والمخزن القديم مستقلة");
        }
        _publicReads++;
        var apiId=sample%6+1;
        var apiSeal=sample%2==0?31:21;
        var apiN=sizes[(sample-1)%sizes.Length];
        var streamApi=NormativeScroll.AskBowl(sauce,apiId,apiSeal);
        var fixedApi=CalendarDateSpaghetti.EvaluateWideFamilyRank(
            c,t,apiId,apiSeal,apiN);
        var oldApi=CalendarDateSpaghetti.EvaluateLegacyReversedWideRank(
            c,t,apiId,apiSeal,apiN);
        Check(fixedApi==NormativeScroll.ChooseRankWide(streamApi,apiN) &&
              oldApi==new LegacyReversedWideDigits().Choose(
                  new LegacyBowlQuestionResult(streamApi.First,streamApi.DirectionStep),apiN),
              "واجهة مصححة مستقلة عن الواجهة التاريخية "+sample);
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

        Console.WriteLine("الأسئلة التركيبية: "+_synthetic);
        Console.WriteLine("مطابقات الرقعة: "+_correct);
        Console.WriteLine("المخالفات التاريخية: "+_legacyDifferences);
        Console.WriteLine("تطابقات التاريخ: "+_legacyMatches);
        Console.WriteLine("موضعان: "+_twoPlaces);
        Console.WriteLine("ثلاثة مواضع: "+_threePlaces);
        Console.WriteLine("الصلصات: "+_sauces);
        Console.WriteLine("أسئلة الإنتاج: "+_production);
        Console.WriteLine("إجابات الإنتاج المصححة: "+_productionCorrect);
        Console.WriteLine("مخالفات الإنتاج التاريخية: "+_productionLegacyDifferences);
        Console.WriteLine("شهود الجواب الأول الصحيح: "+_correctFirstAnswers);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        return _unexpected==0 && _synthetic==34560 && _correct==34560 &&
            _legacyDifferences==34560 && _legacyMatches==0 &&
            _twoPlaces==25920 && _threePlaces==8640 &&
            _sauces==8 && _production==32 && _productionCorrect==32 &&
            _productionLegacyDifferences==32 && _correctFirstAnswers==32 &&
            _publicReads==8 ? 0 : 1;
    }
}
