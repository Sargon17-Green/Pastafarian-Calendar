import java.lang.reflect.InvocationTargetException;

/**
 * Input/output transport ONLY. No calendar calculations, no epoch arithmetic,
 * no reference tables, no field normalization and no fallback computations.
 * The five fields and the native paleo-Hebrew names are returned by Codesh.
 */
public final class NativePairTransport {
    private NativePairTransport() {}

    private static String json(String value) {
        // ASCII-only JSON wire format preserves all native Unicode code units on
        // consoles where the output encoding would otherwise produce '?'.
        final StringBuilder b = new StringBuilder("\"");
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '\\' -> b.append("\\\\");
                case '"' -> b.append("\\\"");
                case '\n' -> b.append("\\n");
                case '\r' -> b.append("\\r");
                case '\t' -> b.append("\\t");
                default -> {
                    if (c < 32 || c > 126) {
                        b.append(String.format(java.util.Locale.ROOT,"\\u%04x",(int)c));
                    } else b.append(c);
                }
            }
        }
        return b.append('"').toString();
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            System.err.println("USAGE NativePairTransport ID ACTION_JDN TARGET_JDN");
            System.exit(64);
        }
        String id = args[0];
        int action = Integer.parseInt(args[1]);
        int target = Integer.parseInt(args[2]);
        Class<?> engineClass = Class.forName("מקור.המרת־זוג־טהורה");
        Object engine = engineClass.getConstructor().newInstance();
        Object date;
        try {
            date = engineClass.getMethod("המר־זוג",int.class,int.class).invoke(engine,action,target);
        } catch (InvocationTargetException e) {
            Throwable cause = e.getCause();
            if (cause instanceof Exception exception) throw exception;
            if (cause instanceof Error error) throw error;
            throw e;
        }
        Class<?> result = Class.forName("מקור.תוצאת־תאריך־טהורה");
        int year = (int)result.getMethod("קח־שנה").invoke(date);
        int cutletIndex = (int)result.getMethod("קח־קציצה").invoke(date);
        int dayInCutlet = (int)result.getMethod("קח־יום־בקציצה").invoke(date);
        int monthIndex = (int)result.getMethod("קח־חודש").invoke(date);
        int dayInMonth = (int)result.getMethod("קח־יום־בחודש").invoke(date);
        String cutletName = (String)result.getMethod("קח־שם־קציצה").invoke(date);
        String monthName = (String)result.getMethod("קח־שם־חודש").invoke(date);
        System.out.println("{\"id\":"+json(id)+",\"native\":{\"year\":"+year+
            ",\"cutletIndex\":"+cutletIndex+",\"dayInCutlet\":"+dayInCutlet+
            ",\"monthIndex\":"+monthIndex+",\"dayInMonth\":"+dayInMonth+
            ",\"codeshCutletName\":"+json(cutletName)+
            ",\"codeshMonthName\":"+json(monthName)+"}}");
    }
}