package pastafari

object NormativeCore {
    val M: ExactInt = ExactInt.parse("170141183460469231731687303715884105727")
    val TABLETS_DAY: ExactInt = ExactInt.of(-278522L)
    val FOUNDATION_DAY: ExactInt = ExactInt.of(-15055671L)
    const val GATE_GAP_MIN = 42
    const val GATE_GAP_MAX = 963
    const val YEAR_MIN_DAYS = 252
    const val YEAR_MAX_DAYS = 5778
    const val MIN_CUTLETS = 6
    const val MAX_CUTLETS = 17
    const val MIN_MONTHS = 3
    const val MAX_MONTHS = 47
    const val MIN_MONTH_DAYS = 4
    const val MAX_MONTH_DAYS = 123

    const val SEAL_GATE_GAP = 1
    const val SEAL_YEAR_5000 = 10
    const val SEAL_NEXT_YEAR = 11
    const val SEAL_PREVIOUS_YEAR = 12
    const val SEAL_CUTLET_COUNT = 20
    const val SEAL_CUTLET_PARTITION = 21
    const val SEAL_CUTLET_NAMES = 22
    const val SEAL_MONTH_COUNT = 30
    const val SEAL_MONTH_LENGTHS = 31
    const val SEAL_MONTH_WEAVING = 32
    const val SEAL_MONTH_NAMES = 33

    const val WHEAT = 0
    const val BARLEY = 1
    const val SALT = 2
    const val BITTER = 3
    const val RED = 4

    data class WorkCounts(
        val action: ExactInt,
        val target: ExactInt,
        val distance: ExactInt,
        val connection: ExactInt,
        val direction: ExactInt
    )

    data class SauceResult(
        val bowls: Array<ExactInt>,
        val orderAtDrop46: IntArray
    )

    data class AnswerStream(val first: ExactInt, val directionStep: Int)

    fun regularMod(x: ExactInt, d: ExactInt): ExactInt = x.euclideanMod(d)

    fun save(x: ExactInt): ExactInt = ExactInt.ONE + regularMod(x - ExactInt.ONE, M)

    fun wrap1(position: Int, size: Int): Int {
        val r = ((position - 1) % size + size) % size
        return r + 1
    }

    fun dayCount(day: ExactInt): ExactInt {
        return when {
            day == FOUNDATION_DAY -> ExactInt.ONE
            day > FOUNDATION_DAY -> (day - FOUNDATION_DAY).multiplyByInt(2) + 1L
            else -> (FOUNDATION_DAY - day).multiplyByInt(2)
        }
    }

    fun workCounts(calculationDay: ExactInt, targetDay: ExactInt): WorkCounts {
        val c = dayCount(calculationDay)
        val t = dayCount(targetDay)
        val chronological = (targetDay - calculationDay).abs()
        val direction = when {
            targetDay < calculationDay -> 1L
            targetDay == calculationDay -> 2L
            else -> 3L
        }
        return WorkCounts(
            c,
            t,
            chronological + 1L,
            c + t,
            ExactInt.of(direction)
        )
    }

    fun buildStones(): Array<Array<ExactInt>> {
        val table = Array(47) { Array(5) { ExactInt.ZERO } }
        table[1] = arrayOf(
            ExactInt.of(17), ExactInt.of(29), ExactInt.of(43), ExactInt.of(71), ExactInt.of(101)
        )
        for (i in 2..46) {
            val old = table[i - 1]
            table[i] = arrayOf(
                save(old[WHEAT].square() + old[BARLEY].multiplyByInt(3) + i.toLong()),
                save(old[BARLEY].square() + old[SALT].multiplyByInt(5) + old[WHEAT]),
                save(old[SALT].square() + old[BITTER].multiplyByInt(7) + old[BARLEY]),
                save(old[BITTER].square() + old[RED].multiplyByInt(11) + old[SALT]),
                save(old[RED].square() + old[WHEAT].multiplyByInt(13) + old[BITTER])
            )
        }
        return table
    }

