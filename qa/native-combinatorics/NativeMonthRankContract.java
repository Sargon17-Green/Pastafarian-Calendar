import java.lang.reflect.Method;
import java.util.Arrays;

/** Bounded invariant oracle for native 1-based month-rank decoding. */
public final class NativeMonthRankContract {
  private static void check(boolean ok, String details) {
    if (!ok) throw new AssertionError(details);
  }
  public static void main(String[] args) throws Exception {
    check(args.length == 0, "no arguments");
    Class<?> chain=Class.forName("מקור.שרשרת־שלמים");
    Class<?> big=Class.forName("מקור.מספר־אין־חקר");
    Class<?> arith=Class.forName("מקור.חשבון־אין־חקר");
    Class<?> solver=Class.forName("מקור.דרוג־שזירה־טהור");
    Class<?> result=Class.forName("מקור.מענה־שזירה־טהור");
    Object factory=arith.getConstructor().newInstance();
    Object nativeSolver=solver.getConstructor().newInstance();
    Method fromInt=arith.getMethod("הקם־מספר",int.class);
    Method append=chain.getMethod("הוסף",int.class);
    Method decode=solver.getMethod("חודש־מדרגה",chain,big,int.class);
    Method index=result.getMethod("קח־מדד־חודש");
    Method day=result.getMethod("קח־יום־בחודש");
    int valid=0;
    for(int[] lengths:new int[][]{{4,4},{4,5,6}}){
      Object items=chain.getConstructor().newInstance();
      int total=0;
      for(int length:lengths){append.invoke(items,length); total+=length;}
      for(int rank:new int[]{1,2,10,20}){
        Object rankValue=fromInt.invoke(factory,rank);
        int[] seen=new int[lengths.length];
        for(int step=1;step<=total;step++){
          Object value=decode.invoke(nativeSolver,items,rankValue,step);
          int month=(int)index.invoke(value);
          int ordinal=(int)day.invoke(value);
          check(month>=0 && month<lengths.length,
                "invalid month: lengths="+Arrays.toString(lengths)+" rank="+rank+" step="+step+" month="+month);
          seen[month]++;
          check(ordinal==seen[month] && ordinal>=1 && ordinal<=lengths[month],
                "invalid ordinal: rank="+rank+" step="+step+" ordinal="+ordinal+" seen="+seen[month]);
          valid++;
        }
        check(Arrays.equals(seen,lengths),"wrong total counts: rank="+rank+" seen="+Arrays.toString(seen));
      }
      for(int bad:new int[]{0,-1}){
        Object value=decode.invoke(nativeSolver,items,fromInt.invoke(factory,bad),1);
        check((int)day.invoke(value)==0,"invalid rank accepted="+bad);
      }
    }
    System.out.println("CODESH_MONTH_RANK_BOUNDED_PASS validDays="+valid+" rejectedRanks=4");
  }
}
