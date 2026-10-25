using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage45Tests;

internal static class Program
{
    private static int passed,failed,controls,controlGood,oldControlsDifferent;
    private static int rejections,rejectionsGood,oldRejectionsDifferent;
    private static int production,productionGood,productionOldDifferent,productionOldEqual;
    private static int realRejections,publicReads;
    private static readonly List<MonsterContext> Contexts=new();
    private static BigInteger M=>NormativeScroll.M;

    private static void Check(bool ok,string message)
    {
        if(ok){passed++;return;}
        failed++;
        Console.WriteLine("إخفاق في الرقعة الثانية والعشرين: "+message);
    }
    private static BigInteger Historical(BigInteger correct,BigInteger n,int direction)
        => direction==-1?n+BigInteger.One-correct:correct;
    private static BigInteger Wide(AnswerStream stream)
        => stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*M;

    private static void Synthetic()
    {
        var previous=new WideDigitOrderPatchWrapper();
        var old=new LegacyDescendingRankMirror();
        var patch=new DescendingRankMirrorPatchWrapper();
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
                var correctBefore=previous.Patch(source,n);
                var scar=old.Reflect(correctBefore,n,direction);
                var repaired=patch.Unmirror(scar,n,direction);
                if(repaired==expected)controlGood++;
                if(scar!=expected)oldControlsDifferent++;
                Check(correctBefore==expected &&
                      scar==Historical(expected,n,direction) &&
                      repaired==expected && repaired>=1 && repaired<=n,
                      "فحص رتبة الضبط والاتجاه المستقل");
            }

