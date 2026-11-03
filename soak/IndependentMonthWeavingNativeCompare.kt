package pastafari

import java.io.File
import java.math.BigInteger

/** Diagnostic comparator only: calls real compiled production weaving engine. */
object IndependentMonthWeavingNativeCompare {
    @JvmStatic fun main(args: Array<String>) {
        require(args.size == 1) { "E_WEAVE_WITNESS_PATH" }
        var count = 0
        File(args[0]).forEachLine(Charsets.US_ASCII) { line ->
            val fields = line.split("|")
            require(fields.size == 6) { "E_WEAVE_WITNESS_FIELDS" }
            val lengths = fields[0].split(",").map { it.toInt() }.toIntArray()
            val rank = BigInteger(fields[1])
            val offset = fields[2].toInt()
            val expectedCount = BigInteger(fields[3])
            val expectedMonth = fields[4].toInt()
            val expectedDay = fields[5].toInt()
            val engine = ProductionMonthWeavingEngine(lengths)
            check(engine.countAll() == expectedCount) {
                "E_NATIVE_WEAVE_COUNT case=$count"
            }
            val got = engine.dayAt(rank, offset)
            check(got.monthOrdinal == expectedMonth && got.dayInMonth == expectedDay) {
                "E_NATIVE_WEAVE_DATE case=$count actual=$got expected=$expectedMonth,$expectedDay"
            }
            count++
        }
        check(count >= 40) { "E_NATIVE_WEAVE_WITNESSES" }
        println("PASS_NATIVE_INDEPENDENT_MONTH_WEAVING_DIFFERENTIAL_NOT_FULL_DATE_CERTIFIED " + count)
    }
}
