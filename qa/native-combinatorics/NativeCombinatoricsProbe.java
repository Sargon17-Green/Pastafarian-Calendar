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
