using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage35Tests;

internal static partial class Program
{
    private static int _passed,_failed,_controls,_controlCorrect,_controlHistoricMatches;
    private static int _witnesses,_witnessCorrect,_witnessHistoricDifferent;
    private static int _sauces,_production,_productionCorrect,_productionOldDifferent,_productionOldSame;
    private static int _publicReads,_correctStreams;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string description)
    {
        if(ok){_passed++;return;}
        _failed++;
        Console.WriteLine("إخفاق غير متوقع في رقعة الحدّ السابعة عشرة: "+description);
    }

    private static BigInteger[] ControlSizes()
    {
        var m=NormativeScroll.M;
        return new BigInteger[]{m+1,2*m+1,m*m-1,m*m+1};
    }

    private static BigInteger InitialWide(AnswerStream stream)
        => stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*NormativeScroll.M;

    private static void Synthetic()
    {
        var legacy=new LegacyInclusiveWideLimit();
        var previous=new WideDigitOrderPatchWrapper();
        var patch=new InclusiveWideLimitPatchWrapper();
        var m=NormativeScroll.M;
        foreach(var rank in Enumerable.Range(1,720))
        for(var id=1;id<=6;id++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+id);
            var stream=new AnswerStream(first,direction);
            var production=new LegacyBowlQuestionResult(first,direction);
            foreach(var n in ControlSizes())
            {
                _controls++;
                var expected=NormativeScroll.ChooseRankWide(stream,n);
                var before=previous.Patch(production,n);
                var historic=legacy.Choose(production,n);
                // التمرين على الغلاف الحقيقي: مرشح تاريخي من طبقة السؤال الناجحة.
                // اختبارات الإنتاج أدناه تستدعي الغلاف نفسه عبر المعالج والموزع.
                var boundary=BigInteger.Pow(m, n>m*m ? 3 : 2);
                var limit=boundary/n*n;
                var initial=first+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*m;
                Check(patch.Accepts(initial,n,boundary)==(initial<=limit),
                      "مقارنة الحد الصحيحة في الضوابط");
                Check(before==expected && historic==expected,
                      "شاهد الضبط لا يتغير حين يكون دون الحد");
                if(before==expected)_controlCorrect++;
                if(historic==expected)_controlHistoricMatches++;
            }

            var boundaryStream=new AnswerStream(m-1-first,direction);
            var actualStream=new LegacyBowlQuestionResult(boundaryStream.First,direction);
            var nLimit=InitialWide(boundaryStream);
            _witnesses++;
            Check(nLimit>m*m/2 && nLimit<m*m,
                  "الحد المحدّد يساوي الإجابة الأولى المركبة");
            var patched=previous.Patch(actualStream,nLimit);
            var expectedLimit=NormativeScroll.ChooseRankWide(boundaryStream,nLimit);
            var historicLimit=legacy.Choose(actualStream,nLimit);
            if(patched==expectedLimit)_witnessCorrect++;
            if(historicLimit!=expectedLimit)_witnessHistoricDifferent++;
            Check(patch.Accepts(nLimit-1,nLimit,m*m) &&
                  patch.Accepts(nLimit,nLimit,m*m) &&
                  !patch.Accepts(nLimit+1,nLimit,m*m),
                  "المقبول أقل من الحد ومساو له، والمرفوض أكبر");
            Check(patched==nLimit && patched==expectedLimit &&
                  historicLimit!=expectedLimit &&
                  historicLimit==(direction==1?BigInteger.One:nLimit-1),
                  "الرقعة تحفظ مساواة الحد وتُبقي رفض القديم منفصلاً");
        }
        Check(_controls==34560 && _controlCorrect==34560 &&
              _controlHistoricMatches==34560 && _witnesses==8640 &&
              _witnessCorrect==8640 && _witnessHistoricDifferent==8640,
              "توقيع جميع الرتب والحالات العادية والحدود الحقيقية");
    }

    private static void Boundaries()
    {
        var m=NormativeScroll.M;
        var patch=new InclusiveWideLimitPatchWrapper();
        var old=new LegacyInclusiveWideLimit();
        var correct=new WideDigitOrderPatchWrapper();
        foreach(var first in new BigInteger[]{1,2,m/2,m-2,m-1,m})
        foreach(var direction in new[]{-1,1})
        foreach(var n in ControlSizes())
        {
            var stream=new AnswerStream(first,direction);
            var source=new LegacyBowlQuestionResult(first,direction);
            // (M-2,+1,M²+1) يبدأ داخل ذيل رفض طوله ~M جواباً.
            // المرجع التكراري هناك غير عملي؛ جواب ما بعد الالتفاف هو 1 بالضبط.
            var reference=first==m-2 && direction==1 && n==m*m+1
                ? BigInteger.One
                : NormativeScroll.ChooseRankWide(stream,n);
            Check(correct.Patch(source,n)==reference,
                  "تطابق قاعدة القبول عند الحدود والالتفاف الحسابي دون انتظار فلكي");
            Check(old.Choose(source,n)>=1 && old.Choose(source,n)<=n,
                  "مدى النتيجة القديمة القانونية محفوظ");
        }

        // حجم عائلة من آلاف البتات: بداية مقبولة دون اجتياز مرجع تكراري فلكي.
        var huge=(BigInteger.One<<8192)+m*m+1;
        var streamHuge=new AnswerStream(BigInteger.One,1);
        Check(correct.Patch(new LegacyBowlQuestionResult(1,1),huge)==
              NormativeScroll.ChooseRankWide(streamHuge,huge),
              "عائلة واسعة بثمانية آلاف بت على التيار الحقيقي");
        var space=m;
        while(space<huge)space*=m;
        var acceptLimit=space/huge*huge;
        Check(patch.Accepts(acceptLimit,huge,space) &&
              !patch.Accepts(acceptLimit+1,huge,space),
              "قبول المساواة في فضاء كبير دون تجاوز");
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        _sauces++;
        var reference=NormativeScroll.Sauce(c,t);
        var manager=new MonsterManager();
        var m=NormativeScroll.M;
        var found=false;
        for(var id=1;id<=6 && !found;id++)
        for(var sealIndex=0;sealIndex<2 && !found;sealIndex++)
        {
            var seal=sealIndex==0?21:31;
            var stream=NormativeScroll.AskBowl(reference,id,seal);
            var n=InitialWide(stream);
            if(n<=m*m/2 || n>=m*m)continue;
            found=true;
            var context=manager.ExecutePatchedInclusiveWideLimit(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            _production++;
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            if(context.PatchedInclusiveWideLimitRankResult==expected)_productionCorrect++;
            if(context.LegacyInclusiveWideLimitRankResult!=expected)_productionOldDifferent++;
            Check(expected==n && context.PatchedInclusiveWideLimitRankResult==expected &&
                  context.LegacyInclusiveWideLimitRankResult!=expected &&
                  context.LegacyInclusiveWideLimitRankResult==
                      (stream.DirectionStep==1?BigInteger.One:n-1),
                  "إنتاج بقيمة مساوية لحدّ القبول "+sample);
            Check(context.PatchedWideRankResult==expected &&
                  context.PatchedAnswerAtResult==stream.First,
                  "بقاء الرقعة السادسة عشرة وتصحيح k=0 "+sample);
            VerifyContext(context,reference,id,n,sample);
        }
        Check(found,"تغطية شاهد إنتاجي عند حدّ القبول "+sample);

        var ctrlId=sample%6+1;
        var ctrlSeal=sample%2==0?31:21;
        var ctrlN=m+1;
        var ctrlStream=NormativeScroll.AskBowl(reference,ctrlId,ctrlSeal);
        var ctrl=manager.ExecutePatchedInclusiveWideLimit(c,t,ctrlId,ctrlSeal,ctrlN);
        _production++;
        var ctrlExpected=NormativeScroll.ChooseRankWide(ctrlStream,ctrlN);
        if(ctrl.PatchedInclusiveWideLimitRankResult==ctrlExpected)_productionCorrect++;
        if(ctrl.LegacyInclusiveWideLimitRankResult==ctrlExpected)_productionOldSame++;
        Check(ctrl.PatchedInclusiveWideLimitRankResult==ctrlExpected &&
              ctrl.LegacyInclusiveWideLimitRankResult==ctrlExpected,
              "التحكم الإنتاجي دون تغيير في الحالات غير الحدية "+sample);
        VerifyContext(ctrl,reference,ctrlId,ctrlN,sample+100);

        _publicReads++;
        var api=CalendarDateSpaghetti.EvaluateInclusiveWideLimit(
            c,t,ctrlId,ctrlSeal,ctrlN);
        var oldApi=CalendarDateSpaghetti.EvaluateLegacyInclusiveWideLimit(
            c,t,ctrlId,ctrlSeal,ctrlN);
        Check(api==ctrlExpected && oldApi==ctrlExpected,
              "الواجهة العامة المصححة والشاهد القديم مستقلان "+sample);
    }

    private static void VerifyContext(MonsterContext context,SauceResult refSauce,
                                      int id,BigInteger n,int caseId)
    {
        var next=NormativeScroll.NextBowlInDrop46Order(refSauce,id);
        Check(context.Status=="PATCHED_INCLUSIVE_WIDE_LIMIT_COMPLETE" &&
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
                  "PATCHED_INCLUSIVE_WIDE_LIMIT"}) &&
              context.Metrics["legacy.inclusive.wide.limit.witness"]==1 &&
              context.Metrics["patched.inclusive.wide.limit.dispatch"]==1,
              "تسلسل التحقق والقياسات والتثبيت "+caseId);
        Check(context.PatchedSauceFinalBowls is {Length:7} &&
              context.PatchedSauceFinalBowls.SequenceEqual(refSauce.Bowls) &&
              context.PatchedOrderAt46Latch is {Length:6} &&
              context.PatchedOrderAt46Latch.SequenceEqual(refSauce.OrderAtDrop46) &&
              context.LegacySauceFinalBowls is {Length:7} &&
              !ReferenceEquals(context.PatchedSauceFinalBowls,
                               context.LegacySauceFinalBowls) &&
              context.PatchedNextBowlResult==next &&
              context.LegacyFixedNextBowlResult==id%6+1 &&
              context.LegacyWideFamilySize==n,
              "سلامة الصلصة وترتيب القطرة والجار "+caseId);
        Check(context.PatchedInclusiveWideLimitRankResult is BigInteger x &&
              x>=1 && x<=n &&
              context.LegacyInclusiveWideLimitRankResult is BigInteger y &&
              y>=1 && y<=n &&
              context.PatchedBowlQuestionResult is not null &&
              context.PatchedAnswerAtResult==context.PatchedBowlQuestionResult.First &&
              context.LegacyOneBasedAnswerAtResult.HasValue,
              "سلامة المرتبتين والجواب المختوم والخطوة الصفرية "+caseId);
        if(context.PatchedBowlQuestionResult is not null &&
           context.PatchedAnswerAtResult==context.PatchedBowlQuestionResult.First)
            _correctStreams++;
    }

    private static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        Synthetic();
        Boundaries();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var samples=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<samples.Length;i++)Production(samples[i].C,samples[i].T,i+1);
        ValidationAndOwnership();

        Console.WriteLine("الضوابط التركيبية: "+_controls);
        Console.WriteLine("المطابقات المصححة للضوابط: "+_controlCorrect);
        Console.WriteLine("المطابقات التاريخية للضوابط: "+_controlHistoricMatches);
        Console.WriteLine("شواهد المساواة: "+_witnesses);
        Console.WriteLine("الشواهد المصححة: "+_witnessCorrect);
        Console.WriteLine("المخالفات التاريخية عند الحد: "+_witnessHistoricDifferent);
        Console.WriteLine("الصلصات الحقيقية: "+_sauces);
        Console.WriteLine("القراءات الإنتاجية: "+_production);
        Console.WriteLine("القراءات المصححة: "+_productionCorrect);
        Console.WriteLine("مخالفات التاريخ في الإنتاج: "+_productionOldDifferent);
        Console.WriteLine("مطابقات التاريخ في الإنتاج: "+_productionOldSame);
        Console.WriteLine("شهود الجواب الأول: "+_correctStreams);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_failed);
        return _failed==0 && _controls==34560 && _controlCorrect==34560 &&
            _controlHistoricMatches==34560 && _witnesses==8640 &&
            _witnessCorrect==8640 && _witnessHistoricDifferent==8640 &&
            _sauces==8 && _production==16 && _productionCorrect==16 &&
            _productionOldDifferent==8 && _productionOldSame==8 &&
            _correctStreams==16 && _publicReads==8 ? 0:1;
    }
}