    val STONES: Array<Array<ExactInt>> by lazy { buildStones() }

    private val hiddenCoeff = arrayOf(
        intArrayOf(0, 0, 0, 0),
        intArrayOf(3, 4, 6, 8),
        intArrayOf(5, 7, 10, 12),
        intArrayOf(7, 10, 14, 16),
        intArrayOf(9, 13, 18, 20),
        intArrayOf(11, 16, 22, 24),
        intArrayOf(13, 19, 26, 28),
        intArrayOf(15, 22, 30, 32)
    )

    private val hiddenGrindStone = intArrayOf(WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY)

    fun buildHiddenDrops(counts: WorkCounts, stones: Array<Array<ExactInt>> = STONES): Array<ExactInt> {
        val hidden = Array(8) { ExactInt.ZERO }
        for (k in 1..7) {
            val c = hiddenCoeff[k]
            var x = counts.action +
                counts.target.multiplyByInt(c[0]) +
                counts.distance.multiplyByInt(c[1]) +
                counts.connection.multiplyByInt(c[2]) +
                counts.direction.multiplyByInt(c[3])
            for (kind in 0..4) x += stones[k][kind]
            x = save(x)
            for (grind in 1..7) {
                val oldX = x
                x = save(
                    oldX.square() +
                        oldX.multiplyByInt(3) +
                        stones[k][hiddenGrindStone[grind - 1]] +
                        grind.toLong()
                )
            }
            hidden[k] = x
        }
        return hidden
    }

    private data class GrindRow(val a: Int, val b: Int, val c: Int, val d: Int, val kind: Int)

    private val visibleGrinds = arrayOf(
        GrindRow(3, 5, 7, 11, WHEAT),
        GrindRow(5, 7, 11, 13, BARLEY),
        GrindRow(7, 11, 13, 17, SALT),
        GrindRow(11, 13, 17, 19, BITTER),
        GrindRow(13, 17, 19, 23, RED),
        GrindRow(17, 19, 23, 29, WHEAT),
        GrindRow(19, 23, 29, 31, BARLEY),
        GrindRow(23, 29, 31, 37, SALT),
        GrindRow(29, 31, 37, 41, BITTER),
        GrindRow(31, 37, 41, 43, RED),
        GrindRow(37, 41, 43, 47, WHEAT)
    )

    fun buildVisibleDrops(
        counts: WorkCounts,
        stones: Array<Array<ExactInt>> = STONES,
        hidden: Array<ExactInt>
    ): Array<ExactInt> {
        val timeline = linkedMapOf<Int, ExactInt>()
        for (k in 1..7) timeline[1 - k] = hidden[k]
        val visible = Array(47) { ExactInt.ZERO }
        for (i in 1..46) {
            val p1 = timeline[i - 1] ?: error("E_ORACLE_P1")
            val p3 = timeline[i - 3] ?: error("E_ORACLE_P3")
            val p7 = timeline[i - 7] ?: error("E_ORACLE_P7")
            var x = save(
                stones[i][WHEAT] * counts.action +
                    stones[i][BARLEY] * counts.target +
                    stones[i][SALT] * counts.distance +
                    stones[i][BITTER] * counts.connection +
                    stones[i][RED] * counts.direction +
                    p1 + p3.multiplyByInt(3) + p7.multiplyByInt(5) + i.toLong()
            )
            for (row in visibleGrinds) {
                val oldX = x
                x = save(
                    oldX.square() +
                        oldX.multiplyByInt(row.a) +
                        p1.multiplyByInt(row.b) +
                        p3.multiplyByInt(row.c) +
                        p7.multiplyByInt(row.d) +
                        stones[i][row.kind]
                )
            }
            timeline[i] = x
            visible[i] = x
        }
        return visible
    }

