package pastafari

class NormativeCalendar {
    data class Year(
        val number: ExactInt,
        val openGateIndex: ExactInt,
        val closeGateIndex: ExactInt,
        val openGateDay: ExactInt,
        val closeGateDay: ExactInt
    )

    data class Cutlet(
        val canonicalIndex: Int,
        val openGateIndex: ExactInt,
        val closeGateIndex: ExactInt,
        val firstDay: ExactInt,
        val lastDay: ExactInt
    )

    data class YearStructure(
        val year: Year,
        val cutletCount: Int,
        val cutletPartition: IntArray,
        val cutletCanonicalIndices: IntArray,
        val cutlets: List<Cutlet>,
        val monthCount: Int,
        val monthLengths: IntArray,
        val monthWeaving: IntArray,
        val monthCanonicalIndices: IntArray
    )

    data class OracleResult(
        val yearNumber: ExactInt,
        val cutletCanonicalIndex: Int,
        val dayInCutlet: ExactInt,
        val monthCanonicalIndex: Int,
        val dayInMonth: Int
    ) {
        fun presentation(): List<Any> = listOf(
            yearNumber,
            SourceLanguageCatalog.cutlet(cutletCanonicalIndex),
            dayInCutlet,
            SourceLanguageCatalog.month(monthCanonicalIndex),
            dayInMonth
        )
    }

    inner class GateTable {
        private val gate = mutableMapOf(ExactInt.ZERO to NormativeCore.FOUNDATION_DAY)
        var minKnownGateIndex: ExactInt = ExactInt.ZERO
            private set
        var maxKnownGateIndex: ExactInt = ExactInt.ZERO
            private set

        fun get(index: ExactInt): ExactInt {
            ensureGateIndex(index)
            return gate[index] ?: error("E_ORACLE_GATE_MISSING")
        }

        fun ensureGateIndex(index: ExactInt) {
            if (index > maxKnownGateIndex) {
                var n = maxKnownGateIndex + 1L
                while (n <= index) {
                    val previous = gate[n - 1L] ?: error("E_ORACLE_GATE_PREV")
                    gate[n] = previous + positiveGateGap(n).toLong()
                    maxKnownGateIndex = n
                    n += 1L
                }
            }
            if (index < minKnownGateIndex) {
                var n = minKnownGateIndex - 1L
                while (n >= index) {
                    val next = gate[n + 1L] ?: error("E_ORACLE_GATE_NEXT")
                    gate[n] = next - negativeGateGap(n.abs()).toLong()
                    minKnownGateIndex = n
                    n -= 1L
                }
            }
        }

        fun ensureGatesCover(lowDay: ExactInt, highDay: ExactInt) {
            require(lowDay <= highDay) { "E_ORACLE_GATE_RANGE" }
            while (get(minKnownGateIndex) > lowDay) ensureGateIndex(minKnownGateIndex - 1L)
            while (get(maxKnownGateIndex) < highDay) ensureGateIndex(maxKnownGateIndex + 1L)
        }

        fun gateIndexAtOrBefore(day: ExactInt): ExactInt {
            ensureGatesCover(day, day)
            var lo = minKnownGateIndex
            var hi = maxKnownGateIndex
            val two = ExactInt.of(2)
            while (lo < hi) {
                val mid = lo + (hi - lo + 1L) / two
                if (get(mid) <= day) lo = mid else hi = mid - 1L
            }
            return lo
        }

        fun exactGateIndex(day: ExactInt): ExactInt? {
            val i = gateIndexAtOrBefore(day)
            return if (get(i) == day) i else null
        }
    }

    val gates = GateTable()

    fun positiveGateGap(n: ExactInt): Int {
        require(n >= ExactInt.ONE) { "E_ORACLE_GATE_POS" }
        val r = NormativeCore.sauce(NormativeCore.FOUNDATION_DAY, NormativeCore.FOUNDATION_DAY + n)
        val stream = NormativeCore.askBowl(r, 1, NormativeCore.SEAL_GATE_GAP)
        return 41 + NormativeCore.chooseRankInt(stream, 922)
    }

