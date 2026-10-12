package pastafari

import java.math.BigInteger

/** Chwe chylch llawn × 720: tystion annibynnol heb oracl cynhyrchu. */
object Stage20BigIntegerTests {
    private val modulus = BigInteger("170141183460469231731687303715884105727")
    private val orderModulus = BigInteger.valueOf(720L)
    private val one = BigInteger.ONE
    private val old = listOf("0","101","211","307","401","503","607")
        .map(::BigInteger)
    private val stone = listOf("17","29","43","71","101")
        .map(::BigInteger)
    private val byPosition = intArrayOf(0,1,2,3,4,0)
    private fun saved(n: BigInteger): BigInteger =
        n.subtract(one).mod(modulus).add(one)

    private fun independentUnrank(rank0: Int): List<Int> {
        require(rank0 in 0..719)
        var n = rank0
        val remaining = mutableListOf(1,2,3,4,5,6)
        val order = ArrayList<Int>()
        for (slots in 6 downTo 1) {
            var factorial = 1
            for (i in 2 until slots) factorial *= i
            val index = n / factorial
            n %= factorial
            order.add(remaining.removeAt(index))
        }
        return order
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY10_BIGINT_ARGS" }
        val starts = listOf(
            "0", "-720", "720",
            "1234567890123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val exactOld = old.map { ExactInt.parse(it.toString()) }
        val row = MutableStoneRow(
            ExactInt.of(17L),ExactInt.of(29L),ExactInt.of(43L),
            ExactInt.of(71L),ExactInt.of(101L))
        val adapter = LegacyInPlaceBowlAdapter()
        var runsRed = 0
        var runsMatch = 0
        var firstWriteGreen = 0
        var wrongWrites = 0
        for (start in starts) for (offset in 1..720) {
            val drop = start.add(BigInteger.valueOf(offset.toLong()))
            val rank0 = drop.subtract(one).mod(orderModulus).toInt()
            val order = independentUnrank(rank0)
            val outcome = adapter.mutateBowlsWrong(
                ExactInt.parse(drop.toString()),1,exactOld,row)
            check(outcome.iteration == 1 &&
                outcome.pourPatch.order == order &&
                outcome.pourPatch.sourceIdsByPosition == order.take(3) &&
                outcome.pourPatch.correctedPourCalls == 1 &&
                outcome.pourPatch.legacyRead.fixedPourCalls == 1 &&
                outcome.writes.size == 6 &&
                outcome.writes.map { it.bowlId } == order &&
                outcome.oldSnapshot == exactOld) {
                "E_DISCOVERY10_BIGINT_SHAPE_$drop"
            }
            val pour = MutableList(7) { BigInteger.ZERO }
            for (position in 1..3) {
                pour[position] = saved(drop*drop +
                    stone[position-1]*old[order[position-1]] +
                    BigInteger.valueOf((2*position+1).toLong()))
                check(outcome.pourPatch.correctedPours[position].toString() ==
                    pour[position].toString()) {
                    "E_DISCOVERY10_BIGINT_POUR_PATCH_$drop-$position"
                }
            }
            val live = old.toMutableList()
            val correct = MutableList(7) { BigInteger.ZERO }
            var mismatch = false
            for (position in 1..6) {
                val id = order[position-1]
                val prevId = order[if (position == 1) 5 else position-2]
                val nextId = order[if (position == 6) 0 else position]
                val beforePrev = live[prevId]
                val beforeNext = live[nextId]
                val liveMix = live[id] + beforePrev*
                    BigInteger.valueOf(2) + beforeNext*
                    BigInteger.valueOf(3) + pour[position] + drop +
                    stone[byPosition[position-1]]
                live[id] = saved(liveMix*liveMix +
                    beforePrev*beforeNext*BigInteger.valueOf(5) +
                    BigInteger.valueOf(position.toLong()))
                val correctMix = old[id] +
                    old[prevId]*BigInteger.valueOf(2) +
                    old[nextId]*BigInteger.valueOf(3) +
                    pour[position] + drop + stone[byPosition[position-1]]
                correct[id] = saved(correctMix*correctMix +
                    old[prevId]*old[nextId]*BigInteger.valueOf(5) +
                    BigInteger.valueOf(position.toLong()))
                val trace = outcome.writes[position-1]
                check(trace.position == position && trace.bowlId == id &&
                    trace.previousId == prevId && trace.nextId == nextId &&
                    trace.previousLiveRead.toString() ==
                        beforePrev.toString() &&
                    trace.nextLiveRead.toString() == beforeNext.toString() &&
                    trace.newValue.toString() == live[id].toString() &&
                    outcome.newBowls[id].toString() == live[id].toString()) {
                    "E_DISCOVERY10_BIGINT_LIVE_WRITE_$drop-$position"
                }
                if (live[id] != correct[id]) {
                    mismatch = true
                    wrongWrites++
                } else if (position == 1) {
                    firstWriteGreen++
                }
            }
            if (mismatch) runsRed++ else runsMatch++
        }
        check(runsRed == 4320 && runsMatch == 0 &&
            firstWriteGreen == 4320 && wrongWrites == 21600) {
            "E_DISCOVERY10_BIGINT_CARDINALITY"
        }
        println("STAGE20_BIGINT_EXPECTED_RED_4320")
        println("STAGE20_BIGINT_MATCH_0")
        println("STAGE20_BIGINT_FIRST_WRITE_GREEN_4320")
        println("STAGE20_BIGINT_LIVE_WRONG_WRITES_21600")
    }
}
