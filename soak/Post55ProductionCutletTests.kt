package pastafari

/** Test-only comparison of production cutlet components to normative families. */
object Post55ProductionCutletTests {
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val f=NormativeCore.FOUNDATION_DAY
        val nav=ProductionYearNavigator()
        val oracle=NormativeCalendar()
        val engine=ProductionCutletStructureEngine(nav)
        val sampler=ProductionRankSampler()
        val m=NormativeCore.M
        var rankChecks=0
        for(s in listOf(
            ProductionAnswerStream(ExactInt.ONE,1),
            ProductionAnswerStream(m,-1),
            ProductionAnswerStream(m,1),
            ProductionAnswerStream(ExactInt.of(123456L),-1)
        )) for(n in listOf(
            ExactInt.ONE,ExactInt.of(922L),ExactInt.of(355687428096000L),
            m+7L,m*m-1L
        )) {
            val actual=sampler.choose(s,n)
            // The reverse stream starting at M rejects M mod n values.
            // For this witness that is 141,533,465,673,727 steps; the
            // sequential test oracle is impractical and its Int counter
            // is not valid for so many steps. The first accepted value
            // is exactly (M / n) * n, whose one-based rank is n.
            val pathological=(s.firstAnswer==m && s.directionStep==-1 &&
                n==ExactInt.of(355687428096000L))
            val expected=if(pathological) {
                val limit=(m/n)*n
                check(m>limit && m-limit>ExactInt.of(100000L)) {
                    "E_CUTLET_RANK_WITNESS_SETUP"
                }
                n
            } else {
                NormativeCore.chooseRank(
                    NormativeCore.AnswerStream(s.firstAnswer,s.directionStep),n)
            }
            check(actual==expected) {
                "E_CUTLET_RANK_SAMPLER first=${s.firstAnswer} step=${s.directionStep} choices=${n} actual=${actual} expected=${expected}"
            }
            rankChecks++
        }
        check(rankChecks==20)
        println("POST55_PRODUCTION_RANK_SHORT_WIDE_20_ORACLE_GREEN")
        var structures=0
        for(offset in listOf(-1L,0L,1L)) {
            val c=f+offset
            val y=nav.year5000(c)
            val oy=oracle.year5000(c)
            val years=listOf(
                y to oy,
                nav.previousYear(c,y) to oracle.previousYear(c,oy),
                nav.nextYear(c,y) to oracle.nextYear(c,oy))
            for((year,reference) in years) {
                val actual=engine.build(c,year)
                val gaps=(reference.closeGateIndex-reference.openGateIndex).toIntExact()
                val cooked=NormativeCore.sauce(c,reference.openGateDay+1L)
                val possible=(6..17).filter{it<=gaps}
                val k=possible[NormativeCore.chooseRankInt(
                    NormativeCore.askBowl(cooked,2,20),possible.size)-1]
                check(actual.cutletCount==k) { "E_CUTLET_COUNT" }
                val exact=oracle.gates.exactGateIndex(c)
                val required=if(exact!=null && reference.openGateIndex<exact &&
                    exact<reference.closeGateIndex)
                    (exact-reference.openGateIndex).toIntExact() else null
                val family=NormativeCore.CutletPartitionFamily(gaps,k,required)
                val expectedPartition=family.unrank1(NormativeCore.chooseRank(
                    NormativeCore.askBowl(cooked,2,21),family.countAll()))
                check(actual.partition.contentEquals(expectedPartition)) {
                    "E_CUTLET_PARTITION"
                }
                val expectedNames=NormativeCore.unrankDistinctIndices(
                    17,k,NormativeCore.chooseRank(
                        NormativeCore.askBowl(cooked,5,22),
                        NormativeCore.fallingFactorial(17,k)))
                check(actual.canonicalIndices.contentEquals(expectedNames)) {
                    "E_CUTLET_NAMES"
                }
                var cursor=reference.openGateIndex
                for(i in expectedPartition.indices) {
                    val next=cursor+expectedPartition[i].toLong()
                    val part=actual.cutlets[i]
                    check(part.canonicalIndex==expectedNames[i] &&
                        part.openGateIndex==cursor &&
                        part.closeGateIndex==next &&
                        part.firstDay==oracle.gates.get(cursor)+1L &&
                        part.lastDay==oracle.gates.get(next)) { "E_CUTLET_BOUNDS" }
                    cursor=next
                }
                check(cursor==reference.closeGateIndex)
                structures++
            }
        }
        check(structures==9)
        println("POST55_PRODUCTION_CUTLET_9_STRUCTURES_ORACLE_GREEN")
        println("POST55_CUTLET_COMPONENT_NOT_FULL_DATE_SOAK")
    }
}
