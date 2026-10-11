package pastafari

/**
 * Cam 3 / PATCH 01.  Defnyddir y cyfeirnod normadol gan brofion yn unig.
 * Rhaid i'r llwybr DISCOVERY_01 aros yn anghywir i gadw'r dystiolaeth.
 */
object Stage03Tests {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH01_ARGUMENTS" }
        val modulus = NormativeCore.M
        val witnesses = listOf(
            "M" to modulus,
            "2M" to modulus.multiplyByInt(2),
            "3M" to modulus.multiplyByInt(3),
            "M+1" to (modulus + ExactInt.ONE)
        )
        fun check(code: String, condition: Boolean) {
            if (!condition) error(code)
        }
        val manager = MonsterBootstrapManager()
        val contexts = witnesses.map { (_, value) ->
            manager.applySavePatch(ExactInt.ONE, ExactInt.ONE, value)
        }
        val patched = contexts.map { it.patch01Output ?: error("E_PATCH01_OUTPUT_NULL") }
        val legacy = contexts.map { it.patch01LegacyOutput ?: error("E_PATCH01_LEGACY_NULL") }
        val normative = witnesses.map { (_, value) -> NormativeCore.save(value) }
        val legacyDifferences = witnesses.indices.filter { legacy[it] != normative[it] }
        val patchedDifferences = witnesses.indices.filter { patched[it] != normative[it] }
        check("E_PATCH01_EXPECTED_LEGACY_VALUES", legacy ==
            listOf(ExactInt.ZERO, ExactInt.ZERO, ExactInt.ZERO, ExactInt.ONE))
        check("E_PATCH01_EXPECTED_NORMATIVE_VALUES", normative ==
            listOf(modulus, modulus, modulus, ExactInt.ONE))
        check("E_PATCH01_EXPECTED_LEGACY_RED", legacyDifferences == listOf(0, 1, 2))
        check("E_PATCH01_GREEN", patchedDifferences.isEmpty())
        check("E_PATCH01_ROUTE", contexts.all {
            it.phase == "PATCH_01" && it.status == "PATCHED" &&
            it.branchTrace == listOf("BOOT", "PATCH_01") &&
            it.diagnostics == listOf("PATCH_01_SAVE_WRAPPER")
        })
        check("E_PATCH01_PER_CALL_FIELDS", contexts.indices.all { i ->
            contexts[i].patch01Input == witnesses[i].second &&
            contexts[i].patch01LegacyOutput == legacy[i] &&
            contexts[i].patch01Output == patched[i] &&
            contexts[i].discovery01Input == null &&
            contexts[i].discovery01Output == null
        })
        check("E_PATCH01_CALL_COUNTS", manager.metrics.snapshot()["patch01.legacy.calls"] == 4L &&
            manager.metrics.snapshot()["patch01.applied"] == 4L &&
            manager.metrics.snapshot()["bootstrap.ready"] == 4L)
        check("E_PATCH01_REFERENCES_SEPARATE", contexts.indices.all { i ->
            contexts.indices.all { j -> i == j || (
                contexts[i] !== contexts[j] &&
                contexts[i].branchTrace !== contexts[j].branchTrace &&
                contexts[i].diagnostics !== contexts[j].diagnostics
            ) }
        })
        println("STAGE03_SAVE_PATCH_GREEN_4")
        println("STAGE03_LEGACY_SCAR_RED_${legacyDifferences.size}")
        println("STAGE03_PATCH_GREEN_${patchedDifferences.size}")

        // Heb ddileu'r graith, dylai llwybr Cam 2 barhau i ddangos y gwall.
        val discovery = manager.observeLegacyRemainder(ExactInt.ONE, ExactInt.ONE, modulus)
        check("E_PATCH01_DISCOVERY_UNMODIFIED", discovery.discovery01Output == ExactInt.ZERO &&
            discovery.patch01Output == null &&
            discovery.branchTrace == listOf("BOOT", "DISCOVERY_01") &&
            discovery.status == "LEGACY_REMAINDER_OBSERVED")
        check("E_PATCH01_DISCOVERY_METRIC", manager.metrics.snapshot()["discovery01.legacy"] == 1L &&
            manager.metrics.snapshot()["patch01.legacy.calls"] == 4L)
        check("E_PATCH01_LEGACY_ADAPTER_UNMODIFIED", witnesses.map {
            manager.legacyRemainderAdapter.oldRemainder(it.second)
        } == legacy)
        println("STAGE03_LEGACY_ROUTE_PRESERVED")

        // Cyfnodau negyddol/positif ac union luosrifau: 65 × 3 achos.
        val periodic = MonsterBootstrapManager()
        val residues = listOf(ExactInt.ZERO, ExactInt.ONE, modulus - ExactInt.ONE)
        var periodicCount = 0
        for (k in -32..32) {
            for (residue in residues) {
                val value = modulus.multiplyByInt(k) + residue
                val context = periodic.applySavePatch(
                    ExactInt.of(-15055671), ExactInt.of(20261011), value
                )
                check("E_PATCH01_PERIODIC_LEGACY_${k}_${residue}",
                    context.patch01LegacyOutput == residue)
                check("E_PATCH01_PERIODIC_GREEN_${k}_${residue}",
                    context.patch01Output == (if (residue.isZero()) modulus else residue) &&
                    context.patch01Output == NormativeCore.save(value))
                check("E_PATCH01_PERIODIC_TRACE_${k}_${residue}",
                    context.branchTrace == listOf("BOOT", "PATCH_01") &&
                    context.patch01Input == value && context.status == "PATCHED")
                periodicCount++
            }
        }
        check("E_PATCH01_PERIODIC_METRICS", periodic.metrics.snapshot()["patch01.legacy.calls"] ==
            periodicCount.toLong() && periodic.metrics.snapshot()["patch01.applied"] == periodicCount.toLong())
        println("STAGE03_PERIODICITY_GREEN_$periodicCount")

