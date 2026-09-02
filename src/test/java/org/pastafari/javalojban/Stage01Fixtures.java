package org.pastafari.javalojban;

import java.math.BigInteger;

public final class Stage01Fixtures {
    public static final BigInteger[] STONE_2 = values("378","1073","2375","6195","10493");
    public static final BigInteger HIDDEN_1_AT_FOUNDATION = new BigInteger("119390830530032782664128530203002080344");
    public static final BigInteger DROP_1_AT_FOUNDATION = new BigInteger("56644603826892212324764499696091907135");
    public static final BigInteger DROP_46_AT_FOUNDATION = new BigInteger("141872771689426650819909896585756512282");
    public static final BigInteger[] FINAL_BOWLS_AT_FOUNDATION = values(
        "65286679584284972964194865805379907599",
        "127720283375330263615328810127751035299",
        "54364069496183805843611594721403108554",
        "93072329024469476118876155742008280619",
        "54867842942953573450868747713087920246",
        "111207247632761530752404582123499651367"
    );
    public static final int[] ORDER_46_AT_FOUNDATION = {4,5,2,3,6,1};
    public static final BigInteger ASK_YEAR_5000_FIRST_AT_FOUNDATION = new BigInteger("74583638583639866316524959291339271180");
    public static final int ASK_YEAR_5000_DIRECTION_AT_FOUNDATION = 1;
    public static final BigInteger POSITIVE_GATE_GAP_1 = BigInteger.valueOf(345);
    public static final BigInteger NEGATIVE_GATE_GAP_1 = BigInteger.valueOf(503);
    public static final BigInteger YEAR_5000_OPEN_INDEX_AT_FOUNDATION = BigInteger.valueOf(-4);
    public static final BigInteger YEAR_5000_CLOSE_INDEX_AT_FOUNDATION = BigInteger.valueOf(4);
    public static final BigInteger YEAR_5000_OPEN_DAY_AT_FOUNDATION = BigInteger.valueOf(-15057703L);
    public static final BigInteger YEAR_5000_CLOSE_DAY_AT_FOUNDATION = BigInteger.valueOf(-15053459L);

    private Stage01Fixtures() {}

    private static BigInteger[] values(String... values) {
        BigInteger[] out = new BigInteger[values.length];
        for (int i=0;i<values.length;i++) out[i]=new BigInteger(values[i]);
        return out;
    }
}
