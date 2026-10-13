using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage30Tests;

internal static partial class Program
{
    private static int _passed,_unexpected,_permutations,_synthetic,_matches,_differences;
    private static int _realSauces,_realQueries,_realMatches,_realDifferences,_publicReads;
    private static int _correctFirstAnswers,_singletonMatches;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string label)
    {
        if(ok){_passed++;return;}
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة في اكتشاف المرتبة الخامسة عشرة: "+label);
    }

    private static BigInteger[] FamilySizes()
    {
        var m=NormativeScroll.M;
        return new BigInteger[]{1,2,3,5,7,31,97,65537,m};
    }

    private static void Synthetic()
    {
        var sizes=FamilySizes();
        var old=new LegacyUnshiftedShortRank();
        for(var rank=1;rank<=720;rank++)
        {
            _permutations++;
            for(var bowl=1;bowl<=6;bowl++)
            foreach(var direction in new[]{-1,1})
            {
                var first=(BigInteger)(rank*6+bowl);
                var norm=new AnswerStream(first,direction);
                var production=new LegacyBowlQuestionResult(first,direction);
                foreach(var n in sizes)
                {
                    _synthetic++;
                    var expected=NormativeScroll.ChooseRankShort(norm,n);
                    var actual=old.Choose(production,n);
                    Check(actual>=1 && actual<=n,
                          "مقدار الرتبة ضمن الأسرة "+rank+"/"+bowl+"/"+direction+"/"+n);
                    Check(actual==first%n+1,
                          "الخطأ محفوظ: باقي x وليس x-1");
                    var equal=actual==expected;
                    if(equal)_matches++;else _differences++;
                    if(n==1&&equal)_singletonMatches++;
                    Check((n==1&&equal)||(n>1&&!equal),
                          "الباقي القديم يختلف إلا في الأسرة الواحدة");
                }
            }
        }
        Check(_permutations==720 && _synthetic==77760 &&
              _matches==8640 && _differences==69120 &&
              _singletonMatches==8640,
              "توقيع الندبة الخامسة عشرة عبر كل العائلات");
    }

    private static void Boundary()
    {
        var m=NormativeScroll.M;
        var old=new LegacyUnshiftedShortRank();
        var streams=new[]{
            new LegacyBowlQuestionResult(1,-1),
            new LegacyBowlQuestionResult(1,1),
            new LegacyBowlQuestionResult(m-1,-1),
            new LegacyBowlQuestionResult(m-1,1),
            new LegacyBowlQuestionResult(m,-1),
            new LegacyBowlQuestionResult(m,1)};
        foreach(var stream in streams)
        foreach(var n in new BigInteger[]{1,2,m})
        {
            var norm=new AnswerStream(stream.First,stream.DirectionStep);
            var expected=NormativeScroll.ChooseRankShort(norm,n);
            var observed=old.Choose(stream,n);
            Check(n==1 ? observed==expected : observed!=expected,
                  "حدود صفر وباقي M مع عائلات 1 و2 وM");
        }

        // رفض الحد العلوي مع أول جواب M، والعبور في الاتجاه السالب.
        var down=new LegacyBowlQuestionResult(m,-1);
        var normalized=NormativeScroll.ChooseRankShort(new AnswerStream(m,-1),m-1);
        Check(old.Choose(down,m-1)!=normalized,
              "معالجة الرفض المتسلسل مع اتجاه -1");
        // في الاتجاه الموجب، القفز الحسابي يعادل المرور بالذيل المرفوض حتى 1.
        var up=new LegacyBowlQuestionResult(m,1);
        Check(old.Choose(up,m-1)==2,
              "عبور الردّ المرفوض عند M دون حلقة هائلة");
    }

    private static void Real(BigInteger c,BigInteger t,int sample)
    {
        _realSauces++;
        var sauce=NormativeScroll.Sauce(c,t);
        var id=sample%6+1;
        var seal=sample%2==0?31:21;
        var n=new BigInteger[]{1,2,3,5,31,97,65537,NormativeScroll.M}[sample-1];
        var referenceStream=NormativeScroll.AskBowl(sauce,id,seal);
        var expected=NormativeScroll.ChooseRankShort(referenceStream,n);
        var historical=new MonsterManager().ExecuteLegacyUnshiftedShortRank(c,t,id,seal,n);
        _realQueries++;
        Contexts.Add(historical);
        var got=historical.LegacyShortFamilyRankResult;
        if(got==expected)_realMatches++;else _realDifferences++;
        if(historical.PatchedBowlQuestionResult is not null &&
           historical.PatchedBowlQuestionResult.First==referenceStream.First &&
           historical.PatchedBowlQuestionResult.DirectionStep==referenceStream.DirectionStep &&
           historical.PatchedAnswerAtResult==referenceStream.First)
            _correctFirstAnswers++;

        Check(historical.Status=="LEGACY_UNSHIFTED_SHORT_FAMILY_RANK_COMPLETE" &&
              historical.Phase==historical.Status &&
              historical.BranchTrace.SequenceEqual(new[]{
                  "BOOTSTRAP_VALIDATION",
                  "LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS",
                  "PROTECTED_DROP46_ORDER_LATCH_WITNESS",
                  "LEGACY_FIXED_NEXT_BOWL_WITNESS",
                  "PATCHED_NEXT_BOWL_ORDER_WITNESS",
                  "LEGACY_UNSEALED_BOWL_QUESTION_WITNESS",
                  "PATCHED_SEALED_BOWL_QUESTION_WITNESS",
                  "LEGACY_ONE_BASED_ANSWER_STEP_WITNESS",
                  "PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS",
                  "LEGACY_UNSHIFTED_SHORT_FAMILY_RANK"}) &&
              historical.Metrics["legacy.unshifted.short.family.rank.dispatch"]==1,
              "إنتاج مسار المرتبة الكاملة "+sample);
        Check(historical.LegacyShortFamilySize==n &&
              historical.LegacyShortFamilyRankResult is BigInteger rank &&
              rank>=1 && rank<=n &&
              historical.PatchedAnswerAtResult==referenceStream.First &&
              historical.LegacyOneBasedAnswerAtResult==
                  NormativeScroll.AnswerAt(referenceStream,BigInteger.One),
              "الخطوة الصفرية والندبة السابقة ما زالتا مستقلتين "+sample);
        Check((n==1&&got==expected)||(n>1&&got!=expected),
              "عائلة من عنصر واحد شاهد مساواة والتسعير الخاطئ مختلف "+sample);
        Check(historical.PatchedSauceFinalBowls is {Length:7} &&
              historical.PatchedSauceFinalBowls.SequenceEqual(sauce.Bowls) &&
              historical.PatchedOrderAt46Latch is {Length:6} &&
              historical.PatchedOrderAt46Latch.SequenceEqual(sauce.OrderAtDrop46) &&
              historical.LegacySauceFinalBowls is {Length:7} &&
              !ReferenceEquals(historical.LegacySauceFinalBowls,historical.PatchedSauceFinalBowls),
              "أوعية الصلصة والترتيب المحمي وملكيتهما "+sample);
        Check(historical.PatchedNextBowlResult==
              NormativeScroll.NextBowlInDrop46Order(sauce,id) &&
              historical.LegacyFixedNextBowlResult==id%6+1 &&
              historical.LegacyUnsealedBowlQuestionResult is not null,
              "سجلات الرقع 12 و13 محفوظة "+sample);

        _publicReads++;
        var viaApi=CalendarDateSpaghetti.EvaluateLegacyUnshiftedShortRank(c,t,id,seal,n);
        Check(viaApi==got,"واجهة المرتبة القصيرة تمر بالمدير "+sample);
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verify=args.Length==1&&args[0]=="--verify-expected-red";
        if(args.Length!=0&&!verify)return 2;
        Synthetic();
        Boundary();
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var dates=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),(1,0),
            (NormativeScroll.TabletsDay,f),(huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<dates.Length;i++)Real(dates[i].C,dates[i].T,i+1);
        if(verify)ValidateAndOwnership();

        Console.WriteLine("رتب الترتيب: "+_permutations);
        Console.WriteLine("أسئلة الأسرة التركيبية: "+_synthetic);
        Console.WriteLine("المطابقات التركيبية: "+_matches);
        Console.WriteLine("المخالفات التركيبية: "+_differences);
        Console.WriteLine("الصلصات الحقيقية: "+_realSauces);
        Console.WriteLine("أسئلة الإنتاج: "+_realQueries);
        Console.WriteLine("تطابقات الإنتاج: "+_realMatches);
        Console.WriteLine("مخالفات الإنتاج: "+_realDifferences);
        Console.WriteLine("شواهد الجواب الأول الصحيح: "+_correctFirstAnswers);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("التأكيدات الناجحة: "+_passed);
        Console.WriteLine("الإخفاقات غير المتوقعة: "+_unexpected);
        var pass=_unexpected==0 && _permutations==720 &&
            _synthetic==77760 && _matches==8640 && _differences==69120 &&
            _singletonMatches==8640 && _realSauces==8 && _realQueries==8 &&
            _realMatches==1 && _realDifferences==7 &&
            _correctFirstAnswers==8 && _publicReads==8;
        if(verify)
        {
            Console.WriteLine("تحقق الأحمر المستقل لاختيار الأسرة القصيرة: "+(pass?"PASS":"FAIL"));
            return pass?0:1;
        }
        return _unexpected==0&&_differences==0?0:1;
    }
}
