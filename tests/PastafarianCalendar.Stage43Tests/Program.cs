using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage43Tests;

internal static class Program
{
    private static int _passed,_unexpected,_controls,_controlsRepaired,_controlDifferences;
    private static int _rejections,_rejectionsRepaired,_rejectionDifferences;
    private static int _production,_productionRepaired,_productionDifferences,_productionEqual;
    private static int _realRejections,_publicReads;
    private static readonly List<MonsterContext> Contexts=new();

    private static BigInteger M=>NormativeScroll.M;
    private static void Check(bool ok,string why)
    {
        if(ok){_passed++;return;}
        _unexpected++;
        Console.WriteLine("إخفاق غير متوقع في الرقعة الحادية والعشرين: "+why);
    }
    private static BigInteger Old(BigInteger rank)
        => BigInteger.One+(rank-BigInteger.One)%M;
    private static BigInteger Wide(AnswerStream stream)
        => stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*M;

    private static void Synthetic()
    {
        var old=new LegacyWideSlotTruncation();
        var patch=new WideSlotTruncationPatchWrapper();
        var previous=new WideDigitOrderPatchWrapper();
        var sizes=new[]{M+1,2*M+1,M*M-1,M*M+1};
        for(var rank=1;rank<=720;rank++)
        for(var id=1;id<=6;id++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+id);
            var stream=new AnswerStream(first,direction);
            var source=new LegacyBowlQuestionResult(first,direction);
            foreach(var size in sizes)
            {
                _controls++;
                var expected=NormativeScroll.ChooseRankWide(stream,size);
                var prior=previous.Patch(source,size);
                var scar=old.Fold(prior,size);
                var fixedRank=patch.Restore(scar,prior,size);
                if(fixedRank==expected)_controlsRepaired++;
                if(scar!=expected)_controlDifferences++;
                Check(prior==expected && fixedRank==expected &&
                      scar==Old(expected) && scar>=1 && scar<=M,
                      "رتبة واسعة قبل التخزين وبعده "+rank+"/"+id+"/"+direction);
            }

            // تُستنتج قفزة الرفض المغلقة دون تدوير مرجع تكراري لعدد هائل.
            var high=M-1-first;
            var rejected=new AnswerStream(high,direction);
            var sizeRejected=Wide(rejected)-1;
            var expectedRejected=direction==1?BigInteger.One:sizeRejected;
            var priorRejected=previous.Patch(
                new LegacyBowlQuestionResult(high,direction),sizeRejected);
            var oldRejected=old.Fold(priorRejected,sizeRejected);
            var repairedRejected=patch.Restore(oldRejected,priorRejected,sizeRejected);
            _rejections++;
            if(repairedRejected==expectedRejected)_rejectionsRepaired++;
            if(oldRejected!=expectedRejected)_rejectionDifferences++;
            Check(sizeRejected>M*M/2 && sizeRejected<M*M &&
                  priorRejected==expectedRejected &&
                  repairedRejected==expectedRejected &&
                  oldRejected==Old(expectedRejected) &&
                  (direction==1?oldRejected==BigInteger.One:
                                oldRejected<expectedRejected),
                  "قفزة الرفض الصحيحة رغم شاهد القطع");
        }
        Check(_controls==34560 && _controlsRepaired==34560 &&
              _controlDifferences==25920 &&
              _rejections==8640 && _rejectionsRepaired==8640 &&
              _rejectionDifferences==4320,
              "الإصلاح يعيد كل الرتب ويحفظ 30240 اختلافاً تاريخياً");
    }

    private static void Boundaries()
    {
        var old=new LegacyWideSlotTruncation();
        var patch=new WideSlotTruncationPatchWrapper();
        foreach(var n in new[]{M+1,M*M-1,M*M+1,(BigInteger.One<<8192)+M*M+1})
        foreach(var rank in new[]{BigInteger.One,new BigInteger(2),M,M+1,n-1,n})
        {
            var scar=old.Fold(rank,n);
            var fixedRank=patch.Restore(scar,rank,n);
            Check(scar==Old(rank) && fixedRank==rank &&
                  fixedRank>=1 && fixedRank<=n &&
                  (rank<=M?scar==rank:scar!=rank),
                  "حدود الرتب والأسرة بعرض 8192 بت");
        }

        // شاهد واحد لا يحدد رتبته الأصلية، وإصلاحنا يحتاج المرشح السابق.
        var wideSize=M*M-1;
        Check(old.Fold(1,wideSize)==old.Fold(M+1,wideSize) &&
              patch.Restore(1,1,wideSize)==1 &&
              patch.Restore(1,M+1,wideSize)==M+1,
              "إثبات عدم قابلية عكس القطع وحده");
        foreach(var args in new (BigInteger Old,BigInteger Prior,BigInteger N)[]{
            (0,1,M+1), (M+1,1,M+1), (1,0,M+1),
            (1,M+2,M+1), (1,1,M), (2,1,M+1),
            (1,1,0), (1,1,-1)
        })
        {
            var denied=false;
            try{patch.Restore(args.Old,args.Prior,args.N);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض مدخل الاسترجاع المزور أو غير القانوني");
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
            var reject=stream.DirectionStep==-1 &&
                       wide>M*M/2+1 && wide<M*M;
            var n=reject?wide-1:M+1;
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            var context=manager.ExecutePatchedWideSlotTruncation(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            _production++;
            if(reject)_realRejections++;
            if(context.PatchedWideSlotTruncationRankResult==expected)_productionRepaired++;
            if(context.LegacyWideSlotTruncationRankResult!=expected)_productionDifferences++;
            else _productionEqual++;
            Check(context.Status=="PATCHED_WIDE_SLOT_TRUNCATION_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.Count==21 &&
                  context.BranchTrace[^2]=="LEGACY_WIDE_SLOT_TRUNCATION" &&
                  context.BranchTrace[^1]=="PATCHED_WIDE_SLOT_TRUNCATION" &&
                  context.Metrics["legacy.wide.slot.truncation.dispatch"]==1 &&
                  context.Metrics["patched.wide.slot.truncation.dispatch"]==1 &&
                  context.Metrics["patched.upper.place.bias.dispatch"]==1,
                  "سلسلة التنفيذ والالتزام الحادي والعشرين");

            Check(context.PatchedWideSlotTruncationRankResult==expected &&
                  context.PatchedUpperPlaceBiasRankResult==expected &&
                  context.PatchedDoubleOffsetWideRankResult==expected &&
                  context.LegacyWideSlotTruncationRankResult==Old(expected) &&
                  context.LegacyWideSlotTruncationRankResult>=1 &&
                  context.LegacyWideSlotTruncationRankResult<=M &&
                  context.LegacyWideFamilySize==n &&
                  context.PatchedBowlQuestionResult is not null &&
                  context.PatchedBowlQuestionResult.First==stream.First &&
                  context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
                  context.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(context.PatchedSauceFinalBowls,context.LegacySauceFinalBowls),
                  "الرتبة المستعادة والمرجع والصلصة والشاهد التاريخي");
        }
        _publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var publicStream=NormativeScroll.AskBowl(sauce,publicId,publicSeal);
        var publicN=M*M-1;
        var corrected=CalendarDateSpaghetti.EvaluateWideSlotTruncation(
            c,t,publicId,publicSeal,publicN);
        var historical=CalendarDateSpaghetti.EvaluateLegacyWideSlotTruncation(
            c,t,publicId,publicSeal,publicN);
        Check(corrected==NormativeScroll.ChooseRankWide(publicStream,publicN) &&
              historical==Old(corrected) && historical>=1 && historical<=M,
              "المداخل العامة الصحيحة والتاريخية مستقلة");
    }

    private static void ValidationAndOwnership()
    {
        var first=Contexts[0];var second=Contexts[1];
        var saved=(BigInteger[])second.PatchedSauceFinalBowls!.Clone();
        var rank=second.PatchedWideSlotTruncationRankResult;
        var old=second.LegacyWideSlotTruncationRankResult;
        var trace=second.BranchTrace.ToArray();
        first.PatchedSauceFinalBowls![1]=0;
        Check(!ReferenceEquals(first,second) &&
              !ReferenceEquals(first.Metrics,second.Metrics) &&
              !ReferenceEquals(first.BranchTrace,second.BranchTrace) &&
              !ReferenceEquals(first.PatchedSauceFinalBowls,second.PatchedSauceFinalBowls) &&
              second.PatchedSauceFinalBowls.SequenceEqual(saved) &&
              second.PatchedWideSlotTruncationRankResult==rank &&
              second.LegacyWideSlotTruncationRankResult==old,
              "ملكية منفصلة للسياقات دون تلوّث");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var refused=false;
        try{dispatcher.DispatchPatchedWideSlotTruncation(second);}
        catch(MonsterValidationException){refused=true;}
        Check(refused && second.BranchTrace.SequenceEqual(trace) &&
              second.PatchedWideSlotTruncationRankResult==rank &&
              second.LegacyWideSlotTruncationRankResult==old &&
              second.Metrics["patched.wide.slot.truncation.dispatch"]==1,
              "منع إعادة الالتزام والكتابة الجانبية");

        var f=NormativeScroll.FoundationDay;
        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=M*M-1;
        var candidate=new PatchedWideSlotTruncationPhaseHandler().Handle(ready);
        var verifier=new MonsterValidationManager();
        verifier.ValidatePatchedWideSlotTruncation(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedWideSlotTruncationRankResult is null &&
              ready.LegacyWideSlotTruncationRankResult is null &&
              ready.PatchedUpperPlaceBiasRankResult is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق مستقل عن تثبيت الحالة");
        void Reject(PatchedWideSlotTruncationCandidate forged,string why)
        {
            var denied=false;
            try{verifier.ValidatePatchedWideSlotTruncation(ready,forged);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedWideSlotTruncationRankResult is null &&
                  ready.LegacyWideSlotTruncationRankResult is null &&
                  ready.PatchedUpperPlaceBiasRankResult is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض التزوير قبل الكتابة: "+why);
        }
        Reject(candidate with {Rank=0},"مرتبة صفر");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير الرتبة المصححة");
        Reject(candidate with {Historical=candidate.Historical with {Rank=0}},
               "تغيير شاهد القطع");
        Reject(candidate with {Historical=candidate.Historical with {
            Previous=candidate.Historical.Previous with {Rank=0}}},
            "تغيير الرقعة العشرين");
        Reject(candidate with {Historical=candidate.Historical with {
            Previous=candidate.Historical.Previous with {
                Historical=candidate.Historical.Previous.Historical with {Rank=0}}}},
            "تزوير الشاهد العشرين");

        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=M+1};
        refused=false;
        try{dispatcher.DispatchPatchedWideSlotTruncation(raw);}
        catch(MonsterValidationException){refused=true;}
        Check(refused && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.PatchedWideSlotTruncationRankResult is null,
              "منع استدعاء سياق غير مؤسس");

        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            refused=false;
            try{new MonsterManager().ExecutePatchedWideSlotTruncation(f,f,1,21,n);}
            catch(MonsterValidationException){refused=true;}
            Check(refused,"رفض أسرة غير واسعة");
        }
        foreach(var id in new[]{-1,0,7})
        {
            refused=false;
            try{new MonsterManager().ExecutePatchedWideSlotTruncation(f,f,id,21,M+1);}
            catch(MonsterValidationException){refused=true;}
            Check(refused,"رفض هوية وعاء غير صالحة");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            refused=false;
            try{new MonsterManager().ExecutePatchedWideSlotTruncation(f,f,1,seal,M+1);}
            catch(MonsterValidationException){refused=true;}
            Check(refused,"رفض ختم غير صالح");
        }
    }

    public static int Main()
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
        Console.WriteLine("مطابقات الإصلاح في التحكم: "+_controlsRepaired);
        Console.WriteLine("اختلافات التحكم التاريخية: "+_controlDifferences);
        Console.WriteLine("حالات الرفض: "+_rejections);
        Console.WriteLine("مطابقات الإصلاح في الرفض: "+_rejectionsRepaired);
        Console.WriteLine("اختلافات الرفض التاريخية: "+_rejectionDifferences);
        Console.WriteLine("قراءات الإنتاج: "+_production);
        Console.WriteLine("الإنتاج المصحح: "+_productionRepaired);
        Console.WriteLine("اختلافات الإنتاج التاريخية: "+_productionDifferences);
        Console.WriteLine("مطابقات الإنتاج التاريخية: "+_productionEqual);
        Console.WriteLine("حالات الرفض الحقيقية: "+_realRejections);
        Console.WriteLine("قراءات الواجهة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        return _unexpected==0 &&
               _controls==34560 && _controlsRepaired==34560 &&
               _controlDifferences==25920 &&
               _rejections==8640 && _rejectionsRepaired==8640 &&
               _rejectionDifferences==4320 &&
               _production==96 && _productionRepaired==96 &&
               _productionDifferences==78 && _productionEqual==18 &&
               _realRejections==28 && _publicReads==8?0:1;
    }
}
