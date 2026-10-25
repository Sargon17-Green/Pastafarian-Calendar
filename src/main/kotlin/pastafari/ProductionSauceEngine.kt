package pastafari

/**
 * Standalone post-55 production sauce engine, independent of NormativeCore.
 *
 * Implements deterministic tables, hidden and visible drops, snapshot pours,
 * 12 post-stirs and bowl questions. No test oracle or foreign-language runtime.
 * Inputs are arbitrary-precision JDN day indices, not Gregorian dates.
 */
data class ProductionSauceOutput(
    val finalBowls: List<ExactInt>,
    val orderAtDrop46: List<Int>
)

class ProductionSauceEngine {
    private val modulus = ExactInt.parse("170141183460469231731687303715884105727")
    private val foundation = ExactInt.of(-15055671L)
    private val one = ExactInt.ONE
    private val zero = ExactInt.ZERO
    private val stoneRows: Array<Array<ExactInt>> by lazy { prepareStones() }
    private val primeSequence = intArrayOf(
        3,5,7,11,13,17,19,23,29,31,37,41,43,47
    )
    private val bowlSeedPrimes = intArrayOf(0,17,19,23,29,31,37)
    private val factorials = intArrayOf(1,1,2,6,24,120,720)

    private fun saved(value: ExactInt): ExactInt =
        one + (value - one).euclideanMod(modulus)

    private fun cookedNumber(day: ExactInt): ExactInt = when {
        day == foundation -> one
        day > foundation -> (day - foundation).multiplyByInt(2) + 1L
        else -> (foundation - day).multiplyByInt(2)
    }

    private data class Measures(
        val action: ExactInt,
        val target: ExactInt,
        val distance: ExactInt,
        val connection: ExactInt,
        val direction: ExactInt
    ) {
        fun component(i:Int): ExactInt = when(i) {
            0 -> action
            1 -> target
            2 -> distance
            3 -> connection
            4 -> direction
            else -> error("E_SAUCE_COMPONENT")
        }
    }

    private fun measures(calculationDay:ExactInt,targetDay:ExactInt):Measures {
        val a=cookedNumber(calculationDay)
        val b=cookedNumber(targetDay)
        val d=(targetDay-calculationDay).abs()+1L
        val direction=when {
            targetDay<calculationDay -> 1L
            targetDay==calculationDay -> 2L
            else -> 3L
        }
        return Measures(a,b,d,a+b,ExactInt.of(direction))
    }

    private fun prepareStones():Array<Array<ExactInt>> {
        val all=Array(47) { Array(5) { zero } }
        all[1]=arrayOf(17L,29L,43L,71L,101L).map { ExactInt.of(it) }.toTypedArray()
        for(day in 2..46) {
            val prev=all[day-1]
            all[day]=arrayOf(
                saved(prev[0].square()+prev[1].multiplyByInt(3)+day.toLong()),
                saved(prev[1].square()+prev[2].multiplyByInt(5)+prev[0]),
                saved(prev[2].square()+prev[3].multiplyByInt(7)+prev[1]),
                saved(prev[3].square()+prev[4].multiplyByInt(11)+prev[2]),
                saved(prev[4].square()+prev[0].multiplyByInt(13)+prev[3])
            )
        }
        return all
    }

    private fun hiddenStones(m:Measures):Array<ExactInt> {
        val stones=stoneRows
        val hidden=Array(8) { zero }
        for(k in 1..7) {
            // Source coefficients follow four arithmetic progressions,
            // not a copied literal matrix of test-oracle coefficients.
            var x=m.action +
                m.target.multiplyByInt(2*k+1) +
                m.distance.multiplyByInt(3*k+1) +
                m.connection.multiplyByInt(4*k+2) +
                m.direction.multiplyByInt(4*k+4)
            for(s in stones[k]) x+=s
            x=saved(x)
            for(grind in 1..7) {
                val stoneKind=(grind-1)%5
                x=saved(x.square()+x.multiplyByInt(3)+
                    stones[k][stoneKind]+grind.toLong())
            }
            hidden[k]=x
        }
        return hidden
    }

    private fun visibleStones(m:Measures, hidden:Array<ExactInt>):Array<ExactInt> {
        val stones=stoneRows
        val timeline=HashMap<Int,ExactInt>()
        for(k in 1..7) timeline[1-k]=hidden[k]
        val visible=Array(47) { zero }
        for(i in 1..46) {
            val previous=timeline[i-1]?:error("E_SAUCE_PREV1")
            val third=timeline[i-3]?:error("E_SAUCE_PREV3")
            val seventh=timeline[i-7]?:error("E_SAUCE_PREV7")
            var mixed=zero
            for(j in 0..4) mixed+=stones[i][j]*m.component(j)
            mixed+=previous+third.multiplyByInt(3)+
                seventh.multiplyByInt(5)+i.toLong()
            var x=saved(mixed)
            for(grind in 0 until 11) {
                x=saved(
                    x.square()+
                    x.multiplyByInt(primeSequence[grind])+
                    previous.multiplyByInt(primeSequence[grind+1])+
                    third.multiplyByInt(primeSequence[grind+2])+
                    seventh.multiplyByInt(primeSequence[grind+3])+
                    stones[i][grind%5]
                )
            }
            timeline[i]=x
            visible[i]=x
        }
        return visible
    }