    fun permutationUnrank1(rank1: Int, itemsAscending: IntArray): IntArray {
        require(rank1 >= 1) { "E_ORACLE_PERM_RANK" }
        var rank0 = rank1 - 1
        val remaining = itemsAscending.toMutableList()
        val result = IntArray(itemsAscending.size)
        for (position in result.indices) {
            val slotsLeft = remaining.size
            val block = factorialInt(slotsLeft - 1)
            val q = rank0 / block
            rank0 %= block
            result[position] = remaining.removeAt(q)
        }
        return result
    }

    private fun factorialInt(n: Int): Int {
        var r = 1
        for (i in 2..n) r *= i
        return r
    }

    fun bowlOrderFromDrop(dropValue: ExactInt): IntArray {
        val orderNumber = dropValue.euclideanMod(ExactInt.of(720)).let {
            val adjusted = (dropValue - ExactInt.ONE).euclideanMod(ExactInt.of(720)) + ExactInt.ONE
            adjusted.toIntExact()
        }
        return permutationUnrank1(orderNumber, intArrayOf(1, 2, 3, 4, 5, 6))
    }

    fun initialBowls(counts: WorkCounts): Array<ExactInt> {
        val prime = intArrayOf(0, 17, 19, 23, 29, 31, 37)
        val bowls = Array(7) { ExactInt.ZERO }
        for (id in 1..6) {
            val s = counts.action +
                counts.target.multiplyByInt(id) +
                counts.distance +
                counts.connection +
                counts.direction +
                ExactInt.of((prime[id] * prime[id]).toLong())
            bowls[id] = save(s.square() + id.toLong())
        }
        return bowls
    }

    fun applyVisibleDropsToBowls(
        initial: Array<ExactInt>,
        visible: Array<ExactInt>,
        stones: Array<Array<ExactInt>> = STONES
    ): Pair<Array<ExactInt>, IntArray> {
        var bowls = initial.copyOf()
        var orderAt46 = IntArray(0)
        val stoneByPosition = intArrayOf(WHEAT, BARLEY, SALT, BITTER, RED, WHEAT)
        for (i in 1..46) {
            val drop = visible[i]
            val order = bowlOrderFromDrop(drop)
            val old = bowls.copyOf()
            val pour = Array(7) { ExactInt.ZERO }
            val first = order[0]
            val second = order[1]
            val third = order[2]
            pour[1] = save(drop.square() + stones[i][WHEAT] * old[first] + (3L * i))
            pour[2] = save(drop.square() + stones[i][BARLEY] * old[second] + (5L * i))
            pour[3] = save(drop.square() + stones[i][SALT] * old[third] + (7L * i))
            val nextBowls = Array(7) { ExactInt.ZERO }
            for (position in 1..6) {
                val id = order[position - 1]
                val prevId = order[wrap1(position - 1, 6) - 1]
                val nextId = order[wrap1(position + 1, 6) - 1]
                val s = old[id] +
                    old[prevId].multiplyByInt(2) +
                    old[nextId].multiplyByInt(3) +
                    pour[position] +
                    drop +
                    stones[i][stoneByPosition[position - 1]]
                nextBowls[id] = save(
                    s.square() +
                        (old[prevId] * old[nextId]).multiplyByInt(5) +
                        ExactInt.of((i * position).toLong())
                )
            }
            bowls = nextBowls
            if (i == 46) orderAt46 = order.copyOf()
        }
        return bowls to orderAt46
    }

