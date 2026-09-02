package org.pastafari.javalojban;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class Stage01Tests {
    private static int checks = 0;

    public static void main(String[] args) throws Exception {
        testConstants();
        testSave();
        testDayCounts();
        testWorkCounts();
        testStones();
        testSauceFixtures();
        testPermutation();
        testSelectors();
        testFamilies();
        testGateAndYearFixtures();
        testCatalog();
        testBootstrapSkeleton();
        testProjectText();
        System.out.println("STAGE_01_PASS checks=" + checks);
    }

    private static void testConstants() {
        eq(BigInteger.valueOf(14777149L),NormativeOracle.TABLETS_DAY.subtract(NormativeOracle.FOUNDATION_DAY),"E_CONST_DISTANCE");
        eq(BigInteger.TWO.pow(127).subtract(BigInteger.ONE),NormativeOracle.M,"E_CONST_M");
        eq(5778,NormativeOracle.YEAR_MAX_DAYS,"E_YEAR_MAX");
    }

    private static void testSave() {
        eq(BigInteger.ONE,NormativeOracle.save(BigInteger.ONE),"E_SAVE_1");
        eq(NormativeOracle.M.subtract(BigInteger.ONE),NormativeOracle.save(NormativeOracle.M.subtract(BigInteger.ONE)),"E_SAVE_M1");
        eq(NormativeOracle.M,NormativeOracle.save(NormativeOracle.M),"E_SAVE_M");
        eq(BigInteger.ONE,NormativeOracle.save(NormativeOracle.M.add(BigInteger.ONE)),"E_SAVE_MP1");
        eq(NormativeOracle.M,NormativeOracle.save(NormativeOracle.M.multiply(BigInteger.TWO)),"E_SAVE_2M");
        eq(NormativeOracle.M,NormativeOracle.save(NormativeOracle.M.multiply(BigInteger.valueOf(3))),"E_SAVE_3M");
        eq(NormativeOracle.M,NormativeOracle.save(BigInteger.ZERO),"E_SAVE_0");
    }

    private static void testDayCounts() {
        eq(BigInteger.ONE,NormativeOracle.dayCount(NormativeOracle.FOUNDATION_DAY),"E_DAY_F");
        eq(BigInteger.valueOf(3),NormativeOracle.dayCount(NormativeOracle.FOUNDATION_DAY.add(BigInteger.ONE)),"E_DAY_FP1");
        eq(BigInteger.valueOf(2),NormativeOracle.dayCount(NormativeOracle.FOUNDATION_DAY.subtract(BigInteger.ONE)),"E_DAY_FM1");
    }

    private static void testWorkCounts() {
        NormativeOracle.WorkCounts w=NormativeOracle.workCounts(NormativeOracle.FOUNDATION_DAY,NormativeOracle.FOUNDATION_DAY);
        eq(BigInteger.ONE,w.action(),"E_WC_A");
        eq(BigInteger.ONE,w.target(),"E_WC_T");
        eq(BigInteger.ONE,w.distance(),"E_WC_D");
        eq(BigInteger.valueOf(2),w.connection(),"E_WC_C");
        eq(2,w.direction(),"E_WC_W");
        NormativeOracle.WorkCounts x=NormativeOracle.workCounts(NormativeOracle.FOUNDATION_DAY.add(BigInteger.TEN),NormativeOracle.FOUNDATION_DAY.subtract(BigInteger.TEN));
        eq(BigInteger.valueOf(21),x.distance(),"E_WC_CROSS_D");
        eq(1,x.direction(),"E_WC_CROSS_W");
    }

    private static void testStones() {
        BigInteger[][] table=NormativeOracle.stoneTableCopy();
        for (int i=0;i<5;i++) eq(Stage01Fixtures.STONE_2[i],table[2][i+1],"E_STONE2_"+i);
        BigInteger before=table[2][1];
        table[2][1]=BigInteger.ZERO;
        eq(before,NormativeOracle.stoneTableCopy()[2][1],"E_STONE_COPY");
    }

    private static void testSauceFixtures() {
        NormativeOracle.WorkCounts wc=NormativeOracle.workCounts(NormativeOracle.FOUNDATION_DAY,NormativeOracle.FOUNDATION_DAY);
        BigInteger[] hidden=NormativeOracle.buildHiddenDrops(wc);
        eq(Stage01Fixtures.HIDDEN_1_AT_FOUNDATION,hidden[1],"E_HIDDEN1");
        BigInteger[] visible=NormativeOracle.buildVisibleDrops(wc,hidden);
        eq(Stage01Fixtures.DROP_1_AT_FOUNDATION,visible[1],"E_DROP1");
        eq(Stage01Fixtures.DROP_46_AT_FOUNDATION,visible[46],"E_DROP46");
        NormativeOracle.SauceResult s=NormativeOracle.sauce(NormativeOracle.FOUNDATION_DAY,NormativeOracle.FOUNDATION_DAY);
        for (int i=0;i<6;i++) eq(Stage01Fixtures.FINAL_BOWLS_AT_FOUNDATION[i],s.bowls()[i+1],"E_BOWL_"+i);
        arr(Stage01Fixtures.ORDER_46_AT_FOUNDATION,s.orderAtDrop46(),"E_ORDER46");
        eq(4,NormativeOracle.nextBowlInDrop46Order(s,1),"E_NEXT_WRAP");
        NormativeOracle.AnswerStream a=NormativeOracle.askBowl(s,1,NormativeOracle.SEAL_YEAR_5000);
        eq(Stage01Fixtures.ASK_YEAR_5000_FIRST_AT_FOUNDATION,a.first(),"E_ASK_FIRST");
        eq(Stage01Fixtures.ASK_YEAR_5000_DIRECTION_AT_FOUNDATION,a.directionStep(),"E_ASK_DIR");
    }

    private static void testPermutation() {
        arr(new int[]{1,2,3,4,5,6},NormativeOracle.permutationUnrank1(1),"E_PERM1");
        arr(new int[]{6,5,4,3,2,1},NormativeOracle.permutationUnrank1(720),"E_PERM720");
        arr(new int[]{6,5,4,3,2,1},NormativeOracle.bowlOrderFromDrop(BigInteger.valueOf(720)),"E_DROP720");
    }

    private static void testSelectors() {
        NormativeOracle.AnswerStream plus=new NormativeOracle.AnswerStream(BigInteger.ONE,1);
        eq(BigInteger.ONE,NormativeOracle.chooseRank(plus,BigInteger.ONE),"E_PICK1");
        eq(BigInteger.ONE,NormativeOracle.chooseRank(plus,NormativeOracle.M),"E_PICKM");
        BigInteger wideN=NormativeOracle.M.add(BigInteger.ONE);
        BigInteger r=NormativeOracle.chooseRank(new NormativeOracle.AnswerStream(BigInteger.valueOf(7),1),wideN);
        ok(r.compareTo(BigInteger.ONE)>=0 && r.compareTo(wideN)<=0,"E_PICK_WIDE_RANGE");
    }

    private static void testFamilies() {
        eq(BigInteger.valueOf(60),NormativeOracle.fallingFactorial(5,3),"E_FALLING");
        arr(new int[]{1,2,3},NormativeOracle.unrankDistinctIndices(5,3,BigInteger.ONE),"E_NAMES_FIRST");
        arr(new int[]{5,4,3},NormativeOracle.unrankDistinctIndices(5,3,BigInteger.valueOf(60)),"E_NAMES_LAST");
        NormativeOracle.BoundedCompositionFamily b=new NormativeOracle.BoundedCompositionFamily(9,3,2,4);
        eq(BigInteger.valueOf(7),b.count(),"E_BCOMP_COUNT");
        arr(new int[]{2,3,4},b.unrank1(BigInteger.ONE),"E_BCOMP_FIRST");
        arr(new int[]{4,3,2},b.unrank1(BigInteger.valueOf(7)),"E_BCOMP_LAST");
        NormativeOracle.CutletPartitionFamily c=new NormativeOracle.CutletPartitionFamily(7,3,3);
        eq(BigInteger.valueOf(5),c.count(),"E_CUT_COMP_COUNT");
        int[] p=c.unrank1(BigInteger.ONE);
        ok(prefixContains(p,3),"E_CUT_COMP_BOUNDARY");
        NormativeOracle.WeavingFamily w=new NormativeOracle.WeavingFamily(new int[]{2,2});
        eq(BigInteger.valueOf(2),w.count(),"E_WEAVE22_COUNT");
        arr(new int[]{1,1,2,2},w.unrank1(BigInteger.ONE),"E_WEAVE22_1");
        arr(new int[]{1,2,1,2},w.unrank1(BigInteger.valueOf(2)),"E_WEAVE22_2");
        NormativeOracle.WeavingFamily w3=new NormativeOracle.WeavingFamily(new int[]{2,2,2});
        eq(BigInteger.valueOf(5),w3.count(),"E_WEAVE222_COUNT");
    }

    private static boolean prefixContains(int[] p,int wanted) {
        int s=0;
        for (int x:p) { s+=x; if (s==wanted) return true; }
        return false;
    }

    private static void testGateAndYearFixtures() {
        NormativeOracle o=new NormativeOracle();
        eq(Stage01Fixtures.POSITIVE_GATE_GAP_1,o.positiveGateGap(BigInteger.ONE),"E_GATE_P1");
        eq(Stage01Fixtures.NEGATIVE_GATE_GAP_1,o.negativeGateGap(BigInteger.ONE),"E_GATE_M1");
        NormativeOracle.Year y=o.year5000(NormativeOracle.FOUNDATION_DAY);
        eq(BigInteger.valueOf(5000),y.number(),"E_Y5000_NUMBER");
        eq(Stage01Fixtures.YEAR_5000_OPEN_INDEX_AT_FOUNDATION,y.openGateIndex(),"E_Y5000_OI");
        eq(Stage01Fixtures.YEAR_5000_CLOSE_INDEX_AT_FOUNDATION,y.closeGateIndex(),"E_Y5000_CI");
        eq(Stage01Fixtures.YEAR_5000_OPEN_DAY_AT_FOUNDATION,y.openGateDay(),"E_Y5000_OD");
        eq(Stage01Fixtures.YEAR_5000_CLOSE_DAY_AT_FOUNDATION,y.closeGateDay(),"E_Y5000_CD");
        ok(y.closeGateDay().subtract(y.openGateDay()).compareTo(BigInteger.valueOf(5778))<=0,"E_Y5000_MAX");
    }

    private static void testCatalog() {
        List<SourceLanguageCatalog.Entry> c=SourceLanguageCatalog.cutlets();
        List<SourceLanguageCatalog.Entry> m=SourceLanguageCatalog.months();
        eq(17,c.size(),"E_CAT_C_SIZE");
        eq(47,m.size(),"E_CAT_M_SIZE");
        Set<String> cs=new HashSet<>();
        Set<String> ms=new HashSet<>();
        for (int i=0;i<c.size();i++) {
            eq(i+1,c.get(i).canonicalIndex(),"E_CAT_C_INDEX_"+i);
            ok(cs.add(c.get(i).sourceText()),"E_CAT_C_UNIQUE_"+i);
        }
        for (int i=0;i<m.size();i++) {
            eq(i+1,m.get(i).canonicalIndex(),"E_CAT_M_INDEX_"+i);
            ok(ms.add(m.get(i).sourceText()),"E_CAT_M_UNIQUE_"+i);
        }
        eq("maxri",SourceLanguageCatalog.cutletName(12),"E_CAT_WHEAT");
        eq("xasli",SourceLanguageCatalog.monthName(38),"E_CAT_DONKEY");
        eq("silna",SourceLanguageCatalog.monthName(44),"E_CAT_SALT");
        eq("ransu",SourceLanguageCatalog.cutletName(1),"E_CAT_BRONZE");
        eq("lorxu",SourceLanguageCatalog.cutletName(2),"E_CAT_FOX");
        eq("tirxu",SourceLanguageCatalog.monthName(9),"E_CAT_TIGER");
        eq("tinci",SourceLanguageCatalog.monthName(10),"E_CAT_TIN");
        eq("bumru",SourceLanguageCatalog.monthName(11),"E_CAT_FOG");
        eq("kumte",SourceLanguageCatalog.monthName(18),"E_CAT_CAMEL");
        eq("tunka",SourceLanguageCatalog.monthName(19),"E_CAT_COPPER");
        eq("tarla",SourceLanguageCatalog.monthName(30),"E_CAT_TAR");
        eq("figre",SourceLanguageCatalog.monthName(27),"E_CAT_FIG");
        eq("rijno",SourceLanguageCatalog.monthName(35),"E_CAT_SILVER");
        eq("lelxe",SourceLanguageCatalog.monthName(36),"E_CAT_LILY");
        eq("lo nu xenru",SourceLanguageCatalog.monthName(40),"E_CAT_REGRET");
        eq("tance",SourceLanguageCatalog.monthName(42),"E_CAT_TONGUE");
        eq("matli",SourceLanguageCatalog.monthName(43),"E_CAT_FLAX");
        eq("perli",SourceLanguageCatalog.monthName(45),"E_CAT_PEAR");
        eq("bagyce'a",SourceLanguageCatalog.monthName(46),"E_CAT_BOW");
        eq("canre",SourceLanguageCatalog.monthName(47),"E_CAT_SAND");
    }

    private static void testBootstrapSkeleton() {
        MonsterManager manager=new MonsterManager();
        MonsterContext a=manager.bootstrap(BigInteger.ONE,BigInteger.TWO);
        MonsterContext b=manager.bootstrap(BigInteger.ONE,BigInteger.TWO);
        ok(a!=b,"E_CTX_IDENTITY");
        eq("READY",a.status,"E_CTX_STATUS");
        eq(2,a.branchTrace.size(),"E_CTX_TRACE");
        eq(BigInteger.ONE,a.metrics.get("bootstrap.entry"),"E_CTX_METRIC");
        a.branchTrace.add("X");
        eq(2,b.branchTrace.size(),"E_CTX_ISOLATION");
    }

    private static void testProjectText() throws Exception {
        Path root=Path.of(".").toAbsolutePath().normalize();
        List<String> docs=List.of("README.md","SOURCE_LANGUAGE_CATALOG.md","DEVELOPMENT_STAGE.md","SPAGHETTI_DEVELOPMENT_HISTORY.md","HANDOFF_STAGE_01.md");
        for (String name:docs) {
            String s=Files.readString(root.resolve(name),StandardCharsets.UTF_8);
            ok(!hasHebrew(s),"E_DOC_HEBREW_"+name);
        }
        try (var stream=Files.walk(root.resolve("src"))) {
            for (Path p:stream.filter(x -> x.toString().endsWith(".java")).toList()) {
                String s=Files.readString(p,StandardCharsets.UTF_8);
                ok(!s.contains("/"+"/") && !s.contains("/"+"*"),"E_JAVA_COMMENT_"+p.getFileName());
                ok(!hasHebrew(s),"E_JAVA_HEBREW_"+p.getFileName());
            }
        }
    }

    private static boolean hasHebrew(String s) {
        return s.codePoints().anyMatch(cp -> cp>=0x0590 && cp<=0x05FF);
    }

    private static void ok(boolean condition,String code) {
        checks++;
        if (!condition) throw new AssertionError(code);
    }

    private static void eq(Object expected,Object actual,String code) {
        checks++;
        if (!expected.equals(actual)) throw new AssertionError(code+" expected="+expected+" actual="+actual);
    }

    private static void arr(int[] expected,int[] actual,String code) {
        checks++;
        if (!Arrays.equals(expected,actual)) throw new AssertionError(code+" expected="+Arrays.toString(expected)+" actual="+Arrays.toString(actual));
    }
}
