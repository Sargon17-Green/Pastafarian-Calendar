using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage47Tests;

internal static class Program
{
    private static int passed,failed,controls,controlGood,controlOldDifferent;
    private static int accepted,acceptedGood,acceptedOldDifferent;
    private static int rejected,rejectedGood,rejectedOldDifferent;
    private static int production,productionGood,productionOldDifferent,productionOldEqual,realRejected,publicReads;
    private static readonly List<MonsterContext> Contexts=new();
    private static BigInteger M=>NormativeScroll.M;

    private static void Check(bool ok,string name)
    {
        if(ok){passed++;return;}
        failed++;
        Console.WriteLine("إخفاق غير متوقع في الرقعة الثالثة والعشرين: "+name);
    }

    private static BigInteger Legacy(BigInteger rank,BigInteger n)
        => rank==n?BigInteger.One:rank;
    private static BigInteger Wide(AnswerStream s)
        => s.First+(NormativeScroll.AnswerAt(s,BigInteger.One)-1)*M;

    private static void Synthetic()
    {
        var previous=new WideDigitOrderPatchWrapper();
        var old=new LegacyWideTerminalSentinel();
        var patch=new WideTerminalSentinelPatchWrapper();
        var sizes=new[]{M+1,2*M+1,M*M-1,M*M+1};
        for(var index=1;index<=720;index++)
        for(var id=1;id<=6;id++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(index*6+id);
            var stream=new AnswerStream(first,direction);
            var answer=new LegacyBowlQuestionResult(first,direction);
            foreach(var n in sizes)
            {
                controls++;
                var expected=NormativeScroll.ChooseRankWide(stream,n);
                var rank=previous.Patch(answer,n);
                var scar=old.Collapse(rank,n);
                var fixedRank=patch.Restore(scar,rank,n);
                if(scar!=expected)controlOldDifferent++;
                if(fixedRank==expected)controlGood++;
                Check(rank==expected && scar==Legacy(expected,n) &&
                      fixedRank==expected && fixedRank>=1 && fixedRank<=n &&
                      (expected==n ? scar==1 : scar==expected),
                      "حالة ضبط مع حفظ أثر الحارس التاريخي");
            }

            var bound=Wide(stream);
            var expectedAccepted=NormativeScroll.ChooseRankWide(stream,bound);
            var original=previous.Patch(answer,bound);
            var scarAccepted=old.Collapse(original,bound);
            var fixedAccepted=patch.Restore(scarAccepted,original,bound);
            accepted++;
            if(fixedAccepted==expectedAccepted)acceptedGood++;
            if(scarAccepted!=expectedAccepted)acceptedOldDifferent++;
            Check(bound>M && bound<M*M &&
                  expectedAccepted==bound && original==bound &&
                  scarAccepted==BigInteger.One &&
                  fixedAccepted==bound,
                  "الحد المقبول من دون رفض يعود إلى المرتبة القصوى");

            var high=M-1-first;
            var rejectedStream=new AnswerStream(high,direction);
            var nRejected=Wide(rejectedStream)-1;
            var expectedRejected=direction==1?BigInteger.One:nRejected;
            var priorRejected=previous.Patch(
                new LegacyBowlQuestionResult(high,direction),nRejected);
            var scarRejected=old.Collapse(priorRejected,nRejected);
            var fixedRejected=patch.Restore(scarRejected,priorRejected,nRejected);
            rejected++;
            if(fixedRejected==expectedRejected)rejectedGood++;
            if(scarRejected!=expectedRejected)rejectedOldDifferent++;
            Check(nRejected>M*M/2 && nRejected<M*M &&
                  priorRejected==expectedRejected &&
                  scarRejected==Legacy(expectedRejected,nRejected) &&
                  fixedRejected==expectedRejected &&
                  (direction==1?scarRejected==expectedRejected:
                                 scarRejected==BigInteger.One && fixedRejected==nRejected),
                  "الرفض في الاتجاهين والحد الأعلى");
        }
        Check(controls==34560 && controlGood==34560 &&
              controlOldDifferent==4320 &&
              accepted==8640 && acceptedGood==8640 &&
              acceptedOldDifferent==8640 &&
              rejected==8640 && rejectedGood==8640 &&
              rejectedOldDifferent==4320,
              "توقيع الإصلاح عبر كل الأسر والحالات المقبولة والمرفوضة");
    }