    fun postStir12(initial: Array<ExactInt>): Array<ExactInt> {
        var bowls = initial.copyOf()
        for (stir in 1..12) {
            val old = bowls.copyOf()
            var sum = ExactInt.ZERO
            for (id in 1..6) sum += old[id]
            val savedBowlSum = save(sum + 149L * ExactInt.of(stir.toLong()))
            val orderNumber = ((savedBowlSum - ExactInt.ONE).euclideanMod(ExactInt.of(720)) + ExactInt.ONE).toIntExact()
            val order = permutationUnrank1(orderNumber, intArrayOf(1, 2, 3, 4, 5, 6))
            val nextBowls = Array(7) { ExactInt.ZERO }
            for (position in 1..6) {
                val id = order[position - 1]
                val prevId = order[wrap1(position - 1, 6) - 1]
                val nextId = order[wrap1(position + 1, 6) - 1]
                val s = old[id] +
                    old[prevId].multiplyByInt(3) +
                    old[nextId].multiplyByInt(5) +
                    savedBowlSum +
                    stir.toLong() +
                    ExactInt.of((position * position).toLong())
                nextBowls[id] = save(s.square() + (old[prevId] * old[nextId]).multiplyByInt(7))
            }
            bowls = nextBowls
        }
        return bowls
    }

    fun sauce(calculationDay: ExactInt, targetDay: ExactInt): SauceResult {
        val counts = workCounts(calculationDay, targetDay)
        val hidden = buildHiddenDrops(counts)
        val visible = buildVisibleDrops(counts, STONES, hidden)
        val initial = initialBowls(counts)
        val (afterDrops, order) = applyVisibleDropsToBowls(initial, visible)
        val finalBowls = postStir12(afterDrops)
        return SauceResult(finalBowls, order)
    }

    fun nextBowlInDrop46Order(result: SauceResult, queriedBowlId: Int): Int {
        val p = result.orderAtDrop46.indexOf(queriedBowlId)
        require(p >= 0) { "E_ORACLE_QUERY_BOWL" }
        return result.orderAtDrop46[(p + 1) % 6]
    }

    fun askBowl(result: SauceResult, queriedBowlId: Int, seal: Int): AnswerStream {
        val nextId = nextBowlInDrop46Order(result, queriedBowlId)
        val firstBase = result.bowls[queriedBowlId] + seal.toLong() + 181L
        val first = save(
            firstBase.square() +
                result.bowls[nextId].multiplyByInt(179) +
                seal.toLong()
        )
        val directionBase = first + seal.toLong() + 1L + 193L
        val directionNumber = save(
            directionBase.square() +
                first.multiplyByInt(193) +
                result.bowls[6].multiplyByInt(197)
        )
        val step = if (directionNumber.modInt(2) == 1) 1 else -1
        return AnswerStream(first, step)
    }

    fun answerAt(stream: AnswerStream, k: Int): ExactInt {
        return ExactInt.ONE + (
            stream.first - ExactInt.ONE + ExactInt.of((stream.directionStep.toLong() * k.toLong()))
            ).euclideanMod(M)
    }

    fun chooseRankShort(stream: AnswerStream, n: ExactInt): ExactInt {
        require(n >= ExactInt.ONE && n <= M) { "E_ORACLE_SHORT_N" }
        val acceptanceLimit = (M / n) * n
        var k = 0
        while (true) {
            val x = answerAt(stream, k)
            if (x <= acceptanceLimit) return (x - ExactInt.ONE).euclideanMod(n) + ExactInt.ONE
            k++
        }
    }

    fun chooseRankWide(stream: AnswerStream, n: ExactInt): ExactInt {
        require(n > M) { "E_ORACLE_WIDE_N" }
        var places = 1
        var space = M
        while (space < n) {
            places++
            space *= M
        }
        var wide = ExactInt.ONE
        var weight = ExactInt.ONE
        for (j in 0 until places) {
            val digit = answerAt(stream, j) - ExactInt.ONE
            wide += digit * weight
            weight *= M
        }
        val acceptanceLimit = (space / n) * n
        while (wide > acceptanceLimit) {
            wide = ExactInt.ONE + (wide - ExactInt.ONE + stream.directionStep.toLong()).euclideanMod(space)
        }
        return (wide - ExactInt.ONE).euclideanMod(n) + ExactInt.ONE
    }

    fun chooseRank(stream: AnswerStream, n: ExactInt): ExactInt =
        if (n <= M) chooseRankShort(stream, n) else chooseRankWide(stream, n)

