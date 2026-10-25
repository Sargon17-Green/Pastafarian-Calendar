using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage48Tests;

internal static class Program
{
    private static int passed,unexpected,controls,controlDifferent,controlEqual;
    private static int accepted,acceptedDifferent,rejected,rejectedDifferent,rejectedEqual;
    private static int production,productionCorrect,productionDifferent,productionEqual,productionAccepted;
    private static int realRejections,publicReads;
    private static readonly List<MonsterContext> Contexts=new();

    private static BigInteger M=>NormativeScroll.M;
    private static BigInteger Legacy(BigInteger rank,BigInteger n)
        => rank==n-BigInteger.One?n:rank;
    private static BigInteger Wide(AnswerStream stream)
        => stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*M;

    private static void Check(bool ok,string label)
    {
        if(ok){passed++;return;}
        unexpected++;
        Console.WriteLine("مخالفة غير متوقعة في حمل المرتبة قبل الأخيرة: "+label);
    }

    private static void Synthetic()
    {
        var previous=new WideDigitOrderPatchWrapper();
        var old=new LegacyPenultimateWideCarry();
        var sizes=new[]{M+1,2*M+1,M*M-1,M*M+1};
        for(var index=1;index<=720;index++)
        for(var id=1;id<=6;id++)
        foreach(var dir in new[]{-1,1})
        {
            var first=new BigInteger(index*6+id);
            var source=new LegacyBowlQuestionResult(first,dir);
            var stream=new AnswerStream(first,dir);
            foreach(var n in sizes)
            {
                controls++;
                var correct=NormativeScroll.ChooseRankWide(stream,n);
                var prior=previous.Patch(source,n);
                var scar=old.Carry(prior,n);
                if(scar!=correct)controlDifferent++;
                else controlEqual++;
                Check(prior==correct && scar==Legacy(correct,n) &&
                      scar>=1 && scar<=n &&
                      (correct==n ? scar==n :
                       correct==n-1 ? scar==n : scar==correct),
                      "الضبط لا يفسد إلا المرتبة قبل الأخيرة");
            }

            // شاهد قبول بلا رفض: قيمة الإسقاط واسعة لكن أقل من n بواحد.
            var nAccepted=Wide(stream)+1;
            var expectedAccepted=NormativeScroll.ChooseRankWide(stream,nAccepted);
            var priorAccepted=previous.Patch(source,nAccepted);
            var scarAccepted=old.Carry(priorAccepted,nAccepted);
            accepted++;
            if(scarAccepted!=expectedAccepted)acceptedDifferent++;
            Check(nAccepted>M+1 && nAccepted<=M*M &&
                  expectedAccepted==nAccepted-1 &&
                  priorAccepted==expectedAccepted &&
                  scarAccepted==nAccepted &&
                  scarAccepted!=expectedAccepted,
                  "سؤال مقبول صحيح في n-1 يفسد إلى n بلا رفض");

            // الشاهد التاريخي لا يجب أن يغيّر إشارة الرفض: 1 للصعود وn للنزول.
            var high=M-1-first;
            var rejectStream=new AnswerStream(high,dir);
            var nReject=Wide(rejectStream)-1;
            var expectedReject=dir==1?BigInteger.One:nReject;
            var priorReject=previous.Patch(
                new LegacyBowlQuestionResult(high,dir),nReject);
            var scarReject=old.Carry(priorReject,nReject);
            rejected++;
            if(scarReject!=expectedReject)rejectedDifferent++;
            else rejectedEqual++;
            Check(nReject>M*M/2 && nReject<M*M &&
                  priorReject==expectedReject &&
                  scarReject==expectedReject &&
                  scarReject==Legacy(expectedReject,nReject),
                  "شاهد رفض لا تفسده ندبة الحمل قبل الأخيرة");
        }
        Check(controls==34560 &&
              controlDifferent+controlEqual==controls &&
              accepted==8640 && acceptedDifferent==8640 &&
              rejected==8640 && rejectedDifferent==0 && rejectedEqual==8640,
              "توقيع مرآة الرتبة قبل الأخيرة مستقل عن عطب الحارس والرفض");
    }

