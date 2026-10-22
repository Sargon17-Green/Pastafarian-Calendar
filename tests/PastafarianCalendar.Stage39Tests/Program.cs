using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage39Tests;

internal static partial class Program
{
    private static int _pass,_unexpected,_controls,_controlDifferent;
    private static int _rejections,_rejectionDifferent,_ascending,_descending;
    private static int _sauces,_production,_productionDifferent,_realRejections,_publicReads;
    private static int _correctControls,_correctRejections,_productionCorrect;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string name)
    {
        if(ok){_pass++;return;}
        _unexpected++;
        Console.WriteLine("إخفاق غير متوقع في اكتشاف إزاحة الخرج التاسعة عشرة: "+name);
    }

    private static BigInteger[] Sizes()
    {
        var m=NormativeScroll.M;
        return new BigInteger[]{m+1,2*m+1,m*m-1,m*m+1};
    }

    private static BigInteger Wide(AnswerStream stream)
        => stream.First+
            (NormativeScroll.AnswerAt(stream,BigInteger.One)-1)*NormativeScroll.M;

    private static BigInteger LegacyShift(BigInteger correct,BigInteger n)
        => correct==n?BigInteger.One:correct+BigInteger.One;

    private static void Synthetic()
    {
        var m=NormativeScroll.M;
        var corrected=new WideDigitOrderPatchWrapper();
        var offsetPatch=new DoubleOffsetWideRankPatchWrapper();
        for(var rank=1;rank<=720;rank++)
        for(var id=1;id<=6;id++)
        foreach(var direction in new[]{-1,1})
        {
            var first=new BigInteger(rank*6+id);
            var norm=new AnswerStream(first,direction);
            var source=new LegacyBowlQuestionResult(first,direction);
            foreach(var n in Sizes())
            {
                _controls++;
                var expected=NormativeScroll.ChooseRankWide(norm,n);
                var prior=corrected.Patch(source,n);
                var old=LegacyShift(prior,n);
                var fixedRank=offsetPatch.RotateBack(old,n);
                if(fixedRank==expected)_correctControls++;
                if(old!=expected)_controlDifferent++;
                Check(prior==expected && prior>=1 && prior<=n,
                    "الترتيب والقبول المصححان قبل الإزاحة "+rank+"/"+id+"/"+n);
                Check(fixedRank==expected && old>=1 && old<=n && old!=expected &&
                      old==BigInteger.One+(expected%n),
                    "الزيادة الثانية في النطاق الواسع "+rank+"/"+id+"/"+n);
            }

            // إسقاط عينة القبول ثم رفضها: يبقى المسار الصحيح ذو اتجاه ±1.
            var high=m-1-first;
            var rejectStream=new AnswerStream(high,direction);
            var rejectSource=new LegacyBowlQuestionResult(high,direction);
            var nReject=Wide(rejectStream)-1;
            _rejections++;
            Check(nReject>m*m/2 && nReject<m*m,
                "صناعة منطقة رفض آمنة ومحددة بخانتين");
            var trueRank=direction==1?BigInteger.One:nReject;
            var priorRank=corrected.Patch(rejectSource,nReject);
            var historical=LegacyShift(priorRank,nReject);
            var restored=offsetPatch.RotateBack(historical,nReject);
            if(restored==trueRank)_correctRejections++;
            if(historical!=trueRank)_rejectionDifferent++;
            if(direction==1 && historical==2)_ascending++;
            if(direction==-1 && historical==1)_descending++;
            Check(restored==trueRank && priorRank==trueRank &&
                  historical==(direction==1?new BigInteger(2):BigInteger.One) &&
                  historical!=trueRank,
                "لا تُعاد ندبة اتجاه الرفض؛ الخطأ في الخرج وحده");
        }
        Check(_controls==34560 && _controlDifferent==34560 &&
              _correctControls==34560 && _correctRejections==8640 &&
              _rejections==8640 && _rejectionDifferent==8640 &&
              _ascending==4320 && _descending==4320,
              "التوقيع الاصطناعي الكامل للفصل بين الدفق والإخراج");
    }

    private static void Boundaries()
    {
        var m=NormativeScroll.M;
        var offsetPatch=new DoubleOffsetWideRankPatchWrapper();
        foreach(var n in new BigInteger[]{m+1,m*m-1,m*m+1,(BigInteger.One<<8192)+m*m+1})
        {
            Check(offsetPatch.RotateBack(2,n)==1 &&
                  offsetPatch.RotateBack(1,n)==n &&
                  offsetPatch.RotateBack(n,n)==n-1 &&
                  LegacyShift(BigInteger.One,n)==2 &&
                  LegacyShift(n-1,n)==n && LegacyShift(n,n)==1 &&
                  LegacyShift(BigInteger.One,n)!=BigInteger.One,
                  "دوران الإزاحة التاريخية عند أول وآخر رتبة بما فيها حجم 8192 بت");
        }
        // لا يُطلَب من المرجع التكراري عبور منطقة رفض فلكية.
        var safeStream=new AnswerStream(BigInteger.One,1);
        var safeN=(BigInteger.One<<8192)+m*m+1;
        var prior=new WideDigitOrderPatchWrapper().Patch(
            new LegacyBowlQuestionResult(1,1),safeN);
        Check(prior==NormativeScroll.ChooseRankWide(safeStream,safeN) &&
              LegacyShift(prior,safeN)!=prior &&
              offsetPatch.RotateBack(LegacyShift(prior,safeN),safeN)==prior,
              "المرجع المستقل للأسرة شديدة الاتساع دون تجاوز تكراري");
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
            var context=manager.ExecutePatchedDoubleOffsetWideRank(c,t,id,seal,n);
            if(Contexts.Count<2)Contexts.Add(context);
            _production++;
            if(rejects)_realRejections++;
            if(context.LegacyDoubleOffsetWideRankResult!=expected)_productionDifferent++;
            if(context.PatchedDoubleOffsetWideRankResult==expected)_productionCorrect++;
            var oldExpected=LegacyShift(expected,n);
            Check(context.Status=="PATCHED_DOUBLE_OFFSET_WIDE_RANK_COMPLETE" &&
                  context.Phase==context.Status &&
                  context.BranchTrace.SequenceEqual(new[]{
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
                      "PATCHED_DOUBLE_OFFSET_WIDE_RANK"}) &&
                  context.Metrics["legacy.double.offset.wide.rank.witness"]==1 &&
                  context.Metrics["patched.double.offset.wide.rank.dispatch"]==1 &&
                  context.Metrics["patched.rejection.direction.witness"]==1,
                  "المدير والموزع وسجل الشواهد متصلان");
            Check(context.PatchedDoubleOffsetWideRankResult==expected &&
                  context.LegacyDoubleOffsetWideRankResult==oldExpected &&
                  context.PatchedRejectionDirectionRankResult==expected &&
                  context.LegacyDoubleOffsetWideRankResult!=expected &&
                  context.LegacyWideFamilySize==n,
                  "توقيع الإزاحة التاريخية مستقل عن النتيجة السابقة");
            Check(context.PatchedBowlQuestionResult is not null &&
                  context.PatchedBowlQuestionResult.First==stream.First &&
                  context.PatchedBowlQuestionResult.DirectionStep==stream.DirectionStep &&
                  context.PatchedAnswerAtResult==stream.First &&
                  context.PatchedNextBowlResult==
                     NormativeScroll.NextBowlInDrop46Order(sauce,id),
                  "صحة المصدر والنطاق والاتجاه المصححين");
            Check(context.PatchedSauceFinalBowls is {Length:7} &&
                  context.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
                  context.PatchedOrderAt46Latch is {Length:6} &&
                  context.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
                  context.LegacySauceFinalBowls is {Length:7} &&
                  !ReferenceEquals(context.LegacySauceFinalBowls,
                                  context.PatchedSauceFinalBowls),
                  "حماية ترتيب القطرة وحالة الصلصة المستقلة");
        }
        _publicReads++;
        var publicId=sample%6+1;
        var publicSeal=sample%2==0?31:21;
        var normStream=NormativeScroll.AskBowl(sauce,publicId,publicSeal);
        var size=m+1;
        var good=CalendarDateSpaghetti.EvaluateDoubleOffsetWideRank(
            c,t,publicId,publicSeal,size);
        var old=CalendarDateSpaghetti.EvaluateLegacyDoubleOffsetWideRank(
            c,t,publicId,publicSeal,size);
        Check(good==NormativeScroll.ChooseRankWide(normStream,size) &&
              old==LegacyShift(good,size) && old!=good,
              "الواجهتان العامتان منفصلتان وحاسمتان "+sample);
    }

    private static int Main()
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
        Console.WriteLine("حالات التحكم: "+_controls);
        Console.WriteLine("مطابقات التصحيح في التحكم: "+_correctControls);
        Console.WriteLine("مطابقات التصحيح بعد الرفض: "+_correctRejections);
        Console.WriteLine("مخالفات التحكم التاريخية: "+_controlDifferent);
        Console.WriteLine("حالات رفض: "+_rejections);
        Console.WriteLine("مخالفات الرفض التاريخية: "+_rejectionDifferent);
        Console.WriteLine("شواهد الزيادة: "+_ascending);
        Console.WriteLine("شواهد النقصان: "+_descending);
        Console.WriteLine("الصلصات: "+_sauces);
        Console.WriteLine("أسئلة الإنتاج: "+_production);
        Console.WriteLine("مخالفات الإنتاج التاريخية: "+_productionDifferent);
        Console.WriteLine("الإنتاج المصحح: "+_productionCorrect);
        Console.WriteLine("حالات رفض الإنتاج: "+_realRejections);
        Console.WriteLine("قراءات الواجهة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_pass);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        return _unexpected==0 && _controls==34560 &&
            _correctControls==34560 && _controlDifferent==34560 &&
            _rejections==8640 && _correctRejections==8640 &&
            _rejectionDifferent==8640 && _ascending==4320 &&
            _descending==4320 && _sauces==8 && _production==96 &&
            _productionCorrect==96 && _productionDifferent==96 &&
            _realRejections==28 && _publicReads==8 ? 0 : 1;
    }
}