    fun chooseRankInt(stream: AnswerStream, n: Int): Int = chooseRank(stream, ExactInt.of(n.toLong())).toIntExact()

    fun fallingFactorial(n: Int, k: Int): ExactInt {
        var r = ExactInt.ONE
        for (j in 0 until k) r *= ExactInt.of((n - j).toLong())
        return r
    }

    fun unrankDistinctIndices(n: Int, k: Int, rank1: ExactInt): IntArray {
        val remaining = (1..n).toMutableList()
        val out = IntArray(k)
        var r = rank1
        for (position in 0 until k) {
            val suffixLength = k - position - 1
            val block = fallingFactorial(remaining.size - 1, suffixLength)
            var chosen = -1
            for (candidate in remaining.indices) {
                if (r > block) {
                    r -= block
                } else {
                    chosen = candidate
                    break
                }
            }
            require(chosen >= 0) { "E_ORACLE_UNRANK_NAMES" }
            out[position] = remaining.removeAt(chosen)
        }
        return out
    }

    class BoundedCompositionFamily(
        private val total: Int,
        private val slots: Int,
        private val lo: Int,
        private val hi: Int
    ) {
        private val memo = HashMap<Pair<Int, Int>, ExactInt>()

        private fun count(rem: Int, k: Int): ExactInt {
            if (k == 0) return if (rem == 0) ExactInt.ONE else ExactInt.ZERO
            if (rem < k * lo || rem > k * hi) return ExactInt.ZERO
            val key = rem to k
            return memo.getOrPut(key) {
                var s = ExactInt.ZERO
                for (x in lo..hi) s += count(rem - x, k - 1)
                s
            }
        }

        fun countAll(): ExactInt = count(total, slots)

        fun unrank1(rank1: ExactInt): IntArray {
            require(rank1 >= ExactInt.ONE && rank1 <= countAll()) { "E_ORACLE_BOUNDED_RANK" }
            var r = rank1
            var rem = total
            val out = IntArray(slots)
            for (position in 0 until slots) {
                var selected = -1
                for (x in lo..hi) {
                    val block = count(rem - x, slots - position - 1)
                    if (r > block) r -= block else {
                        selected = x
                        break
                    }
                }
                require(selected >= 0) { "E_ORACLE_BOUNDED_UNRANK" }
                out[position] = selected
                rem -= selected
            }
            return out
        }
    }

    class CutletPartitionFamily(
        private val totalGaps: Int,
        private val cutletCount: Int,
        private val requiredBoundary: Int?
    ) {
        private data class Key(val rem: Int, val slots: Int, val cumulative: Int, val hit: Boolean)
        private val memo = HashMap<Key, ExactInt>()

        private fun count(rem: Int, slots: Int, cumulative: Int, hit: Boolean): ExactInt {
            if (slots == 0) {
                if (rem != 0) return ExactInt.ZERO
                return if (requiredBoundary == null || hit) ExactInt.ONE else ExactInt.ZERO
            }
            if (rem < slots) return ExactInt.ZERO
            val key = Key(rem, slots, cumulative, hit)
            return memo.getOrPut(key) {
                var total = ExactInt.ZERO
                val maxX = rem - (slots - 1)
                for (x in 1..maxX) {
                    val nextCumulative = cumulative + x
                    var nextHit = hit
                    if (requiredBoundary != null && !hit) {
                        if (nextCumulative == requiredBoundary) nextHit = true
                        else if (nextCumulative > requiredBoundary) continue
                    }
                    total += count(rem - x, slots - 1, nextCumulative, nextHit)
                }
                total
            }
        }

        fun countAll(): ExactInt = count(totalGaps, cutletCount, 0, false)

        fun unrank1(rank1: ExactInt): IntArray {
            require(rank1 >= ExactInt.ONE && rank1 <= countAll()) { "E_ORACLE_CUTLET_RANK" }
            var r = rank1
            var rem = totalGaps
            var slots = cutletCount
            var cumulative = 0
            var hit = false
            val out = IntArray(cutletCount)
            var position = 0
            while (slots > 0) {
                val maxX = rem - (slots - 1)
                var selected = -1
                var selectedHit = hit
                for (x in 1..maxX) {
                    val nextCumulative = cumulative + x
                    var nextHit = hit
                    if (requiredBoundary != null && !hit) {
                        if (nextCumulative == requiredBoundary) nextHit = true
                        else if (nextCumulative > requiredBoundary) continue
                    }
                    val block = count(rem - x, slots - 1, nextCumulative, nextHit)
                    if (r > block) r -= block else {
                        selected = x
                        selectedHit = nextHit
                        break
                    }
                }
                require(selected >= 0) { "E_ORACLE_CUTLET_UNRANK" }
                out[position++] = selected
                rem -= selected
                slots--
                cumulative += selected
                hit = selectedHit
            }
            return out
        }
    }

