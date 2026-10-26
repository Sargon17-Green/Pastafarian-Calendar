package pastafari

/** Lexicographic positive compositions with an optional compulsory interior gate. */
class ProductionCutletPartitionFamily(
    private val totalGaps:Int,
    private val cutletCount:Int,
    private val requiredBoundary:Int?
) {
    private data class State(val rem:Int,val slots:Int,val used:Int,val hit:Boolean)
    private val cache=HashMap<State,ExactInt>()
    init {
        require(totalGaps in 6..5778 && cutletCount in 6..17 &&
            cutletCount<=totalGaps) { "E_CUTLET_PARTITION_RANGE" }
        require(requiredBoundary==null || requiredBoundary in 1 until totalGaps) {
            "E_CUTLET_BOUNDARY_RANGE"
        }
    }
    private fun count(rem:Int,slots:Int,used:Int,hit:Boolean):ExactInt {
        if(slots==0) return if(rem==0 && (requiredBoundary==null || hit))
            ExactInt.ONE else ExactInt.ZERO
        if(rem<slots) return ExactInt.ZERO
        val key=State(rem,slots,used,hit)
        cache[key]?.let{return it}
        var sum=ExactInt.ZERO
        for(x in 1..(rem-slots+1)) {
            val next=used+x
            if(requiredBoundary!=null && !hit && next>requiredBoundary) break
            sum+=count(rem-x,slots-1,next,
                hit || (requiredBoundary!=null && next==requiredBoundary))
        }
        cache[key]=sum
        return sum
    }
    fun countAll():ExactInt=count(totalGaps,cutletCount,0,false)
    fun unrank1(rank1:ExactInt):IntArray {
        require(rank1>=ExactInt.ONE && rank1<=countAll()) { "E_CUTLET_PARTITION_RANK" }
        var rank=rank1
        var rem=totalGaps
        var slots=cutletCount
        var used=0
        var hit=false
        val parts=IntArray(cutletCount)
        for(i in parts.indices) {
            var chosen=0
            for(x in 1..(rem-slots+1)) {
                val next=used+x
                if(requiredBoundary!=null && !hit && next>requiredBoundary) break
                val nextHit=hit || (requiredBoundary!=null && next==requiredBoundary)
                val ways=count(rem-x,slots-1,next,nextHit)
                if(rank>ways) rank-=ways else {
                    chosen=x
                    hit=nextHit
                    break
                }
            }
            check(chosen>0) { "E_CUTLET_PARTITION_UNRANK" }
            parts[i]=chosen
            rem-=chosen
            used+=chosen
            slots--
        }
        check(rem==0) { "E_CUTLET_PARTITION_SUM" }
        return parts
    }
}
