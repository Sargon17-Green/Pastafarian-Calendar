using System.Numerics;

namespace PastafarianCalendar.Monster;

public sealed class HiddenNearnessWrapper
{
    private static readonly BigInteger Modulus = (BigInteger.One << 127) - BigInteger.One;
    private readonly BigInteger[] _legacyStorage;

    // لا نغيّر ترتيب المخزن القديم، ولا ننشئ مصفوفة جديدة مرتبة.
    // يبقى الموضع السابع فيه هو القطرة الأولى، والموضع الأول هو القطرة السابعة.
    public HiddenNearnessWrapper(BigInteger[] legacyStorage)
    {
        if (legacyStorage is null || legacyStorage.Length != 8)
            throw new MonsterValidationException("تتطلب رقعة الفهرس ثماني خانات محفوظة بالترتيب التاريخي.");
        if (legacyStorage[0] != BigInteger.Zero)
            throw new MonsterValidationException("الخانة الصفرية في المخزن التاريخي ليست قطرة خفية.");

        for (var slot = 1; slot <= 7; slot++)
            if (legacyStorage[slot] < BigInteger.One || legacyStorage[slot] > Modulus)
                throw new MonsterValidationException("قيمة قطرة تاريخية خارج مجال الحفظ.");

        _legacyStorage = legacyStorage;
    }

    // الكاف هي رتبة القرب، لا موضع التخزين: القراءة تمر عبر 8-k دوماً.
    public BigInteger HiddenByNearness(int k)
    {
        if (k is < 1 or > 7)
            throw new MonsterValidationException("رتبة قرب القطرة الخفية خارج المدى.");

        var value = _legacyStorage[8 - k];
        if (value < BigInteger.One || value > Modulus)
            throw new MonsterValidationException("تغيّرت قيمة القطرة المخفية بعد تثبيت المخزن.");
        return value;
    }

    internal bool UsesUnchangedLegacyStorage(BigInteger[] storage)
        => ReferenceEquals(storage, _legacyStorage);
}
