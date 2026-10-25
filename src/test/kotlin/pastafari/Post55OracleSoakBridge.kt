package pastafari

/**
 * Test-only oracle bridge. Diagnostics only: NOT the Kotlin production engine.
 * The diagnostic does not satisfy the required production-vs-production soak.
 * Protocol: c<TAB>t -> c,t,year,cutletIndex,dayInCutlet,monthIndex,dayInMonth.
 */
object Post55OracleSoakBridge {
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty()) { "E_SOAK_ORACLE_ARGS" }
        val oracle=NormativeCalendar()
        while(true) {
            val line=readLine() ?: break
            val fields=line.split('\t')
            require(fields.size==2) { "E_SOAK_ORACLE_INPUT" }
            val c=ExactInt.parse(fields[0])
            val t=ExactInt.parse(fields[1])
            val result=oracle.calendarDate(c,t)
            println(listOf(
                c.toString(),t.toString(),result.yearNumber.toString(),
                result.cutletCanonicalIndex.toString(),
                result.dayInCutlet.toString(),
                result.monthCanonicalIndex.toString(),
                result.dayInMonth.toString()
            ).joinToString("\t"))
        }
    }
}
