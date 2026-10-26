package pastafari

/** Internal oracle regression only. A full five-field date soak is not certified. */
object Post55ProductionMonthTests {
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        var matrices=0
        for(length in listOf(252,275,300,335,421)) {
            for(months in listOf(3,4,5,6)) {
                val family=ProductionMonthLengthFamily(length,months)
                val original=NormativeCore.BoundedCompositionFamily(length,months,4,123)
                check(family.countAll()==original.countAll()) {
                    "E_POST55_MONTH_FAMILY_COUNT_${length}_${months}"
                }
                if(family.countAll()>ExactInt.ZERO) {
                    for(rank in listOf(ExactInt.ONE,family.countAll())) {
                        check(family.unrank1(rank).contentEquals(original.unrank1(rank))) {
                            "E_POST55_MONTH_FAMILY_UNRANK_${length}_${months}"
                        }
                    }
                }
                matrices++
            }
        }
        check(matrices==20)
        println("POST55_PRODUCTION_MONTH_20_FAMILY_MATRIX_GREEN")
        val f=NormativeCore.FOUNDATION_DAY
        val navigator=ProductionYearNavigator()
        val oracle=NormativeCalendar()
        val engine=ProductionMonthStructureEngine()
        var years=0
        for(delta in listOf(0L,1L)) {
            val c=f+delta
            val y=navigator.findTargetYear(c,c)
            val o=oracle.findTargetYear(c,c)
            check(y.openDay==o.openGateDay && y.closeDay==o.closeGateDay)
            val month=engine.build(c,y)
            val total=(o.closeGateDay-o.openGateDay).toIntExact()
            val cooked=NormativeCore.sauce(c,o.openGateDay+1L)
            val min=(total+122)/123
            val max=minOf(47,total/4)
            val count=min+NormativeCore.chooseRankInt(
                NormativeCore.askBowl(cooked,3,30),max-min+1)-1
            val official=NormativeCore.BoundedCompositionFamily(total,count,4,123)
            val lengths=official.unrank1(NormativeCore.chooseRank(
                NormativeCore.askBowl(cooked,3,31),official.countAll()))
            val names=NormativeCore.unrankDistinctIndices(47,count,
                NormativeCore.chooseRank(
                    NormativeCore.askBowl(cooked,5,33),
                    NormativeCore.fallingFactorial(47,count)))
            check(month.monthCount==count &&
                month.lengths.contentEquals(lengths) &&
                month.canonicalIndices.contentEquals(names)
            ) { "E_POST55_PRODUCTION_MONTH_YEAR_"+delta }
            years++
        }
        check(years==2)
        println("POST55_PRODUCTION_MONTH_2_REAL_YEARS_ORACLE_GREEN")
        var rejected=false
        try {ProductionMonthLengthFamily(5779,47)}
        catch (_:IllegalArgumentException) {rejected=true}
        check(rejected) { "E_POST55_MONTH_RESOURCE_BOUND_MISSING" }
        println("POST55_PRODUCTION_MONTH_LENGTHS_AND_NAMES_NATIVE_GREEN")
        println("POST55_MONTH_COMPONENT_NOT_FULL_DATE_SOAK")
    }
}
