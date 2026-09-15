using System.Numerics;
using PastafarianCalendar;
using PastafarianCalendar.Core;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage01Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;

    private static void Equal<T>(T expected, T actual, string name) where T : notnull
    {
        if (!EqualityComparer<T>.Default.Equals(expected, actual))
        {
            _failed++;
            Console.WriteLine("فشل: " + name + " | المتوقع=" + expected + " | الفعلي=" + actual);
            return;
        }
        _passed++;
        Console.WriteLine("نجح: " + name);
    }

    private static void True(bool condition, string name)
    {
        if (!condition)
        {
            _failed++;
            Console.WriteLine("فشل: " + name);
            return;
        }
        _passed++;
        Console.WriteLine("نجح: " + name);
    }

    private static void SequenceEqual<T>(IReadOnlyList<T> expected, IReadOnlyList<T> actual, string name)
    {
        if (expected.Count != actual.Count || !expected.SequenceEqual(actual))
        {
            _failed++;
            Console.WriteLine("فشل: " + name + " | المتوقع=[" + string.Join(',', expected) + "] | الفعلي=[" + string.Join(',', actual) + "]");
            return;
        }
        _passed++;
        Console.WriteLine("نجح: " + name);
    }

    private static void RunCatalogTests()
    {
        Equal(17, SourceLanguageCatalog.Cutlets.Count, "عدد أسماء الكُتَيْلات");
        Equal(47, SourceLanguageCatalog.Months.Count, "عدد أسماء الأشهر");
        SequenceEqual(Enumerable.Range(1, 17).ToArray(), SourceLanguageCatalog.Cutlets.Select(x => x.CanonicalIndex).ToArray(), "فهارس الكُتَيْلات الكنسية");
        SequenceEqual(Enumerable.Range(1, 47).ToArray(), SourceLanguageCatalog.Months.Select(x => x.CanonicalIndex).ToArray(), "فهارس الأشهر الكنسية");
        Equal("حِنْطَة", SourceLanguageCatalog.ResolveCutlet(12), "ترجمة الحنطة");
        Equal("بَابِل", SourceLanguageCatalog.ResolveMonth(41), "اسم بابل");
        True(SourceLanguageCatalog.Cutlets.All(x => !string.IsNullOrWhiteSpace(x.ClassicalArabic)), "كل أسماء الكُتَيْلات غير فارغة");
        True(SourceLanguageCatalog.Months.All(x => !string.IsNullOrWhiteSpace(x.ClassicalArabic)), "كل أسماء الأشهر غير فارغة");
    }

    // CANONICAL_NAME_CORRECTION_REGRESSION_TESTS
    private static void RunCanonicalNameCorrectionRegressionTests()
    {
        Equal("\u0628\u064F\u0631\u064F\u0648\u0646\u0652\u0632", SourceLanguageCatalog.ResolveCutlet(1), "corrected cutlet canonicalIndex 1");
        Equal("\u0623\u064E\u0631\u0652\u0628\u064E\u0639\u064E\u0629\u064F\u0020\u0623\u064E\u062C\u0652\u0632\u064E\u0627\u0621\u064D\u0020\u0645\u0650\u0646\u0652\u0020\u062A\u0650\u0633\u0652\u0639\u064E\u0629\u064D", SourceLanguageCatalog.ResolveCutlet(6), "corrected cutlet canonicalIndex 6");
        Equal("\u062B\u064E\u0644\u064E\u0627\u062B\u064E\u0629\u064F\u0020\u0623\u064E\u062C\u0652\u0632\u064E\u0627\u0621\u064D\u0020\u0645\u0650\u0646\u0652\u0020\u062E\u064E\u0645\u0652\u0633\u064E\u0629\u064D", SourceLanguageCatalog.ResolveMonth(7), "corrected month canonicalIndex 7");
        Equal("\u0643\u064E\u0631\u0652\u0634\u064F\u0648\u0645\u064E\u06A4", SourceLanguageCatalog.ResolveMonth(8), "corrected month canonicalIndex 8");
        Equal("\u0633\u064F\u0648\u0633\u064E\u0627", SourceLanguageCatalog.ResolveMonth(36), "corrected month canonicalIndex 36");
    }
    private static void RunArithmeticTests()
    {
        Equal(new BigInteger(14777149), NormativeScroll.TabletsDay - NormativeScroll.FoundationDay, "المسافة بين يوم الألواح ويوم التأسيس");
        Equal(BigInteger.One, NormativeScroll.Save(1), "الحفظ للواحد");
        Equal(NormativeScroll.M - 1, NormativeScroll.Save(NormativeScroll.M - 1), "الحفظ لما قبل المنتهى");
        Equal(NormativeScroll.M, NormativeScroll.Save(NormativeScroll.M), "الحفظ لمضاعف واحد من المنتهى");
        Equal(BigInteger.One, NormativeScroll.Save(NormativeScroll.M + 1), "الحفظ لما بعد المنتهى");
        Equal(NormativeScroll.M, NormativeScroll.Save(2 * NormativeScroll.M), "الحفظ لمضاعفين من المنتهى");
        Equal(BigInteger.One, NormativeScroll.DayCount(NormativeScroll.FoundationDay), "عدّ يوم التأسيس");
        Equal(new BigInteger(3), NormativeScroll.DayCount(NormativeScroll.FoundationDay + 1), "عدّ اليوم التالي للتأسيس");
        Equal(new BigInteger(2), NormativeScroll.DayCount(NormativeScroll.FoundationDay - 1), "عدّ اليوم السابق للتأسيس");
        var same = NormativeScroll.WorkCountsFor(NormativeScroll.FoundationDay, NormativeScroll.FoundationDay);
        Equal(BigInteger.One, same.Distance, "مسافة اليوم إلى نفسه");
        Equal(2, same.Direction, "جهة اليوم إلى نفسه");
    }

    private static void RunProductionArithmeticTests()
    {
        Equal(NormativeScroll.M, CanonicalArithmetic.SauceModulus, "منتهى الصلصة الإنتاجي");
        Equal(NormativeScroll.FoundationDay, CanonicalArithmetic.FoundationDay, "يوم التأسيس الإنتاجي");
        Equal(NormativeScroll.TabletsDay, CanonicalArithmetic.TabletsDay, "يوم الألواح الإنتاجي");

        var values = new BigInteger[] { -3, -1, 0, 1, NormativeScroll.M - 1, NormativeScroll.M, NormativeScroll.M + 1 };
        foreach (var value in values)
            Equal(NormativeScroll.Save(value), CanonicalArithmetic.Save(value), "الحفظ الإنتاجي " + value);

        foreach (var day in new[] { NormativeScroll.FoundationDay - 3, NormativeScroll.FoundationDay - 1, NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1, NormativeScroll.FoundationDay + 3 })
            Equal(NormativeScroll.DayCount(day), CanonicalArithmetic.DayCount(day), "عدّ اليوم الإنتاجي " + day);

        foreach (var pair in new[]
        {
            (NormativeScroll.FoundationDay, NormativeScroll.FoundationDay),
            (NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1),
            (NormativeScroll.FoundationDay + 1, NormativeScroll.FoundationDay)
        })
        {
            var expected = NormativeScroll.WorkCountsFor(pair.Item1, pair.Item2);
            var actual = CanonicalArithmetic.WorkCountsFor(pair.Item1, pair.Item2);
            Equal(expected.Action, actual.CalculationCount, "منين العمل الإنتاجي");
            Equal(expected.Target, actual.TargetCount, "منين المطلوب الإنتاجي");
            Equal(expected.Distance, actual.DistanceCount, "منين البعد الإنتاجي");
            Equal(expected.Connection, actual.ConnectionCount, "منين الوصل الإنتاجي");
            Equal(expected.Direction, actual.Direction, "منين الطريق الإنتاجي");
        }

        Equal(NormativeScroll.FallingFactorial(7, 4), CanonicalArithmetic.FallingFactorial(7, 4), "المضروب الناقص الإنتاجي");
        SequenceEqual(NormativeScroll.UnrankDistinctIndices(6, 4, 201), CanonicalArithmetic.UnrankDistinctIndices(6, 4, 201), "فك رتبة الأسماء الإنتاجي");
    }

    private static void RunStoneAndPermutationTests()
    {
        var stones = NormativeScroll.BuildStones();
        SequenceEqual(new BigInteger[] { 0, 17, 29, 43, 71, 101 }, stones[1], "صف الحجارة الأول");
        SequenceEqual(new BigInteger[] { 0, 378, 1073, 2375, 6195, 10493 }, stones[2], "صف الحجارة الثاني");
        SequenceEqual(new[] { 1, 2, 3, 4, 5, 6 }, NormativeScroll.PermutationUnrank1(1), "أول ترتيب للأوعية");
        SequenceEqual(new[] { 6, 5, 4, 3, 2, 1 }, NormativeScroll.PermutationUnrank1(720), "آخر ترتيب للأوعية");
        SequenceEqual(new[] { 6, 5, 4, 3, 2, 1 }, NormativeScroll.BowlOrderFromDrop(720), "قطرة مضاعفة لسبعمائة وعشرين");
    }

    private static void RunFamilyTests()
    {
        var bounded = new NormativeScroll.BoundedCompositionFamily(10, 2, 4, 6);
        Equal(new BigInteger(3), bounded.Count(), "عدد التراكيب المحدودة الصغيرة");
        SequenceEqual(new[] { 4, 6 }, bounded.Unrank1(1), "أول تركيب محدود");
        SequenceEqual(new[] { 6, 4 }, bounded.Unrank1(3), "آخر تركيب محدود");

        var partitions = new NormativeScroll.CutletPartitionFamily(5, 3, null);
        Equal(new BigInteger(6), partitions.Count(), "عدد تقسيمات الكُتَيْلات الصغيرة");
        SequenceEqual(new[] { 1, 1, 3 }, partitions.Unrank1(1), "أول تقسيم كُتَيْلات");
        SequenceEqual(new[] { 3, 1, 1 }, partitions.Unrank1(6), "آخر تقسيم كُتَيْلات");

        var filtered = new NormativeScroll.CutletPartitionFamily(5, 3, 2);
        Equal(new BigInteger(3), filtered.Count(), "عدد التقسيمات التي تمر بالحد المطلوب");
        SequenceEqual(new[] { 1, 1, 3 }, filtered.Unrank1(1), "أول تقسيم مفلتر");
        SequenceEqual(new[] { 2, 2, 1 }, filtered.Unrank1(3), "آخر تقسيم مفلتر");

        var weaving = new NormativeScroll.WeavingFamily(new[] { 2, 2 });
        Equal(new BigInteger(2), weaving.Count(), "عدد الأنسجة الصغيرة");
        SequenceEqual(new[] { 1, 1, 2, 2 }, weaving.Unrank1(1), "أول نسيج صغير");
        SequenceEqual(new[] { 1, 2, 1, 2 }, weaving.Unrank1(2), "ثاني نسيج صغير");

        SequenceEqual(new[] { 1, 2, 3 }, NormativeScroll.UnrankDistinctIndices(3, 3, 1), "أول ترتيب أسماء متميزة");
        SequenceEqual(new[] { 3, 2, 1 }, NormativeScroll.UnrankDistinctIndices(3, 3, 6), "آخر ترتيب أسماء متميزة");
    }

    private static void RunSelectorTests()
    {
        var forward = new PastafarianCalendar.Stage01Tests.Normative.AnswerStream(BigInteger.One, 1);
        Equal(BigInteger.One, NormativeScroll.ChooseRankShort(forward, 10), "اختيار قصير بلا رفض");

        var backward = new PastafarianCalendar.Stage01Tests.Normative.AnswerStream(NormativeScroll.M, -1);
        Equal(new BigInteger(10), NormativeScroll.ChooseRankShort(backward, 10), "اختيار قصير بعد رفض متتابع");

        var wide = new PastafarianCalendar.Stage01Tests.Normative.AnswerStream(BigInteger.One, 1);
        Equal(NormativeScroll.M + 1, NormativeScroll.ChooseRankWide(wide, NormativeScroll.M + 1), "اختيار واسع فوق المنتهى مباشرة");
    }

    private static void RunSauceSmokeTests()
    {
        var first = NormativeScroll.Sauce(NormativeScroll.FoundationDay, NormativeScroll.FoundationDay);
        var second = NormativeScroll.Sauce(NormativeScroll.FoundationDay, NormativeScroll.FoundationDay);
        SequenceEqual(first.OrderAtDrop46, second.OrderAtDrop46, "ثبات ترتيب القطرة السادسة والأربعين");
        SequenceEqual(first.Bowls, second.Bowls, "ثبات ناتج الصلصة");
        True(first.Bowls.Skip(1).All(x => x >= 1 && x <= NormativeScroll.M), "مدى الأوعية بعد الصلصة");
        True(first.OrderAtDrop46.OrderBy(x => x).SequenceEqual(new[] { 1, 2, 3, 4, 5, 6 }), "ترتيب القطرة السادسة والأربعين تبديل كامل");
        var next = NormativeScroll.NextBowlInDrop46Order(first, first.OrderAtDrop46[5]);
        Equal(first.OrderAtDrop46[0], next, "التفاف الوعاء التالي في ترتيب القطرة السادسة والأربعين");
    }

    private static void RunProductionSauceTests()
    {
        var expected = NormativeScroll.Sauce(NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1);
        var actual = SauceCore.Brew(NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1);
        SequenceEqual(expected.Bowls, actual.Bowls, "أوعية الصلصة الإنتاجية");
        SequenceEqual(expected.OrderAtDrop46, actual.OrderAtDrop46, "ترتيب القطرة السادسة والأربعين الإنتاجي");
        Equal(NormativeScroll.NextBowlInDrop46Order(expected, expected.OrderAtDrop46[5]), SauceCore.NextBowlInDrop46Order(actual, actual.OrderAtDrop46[5]), "الوعاء التالي الإنتاجي");
        var expectedStream = NormativeScroll.AskBowl(expected, 2, 21);
        var actualStream = SauceCore.AskBowl(actual, 2, 21);
        Equal(expectedStream.First, actualStream.First, "أول جواب إنتاجي");
        Equal(expectedStream.DirectionStep, actualStream.DirectionStep, "اتجاه الجواب الإنتاجي");
        Equal(NormativeScroll.ChooseRank(expectedStream, 922), SauceCore.ChooseRank(actualStream, 922), "رتبة الاختيار الإنتاجية");
    }

    private static void RunGateSmokeTests()
    {
        var oracle = new NormativeScroll();
        var positive = oracle.PositiveGateGap(1);
        var negative = oracle.NegativeGateGap(1);
        True(positive >= NormativeScroll.GateGapMin && positive <= NormativeScroll.GateGapMax, "مدى فجوة البوابة الموجبة الأولى");
        True(negative >= NormativeScroll.GateGapMin && negative <= NormativeScroll.GateGapMax, "مدى فجوة البوابة السالبة الأولى");
    }

    private static void RunProductionGateTests()
    {
        var oracle = new NormativeScroll();
        var actual = new GateDiscovery();
        foreach (var step in new BigInteger[] { 1, 2 })
        {
            Equal(oracle.PositiveGateGap(step), actual.PositiveGateGap(step), "فجوة البوابة الموجبة الإنتاجية " + step);
            Equal(oracle.NegativeGateGap(step), actual.NegativeGateGap(step), "فجوة البوابة السالبة الإنتاجية " + step);
        }
        foreach (var index in new BigInteger[] { -2, -1, 0, 1, 2 })
            Equal(oracle.EnsureGateIndex(index), actual.GateDay(index), "يوم البوابة الإنتاجي " + index);

        var gateOne = actual.GateDay(1);
        Equal(new BigInteger(0), actual.GateIndexAtOrBefore(gateOne - 1), "الفهرس قبل البوابة الإنتاجي");
        Equal(new BigInteger(1), actual.GateIndexAtOrBefore(gateOne), "الفهرس عند البوابة الإنتاجي");
        Equal(new BigInteger(1), actual.ExactGateIndex(gateOne)!.Value, "الفهرس الدقيق للبوابة الإنتاجي");
    }

    private static void RunProductionYearTests()
    {
        var calculationDay = NormativeScroll.FoundationDay;
        var oracle = new NormativeScroll();
        var actual = new YearSelection();
        var expectedYear5000 = oracle.Year5000(calculationDay);
        var actualYear5000 = actual.Year5000(calculationDay);
        Equal(expectedYear5000.Number, actualYear5000.Number, "رقم سنة خمسة آلاف الإنتاجي");
        Equal(expectedYear5000.OpenGateIndex, actualYear5000.OpenGateIndex, "بوابة فتح سنة خمسة آلاف الإنتاجية");
        Equal(expectedYear5000.CloseGateIndex, actualYear5000.CloseGateIndex, "بوابة ختم سنة خمسة آلاف الإنتاجية");
        var expectedNext = oracle.NextYear(calculationDay, expectedYear5000);
        var actualNext = actual.NextYear(calculationDay, actualYear5000);
        Equal(expectedNext.OpenGateIndex, actualNext.OpenGateIndex, "فتح السنة التالية الإنتاجية");
        Equal(expectedNext.CloseGateIndex, actualNext.CloseGateIndex, "ختم السنة التالية الإنتاجية");
        var expectedPrevious = oracle.PreviousYear(calculationDay, expectedYear5000);
        var actualPrevious = actual.PreviousYear(calculationDay, actualYear5000);
        Equal(expectedPrevious.OpenGateIndex, actualPrevious.OpenGateIndex, "فتح السنة السابقة الإنتاجية");
        Equal(expectedPrevious.CloseGateIndex, actualPrevious.CloseGateIndex, "ختم السنة السابقة الإنتاجية");
        var target = actualYear5000.CloseGateDay;
        Equal(actualYear5000, actual.FindTargetYear(calculationDay, target), "إيجاد سنة يوم الختم الإنتاجي");
    }

    private static void RunMonsterBootstrapTests()
    {
        var context = CalendarDateSpaghetti.BootstrapInvocation(NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1);
        Equal("BOOTSTRAP_READY", context.Status, "حالة هيكل الوحش المحايد");
        Equal("BOOTSTRAP_READY", context.Phase, "مرحلة هيكل الوحش المحايد");
        Equal(1L, context.Metrics["bootstrap.dispatch"], "مقياس الإرسال المحايد");
        True(context.BranchTrace.SequenceEqual(new[] { "BOOTSTRAP_VALIDATION" }), "أثر الفرع المحايد");
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        RunCatalogTests();
        RunCanonicalNameCorrectionRegressionTests();
        RunArithmeticTests();
        RunProductionArithmeticTests();
        RunStoneAndPermutationTests();
        RunFamilyTests();
        RunSelectorTests();
        RunSauceSmokeTests();
        RunProductionSauceTests();
        RunGateSmokeTests();
        RunProductionGateTests();
        RunProductionYearTests();
        RunMonsterBootstrapTests();
        Console.WriteLine("الاختبارات الناجحة: " + _passed);
        Console.WriteLine("الاختبارات الفاشلة: " + _failed);
        return _failed == 0 ? 0 : 1;
    }
}
