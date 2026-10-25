using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage46Tests;

internal static class Program
{
    private static int passed,unexpected,controls,controlDifferent,controlEqual;
    private static int acceptedBoundary,boundaryDifferent,rejections,rejectionDifferent,rejectionEqual;
    private static int production,productionCorrect,productionDifferent,productionEqual,realRejections,publicReads;
    private static readonly List<MonsterContext> Contexts=new();
    private static BigInteger M=>NormativeScroll.M;

    private static void Check(bool ok,string explanation)
    {
        if(ok){passed++;return;}
        unexpected++;
        Console.WriteLine("مخالفة غير متوقعة في اكتشاف حارس الرتبة النهائية: "+explanation);
    }
    private static BigInteger Historical(BigInteger correct,BigInteger n)
        => correct==n?BigInteger.One:correct;
    private static BigInteger Wide(AnswerStream stream)
        => stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*M;

    private static void Synthetic()
    {
        var prior=new WideDigitOrderPatchWrapper();
        var old=new LegacyWideTerminalSentinel();
        var sizes=new[]{M+1,2*M+1,M*M-1,M*M+1};
        for(var index=1;index<=720;index++)
        for(var id=1;id<=6;id++)
        foreach(var dir in new[]{-1,1})
        {
            var first=new BigInteger(index*6+id);
            var stream=new AnswerStream(first,dir);
            var source=new LegacyBowlQuestionResult(first,dir);
            foreach(var n in sizes)
            {
                controls++;
                var correct=NormativeScroll.ChooseRankWide(stream,n);
                var priorRank=prior.Patch(source,n);
                var scar=old.Collapse(priorRank,n);
                if(scar!=correct)controlDifferent++;
                else controlEqual++;
                Check(priorRank==correct && scar==Historical(correct,n) &&
                      (correct==n ? scar==BigInteger.One :
                                    scar==correct && scar>=1 && scar<n),
                      "ملاحظة فساد رتبة النهاية دون تغيير الخانات الأخرى");
            }

            // قبول الحد نفسه، بلا رفض: x=W من تيار إجابتين، وn=x.
            var boundaryN=Wide(stream);
            var accepted=NormativeScroll.ChooseRankWide(stream,boundaryN);
            var actual=prior.Patch(source,boundaryN);
            var scarBoundary=old.Collapse(actual,boundaryN);
            acceptedBoundary++;
            if(scarBoundary!=accepted)boundaryDifferent++;
            Check(boundaryN>M && boundaryN<M*M &&
                  accepted==boundaryN && actual==boundaryN &&
                  scarBoundary==BigInteger.One &&
                  scarBoundary!=actual,
                  "خسارة المرتبة القصوى المقبولة من دون رفض");

            // شاهد رفض مستقل: نزولاً إلى n، وصعوداً إلى 1.
            var rejectedFirst=M-1-first;
            var rejectedStream=new AnswerStream(rejectedFirst,dir);
            var nReject=Wide(rejectedStream)-1;
            var correctReject=dir==1?BigInteger.One:nReject;
            var priorReject=prior.Patch(
                new LegacyBowlQuestionResult(rejectedFirst,dir),nReject);
            var scarReject=old.Collapse(priorReject,nReject);
            rejections++;
            if(scarReject!=correctReject)rejectionDifferent++;
            else rejectionEqual++;
            Check(nReject>M*M/2 && nReject<M*M &&
                  priorReject==correctReject &&
                  scarReject==Historical(correctReject,nReject) &&
                  scarReject==BigInteger.One &&
                  (dir==1?scarReject==correctReject:scarReject!=correctReject),
                  "الرفض السليم صار شاهد فساد في المخرج فقط");
        }
        Check(controls==34560 && controlDifferent==4320 &&
              controlEqual==30240 &&
              acceptedBoundary==8640 && boundaryDifferent==8640 &&
              rejections==8640 && rejectionDifferent==4320 &&
              rejectionEqual==4320,
              "توقيع عطب النهاية في الإجابات المقبولة والمرفوضة");
    }

