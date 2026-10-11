using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage09Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;
    private static int _compared;
    private static int _legacyDivergences;
    private static int _inputCases;

    private static void Check(bool condition, string title)
    {
        if (condition) { _passed++; return; }
        _failed++;
        Console.WriteLine("فشل: " + title);
    }

    private static BigInteger[] ExpectedFromSnapshot(int row, BigInteger[] old)
    {
        // ليس في الإنتاج شيء من مرجع الاختبار؛ الحساب التالي شاهد اختباري مستقل.
        return new[]
        {
            BigInteger.Zero,
            NormativeScroll.Save(old[1] * old[1] + 3 * old[2] + row),
            NormativeScroll.Save(old[2] * old[2] + 5 * old[3] + old[1]),
            NormativeScroll.Save(old[3] * old[3] + 7 * old[4] + old[2]),
            NormativeScroll.Save(old[4] * old[4] + 11 * old[5] + old[3]),
            NormativeScroll.Save(old[5] * old[5] + 13 * old[1] + old[4])
        };
    }

    private static void VerifyAllRows()
    {
        var oracle = NormativeScroll.BuildStones();
        var patched = CalendarDateSpaghetti.EvaluatePatchedStones(
            NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1);
        var legacy = CalendarDateSpaghetti.EvaluateLegacyStones(
            NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1);
        var wrapper = new StonePatchWrapper();

        Check(patched.Length == 47 && legacy.Length == 47, "عدد صفوف الأحجار");
        Check(patched[0] is null && legacy[0] is null, "الفهرس المحجوز");
        Check(patched[1].SequenceEqual(LegacyStones.InitialStones()), "بذرة الأحجار");

        for (var row = 1; row <= 46; row++)
        {
            Check(patched[row].Length == 6, "خمسة أحجار في الصف " + row);
            Check(!ReferenceEquals(patched[row], legacy[row]), "فصل صف الرقعة عن الصف التاريخي " + row);
            if (row > 1)
            {
                Check(!ReferenceEquals(patched[row], patched[row - 1]), "ملكية نسخة الصف " + row);
                var replay = wrapper.StonePatch(row, patched[row - 1]);
                Check(replay.SequenceEqual(patched[row]), "إعادة بناء الصف من سلفه " + row);
            }

            for (var kind = 1; kind <= 5; kind++)
            {
                _compared++;
                Check(patched[row][kind] == oracle[row][kind],
                    "تكافؤ مرجع الأحجار للصف " + row + "/" + kind);
                Check(patched[row][kind] >= 1 && patched[row][kind] <= NormativeScroll.M,
                    "حدود الباقي للحجر " + row + "/" + kind);
                if (legacy[row][kind] != oracle[row][kind])
                    _legacyDivergences++;
            }
        }

        Check(_compared == 230 && _legacyDivergences == 224,
            "الاحتفاظ بتوقيع عيب الأحجار القديمة: 224 من 230");
    }

    private static void VerifyInput(int row, BigInteger[] values, string label)
    {
        _inputCases++;
        var snapshot = (BigInteger[])values.Clone();
        var wrapper = new StonePatchWrapper();
        var patched = wrapper.StonePatch(row, values);
        var expected = ExpectedFromSnapshot(row, snapshot);

        Check(!ReferenceEquals(patched, values), "استقلال الناتج عن المدخل " + label);
        Check(values.SequenceEqual(snapshot), "عدم تغيير المدخل " + label);
        Check(patched.Length == 6 && patched[0] == values[0], "فهرس الصفر " + label);
        for (var kind = 1; kind <= 5; kind++)
        {
            Check(patched[kind] == expected[kind], "مطابقة الصورة القديمة " + kind + "/" + label);
            Check(patched[kind] >= BigInteger.One && patched[kind] <= NormativeScroll.M,
                "نطاق الحساب " + kind + "/" + label);
        }

        // هذا شاهد على مسار الطفرة القديمة الذي لا يزال يعطي نتائج خاطئة.
        var legacyInput = (BigInteger[])snapshot.Clone();
        var garbage = LegacyStones.MutateStonesWrong(row, legacyInput);
        Check(ReferenceEquals(garbage, legacyInput), "بقاء الطفرة في موضعها " + label);
    }

    private static void VerifyInputs()
    {
        var baseStones = LegacyStones.InitialStones();
        var boundary = NormativeScroll.M;
        var huge = BigInteger.One << 8192;
        var inputs = new BigInteger[][]
        {
            baseStones,
            new BigInteger[] { 0, 0, 0, 0, 0, 0 },
            new BigInteger[] { 0, 1, 1, 1, 1, 1 },
            new BigInteger[] { 0, boundary, boundary, boundary, boundary, boundary },
            new BigInteger[] { 0, boundary - 1, boundary + 1, 2 * boundary, -boundary, -2 * boundary },
            new BigInteger[] { 0, -1, -2, -3, -4, -5 },
            new BigInteger[] { 0, huge, huge + 1, huge + 2, huge + 3, huge + 4 },
            new BigInteger[] { 0, -huge, -huge - 1, huge, huge * 2, huge * 3 },
            new BigInteger[] { 0, huge * huge, -huge * huge, boundary, -boundary, 0 },
        };
        foreach (var row in new[] { 2, 3, 7, 13, 23, 46 })
            for (var i = 0; i < inputs.Length; i++)
                VerifyInput(row, inputs[i], "صف " + row + " حالة " + i);
    }

    private static void VerifyIsolation()
    {
        var manager = new MonsterManager();
        var a = manager.ExecutePatchedStones(BigInteger.Zero, BigInteger.One);
        var b = manager.ExecutePatchedStones(BigInteger.One, BigInteger.Zero);
        var c = manager.ExecuteLegacyStones(BigInteger.Zero, BigInteger.One);
        Check(!ReferenceEquals(a, b) && !ReferenceEquals(a.Metrics, b.Metrics),
            "عزل السياقات والقياسات");
        Check(!ReferenceEquals(a.BranchTrace, b.BranchTrace), "عزل مسارات العمليات");
        Check(!ReferenceEquals(a.PatchedStoneRows, b.PatchedStoneRows), "عزل الجداول المصححة");
        Check(!ReferenceEquals(a.LegacyStoneRows, b.LegacyStoneRows), "عزل الجداول التاريخية");
        Check(!ReferenceEquals(a.PatchedStoneRows![20], b.PatchedStoneRows![20]),
            "عزل الصورة العميقة للصف");
        Check(a.PatchedStoneRows[46].SequenceEqual(b.PatchedStoneRows![46]),
            "استقلال المعنى عن أيام العمل وترتيب الاستدعاء");
        Check(a.LegacyStoneRows![46].SequenceEqual(c.LegacyStoneRows![46]),
            "عدم طمس المحرك القديم عند تشغيل الرقعة");
        Check(a.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_STONES_MUTATION", "STONE_PATCH" }),
            "تشغيل المعالج القديم قبل الرقعة");
        Check(a.Status == "STONE_PATCH_COMPLETE" && a.Phase == "STONE_PATCH_COMPLETE",
            "حالة انتهاء الرقعة الرابعة");
        Check(a.Metrics.TryGetValue("bootstrap.dispatch", out var boot) && boot == 1 &&
            a.Metrics.TryGetValue("legacy.stones.mutation.dispatch", out var old) && old == 1 &&
            a.Metrics.TryGetValue("stone.patch.dispatch", out var fix) && fix == 1,
            "عداد استدعاء كل طبقة من الطبقات الثلاث");
        Check(a.PatchedCountsResult is null && a.LegacyDistanceResult is null &&
            a.PatchedSaveResult is null && a.PatchedDayTagResult is null,
            "عدم خلط الحالة مع الرقع السابقة");

        var original = (BigInteger[])b.PatchedStoneRows![27].Clone();
        a.PatchedStoneRows![27][1] = -1;
        a.LegacyStoneRows![21][2] = -2;
        Check(b.PatchedStoneRows[27].SequenceEqual(original), "منع تسرّب الكتابة بين السياقات");
        Check(b.LegacyStoneRows![21][2] >= 1, "عزل القديم في السياق الثاني");
        Check(a.PatchedStoneRows[26][1] >= 1 && a.PatchedStoneRows[28][1] >= 1,
            "منع تسرّب الكتابة إلى صفوف مجاورة");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(), new MonsterMetricsManager());
        var trace = a.BranchTrace.ToArray();
        var rejected = false;
        try { dispatcher.DispatchPatchedStones(a); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && a.BranchTrace.SequenceEqual(trace)
            && a.Metrics["stone.patch.dispatch"] == 1, "رفض إرسال الرقعة مرتين");

        var unready = new MonsterContext(BigInteger.Zero, BigInteger.One);
        rejected = false;
        try { dispatcher.DispatchPatchedStones(unready); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && unready.PatchedStoneRows is null && unready.LegacyStoneRows is null &&
            unready.BranchTrace.Count == 0 && unready.Status == "NEW", "رفض ما قبل التأسيس");

        var preoccupied = manager.Prepare(0, 1);
        preoccupied.LegacyStoneRows = LegacyStones.BuildWrongRows();
        var previous = preoccupied.BranchTrace.ToArray();
        rejected = false;
        try { dispatcher.DispatchPatchedStones(preoccupied); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && preoccupied.PatchedStoneRows is null &&
            preoccupied.BranchTrace.SequenceEqual(previous), "رفض ملكية قديمة سبق التزامها");

        var validation = new MonsterValidationManager();
        var candidateContext = manager.ExecuteLegacyStones(0, 1);
        var correct = new StonePatchWrapper().BuildPatchedRows();
        validation.ValidatePatchedStones(candidateContext, correct);
        Check(candidateContext.PatchedStoneRows is null, "التحقق وحده لا يلتزم بالنتيجة");
        var malformed = new StonePatchWrapper().BuildPatchedRows();
        malformed[18] = malformed[17];
        rejected = false;
        try { validation.ValidatePatchedStones(candidateContext, malformed); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && candidateContext.PatchedStoneRows is null, "رفض خلط ملكية الصفوف");
        var broken = new StonePatchWrapper().BuildPatchedRows();
        broken[20][3] = BigInteger.Zero;
        rejected = false;
        try { validation.ValidatePatchedStones(candidateContext, broken); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected, "رفض حجر صفر خارج المجال");
        var displaced = new StonePatchWrapper().BuildPatchedRows();
        displaced[0] = new BigInteger[6];
        rejected = false;
        try { validation.ValidatePatchedStones(candidateContext, displaced); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected, "رفض كتابة فهرس الصفر");

        var wrapper = new StonePatchWrapper();
        var input = LegacyStones.InitialStones();
        foreach (var invalidRow in new[] { -1, 0, 1, 47, int.MaxValue })
        {
            var remembered = (BigInteger[])input.Clone();
            rejected = false;
            try { wrapper.StonePatch(invalidRow, input); }
            catch (MonsterValidationException) { rejected = true; }
            Check(rejected && input.SequenceEqual(remembered), "رفض دورة أحجار غير مسموحة " + invalidRow);
        }
        rejected = false;
        try { wrapper.StonePatch(2, new BigInteger[5]); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected, "رفض مدخل بمصفوفة قصيرة");
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        VerifyAllRows();
        VerifyInputs();
        VerifyIsolation();
        Console.WriteLine("خانات الأحجار المفحوصة: " + _compared);
        Console.WriteLine("اختلافات المسار القديم المستبقاة: " + _legacyDivergences);
        Console.WriteLine("مدخلات الرقعة المتنوعة: " + _inputCases);
        Console.WriteLine("الاختبارات الناجحة: " + _passed);
        Console.WriteLine("الاختبارات الفاشلة: " + _failed);
        return _failed == 0 ? 0 : 1;
    }
}
