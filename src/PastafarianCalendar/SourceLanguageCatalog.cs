using System.Collections.ObjectModel;

namespace PastafarianCalendar;

public sealed record SourceNameEntry(int CanonicalIndex, string ClassicalArabic);

public static class SourceLanguageCatalog
{
    public const string CatalogVersion = "1.0.0-stage01";
    public const string NaturalLanguage = "العربية الكلاسيكية";

    private static readonly ReadOnlyCollection<SourceNameEntry> CutletsInternal = Array.AsReadOnly(new[]
    {
        new SourceNameEntry(1, "أَرْض"),
        new SourceNameEntry(2, "ثَعْلَب"),
        new SourceNameEntry(3, "كُلْيَة"),
        new SourceNameEntry(4, "لَجَش"),
        new SourceNameEntry(5, "فِكْر"),
        new SourceNameEntry(6, "أَرْبَعَةُ أَتْسَاع"),
        new SourceNameEntry(7, "فَلْجُورَش"),
        new SourceNameEntry(8, "بَرْدِيّ"),
        new SourceNameEntry(9, "عُنْقُود"),
        new SourceNameEntry(10, "عَقْرَب"),
        new SourceNameEntry(11, "رَمَاد"),
        new SourceNameEntry(12, "حِنْطَة"),
        new SourceNameEntry(13, "نَهْر"),
        new SourceNameEntry(14, "ضَحِك"),
        new SourceNameEntry(15, "أَكَّد"),
        new SourceNameEntry(16, "قَرْن"),
        new SourceNameEntry(17, "الجَرَّةُ الفَارِغَة")
    });

    private static readonly ReadOnlyCollection<SourceNameEntry> MonthsInternal = Array.AsReadOnly(new[]
    {
        new SourceNameEntry(1, "طِين"),
        new SourceNameEntry(2, "رُمَّان"),
        new SourceNameEntry(3, "مِرْفَق"),
        new SourceNameEntry(4, "حَسَد"),
        new SourceNameEntry(5, "إِرِيدُو"),
        new SourceNameEntry(6, "مَعْجُونُ الأَسْنَان"),
        new SourceNameEntry(7, "ثَلَاثَةُ أَخْمَاس"),
        new SourceNameEntry(8, "كَرْشُومَب"),
        new SourceNameEntry(9, "نَمِر"),
        new SourceNameEntry(10, "قَصْدِير"),
        new SourceNameEntry(11, "ضَبَاب"),
        new SourceNameEntry(12, "لُبَان"),
        new SourceNameEntry(13, "مِغْزَل"),
        new SourceNameEntry(14, "ضِلْع"),
        new SourceNameEntry(15, "خَرُّوب"),
        new SourceNameEntry(16, "أُورُوك"),
        new SourceNameEntry(17, "خِزْي"),
        new SourceNameEntry(18, "جَمَل"),
        new SourceNameEntry(19, "نُحَاس"),
        new SourceNameEntry(20, "بِئْر"),
        new SourceNameEntry(21, "مُحُّ البَيْض"),
        new SourceNameEntry(22, "نَجْم"),
        new SourceNameEntry(23, "عَسَل"),
        new SourceNameEntry(24, "طِحَال"),
        new SourceNameEntry(25, "حَجَرُ الجِير"),
        new SourceNameEntry(26, "فَرَح"),
        new SourceNameEntry(27, "تِين"),
        new SourceNameEntry(28, "نِينَوَى"),
        new SourceNameEntry(29, "ضِفْدَع"),
        new SourceNameEntry(30, "قَار"),
        new SourceNameEntry(31, "سِرَاج"),
        new SourceNameEntry(32, "البَابُ المُغْلَق"),
        new SourceNameEntry(33, "سِمْسِم"),
        new SourceNameEntry(34, "قَفَا"),
        new SourceNameEntry(35, "فِضَّة"),
        new SourceNameEntry(36, "سَوْسَن"),
        new SourceNameEntry(37, "عَاصِفَة"),
        new SourceNameEntry(38, "حِمَار"),
        new SourceNameEntry(39, "دَقِيق"),
        new SourceNameEntry(40, "نَدَم"),
        new SourceNameEntry(41, "بَابِل"),
        new SourceNameEntry(42, "لِسَان"),
        new SourceNameEntry(43, "كَتَّان"),
        new SourceNameEntry(44, "مِلْح"),
        new SourceNameEntry(45, "كُمَّثْرَى"),
        new SourceNameEntry(46, "قَوْس"),
        new SourceNameEntry(47, "رَمْل")
    });

    public static IReadOnlyList<SourceNameEntry> Cutlets => CutletsInternal;
    public static IReadOnlyList<SourceNameEntry> Months => MonthsInternal;

    public static string ResolveCutlet(int canonicalIndex) => Resolve(CutletsInternal, canonicalIndex);
    public static string ResolveMonth(int canonicalIndex) => Resolve(MonthsInternal, canonicalIndex);

    private static string Resolve(IReadOnlyList<SourceNameEntry> entries, int canonicalIndex)
    {
        if (canonicalIndex < 1 || canonicalIndex > entries.Count)
            throw new ArgumentOutOfRangeException(nameof(canonicalIndex), "فهرس الاسم الكنسي خارج المدى المجمَّد.");
        return entries[canonicalIndex - 1].ClassicalArabic;
    }
}