    private static void Boundaries()
    {
        var old=new LegacyWideTerminalSentinel();
        foreach(var n in new[]{M+1,2*M+1,M*M-1,M*M+1,(BigInteger.One<<8192)+M*M+1})
        foreach(var rank in new[]{BigInteger.One,new BigInteger(2),n-1,n})
        {
            var scar=old.Collapse(rank,n);
            Check(scar==Historical(rank,n) &&
                  (rank==n?scar==BigInteger.One:scar==rank) &&
                  scar>=1 && scar<=n,
                  "حارس مرتبة المجال العريض حتى 8192 بت");
        }
        Check(old.Collapse(M+1,M+1)==old.Collapse(1,M+1) &&
              old.Collapse(M+1,M+1)==BigInteger.One,
              "عدم إمكان استعادة المرتبة من شاهد الحارس وحده");

        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            var denied=false;
            try{old.Collapse(1,n);}catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض أسرة غير واسعة");
        }
        foreach(var rank in new[]{BigInteger.Zero,new BigInteger(-1),M+2})
        {
            var denied=false;
            try{old.Collapse(rank,M+1);}catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض مرتبة خارج المجال");
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
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            var context=manager.ExecuteLegacyWideTerminalSentinel(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            production++;
            if(reject)realRejections++;
            if(context.PatchedDescendingRankMirrorResult==expected)productionCorrect++;
            if(context.LegacyWideTerminalSentinelRankResult!=expected)productionDifferent++;
            else productionEqual++;
            Check(context.Status=="LEGACY_WIDE_TERMINAL_SENTINEL_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.Count==24 &&
                  context.BranchTrace[^2]=="PATCHED_DESCENDING_RANK_MIRROR" &&
                  context.BranchTrace[^1]=="LEGACY_WIDE_TERMINAL_SENTINEL" &&
                  context.Metrics["legacy.wide.terminal.sentinel.dispatch"]==1 &&
                  context.Metrics["patched.descending.rank.mirror.dispatch"]==1 &&
                  context.Metrics["legacy.descending.rank.mirror.dispatch"]==1,
                  "حضور الشاهد التاريخي في سلسلة إنتاج مستقلة");
            Check(context.PatchedDescendingRankMirrorResult==expected &&
                  context.PatchedWideSlotTruncationRankResult==expected &&
                  context.PatchedUpperPlaceBiasRankResult==expected &&
                  context.LegacyWideTerminalSentinelRankResult==Historical(expected,n) &&
                  context.LegacyWideFamilySize==n &&
                  context.PatchedBowlQuestionResult is not null &&
                  context.PatchedBowlQuestionResult.First==stream.First &&
                  context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46),
                  "المصدر والصلصة والرتبة المصححة محفوظة");
        }
        publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var publicStream=NormativeScroll.AskBowl(sauce,publicId,publicSeal);
        var nPublic=M*M-1;
        var good=CalendarDateSpaghetti.EvaluateDescendingRankMirror(
            c,t,publicId,publicSeal,nPublic);
        var old=CalendarDateSpaghetti.EvaluateLegacyWideTerminalSentinel(
            c,t,publicId,publicSeal,nPublic);
        Check(good==NormativeScroll.ChooseRankWide(publicStream,nPublic) &&
              old==Historical(good,nPublic),
              "استقلال الواجهة العامة التاريخية عن الصحيحة");
    }

    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];var b=Contexts[1];
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var scar=b.LegacyWideTerminalSentinelRankResult;
        var prior=b.PatchedDescendingRankMirrorResult;
        var trace=b.BranchTrace.ToArray();
        a.PatchedSauceFinalBowls![1]=0;
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.Metrics,b.Metrics) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              b.PatchedSauceFinalBowls.SequenceEqual(saved) &&
              b.LegacyWideTerminalSentinelRankResult==scar &&
              b.PatchedDescendingRankMirrorResult==prior,
              "لا تتسرّب بيانات الشواهد بين سياقات مختلفة");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var denied=false;
        try{dispatcher.DispatchLegacyWideTerminalSentinel(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyWideTerminalSentinelRankResult==scar &&
              b.Metrics["legacy.wide.terminal.sentinel.dispatch"]==1,
              "منع التزام مكرر بعد إغلاق الحالة");

        var f=NormativeScroll.FoundationDay;
        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=M*M-1;
        var candidate=new LegacyWideTerminalSentinelPhaseHandler().Handle(ready);
        var validation=new MonsterValidationManager();
        validation.ValidateLegacyWideTerminalSentinel(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyWideTerminalSentinelRankResult is null &&
              ready.PatchedDescendingRankMirrorResult is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق يسبق الالتزام ولا يكتب حالة");

        void Reject(LegacyWideTerminalSentinelCandidate forged,string reason)
        {
            var refused=false;
            try{validation.ValidateLegacyWideTerminalSentinel(ready,forged);}
            catch(MonsterValidationException){refused=true;}
            Check(refused && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyWideTerminalSentinelRankResult is null &&
                  ready.PatchedDescendingRankMirrorResult is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض التزوير دون كتابة "+reason);
        }
        Reject(candidate with {Rank=0},"حارس صفر");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير شاهد الحارس");
        Reject(candidate with {Previous=candidate.Previous with {Rank=0}},
               "إفساد الرقعة الثانية والعشرين");
        Reject(candidate with {Previous=candidate.Previous with {
            Historical=candidate.Previous.Historical with {Rank=0}}},
               "تحريف مرآة الاتجاه السابقة");

        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=M+1};
        denied=false;
        try{dispatcher.DispatchLegacyWideTerminalSentinel(raw);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && raw.Status=="NEW" &&
              raw.BranchTrace.Count==0 && raw.LegacyWideTerminalSentinelRankResult is null,
              "رفض السياق غير المؤسس");
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyWideTerminalSentinel(f,f,1,21,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض عائلة غير واسعة");
        }
        foreach(var id in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyWideTerminalSentinel(f,f,id,21,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض هوية الوعاء غير الصالحة");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyWideTerminalSentinel(f,f,1,seal,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض الحاتم غير القانوني");
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
        var dates=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<dates.Length;i++)Production(dates[i].C,dates[i].T,i+1);
        if(verify)ValidationAndOwnership();
        Console.WriteLine("الضبط التركيبي: "+controls);
        Console.WriteLine("اختلافات الضبط القديمة: "+controlDifferent);
        Console.WriteLine("مطابقات الضبط: "+controlEqual);
        Console.WriteLine("الحد المقبول بلا رفض: "+acceptedBoundary);
        Console.WriteLine("اختلافات الحد المقبول: "+boundaryDifferent);
        Console.WriteLine("حالات الرفض: "+rejections);
        Console.WriteLine("اختلافات الرفض: "+rejectionDifferent);
        Console.WriteLine("مطابقات الرفض: "+rejectionEqual);
        Console.WriteLine("أسئلة الإنتاج: "+production);
        Console.WriteLine("مراتب الإنتاج الصحيحة قبل الندبة: "+productionCorrect);
        Console.WriteLine("الاختلافات الإنتاجية التاريخية: "+productionDifferent);
        Console.WriteLine("مطابقات الإنتاج التاريخية: "+productionEqual);
        Console.WriteLine("رفض الإنتاج الحقيقي: "+realRejections);
        Console.WriteLine("الواجهات العامة: "+publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+unexpected);
        var ok=unexpected==0 &&
               controls==34560 && controlDifferent==4320 && controlEqual==30240 &&
               acceptedBoundary==8640 && boundaryDifferent==8640 &&
               rejections==8640 && rejectionDifferent==4320 && rejectionEqual==4320 &&
               production==96 && productionCorrect==96 &&
               productionDifferent>=28 && productionEqual>=1 &&
               productionDifferent+productionEqual==96 &&
               realRejections==28 && publicReads==8;
        if(verify)
        {
            Console.WriteLine("توقيع الأحمر المقصود لحارس الرتبة: "+(ok?"PASS":"FAIL"));
            return ok?0:1;
        }
        return unexpected==0 && controlDifferent==0 &&
               boundaryDifferent==0 && rejectionDifferent==0 &&
               productionDifferent==0?0:1;
    }
}
