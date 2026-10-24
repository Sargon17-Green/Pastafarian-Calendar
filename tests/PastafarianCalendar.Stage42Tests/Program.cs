using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage42Tests;
internal static class Program
{
    private static int pass,unexpected,controls,controlDifferent,controlEqual;
    private static int rejections,rejectionDifferent,ascendingEqual,descendingDifferent;
    private static int production,productionGood,productionDifferent,productionEqual,realRejections,publicReads;
    private static readonly List<MonsterContext> Contexts=new();

    private static BigInteger M=>NormativeScroll.M;
    private static BigInteger Wide(AnswerStream s)
        => s.First+(NormativeScroll.AnswerAt(s,BigInteger.One)-1)*M;
    private static BigInteger Old(BigInteger r)
        => BigInteger.One+(r-BigInteger.One)%M;
    private static void Check(bool ok,string message)
    {
        if(ok){pass++;return;}
        unexpected++;
        Console.WriteLine("مخالفة غير متوقعة: "+message);
    }

    private static void Synthetic()
    {
        var prior=new WideDigitOrderPatchWrapper();
        var old=new LegacyWideSlotTruncation();
        var sizes=new[]{M+1,2*M+1,M*M-1,M*M+1};
        for(var rank=1;rank<=720;rank++)
        for(var id=1;id<=6;id++)
        foreach(var dir in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+id);
            var stream=new AnswerStream(first,dir);
            var source=new LegacyBowlQuestionResult(first,dir);
            foreach(var n in sizes)
            {
                controls++;
                var correct=NormativeScroll.ChooseRankWide(stream,n);
                var fixedRank=prior.Patch(source,n);
                var truncated=old.Fold(fixedRank,n);
                if(truncated!=correct)controlDifferent++;
                else controlEqual++;
                Check(fixedRank==correct && truncated==Old(correct) &&
                      truncated>=1 && truncated<=M &&
                      (correct<=M?truncated==correct:truncated!=correct),
                      "نتيجة التحكم لا تعكس عيباً في الرتبة المعتمدة");
            }
            var high=M-1-first;
            var rejected=new AnswerStream(high,dir);
            var nReject=Wide(rejected)-1;
            var correctRejected=dir==1?BigInteger.One:nReject;
            var fixedRejected=prior.Patch(new LegacyBowlQuestionResult(high,dir),nReject);
            var oldRejected=old.Fold(fixedRejected,nReject);
            rejections++;
            if(oldRejected!=correctRejected)rejectionDifferent++;
            if(dir==1 && oldRejected==correctRejected)ascendingEqual++;
            if(dir==-1 && oldRejected!=correctRejected)descendingDifferent++;
            Check(nReject>M*M/2 && nReject<M*M &&
                  fixedRejected==correctRejected &&
                  oldRejected==Old(correctRejected) &&
                  (dir==1?oldRejected==1:oldRejected<correctRejected),
                  "شاهد رفض لا يغير اتجاه القبول");
        }
        Check(controls==34560 && controlDifferent==25920 &&
              controlEqual==8640 && rejections==8640 &&
              rejectionDifferent==4320 && ascendingEqual==4320 &&
              descendingDifferent==4320,
              "توقيع مستقل لعطب إسقاط الخانات العليا");
    }

    private static void Boundaries()
    {
        var old=new LegacyWideSlotTruncation();
        foreach(var n in new[]{M+1,M*M-1,M*M+1,(BigInteger.One<<8192)+M*M+1})
        foreach(var r in new[]{BigInteger.One,new BigInteger(2),M,M+1,n-1,n})
        {
            var value=old.Fold(r,n);
            Check(value==Old(r) && value>=1 && value<=M &&
                  (r<=M?value==r:value!=r),
                  "حالة حدية بعرض كبير ودون قطع خفي");
        }
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            var denied=false;
            try{old.Fold(1,n);}catch(MonsterValidationException){denied=true;}
            Check(denied,"أسرة غير واسعة");
        }
        foreach(var r in new[]{BigInteger.Zero,new BigInteger(-1),M+2})
        {
            var denied=false;
            try{old.Fold(r,M+1);}catch(MonsterValidationException){denied=true;}
            Check(denied,"رتبة خارج المجال");
        }
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        var sauce=NormativeScroll.Sauce(c,t);
        var manager=new MonsterManager();
        for(var id=1;id<=6;id++)
        for(var j=0;j<2;j++)
        {
            var seal=j==0?21:31;
            var stream=NormativeScroll.AskBowl(sauce,id,seal);
            var wide=Wide(stream);
            var reject=stream.DirectionStep==-1 && wide>M*M/2+1 && wide<M*M;
            var n=reject?wide-1:M+1;
            var correct=NormativeScroll.ChooseRankWide(stream,n);
            var ctx=manager.ExecuteLegacyWideSlotTruncation(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(ctx);
            production++;
            if(reject)realRejections++;
            if(ctx.PatchedUpperPlaceBiasRankResult==correct)productionGood++;
            if(ctx.LegacyWideSlotTruncationRankResult!=correct)productionDifferent++;
            else productionEqual++;
            Check(ctx.Status=="LEGACY_WIDE_SLOT_TRUNCATION_COMPLETE" &&
                  ctx.Phase==ctx.Status && ctx.BranchTrace.Count==20 &&
                  ctx.BranchTrace[^2]=="PATCHED_UPPER_PLACE_BIAS" &&
                  ctx.BranchTrace[^1]=="LEGACY_WIDE_SLOT_TRUNCATION" &&
                  ctx.Metrics["legacy.wide.slot.truncation.dispatch"]==1 &&
                  ctx.Metrics["patched.upper.place.bias.dispatch"]==1,
                  "سلسلة الاكتشاف المستقلة");
            Check(ctx.PatchedUpperPlaceBiasRankResult==correct &&
                  ctx.PatchedDoubleOffsetWideRankResult==correct &&
                  ctx.LegacyWideSlotTruncationRankResult==Old(correct) &&
                  ctx.LegacyWideSlotTruncationRankResult>=1 &&
                  ctx.LegacyWideSlotTruncationRankResult<=M &&
                  ctx.PatchedBowlQuestionResult is not null &&
                  ctx.PatchedBowlQuestionResult.First==stream.First &&
                  ctx.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  ctx.PatchedSauceFinalBowls is {Length:7} &&
                  ctx.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  ctx.PatchedOrderAt46Latch is {Length:6} &&
                  ctx.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46),
                  "الحفاظ على الرتبة والصلصة والسؤال");
        }
        publicReads++;
        var idPublic=sample%6+1;
        var sealPublic=sample%2==0?31:21;
        var streamPublic=NormativeScroll.AskBowl(sauce,idPublic,sealPublic);
        var nPublic=M*M-1;
        var good=CalendarDateSpaghetti.EvaluateUpperPlaceBias(c,t,idPublic,sealPublic,nPublic);
        var old=CalendarDateSpaghetti.EvaluateLegacyWideSlotTruncation(c,t,idPublic,sealPublic,nPublic);
        Check(good==NormativeScroll.ChooseRankWide(streamPublic,nPublic) &&
              old==Old(good) && old>=1 && old<=M,
              "واجهة الإنتاج قبل القطع وبعده");
    }

    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];var b=Contexts[1];
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var rank=b.LegacyWideSlotTruncationRankResult;
        var trace=b.BranchTrace.ToArray();
        a.PatchedSauceFinalBowls![1]=0;
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              !ReferenceEquals(a.Metrics,b.Metrics) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              b.PatchedSauceFinalBowls.SequenceEqual(saved) &&
              b.LegacyWideSlotTruncationRankResult==rank,
              "عدم تلوث سياق بسياق آخر");
        var dispatch=new MonsterDispatcher(new MonsterValidationManager(),
                                           new MonsterMetricsManager());
        var denied=false;
        try{dispatch.DispatchLegacyWideSlotTruncation(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyWideSlotTruncationRankResult==rank,
              "رفض التزام مكرر دون تغيّر");
        var f=NormativeScroll.FoundationDay;
        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;ready.LegacyWideFamilySize=M*M-1;
        var candidate=new LegacyWideSlotTruncationPhaseHandler().Handle(ready);
        var validation=new MonsterValidationManager();
        validation.ValidateLegacyWideSlotTruncation(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyWideSlotTruncationRankResult is null &&
              ready.PatchedUpperPlaceBiasRankResult is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "المدقق يعمل قبل كتابة النتائج");
        void Reject(LegacyWideSlotTruncationCandidate forged,string why)
        {
            var refused=false;
            try{validation.ValidateLegacyWideSlotTruncation(ready,forged);}
            catch(MonsterValidationException){refused=true;}
            Check(refused && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyWideSlotTruncationRankResult is null &&
                  ready.PatchedUpperPlaceBiasRankResult is null,
                  "رفض تزوير شاهد القطع "+why);
        }
        Reject(candidate with {Rank=0},"الصفر");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير الناتج");
        Reject(candidate with {Previous=candidate.Previous with {Rank=0}},
               "تغيير الرقعة العشرين");
        Reject(candidate with {Previous=candidate.Previous with {
            Historical=candidate.Previous.Historical with {Rank=0}}},
               "تغيير الشاهد العشرين");
        var unprepared=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=M+1};
        denied=false;
        try{dispatch.DispatchLegacyWideSlotTruncation(unprepared);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && unprepared.Status=="NEW" && unprepared.BranchTrace.Count==0,
              "رفض سياق غير مؤسس");
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyWideSlotTruncation(f,f,1,21,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض عائلة غير واسعة");
        }
        foreach(var id in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyWideSlotTruncation(f,f,id,21,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض وعاء غير قانوني");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyWideSlotTruncation(f,f,1,seal,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض حاتم غير قانوني");
        }
    }

    public static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verify=args.Length==1 && args[0]=="--verify-expected-red";
        if(args.Length!=0 && !verify)return 2;
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
        Console.WriteLine("حالات التحكم: "+controls);
        Console.WriteLine("اختلافات التحكم: "+controlDifferent);
        Console.WriteLine("مطابقات الرتب الصغيرة: "+controlEqual);
        Console.WriteLine("حالات الرفض: "+rejections);
        Console.WriteLine("اختلافات الرفض: "+rejectionDifferent);
        Console.WriteLine("قراءات الإنتاج: "+production);
        Console.WriteLine("الإنتاج المعياري الصحيح: "+productionGood);
        Console.WriteLine("اختلافات الإنتاج التاريخية: "+productionDifferent);
        Console.WriteLine("مطابقات الإنتاج التاريخية: "+productionEqual);
        Console.WriteLine("حالات الرفض الإنتاجية: "+realRejections);
        Console.WriteLine("التأكيدات الناجحة: "+pass);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+unexpected);
        var ok=unexpected==0 && controls==34560 && controlDifferent==25920 &&
               controlEqual==8640 && rejections==8640 && rejectionDifferent==4320 &&
               ascendingEqual==4320 && descendingDifferent==4320 &&
               production==96 && productionGood==96 &&
               productionDifferent>=28 && productionEqual>=1 &&
               productionDifferent+productionEqual==96 &&
               realRejections==28 && publicReads==8;
        if(verify)
        {
            Console.WriteLine("التحقق من الأحمر المقصود لقطع الرتبة: "+(ok?"PASS":"FAIL"));
            return ok?0:1;
        }
        return unexpected==0 && controlDifferent==0 &&
               rejectionDifferent==0 && productionDifferent==0?0:1;
    }
}
