package pastafari

/**
 * Post-55 production month counts, bounded compositions and canonical names.
 * This implementation does not produce the required month weaving yet;
 * no test oracle is imported into this production module.
 */
data class ProductionMonthStructure(
    val year: ProductionYearInterval,
    val monthCount: Int,
    val lengths: IntArray,
    val canonicalIndices: IntArray
)

/** An exact dynamic-programming table with an O(slots * total) sliding window. */
class ProductionMonthLengthFamily(
    private val days: Int,
    private val slots: Int,
    private val minimum: Int = 4,
    private val maximum: Int = 123
) {
    private val ways: Array<Array<ExactInt>>
    init {
        require(days in 1..5778 && slots in 1..47 &&
            minimum in 1..maximum && maximum<=123 &&
            (slots.toLong()+1L)*(days.toLong()+1L)<=350000L
        ) { "E_POST55_MONTH_FAMILY_BUDGET" }
        ways = Array(slots+1) { Array(days+1) { ExactInt.ZERO } }
        ways[0][0] = ExactInt.ONE
        for (k in 1..slots) {
            var sliding = ExactInt.ZERO
            for (sum in 0..days) {
                if (sum>=minimum) sliding+=ways[k-1][sum-minimum]
                if (sum>maximum) sliding-=ways[k-1][sum-maximum-1]
                check(sliding>=ExactInt.ZERO) { "E_POST55_MONTH_DP_NEGATIVE" }
                ways[k][sum]=sliding
            }
        }
    }
    fun countAll(): ExactInt=ways[slots][days]
    fun unrank1(rank1:ExactInt):IntArray {
        require(rank1>=ExactInt.ONE && rank1<=countAll()) {
            "E_POST55_MONTH_LENGTH_RANK"
        }
        var remaining=days
        var rank=rank1
        val out=IntArray(slots)
        for (index in out.indices) {
            var selected=0
            val available=slots-index-1
            for (length in minimum..minOf(maximum,remaining)) {
                val rest=remaining-length
                val block=ways[available][rest]
                if (rank>block) rank-=block
                else { selected=length;break }
            }
            check(selected in minimum..maximum) { "E_POST55_MONTH_UNRANK" }
            out[index]=selected
            remaining-=selected
        }
        check(remaining==0 && out.sum()==days) { "E_POST55_MONTH_TOTAL" }
        return out
    }
}

class ProductionMonthStructureEngine(
    private val sauce:ProductionSauceEngine=ProductionSauceEngine(),
    private val selector:ProductionRankSampler=ProductionRankSampler()
) {
    private fun falling(total:Int,length:Int):ExactInt {
        require(total==47 && length in 0..47) { "E_POST55_MONTH_NAMES_SHAPE" }
        var result=ExactInt.ONE
        repeat(length) { i -> result*=ExactInt.of((total-i).toLong()) }
        return result
    }
    private fun names(count:Int,rank1:ExactInt):IntArray {
        require(rank1>=ExactInt.ONE && rank1<=falling(47,count)) {
            "E_POST55_MONTH_NAMES_RANK"
        }
        val remaining=(1..47).toMutableList()
        val selected=IntArray(count)
        var r=rank1
        for(i in 0 until count) {
            var choices=ExactInt.ONE
            for(j in 0 until count-i-1) {
                choices*=ExactInt.of((remaining.size-1-j).toLong())
            }
            val ordinal=((r-ExactInt.ONE)/choices).toIntExact()
            check(ordinal in remaining.indices) { "E_POST55_MONTH_NAME_INDEX" }
            selected[i]=remaining.removeAt(ordinal)
            r=(r-ExactInt.ONE).euclideanMod(choices)+ExactInt.ONE
        }
        return selected
    }
    fun build(calculationDay:ExactInt, year:ProductionYearInterval):ProductionMonthStructure {
        val total=(year.closeDay-year.openDay).toIntExact()
        require(total in 252..5778) { "E_POST55_MONTH_YEAR_LENGTH" }
        val minMonths=(total+122)/123
        val maxMonths=minOf(47,total/4)
        require(minMonths in 3..maxMonths) { "E_POST55_MONTH_COUNT_RANGE" }
        val cooked=sauce.cook(calculationDay,year.openDay+1L)
        val options=maxMonths-minMonths+1
        val count=minMonths+selector.choose(
            sauce.question(cooked,3,30),ExactInt.of(options.toLong())
        ).toIntExact()-1
        val family=ProductionMonthLengthFamily(total,count)
        val lengths=family.unrank1(selector.choose(
            sauce.question(cooked,3,31),family.countAll()
        ))
        val chosenNames=names(count,selector.choose(
            sauce.question(cooked,5,33),falling(47,count)
        ))
        check(lengths.sum()==total && lengths.all { it in 4..123 } &&
            chosenNames.size==count && chosenNames.distinct().size==count &&
            chosenNames.all { it in 1..47 }) { "E_POST55_MONTH_BUILD_INVALID" }
        return ProductionMonthStructure(year,count,lengths,chosenNames)
    }
}
