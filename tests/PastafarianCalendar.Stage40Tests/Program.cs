using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage40Tests;

internal static partial class Program
{
    private static int _passed,_unexpected,_controls,_controlCorrect,_controlDifferent;
    private static int _rejections,_rejectionCorrect,_rejectionDifferent,_ascending,_descending;
    private static int _sauces,_production,_productionCorrect,_productionDifferent,_realRejections,_publicReads;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string message)
    {
        if(ok){_passed++;return;}
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة في اكتشاف انحياز الخانة العليا: "+message);
    }

    private static BigInteger[] Sizes()
    {
        var m=NormativeScroll.M;
        return new BigInteger[]{m+1,2*m+1,m*m-1,m*m+1};
    }

    private static BigInteger HighWeight(BigInteger size)
    {
        var m=NormativeScroll.M;
        var space=m;var high=BigInteger.One;
        while(space<size){high=space;space*=m;}
        return high;
    }

    private static BigInteger Wide(AnswerStream stream)
        => stream.First+(NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*NormativeScroll.M;

    private static BigInteger ExpectedHistorical(BigInteger correct,BigInteger size)
        => BigInteger.One+(correct-BigInteger.One+HighWeight(size))%size;

    private static void Synthetic()
    {
        var m=NormativeScroll.M;
        var previous=new WideDigitOrderPatchWrapper();
        var legacy=new LegacyUpperPlaceBias();
        for(var rank=1;rank<=720;rank++)
        for(var id=1;id<=6;id++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+id);
            var normal=new AnswerStream(first,direction);
            var source=new LegacyBowlQuestionResult(first,direction);
            foreach(var size in Sizes())
            {
                _controls++;
                var expected=NormativeScroll.ChooseRankWide(normal,size);
                var prior=previous.Patch(source,size);
                var actual=legacy.Shift(prior,size);
                if(prior==expected)_controlCorrect++;
                if(actual!=expected)_controlDifferent++;
                Check(prior==expected,"الرتبة المعتمدة سابقاً لم تتغير");
                Check(actual==ExpectedHistorical(expected,size) && actual!=expected &&
                      actual>=1 && actual<=size,
                      "وزن الخانة العليا مضاف دون تزييف النطاق");
                Check(HighWeight(size)<size && HighWeight(size)>0,
                      "وزن الخانة أقل من حجم الأسرة");
            }
            // لا يمسّ هذا الخطأ اتجاه الرفض أو الخطوة الصفرية.
            var high=m-1-first;
            var rejectedStream=new AnswerStream(high,direction);
            var rejectedSource=new LegacyBowlQuestionResult(high,direction);
            var nReject=Wide(rejectedStream)-1;
            _rejections++;
            // الحدّ nReject=wide-1، وهو أكبر من نصف M²؛ لذلك لا توجد
            // إلا قفزة واحدة مقبولة: صعوداً إلى 1 أو هبوطاً إلى nReject.
            // المرجع التكراري سينفّذ نحو M خطوة في الاتجاه الموجب.
            var correctRejected=direction==1?BigInteger.One:nReject;
            var priorRejected=previous.Patch(rejectedSource,nReject);
            var actualRejected=legacy.Shift(priorRejected,nReject);
            if(correctRejected==priorRejected)_rejectionCorrect++;
            if(actualRejected!=correctRejected)_rejectionDifferent++;
            if(direction==1 && correctRejected==1)_ascending++;
            if(direction==-1 && correctRejected==nReject)_descending++;
            Check(nReject>m*m/2 && nReject<m*m &&
                  priorRejected==correctRejected,
                  "شاهد رفض حقيقي من الاتجاهين محفوظ");
            Check(actualRejected==ExpectedHistorical(correctRejected,nReject) &&
                  actualRejected!=correctRejected &&
                  actualRejected>=1 && actualRejected<=nReject,
                  "العيب في ترتيب خانة الخرج، لا في رفض الإجابة");
        }
        Check(_controls==34560 && _controlCorrect==34560 &&
              _controlDifferent==34560 && _rejections==8640 &&
              _rejectionCorrect==8640 && _rejectionDifferent==8640 &&
              _ascending==4320 && _descending==4320,
              "توقيع الخطأ العشرين المستقل في 43200 حالة");
    }

    private static void Boundaries()
    {
        var m=NormativeScroll.M;
        var legacy=new LegacyUpperPlaceBias();
        foreach(var n in new BigInteger[]{m+1,m*m-1,m*m+1,
                                          (BigInteger.One<<8192)+m*m+1})
        {
            var high=HighWeight(n);
            Check(high<n && high>0 && legacy.Shift(1,n)==1+high,
                  "الانزياح عند الرتبة الأولى مع عائلات واسعة جداً");
            Check(legacy.Shift(n,n)==high &&
                  legacy.Shift(n-high+1,n)==BigInteger.One,
                  "انتقال النتيجة القديمة دورياً عبر آخر مرتبة");
            Check(legacy.Shift(n,n)!=n,"الشاهد القديم غير مصحّح");
        }
        var safeN=(BigInteger.One<<8192)+m*m+1;
        var safe=new AnswerStream(BigInteger.One,1);
        var prior=new WideDigitOrderPatchWrapper().Patch(
            new LegacyBowlQuestionResult(BigInteger.One,1),safeN);
        Check(prior==NormativeScroll.ChooseRankWide(safe,safeN) &&
              legacy.Shift(prior,safeN)==ExpectedHistorical(prior,safeN),
              "مرجع مستقل للأسرة ذات 8192 بت دون رفض متكرر فلكي");
    }

    private static void Production(BigInteger c,BigInteger t,int sample)
    {
        _sauces++;
        var sauce=NormativeScroll.Sauce(c,t);
        var manager=new MonsterManager();
        var m=NormativeScroll.M;
        for(var id=1;id<=6;id++)
        for(var sealIndex=0;sealIndex<2;sealIndex++)
        {
            var seal=sealIndex==0?21:31;
            var stream=NormativeScroll.AskBowl(sauce,id,seal);
            var wide=Wide(stream);
            var rejects=stream.DirectionStep==-1 &&
                        wide>m*m/2+1 && wide<m*m;
            var n=rejects?wide-1:m+1;
            var expected=NormativeScroll.ChooseRankWide(stream,n);
            var ctx=manager.ExecuteLegacyUpperPlaceBias(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(ctx);
            _production++;
            if(rejects)_realRejections++;
            if(ctx.PatchedDoubleOffsetWideRankResult==expected)_productionCorrect++;
            if(ctx.LegacyUpperPlaceBiasRankResult!=expected)_productionDifferent++;
            Check(ctx.Status=="LEGACY_UPPER_PLACE_BIAS_COMPLETE" &&
                  ctx.Phase==ctx.Status &&
                  ctx.BranchTrace.SequenceEqual(new[]{
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
                      "PATCHED_INCLUSIVE_WIDE_LIMIT_WITNESS",
                      "LEGACY_WIDE_REJECTION_DIRECTION_WITNESS",
                      "PATCHED_REJECTION_DIRECTION_WITNESS",
                      "LEGACY_DOUBLE_OFFSET_WIDE_RANK_WITNESS",
                      "PATCHED_DOUBLE_OFFSET_WIDE_RANK_WITNESS",
                      "LEGACY_UPPER_PLACE_BIAS"}) &&
                  ctx.Metrics["legacy.upper.place.bias.dispatch"]==1 &&
                  ctx.Metrics["patched.double.offset.wide.rank.dispatch"]==1,
                  "موزّع الاكتشاف العشرين يعمل عبر السلسلة كاملة");
            Check(ctx.PatchedDoubleOffsetWideRankResult==expected &&
                  ctx.LegacyUpperPlaceBiasRankResult==ExpectedHistorical(expected,n) &&
                  ctx.LegacyUpperPlaceBiasRankResult!=expected &&
                  ctx.LegacyWideFamilySize==n,
                  "الجواب المعياري صحيح والشاهد القديم منحرف وحده");
            Check(ctx.PatchedBowlQuestionResult is not null &&
                  ctx.PatchedBowlQuestionResult.First==stream.First &&
                  ctx.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  ctx.PatchedAnswerAtResult==stream.First &&
                  ctx.PatchedNextBowlResult==
                      NormativeScroll.NextBowlInDrop46Order(sauce,id),
                  "الصلصة والسؤال والخطوة الأولى لم تتأثر");
            Check(ctx.PatchedSauceFinalBowls is {Length:7} &&
                  ctx.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  ctx.PatchedOrderAt46Latch is {Length:6} &&
                  ctx.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
                  ctx.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(ctx.LegacySauceFinalBowls,ctx.PatchedSauceFinalBowls),
                  "الملكية المستقلة لترتيب القطرة السادسة والأربعين");
        }
        _publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var streamPublic=NormativeScroll.AskBowl(sauce,publicId,publicSeal);
        var nPublic=m+1;
        var good=CalendarDateSpaghetti.EvaluateDoubleOffsetWideRank(
            c,t,publicId,publicSeal,nPublic);
        var old=CalendarDateSpaghetti.EvaluateLegacyUpperPlaceBias(
            c,t,publicId,publicSeal,nPublic);
        Check(good==NormativeScroll.ChooseRankWide(streamPublic,nPublic) &&
              old==ExpectedHistorical(good,nPublic) && good!=old,
              "الواجهة العامة القديمة منفصلة عن النتيجة المصححة");
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verify=args.Length==1 && args[0]=="--verify-expected-red";
        if(args.Length!=0&&!verify)return 2;
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

        Console.WriteLine("الحالات الضابطة: "+_controls);
        Console.WriteLine("مطابقات الرقعة السابقة: "+_controlCorrect);
        Console.WriteLine("المخالفات التاريخية الضابطة: "+_controlDifferent);
        Console.WriteLine("حالات الرفض: "+_rejections);
        Console.WriteLine("مطابقات الرقعة السابقة عند الرفض: "+_rejectionCorrect);
        Console.WriteLine("المخالفات التاريخية عند الرفض: "+_rejectionDifferent);
        Console.WriteLine("الصلصات الحقيقية: "+_sauces);
        Console.WriteLine("أسئلة الإنتاج: "+_production);
        Console.WriteLine("الشواهد التاريخية المخالفة في الإنتاج: "+_productionDifferent);
        Console.WriteLine("النتائج المعيارية الصحيحة في الإنتاج: "+_productionCorrect);
        Console.WriteLine("حالات رفض حقيقية: "+_realRejections);
        Console.WriteLine("قراءات الواجهة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        var ok=_unexpected==0 && _controls==34560 &&
               _controlCorrect==34560 && _controlDifferent==34560 &&
               _rejections==8640 && _rejectionCorrect==8640 &&
               _rejectionDifferent==8640 && _ascending==4320 && _descending==4320 &&
               _sauces==8 && _production==96 && _productionCorrect==96 &&
               _productionDifferent==96 && _realRejections==28 &&
               _publicReads==8;
        if(verify)
        {
            Console.WriteLine("التحقق من الأحمر المقصود في وزن الخانة العليا: "+(ok?"PASS":"FAIL"));
            return ok?0:1;
        }
        return _unexpected==0 && _controlDifferent==0 && _rejectionDifferent==0?0:1;
    }
}
