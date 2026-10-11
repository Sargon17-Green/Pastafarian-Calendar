package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;

public final class Stage02WeavingHeapTests {
    private static int checks;

    private Stage02WeavingHeapTests() {}

    public static void main(String[] args) {
        if (args.length != 1 ||
                (!"medium".equals(args[0]) && !"large".equals(args[0]))) {
            throw new IllegalArgumentException("E_HEAP_PROFILE");
        }
        int months = "medium".equals(args[0]) ? 8 : 16;
        int[] lengths = new int[months];
        Arrays.fill(lengths, 123);
        int totalDays = months * 123;
        MonsterWeavingEndpointDP weaving = new MonsterWeavingEndpointDP(lengths);
        BigInteger count = weaving.count();
        positive(count, "E_HEAP_COUNT");
        equal(totalDays, Arrays.stream(lengths).sum(), "E_HEAP_DAY_COVERAGE");
        positive(count.subtract(BigInteger.ONE), "E_HEAP_NONTRIVIAL");
        equal(BigInteger.ONE,
            new MonsterWeavingEndpointDP(new int[]{123}).count(),
            "E_HEAP_SINGLE_MONTH");
        System.out.println("STAGE_02_HEAP_" + args[0].toUpperCase()
            + "_PASS checks=" + checks + " heap_limit_mb="
            + (Runtime.getRuntime().maxMemory() / (1024 * 1024))
            + " days=" + totalDays);
    }

    private static void positive(BigInteger value, String code) {
        checks++;
        if (value.signum() <= 0) throw new AssertionError(code);
    }

    private static void equal(Object wanted, Object actual, String code) {
        checks++;
        if (!wanted.equals(actual)) {
            throw new AssertionError(code + " wanted=" + wanted + " got=" + actual);
        }
    }
}