    private static void Boundaries()
    {
        var old=new LegacyWideTerminalSentinel();
        var patch=new WideTerminalSentinelPatchWrapper();
        foreach(var n in new[]{M+1,2*M+1,M*M-1,M*M+1,(BigInteger.One<<8192)+M*M+1})
        foreach(var rank in new[]{BigInteger.One,new BigInteger(2),n-1,n})
        {
            var scar=old.Collapse(rank,n);
            Check(scar==Legacy(rank,n) &&
                  patch.Restore(scar,rank,n)==rank &&
                  (rank==n ? scar==BigInteger.One : scar==rank),
                  "حدود الرتبة النهائية حتى 8192 بت");
        }
        Check(old.Collapse(M+1,M+1)==old.Collapse(1,M+1) &&
              patch.Restore(1,1,M+1)==1 &&
              patch.Restore(1,M+1,M+1)==M+1,
              "استعادة الشاهد الملتبس من المرشح السابق");

        foreach(var triple in new (BigInteger Scar,BigInteger Previous,BigInteger N)[]{
            (0,1,M+1),(M+2,1,M+1),(1,0,M+1),(1,M+2,M+1),
            (1,1,M),(1,1,0),(1,1,-1),(2,1,M+1)
        })
        {
            var denied=false;
            try{patch.Restore(triple.Scar,triple.Previous,triple.N);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض شاهد مزور أو مدخل غير قانوني");
        }
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        var sauce=NormativeScroll.Sauce(c,t);
        var manager=new MonsterManager();
        for(var id=1;id<=6;id++)
        for(var idx=0;idx<2;idx++)
        {
            var seal=idx==0?21:31;
            var stream=NormativeScroll.AskBowl(sauce,id,seal);
            var wide=Wide(stream);
            var rejection=stream.DirectionStep==-1 && wide>M*M/2+1 && wide<M*M;
            var n=rejection?wide-1:M+1;
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            var context=manager.ExecutePatchedWideTerminalSentinel(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            production++;
            if(rejection)realRejected++;
            if(context.PatchedWideTerminalSentinelRankResult==expected)productionGood++;
            if(context.LegacyWideTerminalSentinelRankResult!=expected)productionOldDifferent++;
            else productionOldEqual++;

            Check(context.Status=="PATCHED_WIDE_TERMINAL_SENTINEL_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.Count==25 &&
                  context.BranchTrace[^2]=="LEGACY_WIDE_TERMINAL_SENTINEL" &&
                  context.BranchTrace[^1]=="PATCHED_WIDE_TERMINAL_SENTINEL" &&
                  context.Metrics["legacy.wide.terminal.sentinel.dispatch"]==1 &&
                  context.Metrics["patched.wide.terminal.sentinel.dispatch"]==1 &&
                  context.Metrics["patched.descending.rank.mirror.dispatch"]==1,
                  "تسلسل الموزع وحالة الرقعة الثالثة والعشرين");
            Check(context.PatchedWideTerminalSentinelRankResult==expected &&
                  context.PatchedDescendingRankMirrorResult==expected &&
                  context.PatchedWideSlotTruncationRankResult==expected &&
                  context.PatchedUpperPlaceBiasRankResult==expected &&
                  context.LegacyWideTerminalSentinelRankResult==Legacy(expected,n) &&
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
                  "الصلصة الصحيحة والنتيجة المصححة والشاهد التاريخي");
        }
        publicReads++;
        var bowl=sample%6+1;
        var sealPublic=sample%2==0?31:21;
        var answer=NormativeScroll.AskBowl(sauce,bowl,sealPublic);
        var nPublic=M*M-1;
        var expectedPublic=NormativeScroll.ChooseRankWide(answer,nPublic);
        var patched=CalendarDateSpaghetti.EvaluateWideTerminalSentinel(c,t,bowl,sealPublic,nPublic);
        var original=CalendarDateSpaghetti.EvaluateLegacyWideTerminalSentinel(
            c,t,bowl,sealPublic,nPublic);
        Check(patched==expectedPublic && original==Legacy(expectedPublic,nPublic),
              "واجهتا المرتبة المصححة والشاهد القديم");
    }

    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];
        var b=Contexts[1];
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var prior=b.PatchedDescendingRankMirrorResult;
        var historical=b.LegacyWideTerminalSentinelRankResult;
        var patched=b.PatchedWideTerminalSentinelRankResult;
        var trace=b.BranchTrace.ToArray();
        a.PatchedSauceFinalBowls![1]=0;
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.Metrics,b.Metrics) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              b.PatchedSauceFinalBowls.SequenceEqual(saved) &&
              b.PatchedDescendingRankMirrorResult==prior &&
              b.LegacyWideTerminalSentinelRankResult==historical &&
              b.PatchedWideTerminalSentinelRankResult==patched,
              "استقلال ملكية السياقات وجداول الصلصة");
        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var denied=false;
        try{dispatcher.DispatchPatchedWideTerminalSentinel(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyWideTerminalSentinelRankResult==historical &&
              b.PatchedWideTerminalSentinelRankResult==patched &&
              b.Metrics["patched.wide.terminal.sentinel.dispatch"]==1,
              "رفض الالتزام المكرر بلا آثار جانبية");

        var f=NormativeScroll.FoundationDay;
        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=0;
        ready.LegacyWideFamilySize=M*M-1;
        var candidate=new PatchedWideTerminalSentinelPhaseHandler().Handle(ready);
        var validation=new MonsterValidationManager();
        validation.ValidatePatchedWideTerminalSentinel(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedWideTerminalSentinelRankResult is null &&
              ready.LegacyWideTerminalSentinelRankResult is null &&
              ready.PatchedDescendingRankMirrorResult is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق قبل الالتزام لا يكتب النتائج");
        void Reject(PatchedWideTerminalSentinelCandidate forged,string reason)
        {
            var rejected=false;
            try{validation.ValidatePatchedWideTerminalSentinel(ready,forged);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedWideTerminalSentinelRankResult is null &&
                  ready.LegacyWideTerminalSentinelRankResult is null &&
                  ready.PatchedDescendingRankMirrorResult is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض التزوير قبل الالتزام "+reason);
        }
        Reject(candidate with {Rank=0},"الرتبة الصفرية");
        Reject(candidate with {Rank=candidate.Rank+1},"تحريف الرتبة المصححة");
        Reject(candidate with {Historical=candidate.Historical with {Rank=0}},
               "تحريف شاهد الحارس");
        Reject(candidate with {Historical=candidate.Historical with {
            Previous=candidate.Historical.Previous with {Rank=0}}},
            "تحريف الرقعة الثانية والعشرين");
        Reject(candidate with {Historical=candidate.Historical with {
            Previous=candidate.Historical.Previous with {
                Historical=candidate.Historical.Previous.Historical with {Rank=0}}}},
            "تحريف شاهد المرآة السابق");

        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=M+1};
        denied=false;
        try{dispatcher.DispatchPatchedWideTerminalSentinel(raw);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.PatchedWideTerminalSentinelRankResult is null,
              "رفض سياق غير مؤسس");
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedWideTerminalSentinel(f,f,1,21,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض عائلة غير واسعة");
        }
        foreach(var bowl in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedWideTerminalSentinel(f,f,bowl,21,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض هوية وعاء غير قانونية");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedWideTerminalSentinel(f,f,1,seal,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض ختم غير قانوني");
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
        Console.WriteLine("الضبط: "+controls);
        Console.WriteLine("الضبط المصحح: "+controlGood);
        Console.WriteLine("اختلافات الضبط التاريخية: "+controlOldDifferent);
        Console.WriteLine("الحد المقبول: "+accepted);
        Console.WriteLine("الحد المقبول المصحح: "+acceptedGood);
        Console.WriteLine("اختلافات الحد التاريخية: "+acceptedOldDifferent);
        Console.WriteLine("الرفض: "+rejected);
        Console.WriteLine("الرفض المصحح: "+rejectedGood);
        Console.WriteLine("اختلافات الرفض التاريخية: "+rejectedOldDifferent);
        Console.WriteLine("الإنتاج: "+production);
        Console.WriteLine("الإنتاج المصحح: "+productionGood);
        Console.WriteLine("اختلافات الإنتاج التاريخية: "+productionOldDifferent);
        Console.WriteLine("مطابقات الإنتاج التاريخية: "+productionOldEqual);
        Console.WriteLine("الرفض الإنتاجي: "+realRejected);
        Console.WriteLine("قراءات الواجهة: "+publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+failed);
        return failed==0 &&
               controls==34560 && controlGood==34560 && controlOldDifferent==4320 &&
               accepted==8640 && acceptedGood==8640 && acceptedOldDifferent==8640 &&
               rejected==8640 && rejectedGood==8640 && rejectedOldDifferent==4320 &&
               production==96 && productionGood==96 &&
               productionOldDifferent==78 && productionOldEqual==18 &&
               realRejected==28 && publicReads==8?0:1;
    }
}
