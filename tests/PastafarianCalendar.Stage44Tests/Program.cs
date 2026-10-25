using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage44Tests;

internal static class Program
{
    private static int _passed,_unexpected;
    private static int _controls,_controlDifferent,_controlEqual,_rejections,_rejectionDifferent,_rejectionEqual;
    private static int _production,_productionDifferent,_productionEqual,_productionCorrect,_realRejections,_publicReads;
    private static readonly List<MonsterContext> Contexts=new();
    private static BigInteger M=>NormativeScroll.M;

    private static void Check(bool ok,string reason)
    {
        if(ok){_passed++;return;}
        _unexpected++;
        Console.WriteLine("إخفاق غير متوقع في اكتشاف مرآة الاتجاه: "+reason);
    }
    private static BigInteger Old(BigInteger rank,BigInteger n,int dir)
        => dir==-1?n+BigInteger.One-rank:rank;
    private static BigInteger Wide(AnswerStream stream)
        => stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*M;

    private static void Synthetic()
    {
        var old=new LegacyDescendingRankMirror();
        var previous=new WideDigitOrderPatchWrapper();
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
                _controls++;
                var correct=NormativeScroll.ChooseRankWide(stream,n);
                var previousRank=previous.Patch(source,n);
                var historical=old.Reflect(previousRank,n,dir);
                if(historical!=correct)_controlDifferent++;
                else _controlEqual++;
                Check(previousRank==correct && historical==Old(correct,n,dir) &&
                      historical>=1 && historical<=n &&
                      (dir==1?historical==correct:historical!=correct),
                      "تحكم: الانعكاس يقع في إخراج الرتبة لا في جواب السؤال");
            }