    private fun permutation(rank:Int):IntArray {
        require(rank in 1..720) { "E_SAUCE_PERM_RANK" }
        val available=mutableListOf(1,2,3,4,5,6)
        var residue=rank-1
        val order=IntArray(6)
        for(place in 0..5) {
            val divisor=factorials[5-place]
            val choice=residue/divisor
            residue%=divisor
            order[place]=available.removeAt(choice)
        }
        return order
    }

    private fun snapshotOrder(value:ExactInt):IntArray {
        val rank=((value-one).euclideanMod(ExactInt.of(720))+one).toIntExact()
        return permutation(rank)
    }

    private fun newBowls():Array<ExactInt> = Array(7) { zero }

    private fun startingBowls(m:Measures):Array<ExactInt> {
        val out=newBowls()
        for(id in 1..6) {
            val prime=bowlSeedPrimes[id].toLong()
            val x=m.action+m.target.multiplyByInt(id)+m.distance+
                m.connection+m.direction+prime*ExactInt.of(prime)
            out[id]=saved(x.square()+id.toLong())
        }
        return out
    }

    private fun pourVisibleDrops(
        initial:Array<ExactInt>, drops:Array<ExactInt>
    ):Pair<Array<ExactInt>,IntArray> {
        var bowls=initial
        var finalOrder=IntArray(0)
        val stones=stoneRows
        for(i in 1..46) {
            val drop=drops[i]
            val order=snapshotOrder(drop)
            val before=bowls
            val pour=newBowls()
            val sq=drop.square()
            for(p in 1..3) {
                val from=order[p-1]
                pour[p]=saved(sq+stones[i][p-1]*before[from]+
                    ((p*2+1)*i).toLong())
            }
            val after=newBowls()
            for(position in 0..5) {
                val id=order[position]
                val prev=order[(position+5)%6]
                val next=order[(position+1)%6]
                val term=before[id]+
                    before[prev].multiplyByInt(2)+
                    before[next].multiplyByInt(3)+
                    pour[position+1]+drop+stones[i][position%5]
                after[id]=saved(
                    term.square()+
                    (before[prev]*before[next]).multiplyByInt(5)+
                    ((position+1)*i).toLong()
                )
            }
            bowls=after
            if(i==46) finalOrder=order
        }
        check(finalOrder.size==6) { "E_SAUCE_DROP46_ORDER" }
        return bowls to finalOrder
    }

    private fun postStir(bowlsAfterDrops:Array<ExactInt>):Array<ExactInt> {
        var bowls=bowlsAfterDrops
        for(round in 1..12) {
            val before=bowls
            var total=zero
            for(id in 1..6) total+=before[id]
            val sauce=saved(total+149L*ExactInt.of(round.toLong()))
            val order=snapshotOrder(sauce)
            val after=newBowls()
            for(position in 0..5) {
                val id=order[position]
                val prev=order[(position+5)%6]
                val next=order[(position+1)%6]
                val pos1=position+1
                val mix=before[id]+before[prev].multiplyByInt(3)+
                    before[next].multiplyByInt(5)+sauce+round.toLong()+
                    (pos1*pos1).toLong()
                after[id]=saved(mix.square()+
                    (before[prev]*before[next]).multiplyByInt(7))
            }
            bowls=after
        }
        return bowls
    }

    fun cook(calculationDay:ExactInt,targetDay:ExactInt):ProductionSauceOutput {
        val m=measures(calculationDay,targetDay)
        val hidden=hiddenStones(m)
        val visible=visibleStones(m,hidden)
        val (poured,order)=pourVisibleDrops(startingBowls(m),visible)
        val stirred=postStir(poured)
        return ProductionSauceOutput(stirred.toList(),order.toList())
    }

    fun question(
        cooked:ProductionSauceOutput, bowlId:Int, seal:Int
    ):ProductionAnswerStream {
        require(bowlId in 1..6) { "E_SAUCE_BOWL_ID" }
        require(cooked.finalBowls.size==7 &&
            cooked.orderAtDrop46.size==6) { "E_SAUCE_RESULT_SHAPE" }
        val index=cooked.orderAtDrop46.indexOf(bowlId)
        require(index>=0) { "E_SAUCE_ORDER_SOURCE" }
        val neighbour=cooked.orderAtDrop46[(index+1)%6]
        val firstTerm=cooked.finalBowls[bowlId]+seal.toLong()+181L
        val first=saved(
            firstTerm.square()+
            cooked.finalBowls[neighbour].multiplyByInt(179)+seal.toLong()
        )
        val signTerm=first+seal.toLong()+194L
        val sign=saved(
            signTerm.square()+first.multiplyByInt(193)+
            cooked.finalBowls[6].multiplyByInt(197)
        )
        return ProductionAnswerStream(
            first, if(sign.modInt(2)==1) 1 else -1
        )
    }

    fun answer(
        calculationDay:ExactInt,targetDay:ExactInt,bowlId:Int,seal:Int
    ):ProductionAnswerStream = question(cook(calculationDay,targetDay),bowlId,seal)
}
