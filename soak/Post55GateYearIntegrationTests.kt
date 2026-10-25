package pastafari

/**
 * Test only: compare independently assembled production gate/year components
 * against NormativeCalendar. This is not a full-date, cross-language soak.
 */
object Post55GateYearIntegrationTests {
    private fun insist(code: String, yes: Boolean) { check(yes) { code } }
    private fun rejects(block: () -> Unit) {
        try { block() } catch (_: IllegalArgumentException) { return }
        error("E_POST55_GATE_GUARD_MISSING")
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val foundation = NormativeCore.FOUNDATION_DAY
        val seenGateIndices = ArrayList<ExactInt>()
        val source = ProductionGateAnswerProvider { signedIndex ->
            insist("E_POST55_SIGNED_ZERO", signedIndex != ExactInt.ZERO)
            seenGateIndices.add(signedIndex)
            val result = NormativeCore.sauce(
                foundation, foundation + signedIndex
            )
            val stream = NormativeCore.askBowl(
                result,1,NormativeCore.SEAL_GATE_GAP
            )
            ProductionAnswerStream(stream.first, stream.directionStep)
        }
        val engine = ProductionGateYear5000Engine(source)
        val oracle = NormativeCalendar()
        var gates = 0
        for (i in -48..48) {
            val index = ExactInt.of(i.toLong())
            val actual = engine.getGate(index)
            val expected = oracle.gates.get(index)
            insist("E_POST55_REAL_GATE_$i",actual==expected)
            gates++
        }
        insist("E_POST55_REAL_GATE_TOTAL",gates==97 &&
            seenGateIndices.size==96 && engine.expandedGateCount==97 &&
            !seenGateIndices.contains(ExactInt.ZERO) &&
            seenGateIndices.distinct().size==96 &&
            engine.lowestIndex==ExactInt.of(-48) &&
            engine.highestIndex==ExactInt.of(48))
        println("POST55_PRODUCTION_GATE_97_REAL_ORACLE_GREEN")

        var years=0
        for (offset in listOf(-250L,-1L,0L,1L,250L)) {
            val day=foundation+offset
            val candidates=engine.year5000Candidates(day)
            insist("E_POST55_CANDIDATE_SHAPE_$offset",
                candidates.isNotEmpty() &&
                candidates.distinctBy { it.openIndex to it.closeIndex }.size==
                    candidates.size &&
                candidates.zipWithNext().all { (a,b) ->
                    a.length<b.length ||
                    (a.length==b.length && a.openDay<=b.openDay)
                } &&
                candidates.all {
                    it.openDay<day && day<=it.closeDay &&
                    it.length>=ExactInt.of(252) &&
                    it.length<=ExactInt.of(5778) &&
                    it.closeIndex-it.openIndex>=ExactInt.of(6)
                })
            val result = NormativeCore.sauce(day,day)
            val stream = NormativeCore.askBowl(
                result,1,NormativeCore.SEAL_YEAR_5000)
            val chosen = engine.chooseYear5000(
                day,ProductionAnswerStream(stream.first,stream.directionStep))
            val expected=oracle.year5000(day)
            insist("E_POST55_YEAR5000_$offset",
                chosen.candidate.openIndex==expected.openGateIndex &&
                chosen.candidate.closeIndex==expected.closeGateIndex &&
                chosen.candidate.openDay==expected.openGateDay &&
                chosen.candidate.closeDay==expected.closeGateDay &&
                chosen.correctedIndex0==chosen.rank1-1 &&
                chosen.candidateCount==candidates.size &&
                chosen.candidate==candidates[chosen.correctedIndex0])
            years++
        }
        insist("E_POST55_YEAR_COUNT",years==5)
        println("POST55_PRODUCTION_YEAR5000_FIVE_REAL_DAYS_GREEN")

        var linear = 0
        val synthetic = ProductionGateYear5000Engine(
            ProductionGateAnswerProvider { idx ->
                insist("E_POST55_SYNTH_SIGN",idx!=ExactInt.ZERO)
                ProductionAnswerStream(ExactInt.ONE,1)
            }, maxGateAbsIndex=256
        )
        for (i in -80..80) {
            val expected=foundation+42L*i.toLong()
            insist("E_POST55_LINEAR_GATE_$i",
                synthetic.getGate(ExactInt.of(i.toLong()))==expected)
            linear++
        }
        insist("E_POST55_LINEAR_TOTAL",
            linear==161 && synthetic.expandedGateCount==161)
        println("POST55_PRODUCTION_GATE_161_SYNTHETIC_MONOTONIC_GREEN")

        val before=engine.expandedGateCount
        val gatePlus=engine.getGate(ExactInt.of(25))
        insist("E_POST55_CACHE_STABLE",
            engine.getGate(ExactInt.of(25))==gatePlus &&
            engine.expandedGateCount==before)
        rejects { engine.getGate(ExactInt.of(8193)) }
        rejects { engine.getGate(ExactInt.of(-8193)) }
        rejects { engine.coverDays(ExactInt.of(5),ExactInt.of(4)) }
        rejects {
            ProductionGateYear5000Engine(source,maxGateAbsIndex=15)
        }
        val bad = ProductionGateYear5000Engine(
            ProductionGateAnswerProvider {
                ProductionAnswerStream(ExactInt.ZERO,1)
            })
        rejects { bad.getGate(ExactInt.ONE) }
        insist("E_POST55_BAD_SOURCE_NO_MUTATION",
            bad.expandedGateCount==1 &&
            bad.lowestIndex==ExactInt.ZERO &&
            bad.highestIndex==ExactInt.ZERO)
        println("POST55_PRODUCTION_GATE_RESOURCE_GUARDS_GREEN")
        println("POST55_GATE_YEAR_COMPONENT_NATIVE_GREEN")
    }
}
