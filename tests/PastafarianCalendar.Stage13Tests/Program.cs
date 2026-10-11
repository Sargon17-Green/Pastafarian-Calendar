using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage13Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;
    private static int _compared;
    private static int _positive;
    private static int _hidden;
    private static int _oldZero;
    private static int _oldNegative;

    private static void Check(bool valid, string message)
    {
        if (valid) { _passed++; return; }
        _failed++;
        Console.WriteLine("فشل: " + message);
    }

    private static void VerifyPair(BigInteger c, BigInteger t, int sample)
    {
        var counts = NormativeScroll.WorkCountsFor(c, t);
        var hidden = NormativeScroll.BuildHiddenDrops(counts);
        var visible = NormativeScroll.BuildVisibleDrops(counts, hidden);
        var original = (BigInteger[])visible.Clone();
        var manager = new MonsterManager();

        for (var i = 1; i <= 46; i++)
        for (var offset = 0; offset < 3; offset++)
        {
            var back = offset == 0 ? 1 : offset == 1 ? 3 : 7;
            var slot = i - back;
            var expected = slot >= 1 ? visible[slot] : hidden[1 - slot];
            var context = manager.ExecutePatchedPrior(c, t, original, i, back);
            var actual = context.PatchedPriorResult;
            var label = sample + "/" + i + "/" + back;
            _compared++;

            Check(actual == expected, "التكافؤ المرجعي لجميع المواضع " + label);
            Check(actual >= 1 && actual <= NormativeScroll.M, "حدود الحفظ " + label);
            Check(context.Status == "PRIOR_ACCESS_PATCH_COMPLETE" &&
                  context.Phase == "PRIOR_ACCESS_PATCH_COMPLETE", "حالة الالتزام " + label);
            Check(context.BranchTrace.Count == 3 &&
                  context.BranchTrace[0] == "BOOTSTRAP_VALIDATION" &&
                  context.BranchTrace[2] == "PRIOR_ACCESS_PATCH",
                "ترتيب استدعاء المسار " + label);
            Check(context.Metrics.TryGetValue("bootstrap.dispatch", out var boot) && boot == 1 &&
                  context.Metrics.TryGetValue("prior.access.patch.dispatch", out var patch) && patch == 1,
                "العدّ المحايد لكل مسار " + label);
            Check(context.LegacyPriorDropStore is not null &&
                  !ReferenceEquals(context.LegacyPriorDropStore, original) &&
                  context.LegacyPriorDropStore.SequenceEqual(original),
                "نسخ المدخل وملكيته " + label);

            if (slot >= 1)
            {
                _positive++;
                Check(context.LegacyPriorResult == expected &&
                      context.BranchTrace[1] == "LEGACY_PRIOR" &&
                      context.Metrics.TryGetValue("legacy.prior.dispatch", out var legacy) && legacy == 1,
                    "النداء التاريخي الفعلي في الموضع الموجب " + label);
                Check(context.LegacyHiddenReversed is null &&
                      context.PatchedHiddenAccess is null &&
                      !context.Metrics.ContainsKey("legacy.hidden.reversed.dispatch"),
                    "عدم تشغيل مسار مخفي لا حاجة إليه " + label);
                Check(LegacyPrior.Read(original, i, back) == expected,
                    "استمرار صحة القديم في الفرع الموجب " + label);
            }
            else
            {
                _hidden++;
                Check(context.LegacyPriorResult is null &&
                      context.BranchTrace[1] == "LEGACY_HIDDEN_REVERSED" &&
                      context.Metrics.TryGetValue("legacy.hidden.reversed.dispatch", out var legacy) && legacy == 1 &&
                      !context.Metrics.ContainsKey("legacy.prior.dispatch"),
                    "استدعاء مخزن الخفية بدلاً من الفهرسة العاجزة " + label);
                Check(context.LegacyHiddenReversed is not null &&
                      context.PatchedHiddenAccess is not null &&
                      context.PatchedHiddenAccess.HiddenByNearness(1-slot) == expected &&
                      context.LegacyHiddenReversed[8-(1-slot)] == expected,
                    "عدم قلب التخزين التاريخي " + label);
                if (slot == 0)
                {
                    _oldZero++;
                    Check(LegacyPrior.Read(original, i, back) == BigInteger.Zero,
                        "الحفاظ على الصفر القديم " + label);
                }
                else
                {
                    _oldNegative++;
                    var threw = false;
                    try { _ = LegacyPrior.Read(original, i, back); }
                    catch (IndexOutOfRangeException) { threw = true; }
                    Check(threw, "الحفاظ على استثناء الفهرس السالب القديم " + label);
                }
            }

            Check(original.SequenceEqual(visible), "عدم كتابة القطرات المقدمة " + label);
        }
    }

    private static void VerifyOwnershipAndValidation()
    {
        var f = NormativeScroll.FoundationDay;
        var manager = new MonsterManager();
        var store = new BigInteger[47];
        for (var i=1;i<=46;i++) store[i] = i*i+17;
        var copy = (BigInteger[])store.Clone();
        var positive = manager.ExecutePatchedPrior(f, f+1, store, 46, 7);
        var nextPositive = manager.ExecutePatchedPrior(f+1, f, store, 46, 7);
        var negative = manager.ExecutePatchedPrior(f, f+1, store, 1, 7);
        var nextNegative = manager.ExecutePatchedPrior(f+1, f, store, 1, 7);
        Check(positive.PatchedPriorResult == store[39] &&
              positive.LegacyPriorResult == store[39] &&
              positive.PatchedHiddenAccess is null, "شاهد المسار الموجب القديم");
        Check(negative.PatchedPriorResult ==
              CalendarDateSpaghetti.EvaluateHiddenDrop(f, f+1, 7) &&
              negative.LegacyPriorResult is null, "شاهد القطرة السابعة المخفية");
        Check(!ReferenceEquals(positive, nextPositive) &&
              !ReferenceEquals(negative, nextNegative) &&
              !ReferenceEquals(positive.LegacyPriorDropStore, nextPositive.LegacyPriorDropStore) &&
              !ReferenceEquals(negative.LegacyHiddenReversed, nextNegative.LegacyHiddenReversed) &&
              !ReferenceEquals(negative.PatchedHiddenAccess, nextNegative.PatchedHiddenAccess) &&
              !ReferenceEquals(negative.Metrics, nextNegative.Metrics),
            "عزل السياقات والمخزن القديم ومرجع الغلاف");
        positive.LegacyPriorDropStore![39] = BigInteger.MinusOne;
        negative.LegacyPriorDropStore![39] = BigInteger.MinusOne;
        negative.LegacyHiddenReversed![1] = BigInteger.MinusOne;
        Check(store.SequenceEqual(copy) &&
              nextPositive.LegacyPriorDropStore![39] == copy[39] &&
              nextNegative.LegacyPriorDropStore![39] == copy[39] &&
              nextNegative.LegacyHiddenReversed![1] >= BigInteger.One,
            "عدم تسرب كتابة السياق إلى المصدر أو سياق آخر");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(), new MonsterMetricsManager());
        foreach (var context in new[] { positive, negative })
        {
            var before = context.BranchTrace.ToArray();
            var rejected = false;
            try { dispatcher.DispatchPatchedPrior(context); }
            catch (MonsterValidationException) { rejected = true; }
            Check(rejected && context.BranchTrace.SequenceEqual(before) &&
                  context.Metrics["prior.access.patch.dispatch"] == 1,
                "رفض الاستدعاء المكرر دون أثر");
        }

        var unprepared = new MonsterContext(0,1)
        {
            LegacyPriorDropStore = (BigInteger[])copy.Clone(),
            LegacyPriorVisibleIndex=1, LegacyPriorBack=7
        };
        var refused = false;
        try { dispatcher.DispatchPatchedPrior(unprepared); }
        catch (MonsterValidationException) { refused = true; }
        Check(refused && unprepared.LegacyHiddenReversed is null &&
              unprepared.PatchedPriorResult is null &&
              unprepared.BranchTrace.Count == 0 && unprepared.Status == "NEW",
            "رفض الاستدعاء السابق للتأسيس بلا حالة جزئية");

        var occupied = manager.Prepare(0, 1);
        occupied.LegacyPriorDropStore = (BigInteger[])copy.Clone();
        occupied.LegacyPriorVisibleIndex=1;
        occupied.LegacyPriorBack=7;
        occupied.LegacyHiddenReversed = new BigInteger[8];
        var oldTrace = occupied.BranchTrace.ToArray();
        refused = false;
        try { dispatcher.DispatchPatchedPrior(occupied); }
        catch (MonsterValidationException) { refused=true; }
        Check(refused && occupied.PatchedPriorResult is null &&
              occupied.BranchTrace.SequenceEqual(oldTrace),
            "رفض مخزن مخفي أجنبي قبل البدء");

        var wrapper = new PriorAccessWrapper();
        var synthetic = new BigInteger[] { 0, 3, 3, 7, 9, 3, 7, 11 };
        var syntheticAccessor = new HiddenNearnessWrapper(synthetic);
        var reverseCases = new[] { (1,1), (1,3), (2,3),
            (1,7), (2,7), (3,7), (4,7), (5,7), (6,7), (7,7) };
        foreach (var (row, back) in reverseCases)
        {
            var hiddenK = 1 - row + back;
            var value = wrapper.Read(copy, syntheticAccessor, row, back);
            Check(value == synthetic[8-hiddenK],
                "خريطة القراءة الخفية مع قيم مكررة " + row + "/" + back);
        }
        Check(synthetic.SequenceEqual(new BigInteger[] {0,3,3,7,9,3,7,11}),
            "الغلاف لا يقلب المخزن ذا القيم المكررة");
        Check(wrapper.Read(copy, null, 46, 7) == copy[39],
            "قراءة موجبة لا تتطلب مخزن خفي");
        foreach (var bad in new[] { (0,1),(47,1),(1,0),(1,2),(1,4),(1,8) })
        {
            refused=false;
            try { wrapper.Read(copy, syntheticAccessor, bad.Item1,bad.Item2); }
            catch (MonsterValidationException) { refused=true; }
            Check(refused, "حارس التحقق من زوج الفهارس " + bad);
        }
        foreach (var len in new[] {0,7,46,48})
        {
            refused=false;
            try { wrapper.Read(new BigInteger[len], syntheticAccessor, 1, 7); }
            catch (MonsterValidationException) { refused=true; }
            Check(refused, "حارس طول المصفوفة " + len);
        }
        refused=false;
        try { wrapper.Read(copy, null, 1,7); }
        catch (MonsterValidationException) { refused=true; }
        Check(refused, "منع قراءة خفية بلا غلاف");
        refused=false;
        try { wrapper.Read(null!, syntheticAccessor, 1,7); }
        catch (MonsterValidationException) { refused=true; }
        Check(refused, "منع غياب المصفوفة");
        refused=false;
        var badSentinel=(BigInteger[])copy.Clone();
        badSentinel[0]=BigInteger.One;
        try { wrapper.Read(badSentinel, syntheticAccessor, 1,7); }
        catch (MonsterValidationException) { refused=true; }
        Check(refused, "حارس فهرس الصفر");

        var validContext = manager.ExecutePatchedPrior(f, f+1, copy, 7,7);
        var validator = new MonsterValidationManager();
        refused=false;
        try { validator.ValidatePatchedPrior(validContext, validContext.PatchedPriorResult!.Value); }
        catch (MonsterValidationException) { refused=true; }
        Check(refused, "رفض التحقق بعد التزام الرقعة");
        var bogus = validContext.PatchedPriorResult.Value + BigInteger.One;
        refused=false;
        // حارس التسجيل يرفض قبل النظر إلى القيمة إذا التزمت الرقعة بالفعل.
        try { validator.ValidatePatchedPrior(validContext, bogus); }
        catch (MonsterValidationException) { refused=true; }
        Check(refused, "رفض تثبيت آخر لنتيجة مصححة");
        Check(validContext.LegacyHiddenReversed is not null &&
              validContext.LegacyPriorResult is null,
              "حفظ شاهد الذاكرة المعكوسة دون استدعاء القديم للموضع صفر");

        // نختبر التحقق قبل تثبيت النتائج، في الفرع القديم ثم الفرع المخفي.
        var prePositive = manager.Prepare(f, f+1);
        prePositive.LegacyPriorDropStore = (BigInteger[])copy.Clone();
        prePositive.LegacyPriorVisibleIndex = 46;
        prePositive.LegacyPriorBack = 7;
        dispatcher.DispatchLegacyPrior(prePositive);
        validator.ValidatePatchedPrior(prePositive, copy[39]);
        Check(prePositive.PatchedPriorResult is null, "نجاح تحقق الموجب دون التزام");
        refused=false;
        try { validator.ValidatePatchedPrior(prePositive, copy[39]+BigInteger.One); }
        catch (MonsterValidationException) { refused=true; }
        Check(refused && prePositive.PatchedPriorResult is null,
            "رفض مرشح موجب مخالف لمسار القديم دون التزام");

        var preHidden = manager.Prepare(f, f+1);
        preHidden.LegacyPriorDropStore = (BigInteger[])copy.Clone();
        preHidden.LegacyPriorVisibleIndex = 1;
        preHidden.LegacyPriorBack = 7;
        dispatcher.DispatchLegacyHiddenDrops(preHidden);
        var hiddenAccess = new HiddenNearnessWrapper(preHidden.LegacyHiddenReversed!);
        validator.ValidateHiddenNearnessWrapper(preHidden, hiddenAccess);
        preHidden.PatchedHiddenAccess = hiddenAccess;
        var correctHidden = hiddenAccess.HiddenByNearness(7);
        validator.ValidatePatchedPrior(preHidden, correctHidden);
        Check(preHidden.PatchedPriorResult is null, "نجاح تحقق الخفية دون التزام");
        refused=false;
        try { validator.ValidatePatchedPrior(preHidden, correctHidden+BigInteger.One); }
        catch (MonsterValidationException) { refused=true; }
        Check(refused && preHidden.PatchedPriorResult is null,
            "رفض مرشح خفي مخالف للمخزن المعكوس دون التزام");

        Check(typeof(PriorAccessWrapper).Assembly.GetType("PastafarianCalendar.Monster.PriorPatch") is null,
            "الاسم القديم المحروس في اكتشاف الطور الثاني عشر غير موجود");
        Check(typeof(PriorAccessWrapper).Assembly.GetType("PastafarianCalendar.Monster.VisibleGrindPatch") is null,
            "لم يبدأ عيب الطحن الظاهر التالي");
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One << 8192;
        var cases = new (BigInteger C, BigInteger T)[]
        {
            (f,f),(f-1,f+1),(f+1,f-1),(f+12,f-19),
            (f+huge,f-huge),(f-huge-1,f+huge+3),
            (f+huge+1,f+huge+7),(f-huge,f-huge-5),
            (f+8,f-8),(f-9,f+17)
        };
        for(var c=0;c<cases.Length;c++)
            VerifyPair(cases[c].C,cases[c].T,c);
        VerifyOwnershipAndValidation();
        Console.WriteLine("أزواج الأيام المختبرة: "+cases.Length);
        Console.WriteLine("قراءات الرجوع المصححة: "+_compared);
        Console.WriteLine("قراءات القديم في المواضع الموجبة: "+_positive);
        Console.WriteLine("قراءات الخفية المستعادة: "+_hidden);
        Console.WriteLine("أصفار القديم المستبقاة: "+_oldZero);
        Console.WriteLine("استثناءات القديم المستبقاة: "+_oldNegative);
        Console.WriteLine("الاختبارات الناجحة: "+_passed);
        Console.WriteLine("الاختبارات الفاشلة: "+_failed);
        return _failed==0?0:1;
    }
}