            var high=M-1-first;
            var rejectedStream=new AnswerStream(high,direction);
            var nReject=Wide(rejectedStream)-1;
            var expectedRejected=direction==1?BigInteger.One:nReject;
            var correctBeforeReject=previous.Patch(
                new LegacyBowlQuestionResult(high,direction),nReject);
            var scarReject=old.Reflect(correctBeforeReject,nReject,direction);
            var repairedReject=patch.Unmirror(scarReject,nReject,direction);
            rejections++;
            if(repairedReject==expectedRejected)rejectionsGood++;
            if(scarReject!=expectedRejected)oldRejectionsDifferent++;
            Check(nReject>M*M/2 && nReject<M*M &&
                  correctBeforeReject==expectedRejected &&
                  scarReject==Historical(expectedRejected,nReject,direction) &&
                  repairedReject==expectedRejected &&
                  (direction==1?scarReject==BigInteger.One:
                               scarReject==BigInteger.One && repairedReject==nReject),
                  "رفض التيار في كلا الاتجاهين دون إتلاف نتيجة الرقعة");
        }
        Check(controls==34560 && controlGood==34560 &&
              oldControlsDifferent==17280 &&
              rejections==8640 && rejectionsGood==8640 &&
              oldRejectionsDifferent==4320,
              "التوقيع 17280 انحرافاً ضابطاً و4320 في الرفض");
    }

    private static void Boundaries()
    {
        var patch=new DescendingRankMirrorPatchWrapper();
        var old=new LegacyDescendingRankMirror();
        foreach(var n in new[]{M+1,2*M+1,M*M-1,M*M+1,(BigInteger.One<<8192)+M*M+1})
        foreach(var r in new[]{BigInteger.One,new BigInteger(2),n-1,n})
        foreach(var dir in new[]{-1,1})
        {
            var scar=old.Reflect(r,n,dir);
            Check(patch.Unmirror(scar,n,dir)==r &&
                  scar==Historical(r,n,dir) &&
                  (dir==1?scar==r:scar!=r),
                  "حدود مرآة الدرجة بعرض يصل إلى 8192 بت");
        }
        var odd=2*M+1;
        var midpoint=M+1;
        Check(old.Reflect(midpoint,odd,-1)==midpoint &&
              patch.Unmirror(midpoint,odd,-1)==midpoint &&
              patch.Unmirror(midpoint,odd,1)==midpoint,
              "المرتبة الوسطى تبقى ثابتة في المرآة الفردية");
        foreach(var (rank,n,dir) in new (BigInteger Rank,BigInteger N,int Dir)[]{
            (0,M+1,-1),(-1,M+1,1),(M+2,M+1,-1),(1,M,-1),
            (1,0,1),(1,M+1,0),(1,M+1,2),(1,M+1,-2)
        })
        {
            var denied=false;
            try{patch.Unmirror(rank,n,dir);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض رتبة أو مجال أو اتجاه غير صالح");
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
            var rejected=stream.DirectionStep==-1 && wide>M*M/2+1 && wide<M*M;
            var n=rejected?wide-1:M+1;
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            var context=manager.ExecutePatchedDescendingRankMirror(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            production++;
            if(rejected)realRejections++;
            if(context.PatchedDescendingRankMirrorResult==expected)productionGood++;
            if(context.LegacyDescendingRankMirrorResult!=expected)productionOldDifferent++;
            else productionOldEqual++;

            Check(context.Status=="PATCHED_DESCENDING_RANK_MIRROR_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.Count==23 &&
                  context.BranchTrace[^2]=="LEGACY_DESCENDING_RANK_MIRROR" &&
                  context.BranchTrace[^1]=="PATCHED_DESCENDING_RANK_MIRROR" &&
                  context.Metrics["legacy.descending.rank.mirror.dispatch"]==1 &&
                  context.Metrics["patched.descending.rank.mirror.dispatch"]==1 &&
                  context.Metrics["patched.wide.slot.truncation.dispatch"]==1,
                  "السلسلة الكاملة للموزع بعد الرقعة الثانية والعشرين");
            Check(context.PatchedDescendingRankMirrorResult==expected &&
                  context.LegacyDescendingRankMirrorResult==
                      Historical(expected,n,stream.DirectionStep) &&
                  context.PatchedWideSlotTruncationRankResult==expected &&
                  context.PatchedUpperPlaceBiasRankResult==expected &&
                  context.PatchedDoubleOffsetWideRankResult==expected &&
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
                  "سلامة الصلصة والمصدر مع استقلال شاهد المرآة");
        }
        publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var publicStream=NormativeScroll.AskBowl(sauce,publicId,publicSeal);
        var nPublic=M*M-1;
        var corrected=CalendarDateSpaghetti.EvaluateDescendingRankMirror(
            c,t,publicId,publicSeal,nPublic);
        var historical=CalendarDateSpaghetti.EvaluateLegacyDescendingRankMirror(
            c,t,publicId,publicSeal,nPublic);
        Check(corrected==NormativeScroll.ChooseRankWide(publicStream,nPublic) &&
              historical==Historical(corrected,nPublic,publicStream.DirectionStep),
              "استقلال الواجهتين التاريخية والمصححة");
    }

    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];var b=Contexts[1];
        var prior=b.PatchedDescendingRankMirrorResult;
        var scar=b.LegacyDescendingRankMirrorResult;
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var trace=b.BranchTrace.ToArray();
        a.PatchedSauceFinalBowls![1]=0;
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.Metrics,b.Metrics) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              b.PatchedSauceFinalBowls.SequenceEqual(saved) &&
              b.PatchedDescendingRankMirrorResult==prior &&
              b.LegacyDescendingRankMirrorResult==scar,
              "عزل نتائج السياقات وعدم تسرب الجداول");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var denied=false;
        try{dispatcher.DispatchPatchedDescendingRankMirror(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.PatchedDescendingRankMirrorResult==prior &&
              b.LegacyDescendingRankMirrorResult==scar &&
              b.Metrics["patched.descending.rank.mirror.dispatch"]==1,
              "رفض الالتزام المكرر من دون أثر جانبي");

        var f=NormativeScroll.FoundationDay;
        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=M*M-1;
        var candidate=new PatchedDescendingRankMirrorPhaseHandler().Handle(ready);
        var validation=new MonsterValidationManager();
        validation.ValidatePatchedDescendingRankMirror(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedDescendingRankMirrorResult is null &&
              ready.LegacyDescendingRankMirrorResult is null &&
              ready.PatchedWideSlotTruncationRankResult is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "المدقق لا يحفظ النتيجة قبل نجاح جميع الشواهد");

        void Reject(PatchedDescendingRankMirrorCandidate forged,string label)
        {
            var refused=false;
            try{validation.ValidatePatchedDescendingRankMirror(ready,forged);}
            catch(MonsterValidationException){refused=true;}
            Check(refused && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedDescendingRankMirrorResult is null &&
                  ready.LegacyDescendingRankMirrorResult is null &&
                  ready.PatchedWideSlotTruncationRankResult is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض شهادة مزورة قبل الالتزام "+label);
        }
        Reject(candidate with {Rank=0},"رتبة صفر");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير الناتج المصحح");
        Reject(candidate with {Historical=candidate.Historical with {Rank=0}},
               "تزوير شاهد المرآة القديم");
        Reject(candidate with {Historical=candidate.Historical with {
            Direction=-candidate.Historical.Direction}},"تزوير اتجاه السؤال");
        Reject(candidate with {Historical=candidate.Historical with {
            Previous=candidate.Historical.Previous with {Rank=0}}},
            "تحريف الرقعة الحادية والعشرين");
        Reject(candidate with {Historical=candidate.Historical with {
            Previous=candidate.Historical.Previous with {
                Historical=candidate.Historical.Previous.Historical with {Rank=0}}}},
            "تحريف شاهد القطع السابق");

        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=M+1};
        denied=false;
        try{dispatcher.DispatchPatchedDescendingRankMirror(raw);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.PatchedDescendingRankMirrorResult is null,
              "رفض سياق غير مؤسس");
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedDescendingRankMirror(f,f,1,21,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض عائلة غير واسعة");
        }
        foreach(var id in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedDescendingRankMirror(f,f,id,21,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض هوية الوعاء غير الصالحة");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedDescendingRankMirror(f,f,1,seal,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض ختم غير صالح");
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
        Console.WriteLine("حالات التحكم: "+controls);
        Console.WriteLine("النتائج المصححة في التحكم: "+controlGood);
        Console.WriteLine("الفروق التاريخية في التحكم: "+oldControlsDifferent);
        Console.WriteLine("حالات الرفض: "+rejections);
        Console.WriteLine("النتائج المصححة في الرفض: "+rejectionsGood);
        Console.WriteLine("الفروق التاريخية في الرفض: "+oldRejectionsDifferent);
        Console.WriteLine("قراءات الإنتاج: "+production);
        Console.WriteLine("النتائج الصحيحة في الإنتاج: "+productionGood);
        Console.WriteLine("الاختلافات التاريخية الإنتاجية: "+productionOldDifferent);
        Console.WriteLine("مطابقات الإنتاج التاريخية: "+productionOldEqual);
        Console.WriteLine("حالات الرفض الحقيقية: "+realRejections);
        Console.WriteLine("قراءات الواجهة: "+publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+failed);
        return failed==0 && controls==34560 && controlGood==34560 &&
               oldControlsDifferent==17280 &&
               rejections==8640 && rejectionsGood==8640 &&
               oldRejectionsDifferent==4320 &&
               production==96 && productionGood==96 &&
               productionOldDifferent==46 && productionOldEqual==50 &&
               realRejections==28 && publicReads==8?0:1;
    }
}
