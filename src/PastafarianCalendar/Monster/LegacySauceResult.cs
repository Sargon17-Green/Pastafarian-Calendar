using System.Numerics;

namespace PastafarianCalendar.Monster;

// الناتج العام لهذا المسار وحده يحمل الترتيب المطموس؛ لا يوجد latch مصحح بعد.
public sealed record LegacySauceResult(BigInteger[] Bowls,int[] QueryOrder);
