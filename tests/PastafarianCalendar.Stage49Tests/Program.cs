using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage49Tests;

internal static class Program
{
    private static int passed,failed,controls,controlGood,controlOldDifferent;
    private static int accepted,acceptedGood,acceptedOldDifferent;
    private static int rejected,rejectedGood,rejectedOldDifferent;
    private static int production,productionGood,productionOldDifferent,productionOldEqual;
    private static int productionAccepted,realRejections,publicReads;
    private static readonly List<MonsterContext> Contexts=new();
    private static BigInteger M=>NormativeScroll.M;
    private static BigInteger Legacy(BigInteger rank,BigInteger n)
        => rank==n-BigInteger.One?n:rank;
    private static BigInteger Wide(AnswerStream s)
        => s.First+(NormativeScroll.AnswerAt(s,BigInteger.One)-1)*M;

    private static void Check(bool ok,string name)
    {
        if(ok){passed++;return;}
        failed++;
        Console.WriteLine("إخفاق غير متوقع في الرقعة الرابعة والعشرين: "+name);
    }

    private static void Synthetic()
    {
        var previous=new WideDigitOrderPatchWrapper();
        var old=new LegacyPenultimateWideCarry();
        var patch=new PenultimateWideCarryPatchWrapper();
        var sizes=new[]{M+1,2*M+1,M*M-1,M*M+1};
        for(var index=1;index<=720;index++)
        for(var id=1;id<=6;id++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(index*6+id);
            var stream=new AnswerStream(first,direction);
            var question=new LegacyBowlQuestionResult(first,direction);
            foreach(var n in sizes)
            {
                controls++;
                var expected=NormativeScroll.ChooseRankWide(stream,n);
                var prior=previous.Patch(question,n);
                var scar=old.Carry(prior,n);
                var restored=patch.Restore(scar,prior,n);
                if(restored==expected)controlGood++;
                if(scar!=expected)controlOldDifferent++;
                Check(prior==expected && restored==expected &&
                      scar==Legacy(expected,n) && scar>=1 && scar<=n &&
                      (expected==n-1?scar==n:scar==expected),
                      "كل رتب التحكم الصحيحة والمخالفة التاريخية");
            }

            // نهاية قبل أخيرة مقبولة من الإجابة الأولى دون رفض.
            var nAccepted=Wide(stream)+1;
            var expectedAccepted=NormativeScroll.ChooseRankWide(stream,nAccepted);
            var priorAccepted=previous.Patch(question,nAccepted);
            var oldAccepted=old.Carry(priorAccepted,nAccepted);
            var restoredAccepted=patch.Restore(oldAccepted,priorAccepted,nAccepted);
            accepted++;
            if(restoredAccepted==expectedAccepted)acceptedGood++;
            if(oldAccepted!=expectedAccepted)acceptedOldDifferent++;
            Check(nAccepted>M+1 && nAccepted<=M*M &&
                  expectedAccepted==nAccepted-1 &&
                  priorAccepted==expectedAccepted &&
                  oldAccepted==nAccepted &&
                  restoredAccepted==nAccepted-1,
                  "استرجاع n-1 المقبولة مع بقاء شهادة الحمل القديمة");

            // رفض حقيقي في كلا الاتجاهين: الطور 48 لم يفسده.
            var high=M-1-first;
            var rejectStream=new AnswerStream(high,direction);
            var nRejected=Wide(rejectStream)-1;
            var expectedRejected=direction==1?BigInteger.One:nRejected;
            var priorRejected=previous.Patch(
                new LegacyBowlQuestionResult(high,direction),nRejected);
            var oldRejected=old.Carry(priorRejected,nRejected);
            var repairedRejected=patch.Restore(oldRejected,priorRejected,nRejected);
            rejected++;
            if(repairedRejected==expectedRejected)rejectedGood++;
            if(oldRejected!=expectedRejected)rejectedOldDifferent++;
            Check(nRejected>M*M/2 && nRejected<M*M &&
                  priorRejected==expectedRejected &&
                  oldRejected==expectedRejected &&
                  repairedRejected==expectedRejected,
                  "إصلاح الحمل لا يغير حالات الرفض الصحيحة");
        }
        Check(controls==34560 && controlGood==34560 &&
              controlOldDifferent==0 &&
              accepted==8640 && acceptedGood==8640 &&
              acceptedOldDifferent==8640 &&
              rejected==8640 && rejectedGood==8640 &&
              rejectedOldDifferent==0,
              "توقيع الرقعة الرابعة والعشرين يشمل القبول والرفض");
    }

