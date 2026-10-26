package pastafari

data class ProductionCutlet(
    val canonicalIndex:Int,
    val openGateIndex:ExactInt,
    val closeGateIndex:ExactInt,
    val firstDay:ExactInt,
    val lastDay:ExactInt
)
data class ProductionCutletStructure(
    val year:ProductionYearInterval,
    val cutletCount:Int,
    val partition:IntArray,
    val canonicalIndices:IntArray,
    val cutlets:List<ProductionCutlet>
)

/** Bounded self-hosted production construction of cutlets, not months. */
class ProductionCutletStructureEngine(
    private val navigator:ProductionYearNavigator=ProductionYearNavigator(),
    private val sauce:ProductionSauceEngine=ProductionSauceEngine()
) {
    private val sampler=ProductionRankSampler()
    private fun falling(n:Int,k:Int):ExactInt {
        require(k in 0..n && n<=47) { "E_CUTLET_NAMES_RANGE" }
        var r=ExactInt.ONE
        for(i in 0 until k) r*=ExactInt.of((n-i).toLong())
        return r
    }
    private fun names(n:Int,k:Int,rank1:ExactInt):IntArray {
        require(rank1>=ExactInt.ONE && rank1<=falling(n,k)) { "E_CUTLET_NAMES_RANK" }
        val remain=(1..n).toMutableList()
        val out=IntArray(k)
        var rank=rank1
        for(i in 0 until k) {
            val block=falling(remain.size-1,k-i-1)
            val choice=((rank-ExactInt.ONE)/block).toIntExact()
            check(choice in remain.indices) { "E_CUTLET_NAMES_UNRANK" }
            out[i]=remain.removeAt(choice)
            rank=(rank-ExactInt.ONE).euclideanMod(block)+ExactInt.ONE
        }
        return out
    }
    fun build(c:ExactInt,year:ProductionYearInterval):ProductionCutletStructure {
        val gaps=(year.closeGateIndex-year.openGateIndex).toIntExact()
        require(gaps>=6 && year.closeDay>year.openDay) { "E_CUTLET_YEAR_SHAPE" }
        val cooked=sauce.cook(c,year.openDay+1L)
        val valid=(6..17).filter{it<=gaps}
        val k=valid[
            sampler.choose(sauce.question(cooked,2,20),
                ExactInt.of(valid.size.toLong())).toIntExact()-1]
        val exact=navigator.exactGateIndex(c)
        val required=if(exact!=null && year.openGateIndex<exact &&
            exact<year.closeGateIndex) (exact-year.openGateIndex).toIntExact()
            else null
        val family=ProductionCutletPartitionFamily(gaps,k,required)
        val parts=family.unrank1(sampler.choose(
            sauce.question(cooked,2,21),family.countAll()))
        val ids=names(17,k,sampler.choose(
            sauce.question(cooked,5,22),falling(17,k)))
        var cursor=year.openGateIndex
        val out=ArrayList<ProductionCutlet>()
        for(i in parts.indices) {
            val next=cursor+parts[i].toLong()
            out.add(ProductionCutlet(ids[i],cursor,next,
                navigator.gateDay(cursor)+1L,navigator.gateDay(next)))
            cursor=next
        }
        check(cursor==year.closeGateIndex && out.size==k &&
            out.first().firstDay==year.openDay+1L &&
            out.last().lastDay==year.closeDay &&
            out.zipWithNext().all{(a,b)->a.lastDay+1L==b.firstDay}) {
            "E_CUTLET_COVERAGE"
        }
        return ProductionCutletStructure(year,k,parts,ids,out)
    }
}