    class WeavingFamily(private val lengths: IntArray) {
        private data class Key(val remaining: List<Int>, val opened: Int, val closed: Int)
        private val memo = HashMap<Key, ExactInt>()

        private fun legal(remaining: IntArray, opened: Int, closed: Int, j: Int): Boolean {
            if (remaining[j] == 0) return false
            val alreadyOpened = remaining[j] < lengths[j]
            if (!alreadyOpened && j != opened + 1) return false
            val willClose = remaining[j] == 1
            if (willClose && j != closed + 1) return false
            return true
        }

        private fun apply(remaining: IntArray, opened: Int, closed: Int, j: Int): Triple<IntArray, Int, Int> {
            val next = remaining.copyOf()
            var nextOpened = opened
            var nextClosed = closed
            if (next[j] == lengths[j]) nextOpened = j
            next[j]--
            if (next[j] == 0) nextClosed = j
            return Triple(next, nextOpened, nextClosed)
        }

        private fun count(remaining: IntArray, opened: Int, closed: Int): ExactInt {
            var allZero = true
            for (j in 1 until remaining.size) if (remaining[j] != 0) { allZero = false; break }
            if (allZero) return ExactInt.ONE
            val key = Key(remaining.drop(1), opened, closed)
            return memo.getOrPut(key) {
                var total = ExactInt.ZERO
                for (j in 1 until remaining.size) {
                    if (!legal(remaining, opened, closed, j)) continue
                    val (next, no, nc) = apply(remaining, opened, closed, j)
                    total += count(next, no, nc)
                }
                total
            }
        }

        private fun initial(): IntArray {
            val r = IntArray(lengths.size)
            for (i in 1 until lengths.size) r[i] = lengths[i]
            return r
        }

        fun countAll(): ExactInt = count(initial(), 0, 0)

        fun unrank1(rank1: ExactInt): IntArray {
            require(rank1 >= ExactInt.ONE && rank1 <= countAll()) { "E_ORACLE_WEAVE_RANK" }
            var r = rank1
            var remaining = initial()
            var opened = 0
            var closed = 0
            val totalLength = lengths.drop(1).sum()
            val out = IntArray(totalLength)
            for (position in 0 until totalLength) {
                var selected = -1
                var selectedState: Triple<IntArray, Int, Int>? = null
                for (j in 1 until remaining.size) {
                    if (!legal(remaining, opened, closed, j)) continue
                    val next = apply(remaining, opened, closed, j)
                    val block = count(next.first, next.second, next.third)
                    if (r > block) r -= block else {
                        selected = j
                        selectedState = next
                        break
                    }
                }
                require(selected >= 0 && selectedState != null) { "E_ORACLE_WEAVE_UNRANK" }
                out[position] = selected
                remaining = selectedState.first
                opened = selectedState.second
                closed = selectedState.third
            }
            return out
        }
    }
}