            var high=M-1-first;
            var rejectedStream=new AnswerStream(high,dir);
            var nRejected=Wide(rejectedStream)-1;
            var expected=dir==1?BigInteger.One:nRejected;
            var previousRankRejected=previous.Patch(
                new LegacyBowlQuestionResult(high,dir),nRejected);
            var historicalRejected=old.Reflect(previousRankRejected,nRejected,dir);
            _rejections++;
            if(historicalRejected!=expected)_rejectionDifferent++;
            else _rejectionEqual++;
            Check(nRejected>M*M/2 && nRejected<M*M &&
                  previousRankRejected==expected &&
                  historicalRejected==Old(expected,nRejected,dir) &&
                  (dir==1?historicalRejected==BigInteger.One:
                          historicalRejected==BigInteger.One &&
                          historicalRejected!=expected),
                  "تحكم الرفض المستقل: الانعكاس لا يُخترع في اتجاه التيار");
        }
        Check(_controls==34560 && _controlDifferent==17280 &&
              _controlEqual==17280 && _rejections==8640 &&
              _rejectionDifferent==4320 && _rejectionEqual==4320,
              "التوقيع التركيبي للمرآة النازلة");
    }

    private static void Boundaries()
    {
        var old=new LegacyDescendingRankMirror();
        foreach(var n in new[]{M+1,2*M+1,M*M-1,M*M+1,(BigInteger.One<<8192)+M*M+1})
        foreach(var rank in new[]{BigInteger.One,new BigInteger(2),n-1,n})
        foreach(var direction in new[]{-1,1})
        {
            var historical=old.Reflect(rank,n,direction);
            Check(historical==Old(rank,n,direction) &&
                  historical>=1 && historical<=n &&
                  (direction==1?historical==rank:historical!=rank),
                  "الحدود الأولى والأخيرة للرتبة بما فيها 8192 بت");
        }
        var odd=2*M+1;
        var center=M+1;
        Check(old.Reflect(center,odd,-1)==center &&
              old.Reflect(center,odd,1)==center,
              "استثناء الرتبة الوسطى الثابتة في الأسرة الفردية");
        foreach(var (rank,n,dir) in new (BigInteger R,BigInteger N,int D)[]{
            (1,M,-1), (0,M+1,-1), (-1,M+1,1), (M+2,M+1,1),
            (1,M+1,0),(1,M+1,2),(1,M+1,-2)
        })
        {
            var denied=false;
            try{old.Reflect(rank,n,dir);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض مرتبة أو اتجاه غير قانونيين");
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
            var context=manager.ExecuteLegacyDescendingRankMirror(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            _production++;
            if(reject)_realRejections++;
            if(context.PatchedWideSlotTruncationRankResult==correct)_productionCorrect++;
            if(context.LegacyDescendingRankMirrorResult!=correct)_productionDifferent++;
            else _productionEqual++;
            Check(context.Status=="LEGACY_DESCENDING_RANK_MIRROR_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.Count==22 &&
                  context.BranchTrace[^2]=="PATCHED_WIDE_SLOT_TRUNCATION" &&
                  context.BranchTrace[^1]=="LEGACY_DESCENDING_RANK_MIRROR" &&
                  context.Metrics["patched.wide.slot.truncation.dispatch"]==1 &&
                  context.Metrics["legacy.descending.rank.mirror.dispatch"]==1,
                  "سلسلة الموزع الجديدة تحفظ شاهد اتجاه الخرج");
            Check(context.PatchedWideSlotTruncationRankResult==correct &&
                  context.PatchedUpperPlaceBiasRankResult==correct &&
                  context.PatchedDoubleOffsetWideRankResult==correct &&
                  context.LegacyDescendingRankMirrorResult==
                      Old(correct,n,stream.DirectionStep) &&
                  context.PatchedBowlQuestionResult is not null &&
                  context.PatchedBowlQuestionResult.First==stream.First &&
                  context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46),
                  "الصلصة والسؤال والرتبة الصحيحة لم تتغير");
        }
        _publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var publicStream=NormativeScroll.AskBowl(sauce,publicId,publicSeal);
        var publicN=M*M-1;
        var good=CalendarDateSpaghetti.EvaluateWideSlotTruncation(
            c,t,publicId,publicSeal,publicN);
        var old=CalendarDateSpaghetti.EvaluateLegacyDescendingRankMirror(
            c,t,publicId,publicSeal,publicN);
        Check(good==NormativeScroll.ChooseRankWide(publicStream,publicN) &&
              old==Old(good,publicN,publicStream.DirectionStep),
              "الواجهتان العامتان مستقلتان");
    }

    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];var b=Contexts[1];
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var rank=b.LegacyDescendingRankMirrorResult;
        var previous=b.PatchedWideSlotTruncationRankResult;
        var trace=b.BranchTrace.ToArray();
        a.PatchedSauceFinalBowls![1]=0;
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.Metrics,b.Metrics) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              b.PatchedSauceFinalBowls.SequenceEqual(saved) &&
              b.LegacyDescendingRankMirrorResult==rank &&
              b.PatchedWideSlotTruncationRankResult==previous,
              "لا تتسرّب البيانات بين الاستدعاءات");

        var dispatch=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var refused=false;
        try{dispatch.DispatchLegacyDescendingRankMirror(b);}
        catch(MonsterValidationException){refused=true;}
        Check(refused && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyDescendingRankMirrorResult==rank &&
              b.Metrics["legacy.descending.rank.mirror.dispatch"]==1,
              "الرفض الذري للاستدعاء المكرر");

        var f=NormativeScroll.FoundationDay;
        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=0;
        ready.LegacyWideFamilySize=M*M-1;
        var candidate=new LegacyDescendingRankMirrorPhaseHandler().Handle(ready);
        var verifier=new MonsterValidationManager();
        verifier.ValidateLegacyDescendingRankMirror(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyDescendingRankMirrorResult is null &&
              ready.PatchedWideSlotTruncationRankResult is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق الكامل قبل الالتزام");

        void Reject(LegacyDescendingRankMirrorCandidate forged,string reason)
        {
            var denied=false;
            try{verifier.ValidateLegacyDescendingRankMirror(ready,forged);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyDescendingRankMirrorResult is null &&
                  ready.PatchedWideSlotTruncationRankResult is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض التزوير دون كتابة: "+reason);
        }
        Reject(candidate with {Rank=0},"صفر");
        Reject(candidate with {Rank=candidate.Rank+1},"تعديل رتبة المرآة");
        Reject(candidate with {Direction=-candidate.Direction},"تزوير الاتجاه");
        Reject(candidate with {Previous=candidate.Previous with {Rank=0}},
               "محو شاهد الرقعة الحادية والعشرين");
        Reject(candidate with {Previous=candidate.Previous with {
            Historical=candidate.Previous.Historical with {Rank=0}}},
            "تغيير شاهد القطع");

        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=M+1};
        refused=false;
        try{dispatch.DispatchLegacyDescendingRankMirror(raw);}
        catch(MonsterValidationException){refused=true;}
        Check(refused && raw.Status=="NEW" && raw.BranchTrace.Count==0,
              "رفض سياق غير مؤسس");
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            refused=false;
            try{new MonsterManager().ExecuteLegacyDescendingRankMirror(f,f,1,21,n);}
            catch(MonsterValidationException){refused=true;}
            Check(refused,"رفض أسرة غير واسعة");
        }
        foreach(var id in new[]{-1,0,7})
        {
            refused=false;
            try{new MonsterManager().ExecuteLegacyDescendingRankMirror(f,f,id,21,M+1);}
            catch(MonsterValidationException){refused=true;}
            Check(refused,"رفض وعاء غير قانوني");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            refused=false;
            try{new MonsterManager().ExecuteLegacyDescendingRankMirror(f,f,1,seal,M+1);}
            catch(MonsterValidationException){refused=true;}
            Check(refused,"رفض ختم غير قانوني");
        }
    }

    public static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verifier=args.Length==1 && args[0]=="--verify-expected-red";
        if(args.Length!=0 && !verifier)return 2;
        Synthetic();
        Boundaries();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var dates=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<dates.Length;i++)Production(dates[i].C,dates[i].T,i+1);
        if(verifier)ValidationAndOwnership();
        Console.WriteLine("حالات التحكم: "+_controls);
        Console.WriteLine("اختلافات التحكم التاريخية: "+_controlDifferent);
        Console.WriteLine("مطابقات التحكم: "+_controlEqual);
        Console.WriteLine("حالات الرفض: "+_rejections);
        Console.WriteLine("اختلافات الرفض التاريخية: "+_rejectionDifferent);
        Console.WriteLine("مطابقات الرفض: "+_rejectionEqual);
        Console.WriteLine("قراءات الإنتاج: "+_production);
        Console.WriteLine("الإنتاج الصحيح السابق: "+_productionCorrect);
        Console.WriteLine("الاختلافات التاريخية الإنتاجية: "+_productionDifferent);
        Console.WriteLine("مطابقات الإنتاج: "+_productionEqual);
        Console.WriteLine("الرفض الإنتاجي الحقيقي: "+_realRejections);
        Console.WriteLine("قراءات الواجهة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);

        var passed=_unexpected==0 &&
                   _controls==34560 && _controlDifferent==17280 &&
                   _controlEqual==17280 && _rejections==8640 &&
                   _rejectionDifferent==4320 && _rejectionEqual==4320 &&
                   _production==96 && _productionCorrect==96 &&
                   _productionDifferent>=28 && _productionEqual>=1 &&
                   _productionDifferent+_productionEqual==96 &&
                   _realRejections==28 && _publicReads==8;
        if(verifier)
        {
            Console.WriteLine("توقيع الأحمر المقصود لمرآة الاتجاه: "+(passed?"PASS":"FAIL"));
            return passed?0:1;
        }
        return _unexpected==0 && _controlDifferent==0 &&
               _rejectionDifferent==0 && _productionDifferent==0?0:1;
    }
}
