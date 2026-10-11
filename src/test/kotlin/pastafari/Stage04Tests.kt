package pastafari

/** Cam 4 / DISCOVERY 02: dim ond profion sy'n defnyddio'r oracl normadol. */
object Stage04Tests {
    private fun assertThat(label: String, condition: Boolean) {
        check(condition) { label }
    }

    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty() || (args.size == 1 && args[0] == "--strict")) {
            "E_DISCOVERY02_BAD_ARGUMENTS"
        }
        val f = NormativeCore.FOUNDATION_DAY
        val witnesses = listOf(
            "F_MINUS_2" to (f - 2L),
            "F_MINUS_1" to (f - 1L),
            "F" to f,
            "F_PLUS_1" to (f + 1L),
            "F_PLUS_2" to (f + 2L)
        )
        val manager = MonsterBootstrapManager()
        val results = witnesses.map { (_, day) ->
            manager.observeLegacyDayTag(f, day, day)
        }
        val actual = results.map { it.discovery02Output ?: error("E_DISCOVERY02_NULL") }
        val expected = witnesses.map { (_, day) -> NormativeCore.dayCount(day) }
        val differences = witnesses.indices.filter { actual[it] != expected[it] }
        val matches = witnesses.indices.filter { actual[it] == expected[it] }
        assertThat("E_DISCOVERY02_EXPECTED_ACTUAL", actual == (listOf(4, 2, 0, 2, 4).map { ExactInt.of(it.toLong()) }))
        assertThat("E_DISCOVERY02_EXPECTED_NORMATIVE", expected == (listOf(4, 2, 1, 3, 5).map { ExactInt.of(it.toLong()) }))
        assertThat("E_DISCOVERY02_RED_INDICES", differences == listOf(2, 3, 4))
        assertThat("E_DISCOVERY02_MATCH_INDICES", matches == listOf(0, 1))
        println("STAGE04_EXPECTED_RED_${differences.size}")
        println("STAGE04_MATCH_${matches.size}")
        witnesses.indices.forEach { i ->
            val c = results[i]
            assertThat("E_DISCOVERY02_INPUT_$i", c.discovery02Input == witnesses[i].second)
            assertThat("E_DISCOVERY02_OUTPUT_$i", c.discovery02Output == actual[i])
            assertThat("E_DISCOVERY02_ROUTE_$i", c.phase == "DISCOVERY_02" &&
                c.status == "LEGACY_DAY_TAG_OBSERVED" &&
                c.branchTrace == listOf("BOOT", "DISCOVERY_02") &&
                c.diagnostics == listOf("DISCOVERY_02_LEGACY_DAY_TAG"))
            assertThat("E_DISCOVERY02_OTHER_FIELDS_$i", c.discovery01Input == null &&
                c.discovery01Output == null && c.patch01Input == null &&
                c.patch01LegacyOutput == null && c.patch01Output == null)
            assertThat("E_DISCOVERY02_CALC_TARGET_$i", c.calculationDay == f &&
                c.targetDay == witnesses[i].second)
            println("STAGE04_WITNESS_${witnesses[i].first}_ACTUAL_${actual[i]}_NORMATIVE_${expected[i]}")
        }
        assertThat("E_DISCOVERY02_METRICS", manager.metrics.snapshot()["bootstrap.ready"] == 5L &&
            manager.metrics.snapshot()["discovery02.legacy"] == 5L)
        assertThat("E_DISCOVERY02_OWNER", results.indices.all { i ->
            results.indices.all { j -> i == j || (results[i] !== results[j] &&
                results[i].branchTrace !== results[j].branchTrace &&
                results[i].diagnostics !== results[j].diagnostics) }
        })
        println("STAGE04_OWNERSHIP_PASS")

        // Sicrhau nad yw gweithredu'r llwybr darganfod yn llygru Patch 01.
        val p = manager.applySavePatch(f, f, NormativeCore.M)
        assertThat("E_DISCOVERY02_SAVE_PATCH_PRESERVED", p.patch01Output == NormativeCore.M &&
            p.discovery02Output == null && manager.metrics.snapshot()["patch01.applied"] == 1L)
        val d = manager.observeLegacyRemainder(f, f, NormativeCore.M)
        assertThat("E_DISCOVERY02_OLD_DISCOVERY_PRESERVED", d.discovery01Output == ExactInt.ZERO &&
            d.discovery02Output == null && manager.metrics.snapshot()["discovery01.legacy"] == 1L)
        println("STAGE04_PREVIOUS_ROUTES_PASS")

        // Heb BOOT, neu heb fewnbwn, rhaid gwrthod heb ymrwymo allbwn.
        val unready = BaseMonsterContext(f, f, phase = "DISCOVERY_02", discovery02Input = f)
        val unreadyCode = try {
            manager.dispatcher.dispatch(unready)
            "NO_ERROR"
        } catch (e: MonsterValidationException) {
            e.machineCode
        }
        assertThat("E_DISCOVERY02_PRE_BOOT", unreadyCode == "E_DISCOVERY02_CONTEXT_NOT_READY" &&
            unready.discovery02Output == null && unready.branchTrace.isEmpty() &&
            unready.diagnostics.isEmpty())
        val missing = manager.prepare(f, f)
        missing.phase = "DISCOVERY_02"
        val missingCode = try {
            manager.dispatcher.dispatch(missing)
            "NO_ERROR"
        } catch (e: MonsterValidationException) {
            e.machineCode
        }
        assertThat("E_DISCOVERY02_MISSING_INPUT", missingCode == "E_DISCOVERY02_NO_INPUT" &&
            missing.discovery02Output == null && missing.branchTrace == listOf("BOOT"))
        println("STAGE04_BOOT_GUARDS_PASS")

        // 331 diwrnod yng nghyffiniau'r Sylfaen: 165 yn cyd-fynd,
        // a 166 anghysondeb bwriadol gan gynnwys y Sylfaen ei hun.
        var rangeRed = 0
        var rangeMatch = 0
        for (offset in -165..165) {
            val day = f + offset.toLong()
            val observed = manager.observeLegacyDayTag(f, day, day)
            val old = observed.discovery02Output ?: error("E_DISCOVERY02_RANGE_NULL")
            val normative = NormativeCore.dayCount(day)
            assertThat("E_DISCOVERY02_RANGE_VALUE_$offset",
                old == ExactInt.of((kotlin.math.abs(offset) * 2L)))
            assertThat("E_DISCOVERY02_RANGE_EXPECTATION_$offset",
                (old != normative) == (offset >= 0))
            if (old != normative) rangeRed++ else rangeMatch++
        }
        assertThat("E_DISCOVERY02_RANGE_COUNTS", rangeRed == 166 && rangeMatch == 165)
        println("STAGE04_RANGE_RED_${rangeRed}_MATCH_${rangeMatch}")

        // Achosion pell: ni chaniateir gorlif Long na defnyddio int y cyfrifiadur.
        val far = ExactInt.parse("1" + "0".repeat(250))
        val farDays = listOf(f - far, f + far, f - ExactInt.ONE, f + ExactInt.ONE)
        var farRed = 0
        for ((index, day) in farDays.withIndex()) {
            val old = manager.observeLegacyDayTag(f, day, day).discovery02Output
            val correct = NormativeCore.dayCount(day)
            val expectedLegacy = if (index < 2) far.multiplyByInt(2) else ExactInt.of(2)
            assertThat("E_DISCOVERY02_FAR_$index", old == expectedLegacy)
            if (old != correct) farRed++
            assertThat("E_DISCOVERY02_FAR_SIDE_$index", (old != correct) == (index % 2 == 1))
        }
        assertThat("E_DISCOVERY02_FAR_COUNTS", farRed == 2)
        assertThat("E_DISCOVERY02_TOTAL_METRIC",
            manager.metrics.snapshot()["discovery02.legacy"] == 340L)
        println("STAGE04_FAR_WIDE_PASS_4")

        // Metamorffiaeth gyda chyfanrifau pell: rhaid i'r hen allbwn aros yn
        // union 2*|diwrnod-F| ar y ddwy ochr, ac i'r oracl ychwanegu un
        // ar yr ochr ar ôl F yn unig. Ni ddylai diwrnod cyfrifo na'r
        // diwrnod targed newid y diwrnod a ddewiswyd yn benodol.
        val vastMagnitudes = (1..24).map { index ->
            ExactInt.parse("1" + "0".repeat(index * 12))
        } + listOf(
            NormativeCore.M - ExactInt.ONE,
            NormativeCore.M,
            NormativeCore.M + ExactInt.ONE,
            NormativeCore.M.multiplyByInt(2),
            NormativeCore.M.multiplyByInt(3),
            NormativeCore.M.square()
        )
        val unrelatedCalculation = f - ExactInt.of(33)
        val unrelatedTarget = f + ExactInt.of(47)
        val initialContext = results.first()
        val initialTrace = initialContext.branchTrace.toList()
        val initialDiagnostics = initialContext.diagnostics.toList()
        val initialOutput = initialContext.discovery02Output
        val metricsBeforeWide = manager.metrics.snapshot()
        var testedWide = 0
        for ((i, magnitude) in vastMagnitudes.withIndex()) {
            for (positive in listOf(false, true)) {
                val day = f + if (positive) magnitude else -magnitude
                val observed = manager.observeLegacyDayTag(
                    unrelatedCalculation, unrelatedTarget, day
                )
                val expectedOld = magnitude.multiplyByInt(2)
                val expectedNormal = expectedOld + if (positive) 1L else 0L
                assertThat("E_DISCOVERY02_WIDE_OLD_${i}_$positive",
                    observed.discovery02Output == expectedOld)
                assertThat("E_DISCOVERY02_WIDE_ORACLE_${i}_$positive",
                    NormativeCore.dayCount(day) == expectedNormal)
                assertThat("E_DISCOVERY02_WIDE_PHASE_${i}_$positive",
                    observed.calculationDay == unrelatedCalculation &&
                    observed.targetDay == unrelatedTarget &&
                    observed.discovery02Input == day &&
                    observed.branchTrace == listOf("BOOT", "DISCOVERY_02") &&
                    observed.status == "LEGACY_DAY_TAG_OBSERVED")
                testedWide++
            }
        }
        assertThat("E_DISCOVERY02_WIDE_TOTAL", testedWide == 60)
        val metricsAfterWide = manager.metrics.snapshot()
        assertThat("E_DISCOVERY02_WIDE_METRIC",
            metricsAfterWide["discovery02.legacy"] ==
                (metricsBeforeWide["discovery02.legacy"] ?: 0L) + testedWide.toLong())
        assertThat("E_DISCOVERY02_PREVIOUS_STATE_IMMUTABLE",
            initialContext.discovery02Output == initialOutput &&
                initialContext.branchTrace == initialTrace &&
                initialContext.diagnostics == initialDiagnostics)
        println("STAGE04_WIDE_METAMORPHIC_PASS_$testedWide")

        // Nid yw ail-anfon yr un cyd-destun yn ganiataol: ni ddylai hyn
        // ailgyfrifo na dyblygu metrig, olrhain neu ddiagnosteg.
        val replayCode = try {
            manager.dispatcher.dispatch(initialContext)
            "NO_ERROR"
        } catch (e: MonsterValidationException) {
            e.machineCode
        }
        assertThat("E_DISCOVERY02_REPLAY_REJECTED",
            replayCode == "E_DISCOVERY02_CONTEXT_NOT_READY" &&
            initialContext.discovery02Output == initialOutput &&
            initialContext.branchTrace == initialTrace &&
            initialContext.diagnostics == initialDiagnostics &&
            manager.metrics.snapshot() == metricsAfterWide)
        println("STAGE04_REPLAY_REJECTION_PASS")

        if (args.firstOrNull() == "--strict") {
            error("E_DISCOVERY02_NORMATIVE_DIFFERENCE:F,F+1,F+2")
        }
        println("STAGE04_COMPLETE_EXPECTED_RED")
    }
}
