using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage41Tests;

internal static class Program
{
    private static int passed,failed,controls,rejections,oldDifferences,production,productionCorrect,productionOldDifferences,realRejections,publicReads;
    private static readonly List<MonsterContext> Contexts=new();
    private static void Check(bool ok,string message)
    {
        if(ok){passed++;return;}
        failed++;
        Console.WriteLine("إخفاق في الرقعة العشرين: "+message);
    }
    private static BigInteger M=>NormativeScroll.M;
    private static BigInteger HighWeight(BigInteger n)
    {
        var space=M;var weight=BigInteger.One;
        while(space<n){weight=space;space*=M;}
        return weight;
    }
    private static BigInteger Historical(BigInteger rank,BigInteger n)
        => BigInteger.One+(rank-BigInteger.One+HighWeight(n))%n;
    private static BigInteger Wide(AnswerStream stream)
        => stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*M;

    private static void Synthetic()
    {
        var patch=new UpperPlaceBiasPatchWrapper();
        var prior=new WideDigitOrderPatchWrapper();
        var old=new LegacyUpperPlaceBias();
        var sizes=new[]{M+1,2*M+1,M*M-1,M*M+1};
        for(var rank=1;rank<=720;rank++)
        for(var id=1;id<=6;id++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+id);
            var stream=new AnswerStream(first,direction);
            var source=new LegacyBowlQuestionResult(first,direction);
            foreach(var n in sizes)
            {
                controls++;
                var expected=NormativeScroll.ChooseRankWide(stream,n);
                var earlier=prior.Patch(source,n);
                var scar=old.Shift(earlier,n);
                var repaired=patch.RotateBack(scar,n);
                if(scar!=expected)oldDifferences++;
                Check(earlier==expected && repaired==expected &&
                      scar==Historical(expected,n) && scar!=expected &&
                      repaired>=1 && repaired<=n,
                      "حالة ضابطة مستقلة "+rank+"/"+id+"/"+direction);
            }
            var rejectedStream=new AnswerStream(M-1-first,direction);
            var rejectedSource=new LegacyBowlQuestionResult(M-1-first,direction);
            var nReject=Wide(rejectedStream)-1;
            var expectedRejected=direction==1?BigInteger.One:nReject;
            var earlierRejected=prior.Patch(rejectedSource,nReject);
            var scarRejected=old.Shift(earlierRejected,nReject);
            var repairedRejected=patch.RotateBack(scarRejected,nReject);
            rejections++;
            if(scarRejected!=expectedRejected)oldDifferences++;
            Check(nReject>M*M/2 && nReject<M*M &&
                  earlierRejected==expectedRejected &&
                  repairedRejected==expectedRejected &&
                  scarRejected==Historical(expectedRejected,nReject) &&
                  scarRejected!=expectedRejected,
                  "رفض من اتجاهين مع حفظ الانحياز");
        }
        Check(controls==34560 && rejections==8640 && oldDifferences==43200,
              "توقيع 43200 شاهداً محفوظاً وتصحيحها جميعاً");
    }

    private static void Boundaries()
    {
        var patch=new UpperPlaceBiasPatchWrapper();
        var old=new LegacyUpperPlaceBias();
        foreach(var n in new[]{M+1,M*M-1,M*M+1,(BigInteger.One<<8192)+M*M+1})
        foreach(var rank in new[]{BigInteger.One,new BigInteger(2),n-1,n})
        {
            var scar=old.Shift(rank,n);
            Check(patch.RotateBack(scar,n)==rank &&
                  scar==Historical(rank,n) && scar!=rank,
                  "حدّ الأسرة ورتبة البدء والنهاية");
        }
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            var denied=false;
            try{patch.RotateBack(1,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض حجم غير واسع");
        }
        foreach(var rank in new[]{BigInteger.Zero,new BigInteger(-1),M+2})
        {
            var denied=false;
            try{patch.RotateBack(rank,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض رتبة خارج النطاق");
        }
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        var sauce=NormativeScroll.Sauce(c,t);
        var manager=new MonsterManager();
        for(var id=1;id<=6;id++)
        for(var sealIndex=0;sealIndex<2;sealIndex++)
        {
            var seal=sealIndex==0?21:31;
            var stream=NormativeScroll.AskBowl(sauce,id,seal);
            var wide=Wide(stream);
            var reject=stream.DirectionStep==-1 && wide>M*M/2+1 && wide<M*M;
            var n=reject?wide-1:M+1;
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            var context=manager.ExecutePatchedUpperPlaceBias(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            production++;
            if(reject)realRejections++;
            if(context.PatchedUpperPlaceBiasRankResult==expected)productionCorrect++;
            if(context.LegacyUpperPlaceBiasRankResult!=expected)productionOldDifferences++;
            Check(context.Status=="PATCHED_UPPER_PLACE_BIAS_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.Count==19 &&
                  context.BranchTrace[^2]=="LEGACY_UPPER_PLACE_BIAS" &&
                  context.BranchTrace[^1]=="PATCHED_UPPER_PLACE_BIAS" &&
                  context.Metrics["legacy.upper.place.bias.dispatch"]==1 &&
                  context.Metrics["patched.upper.place.bias.dispatch"]==1 &&
                  context.Metrics["patched.double.offset.wide.rank.dispatch"]==1,
                  "سلسلة الالتزام الكاملة للرقعة العشرين");
            Check(context.PatchedUpperPlaceBiasRankResult==expected &&
                  context.PatchedDoubleOffsetWideRankResult==expected &&
                  context.LegacyUpperPlaceBiasRankResult==Historical(expected,n) &&
                  context.LegacyUpperPlaceBiasRankResult!=expected &&
                  context.LegacyWideFamilySize==n &&
                  context.PatchedBowlQuestionResult is not null &&
                  context.PatchedBowlQuestionResult.First==stream.First &&
                  context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
                  context.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(context.LegacySauceFinalBowls,context.PatchedSauceFinalBowls),
                  "تكافؤ المرجع مع احتفاظ جميع الشواهد والصلصة");
        }
        publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var publicStream=NormativeScroll.AskBowl(sauce,publicId,publicSeal);
        var good=CalendarDateSpaghetti.EvaluateUpperPlaceBias(
            c,t,publicId,publicSeal,M+1);
        var old=CalendarDateSpaghetti.EvaluateLegacyUpperPlaceBias(
            c,t,publicId,publicSeal,M+1);
        Check(good==NormativeScroll.ChooseRankWide(publicStream,M+1) &&
              old==Historical(good,M+1) && good!=old,
              "استقلال الواجهة العامة");
    }

    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];var b=Contexts[1];
        var prior=b.PatchedUpperPlaceBiasRankResult;
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        Check(!ReferenceEquals(a,b) && !ReferenceEquals(a.Metrics,b.Metrics) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              b.PatchedSauceFinalBowls.SequenceEqual(saved) &&
              b.PatchedUpperPlaceBiasRankResult==prior,
              "ملكية السياق وعدم التلوث");
        var dispatcher=new MonsterDispatcher(new MonsterValidationManager(),
                                             new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var denied=false;
        try{dispatcher.DispatchPatchedUpperPlaceBias(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.PatchedUpperPlaceBiasRankResult==prior &&
              b.Metrics["patched.upper.place.bias.dispatch"]==1,
              "رفض إعادة الالتزام دون آثار جانبية");

        var f=NormativeScroll.FoundationDay;
        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=M*M-1;
        var candidate=new PatchedUpperPlaceBiasPhaseHandler().Handle(ready);
        var validation=new MonsterValidationManager();
        validation.ValidatePatchedUpperPlaceBias(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedUpperPlaceBiasRankResult is null &&
              ready.LegacyUpperPlaceBiasRankResult is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "المدقق لا يلتزم قبل موافقة جميع المرشحين");
        void Reject(PatchedUpperPlaceBiasCandidate forged,string reason)
        {
            var refused=false;
            try{validation.ValidatePatchedUpperPlaceBias(ready,forged);}
            catch(MonsterValidationException){refused=true;}
            Check(refused && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedUpperPlaceBiasRankResult is null &&
                  ready.LegacyUpperPlaceBiasRankResult is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض التزوير قبل الالتزام "+reason);
        }
        Reject(candidate with {Rank=0},"رتبة صفر");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير الإصلاح");
        Reject(candidate with {Historical=candidate.Historical with {Rank=0}},
               "تحريف الشاهد العشرين");
        Reject(candidate with {Historical=candidate.Historical with {
            Previous=candidate.Historical.Previous with {Rank=0}}},
               "تحريف الرقعة التاسعة عشرة");

        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedUpperPlaceBias(f,f,1,21,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"حجم عائلة غير قانوني");
        }
        foreach(var id in new[]{0,-1,7})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedUpperPlaceBias(f,f,id,21,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رقم وعاء غير قانوني");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedUpperPlaceBias(f,f,1,seal,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"حاتم غير قانوني");
        }
    }

    public static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        Synthetic();
        Boundaries();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var dates=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<dates.Length;i++)Production(dates[i].C,dates[i].T,i+1);
        ValidationAndOwnership();
        Console.WriteLine("الحالات الضابطة: "+controls);
        Console.WriteLine("شواهد الرفض: "+rejections);
        Console.WriteLine("الاختلافات التاريخية المحفوظة: "+oldDifferences);
        Console.WriteLine("قراءات الإنتاج: "+production);
        Console.WriteLine("النتائج المصححة: "+productionCorrect);
        Console.WriteLine("الاختلافات التاريخية في الإنتاج: "+productionOldDifferences);
        Console.WriteLine("رفض الإنتاج: "+realRejections);
        Console.WriteLine("قراءات الواجهة: "+publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+failed);
        return failed==0 && controls==34560 && rejections==8640 &&
               oldDifferences==43200 && production==96 &&
               productionCorrect==96 && productionOldDifferences==96 &&
               realRejections==28 && publicReads==8 ? 0:1;
    }
}
