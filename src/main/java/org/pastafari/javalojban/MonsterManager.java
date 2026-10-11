package org.pastafari.javalojban;

import java.math.BigInteger;

public final class MonsterManager {
    private final MonsterDispatcher dispatcher;
    private final MonsterErrorBoundary errorBoundary;

    public MonsterManager() {
        MonsterValidationManager validationManager = new MonsterValidationManager();
        MonsterMetrics metrics = new MonsterMetrics();
        this.dispatcher = new MonsterDispatcher(validationManager, metrics);
        this.errorBoundary = new MonsterErrorBoundary();
    }

    public MonsterContext bootstrap(BigInteger calculationDay, BigInteger targetDay) {
        MonsterContext context = new MonsterContext(calculationDay, targetDay);
        return errorBoundary.execute(() -> dispatcher.dispatchBootstrap(context));
    }
    public MonsterEvaluation runSauce(BigInteger calculationDay, BigInteger targetDay) {
        MonsterContext context = new MonsterContext(calculationDay, targetDay);
        return errorBoundary.execute(() -> dispatcher.dispatchSauce(context));
    }
    public MonsterCutletCalendar.CutletDate cutletDate(
            BigInteger calculationDay, BigInteger targetDay) {
        return errorBoundary.execute(() ->
            MonsterCutletCalendar.convert(calculationDay, targetDay));
    }

    public MonsterCalendarResolver.PrefixRankedYear calendarWithPrefixRank(
            BigInteger calculationDay, BigInteger targetDay,
            int[] fixedPrefix, BigInteger localRank) {
        return errorBoundary.execute(() ->
            MonsterCalendarResolver.forTargetWithPrefixRank(
                calculationDay, targetDay, fixedPrefix, localRank));
    }

    public MonsterCalendarResolver.GlobalPrefixRankedYear calendarWithGlobalPrefixRank(
            BigInteger calculationDay, BigInteger targetDay,
            int[] fixedPrefix, BigInteger globalRank) {
        return errorBoundary.execute(() ->
            MonsterCalendarResolver.forTargetWithGlobalPrefixRank(
                calculationDay, targetDay, fixedPrefix, globalRank));
    }
}
