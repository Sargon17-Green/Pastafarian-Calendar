package pastafari

/** Post-55 audit: no normative code is imported by the production sauce. */
object Post55ProductionSauceTests {
    private fun insist(code:String,valid:Boolean){check(valid){code}}
    private fun rejects(block:()->Unit){
        try{block()}catch(_:IllegalArgumentException){return}
        error("E_POST55_SAUCE_GUARD_MISSING")
    }
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val sauce=ProductionSauceEngine()
        val f=NormativeCore.FOUNDATION_DAY
        val enormous=ExactInt.parse("98765432109876543210987654321098765432109876543210")
        val pairs=listOf(
            f to f,
            (f+1L) to f,
            f to (f+1L),
            (f-1L) to f,
            f to (f-1L),
            NormativeCore.TABLETS_DAY to NormativeCore.TABLETS_DAY,
            ExactInt.ZERO to ExactInt.ZERO,
            ExactInt.of(739834) to ExactInt.of(739834),
            ExactInt.of(-1) to ExactInt.of(1),
            ExactInt.of(1) to ExactInt.of(-1),
            enormous to (enormous+1L),
            (-enormous) to (enormous)
        )
        var comparisons=0
        var questions=0
        for((c,t) in pairs){
            val actual=sauce.cook(c,t)
            val expected=NormativeCore.sauce(c,t)
            insist("E_POST55_SAUCE_BOWLS_$comparisons",
                actual.finalBowls.size==7 &&
                actual.finalBowls.indices.all { i ->
                    actual.finalBowls[i]==expected.bowls[i]
                } &&
                actual.orderAtDrop46==expected.orderAtDrop46.toList() &&
                actual.orderAtDrop46.toSet()==(1..6).toSet())
            for(bowl in listOf(1,3,6))for(seal in listOf(1,10,31,32)){
                val ours=sauce.question(actual,bowl,seal)
                val oracle=NormativeCore.askBowl(expected,bowl,seal)
                insist("E_POST55_SAUCE_QUESTION_$comparisons-$bowl-$seal",
                    ours.firstAnswer==oracle.first &&
                    ours.directionStep==oracle.directionStep &&
                    ours.firstAnswer>=ExactInt.ONE &&
                    ours.firstAnswer<=NormativeCore.M)
                questions++
            }
            comparisons++
        }
        insist("E_POST55_SAUCE_CASE_COUNTS",
            comparisons==12 && questions==144)
        println("POST55_SAUCE_12_EXACT_PAIRS_ALL_FINAL_BOWLS_GREEN")
        println("POST55_SAUCE_144_BOWL_QUESTION_STREAMS_GREEN")

        val productionGates=ProductionGateYear5000Engine(
            ProductionGateAnswerProvider { index ->
                sauce.answer(f,f+index,1,1)
            }
        )
        val oracle=NormativeCalendar()
        var gates=0
        for(i in -28..28){
            val n=ExactInt.of(i.toLong())
            insist("E_POST55_SELF_HOST_GATE_$i",
                productionGates.getGate(n)==oracle.gates.get(n))
            gates++
        }
        insist("E_POST55_SELF_HOST_GATES",gates==57)
        println("POST55_SAUCE_SELF_HOSTED_57_GATES_GREEN")

        var years=0
        for(offset in listOf(-1L,0L,1L)){
            val day=f+offset
            val input=sauce.answer(day,day,1,10)
            val chosen=productionGates.chooseYear5000(day,input)
            val expected=oracle.year5000(day)
            insist("E_POST55_SELF_HOST_YEAR_$offset",
                chosen.candidate.openIndex==expected.openGateIndex &&
                chosen.candidate.closeIndex==expected.closeGateIndex &&
                chosen.candidate.openDay==expected.openGateDay &&
                chosen.candidate.closeDay==expected.closeGateDay)
            years++
        }
        insist("E_POST55_SELF_HOST_YEAR_TOTAL",years==3)
        println("POST55_SAUCE_SELF_HOSTED_3_YEAR5000_CHOICES_GREEN")

        val output=sauce.cook(f,f)
        rejects {sauce.question(output,0,1)}
        rejects {sauce.question(output,7,1)}
        val odd=ProductionSauceOutput(output.finalBowls, emptyList())
        rejects {sauce.question(odd,1,1)}
        println("POST55_SAUCE_SHAPE_GUARDS_GREEN")
        println("POST55_PRODUCTION_SAUCE_NATIVE_GREEN")
    }
}
