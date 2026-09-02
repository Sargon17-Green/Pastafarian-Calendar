namespace PastafarianCalendar.Monster;

public static class CalendarDateSpaghetti
{
    public static MonsterContext BootstrapInvocation(System.Numerics.BigInteger calculationDay, System.Numerics.BigInteger targetDay)
    {
        var manager = new MonsterManager();
        return manager.Prepare(calculationDay, targetDay);
    }
}
