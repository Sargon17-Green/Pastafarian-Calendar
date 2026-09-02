using System.Numerics;

namespace PastafarianCalendar.Stage01Tests.Normative;

internal sealed record WorkCounts(BigInteger Action, BigInteger Target, BigInteger Distance, BigInteger Connection, int Direction);
internal sealed record SauceResult(BigInteger[] Bowls, int[] OrderAtDrop46);
internal sealed record AnswerStream(BigInteger First, int DirectionStep);
internal sealed record Year(BigInteger Number, BigInteger OpenGateIndex, BigInteger CloseGateIndex, BigInteger OpenGateDay, BigInteger CloseGateDay);
internal sealed record CutletRecord(int CanonicalNameIndex, BigInteger OpenGateIndex, BigInteger CloseGateIndex, BigInteger FirstDay, BigInteger LastDay);
internal sealed record YearStructure(
    int CutletCount,
    int[] CutletPartition,
    int[] CutletNameIndices,
    CutletRecord[] Cutlets,
    int MonthCount,
    int[] MonthLengths,
    int[] MonthWeaving,
    int[] MonthNameIndices);
internal sealed record NormativeDate(BigInteger YearNumber, int CutletCanonicalIndex, BigInteger DayInCutlet, int MonthCanonicalIndex, int DayInMonth);
