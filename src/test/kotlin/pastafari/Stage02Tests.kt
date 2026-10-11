package pastafari

/**
 * Mae'r archwiliad yn llwyddo dim ond os yw'r gwall hanesyddol yn weladwy.
 * Mae --strict yn cynnal regression normadol sy'n methu yn fwriadol.
 */
object Stage02Tests {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty() || (args.size == 1 && args[0] == "--strict")) {
            "E_DISCOVERY01_ARGUMENTS"
        }
        val modulus = NormativeCore.M
        val inputs = listOf(
            "M" to modulus,
            "2M" to modulus.multiplyByInt(2),
            "3M" to modulus.multiplyByInt(3),
            "M+1" to (modulus + 1L)
        )
        val manager = MonsterBootstrapManager()
        val contexts = inputs.map { (_, x) ->
            manager.observeLegacyRemainder(ExactInt.ONE, ExactInt.ONE, x)
        }
        val actual = contexts.map { context ->
            context.discovery01Output ?: error("E_DISCOVERY01_MISSING_OUTPUT")
        }
        val expected = inputs.map { (_, x) -> NormativeCore.save(x) }
        val differences = inputs.indices.filter { actual[it] != expected[it] }
            .map { inputs[it].first }

        fun check(code: String, condition: Boolean) {
            if (!condition) error(code)
        }

        check("E_DISCOVERY01_LEGACY_VALUES", actual.map { it.toString() } ==
            listOf("0", "0", "0", "1"))
        check("E_DISCOVERY01_NORMATIVE_VALUES", expected.map { it.toString() } ==
            listOf(modulus.toString(), modulus.toString(), modulus.toString(), "1"))
        check("E_DISCOVERY01_MISMATCH_SET", differences == listOf("M", "2M", "3M"))
        check("E_DISCOVERY01_OUTPUT_ROUTE", contexts.all { it.branchTrace ==
            listOf("BOOT", "DISCOVERY_01") && it.status == "LEGACY_REMAINDER_OBSERVED" })
        check("E_DISCOVERY01_OWNERSHIP", contexts.toSet().size == inputs.size)
        check("E_DISCOVERY01_INPUT_PRESERVED", contexts.indices.all {
            contexts[it].discovery01Input == inputs[it].second
        })
        check("E_DISCOVERY01_METRICS", manager.metrics.snapshot()["discovery01.legacy"] == 4L)
        check("E_DISCOVERY01_BOOTSTRAP_METRICS", manager.metrics.snapshot()["bootstrap.ready"] == 4L)
        check("E_DISCOVERY01_REPEAT", manager.observeLegacyRemainder(
            ExactInt.ONE, ExactInt.ONE, modulus
        ).discovery01Output == ExactInt.ZERO)

        // Achosion ymylol ychwanegol: nid ydynt yn newid y tri thyst coch canonaidd.
        val additionalInputs = listOf(
            Triple("-3M", -modulus.multiplyByInt(3), ExactInt.ZERO),
            Triple("-M", -modulus, ExactInt.ZERO),
            Triple("-M+1", ExactInt.ONE - modulus, ExactInt.ONE),
            Triple("-1", ExactInt.of(-1), modulus - ExactInt.ONE),
            Triple("0", ExactInt.ZERO, ExactInt.ZERO),
            Triple("1", ExactInt.ONE, ExactInt.ONE),
            Triple("M-1", modulus - ExactInt.ONE, modulus - ExactInt.ONE)
        )
        for ((label, input, legacyExpected) in additionalInputs) {
            val context = manager.observeLegacyRemainder(ExactInt.ONE, ExactInt.ONE, input)
            check("E_DISCOVERY01_BOUNDARY_$label", context.discovery01Output == legacyExpected)
            check("E_DISCOVERY01_BOUNDARY_INPUT_$label", context.discovery01Input == input)
            check("E_DISCOVERY01_BOUNDARY_ROUTE_$label",
                context.branchTrace == listOf("BOOT", "DISCOVERY_01"))
        }
        check("E_DISCOVERY01_REFERENCE_OWNERSHIP", contexts.indices.all { i ->
            contexts.indices.all { j -> i == j || (
                contexts[i] !== contexts[j] &&
                contexts[i].branchTrace !== contexts[j].branchTrace &&
                contexts[i].diagnostics !== contexts[j].diagnostics
            ) }
        })
        val isolatedManager = MonsterBootstrapManager()
        val isolatedContext = isolatedManager.observeLegacyRemainder(
            ExactInt.ONE, ExactInt.ONE, modulus
        )
        check("E_DISCOVERY01_INDEPENDENT_MANAGER",
            isolatedContext.discovery01Output == ExactInt.ZERO &&
            isolatedManager.metrics.snapshot()["discovery01.legacy"] == 1L &&
            isolatedManager.metrics.snapshot()["bootstrap.ready"] == 1L)
        check("E_DISCOVERY01_MAIN_MANAGER_METRICS_LATE",
            manager.metrics.snapshot()["discovery01.legacy"] == 12L &&
            manager.metrics.snapshot()["bootstrap.ready"] == 12L)
        // Archwiliad cyfnodol heb addasu'r graith: pob gweddill yn y gylchred.
        // Nid yw'r profion hyn yn gweithredu'r datrysiad Patch 01.
        val periodicManager = MonsterBootstrapManager()
        val residues = listOf(ExactInt.ZERO, ExactInt.ONE, modulus - ExactInt.ONE)
        var periodicCount = 0
        for (k in -32..32) {
            for (residue in residues) {
                val value = modulus.multiplyByInt(k) + residue
                val state = periodicManager.observeLegacyRemainder(
                    ExactInt.of(-15055671), ExactInt.of(20261011), value
                )
                check("E_DISCOVERY01_PERIODIC_LEGACY_${k}_${residue}",
                    state.discovery01Output == residue)
                val normativeExpected = if (residue.isZero()) modulus else residue
                check("E_DISCOVERY01_PERIODIC_REFERENCE_${k}_${residue}",
                    NormativeCore.save(value) == normativeExpected)
                check("E_DISCOVERY01_PERIODIC_OWNERSHIP_${k}_${residue}",
                    state.discovery01Input == value &&
                    state.branchTrace == listOf("BOOT", "DISCOVERY_01") &&
                    state.status == "LEGACY_REMAINDER_OBSERVED")
                periodicCount++
            }
        }
        check("E_DISCOVERY01_PERIODIC_COUNT", periodicCount == 195)
        check("E_DISCOVERY01_PERIODIC_METRICS", periodicManager.metrics.snapshot()[
            "discovery01.legacy"] == 195L)
        // Canfod colli cywirdeb wrth fynd y tu hwnt i 256 did.
        val farValue = modulus.square().multiplyByInt(-17) - modulus
        val farContext = periodicManager.observeLegacyRemainder(
            ExactInt.ONE, ExactInt.ONE, farValue
        )
        check("E_DISCOVERY01_FAR_LEGACY", farContext.discovery01Output == ExactInt.ZERO)
        check("E_DISCOVERY01_FAR_NORMATIVE", NormativeCore.save(farValue) == modulus)
        // Ni chaniateir mynd yn union i'r handler heb gyflwr BOOT dilys.
        val rejectedContext = BaseMonsterContext(
            ExactInt.ONE, ExactInt.ONE, phase = "DISCOVERY_01",
            discovery01Input = modulus
        )
        val rejection = try {
            periodicManager.dispatcher.dispatch(rejectedContext)
            "E_DISCOVERY01_MISSING_REJECTION"
        } catch (e: MonsterValidationException) {
            e.machineCode
        }
        check("E_DISCOVERY01_NO_BOOT_BYPASS",
            rejection == "E_DISCOVERY01_CONTEXT_NOT_READY" &&
            rejectedContext.discovery01Output == null &&
            rejectedContext.branchTrace.isEmpty())
        println("STAGE02_PERIODICITY_PASS_$periodicCount")
        println("STAGE02_FAR_ARITHMETIC_AND_REJECTION_PASS")
        println("STAGE02_BOUNDARY_AND_OWNERSHIP_PASS_7")
        for (i in inputs.indices) {
            println("DISCOVERY01_${inputs[i].first}: actual=${actual[i]}, normative=${expected[i]}")
        }
        if (args.contentEquals(arrayOf("--strict")) && differences.isNotEmpty()) {
            error("E_DISCOVERY01_NORMATIVE_DIFFERENCE:${differences.joinToString(",")}")
        }
        println("STAGE02_EXPECTED_RED_${differences.size}")
    }
}
