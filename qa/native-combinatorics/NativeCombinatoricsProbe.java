import java.lang.reflect.Method;

/** Read-only reflection transport for pure Codesh arithmetic components. */
public final class NativeCombinatoricsProbe {
    private NativeCombinatoricsProbe() {}

    private static String rawLimbs(Object number) throws Exception {
        Class<?> kind = number.getClass();
        Method getCount = kind.getMethod("קח־מנין־אברים");
        Method getSign = kind.getMethod("קח־סימן");
        Method getLimb = kind.getMethod("קח־אבר", int.class);
        int count = (int)getCount.invoke(number);
        int sign = (int)getSign.invoke(number);
        StringBuilder result = new StringBuilder();
        result.append(sign).append('\t').append(count).append('\t');
        for (int i = 0; i < count; i++) {
            if (i > 0) result.append(',');
            result.append((int)getLimb.invoke(number, i));
        }
        return result.toString();
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 0) throw new IllegalArgumentException("No inputs allowed");
        Class<?> kind = Class.forName("מקור.מניני־צירופים");
        Class<?> big = Class.forName("מקור.מספר־אין־חקר");
        Class<?> arithmeticKind = Class.forName("מקור.חשבון־אין־חקר");
        Object engine = kind.getConstructor().newInstance();
        Object arithmetic = arithmeticKind.getConstructor().newInstance();
        Method binomial = kind.getMethod("בינומי", int.class, int.class);
        Method count = kind.getMethod("מנין־ארכי־חודשים", int.class, int.class);
        Method unrank = kind.getMethod("פרק־ארכי־חודשים", int.class, int.class, big);
        Object rankOne = arithmeticKind.getMethod("הקם־מספר", int.class).invoke(arithmetic, 1);

        System.out.println("BINOM_50_20\t" + rawLimbs(binomial.invoke(engine,50,20)));
        System.out.println("BINOM_4300_40\t" + rawLimbs(binomial.invoke(engine,4300,40)));
        System.out.println("BINOM_1000_33\t" + rawLimbs(binomial.invoke(engine,1000,33)));
        Object largeBinomial = binomial.invoke(engine,5000,45);
        System.out.println("BINOM_5000_45\t" + rawLimbs(largeBinomial));
        Method divide = kind.getMethod("חלק־בשלם־מהיר", big, int.class);
        for (int divisor : new int[]{1,2,3,7,97,100,101,123,1001}) {
            System.out.println("QUOTIENT_5000_45_BY_" + divisor + "\t" + rawLimbs(divide.invoke(engine,largeBinomial,divisor)));
        }
        System.out.println("MONTH_WAYS_4244_45\t" + rawLimbs(count.invoke(engine,4244,45)));

        Method multiplyFast = arithmeticKind.getMethod("כפל־חוליות",big,big);
        Method multiplyOld = arithmeticKind.getMethod("כפל",big,big);
        Method small = arithmeticKind.getMethod("הקם־מספר",int.class);
        Object other = binomial.invoke(engine,3000,35);
        Object negative = small.invoke(arithmetic,-123456789);
        Object one = small.invoke(arithmetic,1);
        Object zero = small.invoke(arithmetic,0);
        String[] productNames = {"MUL_LARGE","MUL_SQUARE","MUL_NEGATIVE","MUL_UNIT","MUL_ZERO"};
        Object[][] productArgs = {{largeBinomial,other},{largeBinomial,largeBinomial},
            {negative,largeBinomial},{one,largeBinomial},{zero,largeBinomial}};
        for (int i=0;i<productNames.length;i++) {
            Object left=productArgs[i][0];
            Object right=productArgs[i][1];
            String current=rawLimbs(multiplyFast.invoke(arithmetic,left,right));
            String historical=rawLimbs(multiplyOld.invoke(arithmetic,left,right));
            if(!current.equals(historical)) throw new AssertionError("MUL_LEGACY_DIFFERENCE " + productNames[i]);
            System.out.println(productNames[i] + "\t" + current);
        }


        Method addFast = arithmeticKind.getMethod("חבר־חוליות",big,big);
        Method addOld = arithmeticKind.getMethod("חבר",big,big);
        Object signedOther = small.invoke(arithmetic,-98765432);
        Object carryBig = small.invoke(arithmetic,999999999);
        Object carrySmall = small.invoke(arithmetic,9999);
        String[] sumNames = {"SUM_LARGE","SUM_NEGATIVE","SUM_ZERO","SUM_BOTH_NEGATIVE","SUM_CARRY"};
        Object[][] sumArgs = {{largeBinomial,other},{negative,largeBinomial},
            {zero,largeBinomial},{negative,signedOther},{carryBig,carrySmall}};
        for(int i=0;i<sumNames.length;i++) {
            Object first=sumArgs[i][0],second=sumArgs[i][1];
            String got=rawLimbs(addFast.invoke(arithmetic,first,second));
            String was=rawLimbs(addOld.invoke(arithmetic,first,second));
            if(!got.equals(was)) throw new AssertionError("SUM_LEGACY_DIFFERENCE " + sumNames[i]);
            System.out.println(sumNames[i] + "\t" + got);
        }


        Object monthLengths = unrank.invoke(engine, 4244, 45, rankOne);
        Method length = monthLengths.getClass().getMethod("קח־מנין");
        Method item = monthLengths.getClass().getMethod("קח", int.class);
        int n = (int)length.invoke(monthLengths);
        StringBuilder numbers = new StringBuilder();
        for (int i = 0; i < n; i++) {
            if (i != 0) numbers.append(',');
            numbers.append((int)item.invoke(monthLengths,i));
        }
        System.out.println("MONTH_UNRANK_FIRST_4244_45\t" + numbers);

        // Historical regression for the original, non-multinomial weave semantics.
        Class<?> intChain = Class.forName("מקור.שרשרת־שלמים");
        Class<?> weaveKind = Class.forName("מקור.מונה־משזר־חדשים");
        Method add = intChain.getMethod("הוסף",int.class);
        Method set = weaveKind.getMethod("שים־ארכים",intChain);
        Method full = weaveKind.getMethod("מנין");
        int[][] vectors = {{4,4},{4,5,6},{4,5,6,4}};
        for (int[] values : vectors) {
            Object chain = intChain.getConstructor().newInstance();
            StringBuilder name = new StringBuilder("WEAVE");
            for (int value : values) {
                add.invoke(chain,value);
                name.append('_').append(value);
            }
            Object weaveEngine = weaveKind.getConstructor().newInstance();
            set.invoke(weaveEngine,chain);
            System.out.println(name + "\t" + rawLimbs(full.invoke(weaveEngine)));
        }
    }
}
