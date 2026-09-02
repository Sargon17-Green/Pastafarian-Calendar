package org.pastafari.javalojban;

import java.util.function.Supplier;

public final class MonsterErrorBoundary {
    public <T> T execute(Supplier<T> action) {
        try {
            return action.get();
        } catch (RuntimeException ex) {
            throw ex;
        }
    }
}