    private static void Boundaries()
    {
        var old=new LegacyPenultimateWideCarry();
        var patch=new PenultimateWideCarryPatchWrapper();
        foreach(var n in new[]{M+1,2*M+1,M*M-1,M*M+1,(BigInteger.One<<8192)+M*M+1})
        foreach(var rank in new[]{BigInteger.One,new BigInteger(2),n-2,n-1,n})
        {
            var scar=old.Carry(rank,n);
            Check(scar==Legacy(rank,n) &&
                  patch.Restore(scar,rank,n)==rank &&
                  (rank==n-1?scar==n:scar==rank),
                  "كل الحدود حتى عرض 8192 بت");
        }
        Check(old.Carry(M,M+1)==old.Carry(M+1,M+1) &&
              patch.Restore(M+1,M,M+1)==M &&
              patch.Restore(M+1,M+1,M+1)==M+1,
              "شاهد واحد يقبل تفسيرين ولا يعكس دون الأصل");
        foreach(var triple in new (BigInteger Scar,BigInteger Rank,BigInteger N)[]{
            (0,1,M+1),(M+2,1,M+1),(1,0,M+1),(1,M+2,M+1),
            (1,1,M),(1,1,0),(1,1,-1),(M+1,M-1,M+1)
        })
        {
            var denied=false;
            try{patch.Restore(triple.Scar,triple.Rank,triple.N);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض شاهد تزوير أو قيمة خارج المجال");
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
            var reject=stream.DirectionStep==-1 && wide>M*M/2+1 && wide<M*M;
            var targeted=!reject && id%2==0;
            var n=reject?wide-1:targeted?wide+1:M+1;
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            var ctx=manager.ExecutePatchedPenultimateWideCarry(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(ctx);
            production++;
            if(reject)realRejections++;
            if(targeted)productionAccepted++;
            if(ctx.PatchedPenultimateWideCarryRankResult==expected)productionGood++;
            if(ctx.LegacyPenultimateWideCarryRankResult!=expected)productionOldDifferent++;
            else productionOldEqual++;

            Check(ctx.Status=="PATCHED_PENULTIMATE_WIDE_CARRY_COMPLETE" &&
                  ctx.Phase==ctx.Status && ctx.BranchTrace.Count==27 &&
                  ctx.BranchTrace[^2]=="LEGACY_PENULTIMATE_WIDE_CARRY" &&
                  ctx.BranchTrace[^1]=="PATCHED_PENULTIMATE_WIDE_CARRY" &&
                  ctx.Metrics["legacy.penultimate.wide.carry.dispatch"]==1 &&
                  ctx.Metrics["patched.penultimate.wide.carry.dispatch"]==1 &&
                  ctx.Metrics["patched.wide.terminal.sentinel.dispatch"]==1,
                  "خط التنفيذ الكامل متصل والرقعة وحدها أعادت الرتبة");
            Check(ctx.PatchedPenultimateWideCarryRankResult==expected &&
                  ctx.PatchedWideTerminalSentinelRankResult==expected &&
                  ctx.PatchedDescendingRankMirrorResult==expected &&
                  ctx.PatchedWideSlotTruncationRankResult==expected &&
                  ctx.LegacyPenultimateWideCarryRankResult==Legacy(expected,n) &&
                  (!targeted || (expected==n-1 && ctx.LegacyPenultimateWideCarryRankResult==n)) &&
                  ctx.PatchedBowlQuestionResult is not null &&
                  ctx.PatchedBowlQuestionResult.First==stream.First &&
                  ctx.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  ctx.PatchedSauceFinalBowls is {Length:7} &&
                  ctx.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  ctx.PatchedOrderAt46Latch is {Length:6} &&
                  ctx.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
                  ctx.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(ctx.PatchedSauceFinalBowls,ctx.LegacySauceFinalBowls),
                  "حفظ نتيجة المصدر والصلصة وشاهد الحمل المنفصل");
        }
        publicReads++;
        var idPublic=sample%6+1;
        var sealPublic=sample%2==0?31:21;
        var streamPublic=NormativeScroll.AskBowl(sauce,idPublic,sealPublic);
        var nPublic=Wide(streamPublic)+1;
        var corrected=CalendarDateSpaghetti.EvaluatePenultimateWideCarry(
            c,t,idPublic,sealPublic,nPublic);
        var historical=CalendarDateSpaghetti.EvaluateLegacyPenultimateWideCarry(
            c,t,idPublic,sealPublic,nPublic);
        Check(corrected==NormativeScroll.ChooseRankWide(streamPublic,nPublic) &&
              corrected==nPublic-1 && historical==nPublic,
              "الواجهة العامة الجديدة والحافظة للشاهد القديم");
    }

    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];
        var b=Contexts[1];
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var prior=b.PatchedWideTerminalSentinelRankResult;
        var scar=b.LegacyPenultimateWideCarryRankResult;
        var fixedRank=b.PatchedPenultimateWideCarryRankResult;
        var trace=b.BranchTrace.ToArray();
        a.PatchedSauceFinalBowls![1]=0;
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.Metrics,b.Metrics) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              b.PatchedSauceFinalBowls.SequenceEqual(saved) &&
              b.PatchedWideTerminalSentinelRankResult==prior &&
              b.LegacyPenultimateWideCarryRankResult==scar &&
              b.PatchedPenultimateWideCarryRankResult==fixedRank,
              "كل السياقات والنتائج متباينة الملكية");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var denied=false;
        try{dispatcher.DispatchPatchedPenultimateWideCarry(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.PatchedPenultimateWideCarryRankResult==fixedRank &&
              b.LegacyPenultimateWideCarryRankResult==scar &&
              b.Metrics["patched.penultimate.wide.carry.dispatch"]==1,
              "منع إعادة الالتزام من دون أثر جانبي");

        var foundation=NormativeScroll.FoundationDay;
        var ready=new MonsterManager().Prepare(foundation,foundation);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=0;
        ready.LegacyWideFamilySize=M*M-1;
        var candidate=new PatchedPenultimateWideCarryPhaseHandler().Handle(ready);
        var validator=new MonsterValidationManager();
        validator.ValidatePatchedPenultimateWideCarry(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedPenultimateWideCarryRankResult is null &&
              ready.LegacyPenultimateWideCarryRankResult is null &&
              ready.PatchedWideTerminalSentinelRankResult is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق من المرشحين لا يلزم السياق");
        void Reject(PatchedPenultimateWideCarryCandidate forged,string why)
        {
            var refused=false;
            try{validator.ValidatePatchedPenultimateWideCarry(ready,forged);}
            catch(MonsterValidationException){refused=true;}
            Check(refused && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedPenultimateWideCarryRankResult is null &&
                  ready.LegacyPenultimateWideCarryRankResult is null &&
                  ready.PatchedWideTerminalSentinelRankResult is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض شهادة مزورة قبل الكتابة "+why);
        }
        Reject(candidate with {Rank=0},"المرتبة صفر");
        Reject(candidate with {Rank=candidate.Rank+1},"الرتبة المصححة مختلفة");
        Reject(candidate with {Historical=candidate.Historical with {Rank=0}},
               "إفساد شاهد الحمل");
        Reject(candidate with {Historical=candidate.Historical with {
            Previous=candidate.Historical.Previous with {Rank=0}}},
            "إفساد الرقعة الثالثة والعشرين");
        Reject(candidate with {Historical=candidate.Historical with {
            Previous=candidate.Historical.Previous with {
                Historical=candidate.Historical.Previous.Historical with {Rank=0}}}},
            "إفساد شاهد الحارس قبل الرقعة");

        var raw=new MonsterContext(foundation,foundation){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=M+1};
        denied=false;
        try{dispatcher.DispatchPatchedPenultimateWideCarry(raw);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.PatchedPenultimateWideCarryRankResult is null,
              "منع الاستخدام دون التأسيس");
        foreach(var n in new[]{BigInteger.Zero,BigInteger.One,M})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedPenultimateWideCarry(foundation,foundation,1,21,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض أسرة ليست واسعة");
        }
        foreach(var bowl in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedPenultimateWideCarry(foundation,foundation,bowl,21,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض وعاء غير قانوني");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedPenultimateWideCarry(foundation,foundation,1,seal,M+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض ختم غير قانوني");
        }
    }

    // حراسة نصوص التشخيص العربية من التلف والترميز والتحكم الخفي بالاتجاه.
    private static void UnicodeRtlDiagnostics()
    {
        static bool ValidArabicDiagnostic(string? message)
        {
            if(message is null || !message.IsNormalized(System.Text.NormalizationForm.FormC) ||
               message.Contains('\uFFFD'))
                return false;
            foreach(var symbol in message)
            {
                if(char.IsSurrogate(symbol) ||
                   symbol is '\u061C' or '\u200E' or '\u200F' or '\uFEFF' ||
                   (symbol>='\u202A' && symbol<='\u202E') ||
                   (symbol>='\u2066' && symbol<='\u2069'))
                    return false;
            }
            return System.Text.Encoding.UTF8.GetString(
                System.Text.Encoding.UTF8.GetBytes(message))==message;
        }

        var wrapper=new PenultimateWideCarryPatchWrapper();
        string? invalidRange=null;
        try{wrapper.Restore(BigInteger.Zero,BigInteger.One,M+1);}
        catch(MonsterValidationException ex){invalidRange=ex.Message;}
        Check(invalidRange=="معطيات تصحيح الحمل قبل الأخير غير صالحة." &&
              ValidArabicDiagnostic(invalidRange),
              "سلامة Unicode وRTL في رسالة رفض المرتبة خارج المجال");

        string? forgedWitness=null;
        try{wrapper.Restore(BigInteger.One,new BigInteger(2),M+1);}
        catch(MonsterValidationException ex){forgedWitness=ex.Message;}
        Check(forgedWitness=="شاهد الحمل لا يطابق مرتبة الرقعة الثالثة والعشرين." &&
              ValidArabicDiagnostic(forgedWitness),
              "سلامة Unicode وRTL في رسالة رفض شاهد الحمل المزوّر");

        string? invalidFamily=null;
        try{new MonsterManager().ExecutePatchedPenultimateWideCarry(
            NormativeScroll.FoundationDay,NormativeScroll.FoundationDay,1,21,M);}
        catch(MonsterValidationException ex){invalidFamily=ex.Message;}
        Check(invalidFamily=="مدخلات الأسرة الواسعة غير صالحة." &&
              ValidArabicDiagnostic(invalidFamily),
              "سلامة Unicode وRTL في رسالة رفض الأسرة غير الواسعة");

        Check(Console.OutputEncoding.WebName=="utf-8",
              "إخراج نتائج الاختبار بترميز UTF-8");
    }

    public static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        Synthetic();
        Boundaries();
        var foundation=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var dates=new (BigInteger C,BigInteger T)[]{
            (foundation,foundation),(foundation-1,foundation+1),
            (foundation+1,foundation-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,foundation),
            (huge,-huge),(-huge+foundation,huge+foundation)
        };
        for(var i=0;i<dates.Length;i++)Production(dates[i].C,dates[i].T,i+1);
        ValidationAndOwnership();
        UnicodeRtlDiagnostics();
        Console.WriteLine("حالات الضبط: "+controls);
        Console.WriteLine("نتائج الضبط المصححة: "+controlGood);
        Console.WriteLine("فروق الضبط التاريخية: "+controlOldDifferent);
        Console.WriteLine("القبول بلا رفض: "+accepted);
        Console.WriteLine("القبول المصحح: "+acceptedGood);
        Console.WriteLine("فروق القبول القديمة: "+acceptedOldDifferent);
        Console.WriteLine("حالات الرفض: "+rejected);
        Console.WriteLine("الرفض المصحح: "+rejectedGood);
        Console.WriteLine("فروق الرفض القديمة: "+rejectedOldDifferent);
        Console.WriteLine("الإنتاج: "+production);
        Console.WriteLine("الإنتاج المصحح: "+productionGood);
        Console.WriteLine("الانحرافات القديمة في الإنتاج: "+productionOldDifferent);
        Console.WriteLine("مطابقات الإنتاج القديمة: "+productionOldEqual);
        Console.WriteLine("القبول المستهدف الإنتاجي: "+productionAccepted);
        Console.WriteLine("الرفض الفعلي: "+realRejections);
        Console.WriteLine("الواجهات العامة: "+publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+failed);
        return failed==0 &&
               controls==34560 && controlGood==34560 && controlOldDifferent==0 &&
               accepted==8640 && acceptedGood==8640 && acceptedOldDifferent==8640 &&
               rejected==8640 && rejectedGood==8640 && rejectedOldDifferent==0 &&
               production==96 && productionGood==96 &&
               productionOldDifferent==34 && productionOldEqual==62 &&
               productionAccepted==34 && realRejections==28 &&
               publicReads==8?0:1;
    }
}