        val boundaries = listOf(
            Triple("-3M", -modulus.multiplyByInt(3), modulus),
            Triple("-M", -modulus, modulus),
            Triple("-M+1", ExactInt.ONE - modulus, ExactInt.ONE),
            Triple("-1", ExactInt.of(-1), modulus - ExactInt.ONE),
            Triple("0", ExactInt.ZERO, modulus),
            Triple("1", ExactInt.ONE, ExactInt.ONE),
            Triple("M-1", modulus - ExactInt.ONE, modulus - ExactInt.ONE)
        )
        for ((label, value, expected) in boundaries) {
            val result = manager.applySavePatch(ExactInt.ONE, ExactInt.ONE, value)
            check("E_PATCH01_BOUNDARY_$label", result.patch01Output == expected &&
                result.patch01Output == NormativeCore.save(value))
        }
        println("STAGE03_BOUNDARY_GREEN_${boundaries.size}")

        // Cywirdeb pell y tu hwnt i ystodau'r peiriant.
        val far = -(modulus.square().multiplyByInt(17) + modulus)
        val farResult = periodic.applySavePatch(ExactInt.ONE, ExactInt.ONE, far)
        check("E_PATCH01_FAR_LEGACY", farResult.patch01LegacyOutput == ExactInt.ZERO)
        check("E_PATCH01_FAR_PATCH", farResult.patch01Output == modulus &&
            farResult.patch01Output == NormativeCore.save(far))
        for (i in 0..127) {
            val residue = ExactInt.of(((i * 9176L + 7L) % 65537L))
            val signedMultiplier = if (i % 2 == 0) i * 197 + 1 else -(i * 271 + 1)
            val input = modulus.multiplyByInt(signedMultiplier) + residue
            val result = periodic.applySavePatch(ExactInt.ONE, ExactInt.ONE, input)
            check("E_PATCH01_WIDE_$i", result.patch01Output == NormativeCore.save(input))
        }
        println("STAGE03_WIDE_ARITHMETIC_GREEN_129")

        // Gwrthod croesi cam BOOT; dim newidiadau semantig ar fethiant.
        val unready = BaseMonsterContext(ExactInt.ONE, ExactInt.ONE,
            phase = "PATCH_01", patch01Input = modulus)
        val unreadyError = try {
            periodic.dispatcher.dispatch(unready)
            "E_PATCH01_BYPASS_ACCEPTED"
        } catch (e: MonsterValidationException) { e.machineCode }
        check("E_PATCH01_NO_BOOT_BYPASS", unreadyError == "E_PATCH01_CONTEXT_NOT_READY" &&
            unready.patch01LegacyOutput == null && unready.patch01Output == null &&
            unready.branchTrace.isEmpty())
        val missingInput = periodic.prepare(ExactInt.ONE, ExactInt.ONE)
        missingInput.phase = "PATCH_01"
        val missingError = try {
            periodic.dispatcher.dispatch(missingInput)
            "E_PATCH01_MISSING_INPUT_ACCEPTED"
        } catch (e: MonsterValidationException) { e.machineCode }
        check("E_PATCH01_NO_INPUT", missingError == "E_PATCH01_NO_INPUT" &&
            missingInput.patch01LegacyOutput == null && missingInput.patch01Output == null &&
            missingInput.branchTrace == listOf("BOOT"))
        val wrapper = SavePatchWrapper()
        check("E_PATCH01_WRAPPER_ZERO", wrapper.savePatch(ExactInt.ZERO) == modulus)
        check("E_PATCH01_WRAPPER_NONZERO", wrapper.savePatch(modulus - ExactInt.ONE) == modulus - ExactInt.ONE)
        for (illegal in listOf(-ExactInt.ONE, modulus, modulus + ExactInt.ONE)) {
            val message = try {
                wrapper.savePatch(illegal)
                "E_PATCH01_ILLEGAL_ACCEPTED"
            } catch (e: IllegalArgumentException) { e.message }
            check("E_PATCH01_WRAPPER_RANGE", message == "E_PATCH01_LEGACY_RANGE")
        }
        val secondManager = MonsterBootstrapManager()
        val other = secondManager.applySavePatch(ExactInt.ONE, ExactInt.ONE, modulus)
        check("E_PATCH01_INDEPENDENT_MANAGERS", other.patch01Output == modulus &&
            secondManager.metrics.snapshot()["patch01.applied"] == 1L &&
            manager.metrics.snapshot()["patch01.applied"] == 11L)
        println("STAGE03_OWNERSHIP_AND_VALIDATION_GREEN")
        println("STAGE03_COMPLETE_GREEN")
    }
}
