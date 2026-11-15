package pastafari

/**
 * Read-only probe for DIFFERENT calculation JDNs. Original Kotlin
 * ProductionYearNavigator and source branch remain untouched.
 * These are YEAR NAVIGATION records, NOT F(c,t) date conversions.
 */
object OriginalKotlinCalculationVariationV033 {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_V033_NO_ARGS" }
        val calculationDays = listOf(-15055672L, -15055670L, -15054671L)
        val foundation = ExactInt.of(-15055671L)
        val maxDistance = ExactInt.of(8192L * 963L - 5778L)
        for (value in calculationDays) {
            val c = ExactInt.of(value)
            check((c-foundation).abs() <= maxDistance) {
                "E_V033_ORIGINAL_KOTLIN_OUT_OF_SUPPORTED_DOMAIN"
            }
            val year = ProductionYearNavigator().year5000(c)
            val length = year.closeDay-year.openDay
            check(year.number == ExactInt.of(5000L) &&
                year.openDay < c && c <= year.closeDay &&
                year.closeGateIndex-year.openGateIndex >= ExactInt.of(6L) &&
                length >= ExactInt.of(252L) && length <= ExactInt.of(5778L)) {
                "E_V033_ORIGINAL_KOTLIN_YEAR_GEOMETRY"
            }
            println(listOf(
                c.toString(), year.number.toString(),
                year.openGateIndex.toString(),year.closeGateIndex.toString(),
                year.openDay.toString(),year.closeDay.toString(),
                (year.openDay+1L).toString(),year.closeDay.toString(),
                length.toString()
            ).joinToString("\t"))
        }
        System.err.println("KOTLIN_ORIGINAL_THREE_ALTERNATE_CALCULATION_BOUNDS_COMPLETE")
    }
}
