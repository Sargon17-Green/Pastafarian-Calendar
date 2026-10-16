using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage34Tests;

internal static partial class Program
{
    private static int _pass,_unexpected,_controls,_controlsEqual,_witnesses,_witnessDifferent;
    private static int _sauces,_production,_productionDifferent,_productionSame,_correctStreams,_publicReads;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string description)
    {
        if(ok){_pass++;return;}
        _unexpected++;
        Console.WriteLine("فشل غير متوقع في إثبات رفض المساواة: "+description);
    }

    private static BigInteger[] ControlSizes()
    {
        var m=NormativeScroll.M;
        return new BigInteger[]{m+1,2*m+1,m*m-1,m*m+1};
    }

    private static BigInteger InitialWide(AnswerStream stream)
    {
        var m=NormativeScroll.M;
        return stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*m;
    }

    // نموذج مستقل لخطأ >=؛ لا يستورد شيفرة المنتج التاريخية.
    private static BigInteger InclusiveExpected(AnswerStream stream,BigInteger n)
    {
        var m=NormativeScroll.M;
        var space=m;var places=1;
        while(space<n){space*=m;places++;}
        var wide=BigInteger.One;var weight=BigInteger.One;
        for(var j=0;j<places;j++)
        {
            wide+=(NormativeScroll.AnswerAt(stream,j)-1)*weight;
            weight*=m;
        }
        var limit=space/n*n;
        if(wide>=limit)
        {
            var steps=stream.DirectionStep==1?space-wide+1:wide-limit+1;
            var z=(wide-1+stream.DirectionStep*steps)%space;
            if(z<0)z+=space;
            wide=z+1;
        }
        return (wide-1)%n+1;
    }

    private static void Synthetic()
    {
        var legacy=new LegacyInclusiveWideLimit();
        var m=NormativeScroll.M;
        var controls=ControlSizes();
        for(var rank=1;rank<=720;rank++)
        for(var bowl=1;bowl<=6;bowl++)
        foreach(var direction in new[]{-1,1})
        {
            var lo=new BigInteger(rank*6+bowl);
            var normal=new AnswerStream(lo,direction);
            var actualStream=new LegacyBowlQuestionResult(lo,direction);
            foreach(var n in controls)
            {
                _controls++;
                var correct=NormativeScroll.ChooseRankWide(normal,n);
                var legacyRank=legacy.Choose(actualStream,n);
                if(legacyRank==correct)_controlsEqual++;
                Check(legacyRank==InclusiveExpected(normal,n) &&
                      legacyRank>=1 && legacyRank<=n,
                      "حفظ توقيع عدم قبول الحد دون قلب الأرقام");
                Check(legacyRank==correct,
                      "القيم الواقعة تحت الحدّ لا تتغير");
            }

            // الرقم الأعلى يضع أول عنصر عريض عند حدّه بالضبط:
            // choose n = wide > M^2/2 فيصبح limit=n وتظهر الندبة مباشرة.
            var hi=m-1-lo;
            var witnessStream=new AnswerStream(hi,direction);
            var candidate=InitialWide(witnessStream);
            Check(candidate>m*m/2 && candidate<m*m,
                  "تكوين شاهد حقيقي على حد القبول");
            var observed=legacy.Choose(
                new LegacyBowlQuestionResult(hi,direction),candidate);
            var expected=NormativeScroll.ChooseRankWide(witnessStream,candidate);
            _witnesses++;
            if(observed!=expected)_witnessDifferent++;
            Check(expected==candidate && observed!=expected &&
                  observed==InclusiveExpected(witnessStream,candidate) &&
                  observed==(direction==1?BigInteger.One:candidate-BigInteger.One),
                  "رفض التساوي يتجاوز الجواب الصحيح في كلا الاتجاهين");
        }
        Check(_controls==34560 && _controlsEqual==34560 &&
              _witnesses==8640 && _witnessDifferent==8640,
              "ختم التوقيع الاصطناعي 34560 حالة دون خطأ و8640 شاهد حد");
    }

    private static void Boundaries()
    {
        var m=NormativeScroll.M;
        var legacy=new LegacyInclusiveWideLimit();
        foreach(var first in new BigInteger[]{1,2,m/2,m-2,m-1,m})
        foreach(var direction in new[]{-1,1})
        foreach(var size in ControlSizes())
        {
            var reference=new AnswerStream(first,direction);
            var actual=legacy.Choose(new LegacyBowlQuestionResult(first,direction),size);
            Check(actual==InclusiveExpected(reference,size),
                  "حفظ صيغة الندبة عند حدود 1 وM واتجاه ±1");
            Check(actual>=1 && actual<=size,
                  "مدى المرتبة التاريخية قانوني");
        }
    }

    private static void Production(BigInteger c,BigInteger t,int index)
    {
        _sauces++;
        var sauce=NormativeScroll.Sauce(c,t);
        var m=NormativeScroll.M;
        var manager=new MonsterManager();

        var witnessFound=false;
        for(var id=1;id<=6 && !witnessFound;id++)
        for(var sealIndex=0;sealIndex<2 && !witnessFound;sealIndex++)
        {
            var seal=sealIndex==0?21:31;
            var stream=NormativeScroll.AskBowl(sauce,id,seal);
            var n=InitialWide(stream);
            if(n<=m*m/2 || n>=m*m)continue;
            witnessFound=true;
            var context=manager.ExecuteLegacyInclusiveWideLimit(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            _production++;
            var reference=NormativeScroll.ChooseRankWide(stream,n);
            var observed=context.LegacyInclusiveWideLimitRankResult;
            if(observed!=reference)_productionDifferent++;
            Check(reference==n && observed!=reference &&
                  observed==InclusiveExpected(stream,n),
                  "سؤال إنتاج عند حد القبول نفسه "+index);
            Check(context.PatchedWideRankResult==n &&
                  context.PatchedAnswerAtResult==stream.First &&
                  context.LegacyInclusiveWideLimitRankResult.HasValue &&
                  context.LegacyReversedWideRankResult.HasValue &&
                  context.PatchedBowlQuestionResult is not null &&
                  context.PatchedBowlQuestionResult.First==stream.First &&
                  context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep,
                  "الرقعة السادسة عشرة والجواب الأول الصحيح مستقلان "+index);
            VerifyContext(context,sauce,id,seal,n,index);
        }
        Check(witnessFound,"تغطية حالة إنتاج صحيحة تساوي حد القبول "+index);

        var ctrlId=index%6+1;
        var ctrlSeal=index%2==0?31:21;
        var ctrlN=m+1;
        var ctrlStream=NormativeScroll.AskBowl(sauce,ctrlId,ctrlSeal);
        var ctrl=manager.ExecuteLegacyInclusiveWideLimit(c,t,ctrlId,ctrlSeal,ctrlN);
        _production++;
        if(ctrl.LegacyInclusiveWideLimitRankResult==
           NormativeScroll.ChooseRankWide(ctrlStream,ctrlN))_productionSame++;
        Check(ctrl.LegacyInclusiveWideLimitRankResult==
              InclusiveExpected(ctrlStream,ctrlN),
              "حالة الإنتاج غير الحدية تحمل فقط الندبة المحددة "+index);
        VerifyContext(ctrl,sauce,ctrlId,ctrlSeal,ctrlN,index+100);

        _publicReads++;
        var through=CalendarDateSpaghetti.EvaluateLegacyInclusiveWideLimit(
            c,t,ctrlId,ctrlSeal,ctrlN);
        Check(through==ctrl.LegacyInclusiveWideLimitRankResult,
              "واجهة عامة تعبر السلسلة التاريخية "+index);
    }

    private static void VerifyContext(MonsterContext ctx,SauceScroll sauce,int id,int seal,BigInteger n,int marker)
    {
        var next=NormativeScroll.NextBowlInDrop46Order(sauce,id);
        Check(ctx.Status=="LEGACY_INCLUSIVE_WIDE_LIMIT_COMPLETE" &&
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
                 "LEGACY_INCLUSIVE_WIDE_LIMIT"}) &&
              ctx.Metrics["legacy.inclusive.wide.limit.dispatch"]==1,
              "الموزع والسجل يشهدان رفض المساواة "+marker);
        Check(ctx.PatchedSauceFinalBowls is {Length:7} &&
              ctx.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
              ctx.PatchedOrderAt46Latch is {Length:6} &&
              ctx.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
              ctx.LegacySauceFinalBowls is {Length:7} &&
              !ReferenceEquals(ctx.PatchedSauceFinalBowls,ctx.LegacySauceFinalBowls) &&
              ctx.PatchedNextBowlResult==next &&
              ctx.LegacyFixedNextBowlResult==id%6+1 &&
              ctx.LegacyWideFamilySize==n &&
              ctx.LegacyBowlQuestionSeal==seal,
              "ملكية السياق وثبات الصلصة والجار "+marker);
        if(ctx.PatchedBowlQuestionResult is not null &&
           ctx.PatchedAnswerAtResult==ctx.PatchedBowlQuestionResult.First)
            _correctStreams++;
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verify=args.Length==1 && args[0]=="--verify-expected-red";
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
        Console.WriteLine("الحالات دون حد: "+_controls);
        Console.WriteLine("مطابقات الحالات غير الحدية: "+_controlsEqual);
        Console.WriteLine("شواهد المساواة: "+_witnesses);
        Console.WriteLine("مخالفات المساواة: "+_witnessDifferent);
        Console.WriteLine("الصلصات الحقيقية: "+_sauces);
        Console.WriteLine("أسئلة الإنتاج: "+_production);
        Console.WriteLine("المخالفات الإنتاجية: "+_productionDifferent);
        Console.WriteLine("المطابقات الإنتاجية: "+_productionSame);
        Console.WriteLine("شواهد الإجابة الأولى: "+_correctStreams);
        Console.WriteLine("قراءات الواجهة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_pass);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        var pass=_unexpected==0 && _controls==34560 && _controlsEqual==34560 &&
            _witnesses==8640 && _witnessDifferent==8640 &&
            _sauces==8 && _production==16 && _productionDifferent==8 &&
            _productionSame==8 && _correctStreams==16 && _publicReads==8;
        if(verify)
        {
            Console.WriteLine("تحقق الأحمر التاريخي لرفض التساوي: "+(pass?"PASS":"FAIL"));
            return pass?0:1;
        }
        return _unexpected==0 && _witnessDifferent==0?0:1;
    }
}
