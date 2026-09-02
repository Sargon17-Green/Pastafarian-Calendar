package org.pastafari.javalojban;

public final class MonsterValidationManager {
    public void validateEntry(MonsterContext context) {
        if (context.calculationDay == null || context.targetDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
    }

    public void validateBootstrapState(MonsterContext context) {
        if (context.branchTrace.isEmpty()) {
            throw new IllegalStateException("E_EMPTY_TRACE");
        }
    }
}