    fun negativeGateGap(n: ExactInt): Int {
        require(n >= ExactInt.ONE) { "E_ORACLE_GATE_NEG" }
        val r = NormativeCore.sauce(NormativeCore.FOUNDATION_DAY, NormativeCore.FOUNDATION_DAY - n)
        val stream = NormativeCore.askBowl(r, 1, NormativeCore.SEAL_GATE_GAP)
        return 41 + NormativeCore.chooseRankInt(stream, 922)
    }

    private fun validYearPair(openIndex: ExactInt, closeIndex: ExactInt): Boolean {
        if (closeIndex - openIndex < ExactInt.of(6)) return false
        val length = gates.get(closeIndex) - gates.get(openIndex)
        return length >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            length <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong())
    }

    fun year5000(calculationDay: ExactInt): Year {
        gates.ensureGatesCover(
            calculationDay - NormativeCore.YEAR_MAX_DAYS.toLong(),
            calculationDay + NormativeCore.YEAR_MAX_DAYS.toLong()
        )
        val candidates = mutableListOf<Pair<ExactInt, ExactInt>>()
        var i = gates.minKnownGateIndex
        while (i < gates.maxKnownGateIndex) {
            var j = i + 6L
            while (j <= gates.maxKnownGateIndex) {
                val length = gates.get(j) - gates.get(i)
                if (length > ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong())) break
                if (
                    length >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
                    gates.get(i) < calculationDay && calculationDay <= gates.get(j)
                ) {
                    candidates.add(i to j)
                }
                j += 1L
            }
            i += 1L
        }
        candidates.sortWith(
            compareBy<Pair<ExactInt, ExactInt>> { gates.get(it.second) - gates.get(it.first) }
                .thenBy { gates.get(it.first) }
        )
        require(candidates.isNotEmpty()) { "E_ORACLE_YEAR5000_EMPTY" }
        val r = NormativeCore.sauce(calculationDay, calculationDay)
        val stream = NormativeCore.askBowl(r, 1, NormativeCore.SEAL_YEAR_5000)
        val chosen = candidates[NormativeCore.chooseRankInt(stream, candidates.size) - 1]
        return Year(ExactInt.of(5000), chosen.first, chosen.second, gates.get(chosen.first), gates.get(chosen.second))
    }

    fun nextYear(calculationDay: ExactInt, knownYear: Year): Year {
        val openIndex = knownYear.closeGateIndex
        val openDay = gates.get(openIndex)
        gates.ensureGatesCover(openDay, openDay + NormativeCore.YEAR_MAX_DAYS.toLong())
        val candidates = mutableListOf<ExactInt>()
        var closeIndex = openIndex + 1L
        while (true) {
            gates.ensureGateIndex(closeIndex)
            val length = gates.get(closeIndex) - openDay
            if (length > ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong())) break
            if (validYearPair(openIndex, closeIndex)) candidates.add(closeIndex)
            closeIndex += 1L
        }
        candidates.sortBy { gates.get(it) - openDay }
        require(candidates.isNotEmpty()) { "E_ORACLE_NEXT_YEAR_EMPTY" }
        val r = NormativeCore.sauce(calculationDay, openDay)
        val stream = NormativeCore.askBowl(r, 1, NormativeCore.SEAL_NEXT_YEAR)
        val close = candidates[NormativeCore.chooseRankInt(stream, candidates.size) - 1]
        return Year(knownYear.number + 1L, openIndex, close, openDay, gates.get(close))
    }

    fun previousYear(calculationDay: ExactInt, knownYear: Year): Year {
        val closeIndex = knownYear.openGateIndex
        val closeDay = gates.get(closeIndex)
        gates.ensureGatesCover(closeDay - NormativeCore.YEAR_MAX_DAYS.toLong(), closeDay)
        val candidates = mutableListOf<ExactInt>()
        var openIndex = closeIndex - 1L
        while (true) {
            gates.ensureGateIndex(openIndex)
            val length = closeDay - gates.get(openIndex)
            if (length > ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong())) break
            if (validYearPair(openIndex, closeIndex)) candidates.add(openIndex)
            openIndex -= 1L
        }
        candidates.sortBy { closeDay - gates.get(it) }
        require(candidates.isNotEmpty()) { "E_ORACLE_PREVIOUS_YEAR_EMPTY" }
        val r = NormativeCore.sauce(calculationDay, closeDay)
        val stream = NormativeCore.askBowl(r, 1, NormativeCore.SEAL_PREVIOUS_YEAR)
        val open = candidates[NormativeCore.chooseRankInt(stream, candidates.size) - 1]
        return Year(knownYear.number - 1L, open, closeIndex, gates.get(open), closeDay)
    }

    fun findTargetYear(calculationDay: ExactInt, targetDay: ExactInt): Year {
        var y = year5000(calculationDay)
        while (targetDay > y.closeGateDay) y = nextYear(calculationDay, y)
        while (targetDay <= y.openGateDay) y = previousYear(calculationDay, y)
        require(y.openGateDay < targetDay && targetDay <= y.closeGateDay) { "E_ORACLE_YEAR_INTERVAL" }
        return y
    }

    private fun chooseCutletCount(structureSauce: NormativeCore.SauceResult, year: Year): Int {
        val gateGaps = (year.closeGateIndex - year.openGateIndex).toIntExact()
        val candidates = (NormativeCore.MIN_CUTLETS..NormativeCore.MAX_CUTLETS).filter { it <= gateGaps }
        val stream = NormativeCore.askBowl(structureSauce, 2, NormativeCore.SEAL_CUTLET_COUNT)
        return candidates[NormativeCore.chooseRankInt(stream, candidates.size) - 1]
    }

    private fun chooseCutletPartition(
        calculationDay: ExactInt,
        structureSauce: NormativeCore.SauceResult,
        year: Year,
        cutletCount: Int
    ): IntArray {
        val totalGaps = (year.closeGateIndex - year.openGateIndex).toIntExact()
        val exact = gates.exactGateIndex(calculationDay)
        val required = if (exact != null && year.openGateIndex < exact && exact < year.closeGateIndex) {
            (exact - year.openGateIndex).toIntExact()
        } else null
        val family = NormativeCore.CutletPartitionFamily(totalGaps, cutletCount, required)
        val stream = NormativeCore.askBowl(structureSauce, 2, NormativeCore.SEAL_CUTLET_PARTITION)
        val rank = NormativeCore.chooseRank(stream, family.countAll())
        return family.unrank1(rank)
    }

    private fun chooseCutletNames(structureSauce: NormativeCore.SauceResult, cutletCount: Int): IntArray {
        val n = NormativeCore.fallingFactorial(17, cutletCount)
        val stream = NormativeCore.askBowl(structureSauce, 5, NormativeCore.SEAL_CUTLET_NAMES)
        return NormativeCore.unrankDistinctIndices(17, cutletCount, NormativeCore.chooseRank(stream, n))
    }

    private fun materializeCutlets(year: Year, partition: IntArray, names: IntArray): List<Cutlet> {
        val out = ArrayList<Cutlet>()
        var cursor = year.openGateIndex
        for (k in partition.indices) {
            val open = cursor
            val close = cursor + partition[k].toLong()
            out.add(Cutlet(names[k], open, close, gates.get(open) + 1L, gates.get(close)))
            cursor = close
        }
        return out
    }

    private fun ceilDiv(a: Int, b: Int): Int = (a + b - 1) / b

    private fun chooseMonthCount(structureSauce: NormativeCore.SauceResult, year: Year): Int {
        val length = (year.closeGateDay - year.openGateDay).toIntExact()
        val minMonths = ceilDiv(length, 123)
        val maxMonths = minOf(47, length / 4)
        require(minMonths in 3..maxMonths && maxMonths <= 47) { "E_ORACLE_MONTH_COUNT_RANGE" }
        val stream = NormativeCore.askBowl(structureSauce, 3, NormativeCore.SEAL_MONTH_COUNT)
        return minMonths + NormativeCore.chooseRankInt(stream, maxMonths - minMonths + 1) - 1
    }

    private fun chooseMonthLengths(
        structureSauce: NormativeCore.SauceResult,
        year: Year,
        monthCount: Int
    ): IntArray {
        val length = (year.closeGateDay - year.openGateDay).toIntExact()
        val family = NormativeCore.BoundedCompositionFamily(length, monthCount, 4, 123)
        val stream = NormativeCore.askBowl(structureSauce, 3, NormativeCore.SEAL_MONTH_LENGTHS)
        val rank = NormativeCore.chooseRank(stream, family.countAll())
        return family.unrank1(rank)
    }

    private fun chooseMonthWeaving(structureSauce: NormativeCore.SauceResult, monthLengths: IntArray): IntArray {
        val oneBased = IntArray(monthLengths.size + 1)
        for (i in monthLengths.indices) oneBased[i + 1] = monthLengths[i]
        val family = NormativeCore.WeavingFamily(oneBased)
        val stream = NormativeCore.askBowl(structureSauce, 4, NormativeCore.SEAL_MONTH_WEAVING)
        val rank = NormativeCore.chooseRank(stream, family.countAll())
        return family.unrank1(rank)
    }

    private fun chooseMonthNames(structureSauce: NormativeCore.SauceResult, monthCount: Int): IntArray {
        val n = NormativeCore.fallingFactorial(47, monthCount)
        val stream = NormativeCore.askBowl(structureSauce, 5, NormativeCore.SEAL_MONTH_NAMES)
        return NormativeCore.unrankDistinctIndices(47, monthCount, NormativeCore.chooseRank(stream, n))
    }

    fun buildYearStructure(calculationDay: ExactInt, year: Year): YearStructure {
        val firstDay = year.openGateDay + 1L
        val r = NormativeCore.sauce(calculationDay, firstDay)
        val cutletCount = chooseCutletCount(r, year)
        val partition = chooseCutletPartition(calculationDay, r, year, cutletCount)
        val cutletNames = chooseCutletNames(r, cutletCount)
        val cutlets = materializeCutlets(year, partition, cutletNames)
        val monthCount = chooseMonthCount(r, year)
        val monthLengths = chooseMonthLengths(r, year, monthCount)
        val weaving = chooseMonthWeaving(r, monthLengths)
        val monthNames = chooseMonthNames(r, monthCount)
        return YearStructure(
            year,
            cutletCount,
            partition,
            cutletNames,
            cutlets,
            monthCount,
            monthLengths,
            weaving,
            monthNames
        )
    }

    fun calendarDate(calculationDay: ExactInt, targetDay: ExactInt): OracleResult {
        val year = findTargetYear(calculationDay, targetDay)
        val structure = buildYearStructure(calculationDay, year)
        val chosenCutlet = structure.cutlets.firstOrNull { targetDay >= it.firstDay && targetDay <= it.lastDay }
            ?: error("E_ORACLE_CUTLET_TARGET")
        val dayInCutlet = targetDay - chosenCutlet.firstDay + 1L
        val yearOffset0 = (targetDay - (year.openGateDay + 1L)).toIntExact()
        val monthId = structure.monthWeaving[yearOffset0]
        val monthCanonical = structure.monthCanonicalIndices[monthId - 1]
        var dayInMonth = 0
        for (p in 0..yearOffset0) if (structure.monthWeaving[p] == monthId) dayInMonth++
        return OracleResult(
            year.number,
            chosenCutlet.canonicalIndex,
            dayInCutlet,
            monthCanonical,
            dayInMonth
        )
    }
}