    private static void Boundaries()
    {
        var old=new LegacyPenultimateWideCarry();
        foreach(var n in new[]{M+1,2*M+1,M*M-1,M*M+1,(BigInteger.One<<8192)+M*M+1})
        foreach(var r in new[]{BigInteger.One,new BigInteger(2),n-2,n-1,n})
        {
            var historical=old.Carry(r,n);
            Check(historical==Legacy(r,n) &&
                  historical>=1 && historical<=n &&
                  (r==n-1 ? historical==n : historical==r),
                  "حدود المرتبة عند النقل 8192 بت");
        }
        Check(old.Carry(M,M+1)==old.Carry(M+1,M+1) &&
              old.Carry(M,M+1)==M+1,
              "الخلط القديم بين n-1 وn لا يسمح بعكس الشاهد وحده");
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            var denied=false;
            try{old.Carry(1,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض عائلة غير واسعة");
        }
        foreach(var r in new[]{BigInteger.Zero,new BigInteger(-1),M+2})
        {
            var denied=false;
            try{old.Carry(r,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض رتبة خارجة عن المجال");
        }
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        var sauce=NormativeScroll.Sauce(c,t);
        var manager=new MonsterManager();
        for(var id=1;id<=6;id++)
        for(var index=0;index<2;index++)
        {
            var seal=index==0?21:31;
            var stream=NormativeScroll.AskBowl(sauce,id,seal);
            var wide=Wide(stream);
            var reject=stream.DirectionStep==-1 && wide>M*M/2+1 && wide<M*M;
            var chosenPenultimate=!reject && id%2==0;
            var n=reject?wide-1:chosenPenultimate?wide+1:M+1;
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            var ctx=manager.ExecuteLegacyPenultimateWideCarry(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(ctx);
            production++;
            if(reject)realRejections++;
            if(chosenPenultimate)productionAccepted++;
            if(ctx.PatchedWideTerminalSentinelRankResult==expected)productionCorrect++;
            if(ctx.LegacyPenultimateWideCarryRankResult!=expected)productionDifferent++;
            else productionEqual++;
            Check(ctx.Status=="LEGACY_PENULTIMATE_WIDE_CARRY_COMPLETE" &&
                  ctx.Phase==ctx.Status && ctx.BranchTrace.Count==26 &&
                  ctx.BranchTrace[^2]=="PATCHED_WIDE_TERMINAL_SENTINEL" &&
                  ctx.BranchTrace[^1]=="LEGACY_PENULTIMATE_WIDE_CARRY" &&
                  ctx.Metrics["legacy.penultimate.wide.carry.dispatch"]==1 &&
                  ctx.Metrics["patched.wide.terminal.sentinel.dispatch"]==1 &&
                  ctx.Metrics["legacy.wide.terminal.sentinel.dispatch"]==1,
                  "الموزع القديم يستدعي جميع الرقع السابقة");
            Check(ctx.PatchedWideTerminalSentinelRankResult==expected &&
                  ctx.PatchedDescendingRankMirrorResult==expected &&
                  ctx.PatchedWideSlotTruncationRankResult==expected &&
                  ctx.LegacyPenultimateWideCarryRankResult==Legacy(expected,n) &&
                  (!chosenPenultimate || (expected==n-1 && ctx.LegacyPenultimateWideCarryRankResult==n)) &&
                  ctx.PatchedBowlQuestionResult is not null &&
                  ctx.PatchedBowlQuestionResult.First==stream.First &&
                  ctx.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  ctx.PatchedSauceFinalBowls is {Length:7} &&
                  ctx.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  ctx.PatchedOrderAt46Latch is {Length:6} &&
                  ctx.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
                  ctx.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(ctx.PatchedSauceFinalBowls,ctx.LegacySauceFinalBowls),
                  "نتيجة الرقعة الثالثة والعشرين والصلصة لا تتغيران");
        }
        publicReads++;
        var pubId=sample%6+1;
        var pubSeal=sample%2==0?31:21;
        var streamPub=NormativeScroll.AskBowl(sauce,pubId,pubSeal);
        var nPub=Wide(streamPub)+1;
        var correct=CalendarDateSpaghetti.EvaluateWideTerminalSentinel(
            c,t,pubId,pubSeal,nPub);
        var old=CalendarDateSpaghetti.EvaluateLegacyPenultimateWideCarry(
            c,t,pubId,pubSeal,nPub);
        Check(correct==NormativeScroll.ChooseRankWide(streamPub,nPub) &&
              correct==nPub-1 && old==nPub,
              "الواجهة العامة تبقي القديم والمصحح مستقلين");
    }

    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];
        var b=Contexts[1];
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var scar=b.LegacyPenultimateWideCarryRankResult;
        var prior=b.PatchedWideTerminalSentinelRankResult;
        var trace=b.BranchTrace.ToArray();
        a.PatchedSauceFinalBowls![1]=0;
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.Metrics,b.Metrics) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              b.PatchedSauceFinalBowls.SequenceEqual(saved) &&
              b.LegacyPenultimateWideCarryRankResult==scar &&
              b.PatchedWideTerminalSentinelRankResult==prior,
              "ملكيات مستقلة للسياق والصلصة");

        var dispatch=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var denied=false;
        try{dispatch.DispatchLegacyPenultimateWideCarry(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyPenultimateWideCarryRankResult==scar &&
              b.Metrics["legacy.penultimate.wide.carry.dispatch"]==1,
              "رفض الالتزام المكرر دون كتابة");

        var f=NormativeScroll.FoundationDay;
        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=0;
        ready.LegacyWideFamilySize=M*M-1;
        var candidate=new LegacyPenultimateWideCarryPhaseHandler().Handle(ready);
        var verifier=new MonsterValidationManager();
        verifier.ValidateLegacyPenultimateWideCarry(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyPenultimateWideCarryRankResult is null &&
              ready.PatchedWideTerminalSentinelRankResult is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "حالة المدقق لا تحفظ النتائج مبكراً");
        void Reject(LegacyPenultimateWideCarryCandidate forged,string reason)
        {
            var refused=false;
            try{verifier.ValidateLegacyPenultimateWideCarry(ready,forged);}
            catch(MonsterValidationException){refused=true;}
            Check(refused && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyPenultimateWideCarryRankResult is null &&
                  ready.PatchedWideTerminalSentinelRankResult is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض تزوير المرشح دون كتابة "+reason);
        }
        Reject(candidate with {Rank=0},"رتبة صفر");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير قيمة الحمل القديمة");
        Reject(candidate with {Previous=candidate.Previous with {Rank=0}},
               "إفساد الرقعة الثالثة والعشرين");
        Reject(candidate with {Previous=candidate.Previous with {
            Historical=candidate.Previous.Historical with {Rank=0}}},
               "إفساد الحارس السابق");

        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=M+1};
        denied=false;
        try{dispatch.DispatchLegacyPenultimateWideCarry(raw);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.LegacyPenultimateWideCarryRankResult is null,
              "رفض سياق غير مؤسس");
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyPenultimateWideCarry(f,f,1,21,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض حجم عائلة غير واسع");
        }
        foreach(var bowl in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyPenultimateWideCarry(f,f,bowl,21,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض وعاء غير صالح");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyPenultimateWideCarry(f,f,1,seal,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض ختم غير صالح");
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
        Console.WriteLine("حالات الضبط: "+controls);
        Console.WriteLine("الفروق في الضبط: "+controlDifferent);
        Console.WriteLine("مطابقات الضبط: "+controlEqual);
        Console.WriteLine("المرتبة قبل الأخيرة المقبولة: "+accepted);
        Console.WriteLine("اختلافات القبول بلا رفض: "+acceptedDifferent);
        Console.WriteLine("حالات الرفض: "+rejected);
        Console.WriteLine("اختلافات الرفض: "+rejectedDifferent);
        Console.WriteLine("مطابقات الرفض: "+rejectedEqual);
        Console.WriteLine("أسئلة الإنتاج: "+production);
        Console.WriteLine("الإنتاج السابق الصحيح: "+productionCorrect);
        Console.WriteLine("فروق الإنتاج التاريخية: "+productionDifferent);
        Console.WriteLine("مطابقات الإنتاج: "+productionEqual);
        Console.WriteLine("القبول المستهدف في الإنتاج: "+productionAccepted);
        Console.WriteLine("الرفض الفعلي في الإنتاج: "+realRejections);
        Console.WriteLine("قراءات الواجهة: "+publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+unexpected);
        var signature=unexpected==0 &&
                      controls==34560 && controlDifferent+controlEqual==controls &&
                      accepted==8640 && acceptedDifferent==8640 &&
                      rejected==8640 && rejectedDifferent==0 && rejectedEqual==8640 &&
                      production==96 && productionCorrect==96 &&
                      productionDifferent>=20 && productionEqual>=1 &&
                      productionDifferent+productionEqual==96 &&
                      productionAccepted>=20 && realRejections==28 &&
                      publicReads==8;
        if(verify)
        {
            Console.WriteLine("توقيع الأحمر المقصود للحمل قبل الأخير: "+(signature?"PASS":"FAIL"));
            return signature?0:1;
        }
        return unexpected==0 && acceptedDifferent==0 &&
               controlDifferent==0 && rejectedDifferent==0 &&
               productionDifferent==0 ? 0:1;
    }
}
