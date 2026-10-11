package pastafari

/** Cam 5 / PATCH 02. Defnyddir yr oracl yn y profion yn unig. */
object Stage05Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun rejected(block: () -> Unit): String = try {
        block(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH02_BAD_ARGUMENTS" }
        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val cases = listOf(
            "F_MINUS_2" to (f - 2L),
            "F_MINUS_1" to (f - 1L),
            "F" to f,
            "F_PLUS_1" to (f + 1L),
            "F_PLUS_2" to (f + 2L)
        )
        val oldValues = listOf(4L, 2L, 0L, 2L, 4L).map(ExactInt::of)
        val newValues = listOf(4L, 2L, 1L, 3L, 5L).map(ExactInt::of)
        val results = cases.map { (_, day) -> manager.applyDayTagPatch(f, day, day) }
        val outputs = results.map { it.patch02Output ?: error("E_PATCH02_NULL") }
        insist("E_PATCH02_WITNESS_LEGACY", results.map { it.patch02LegacyOutput } == oldValues)
        insist("E_PATCH02_WITNESS_PATCH", outputs == newValues)
        insist("E_PATCH02_NORMATIVE_WITNESSES", cases.map { NormativeCore.dayCount(it.second) } == outputs)
        insist("E_PATCH02_NO_DIFFERENCES", outputs.indices.none { outputs[it] != NormativeCore.dayCount(cases[it].second) })
        results.forEachIndexed { i, c ->
            insist("E_PATCH02_STATE_$i", c.patch02Input == cases[i].second &&
                c.patch02LegacyOutput == oldValues[i] && c.patch02Output == newValues[i] &&
                c.phase == "PATCH_02" && c.status == "PATCHED_DAY_TAG" &&
                c.branchTrace == listOf("BOOT", "PATCH_02") &&
                c.diagnostics == listOf("PATCH_02_FOUNDATION_SCAR_WRAPPER") &&
                c.discovery01Input == null && c.discovery02Input == null &&
                c.patch01Input == null && c.patch01Output == null &&
                c.discovery02Output == null)
        }
        insist("E_PATCH02_METRIC_FIVE", manager.metrics.snapshot()["patch02.legacy.calls"] == 5L &&
            manager.metrics.snapshot()["patch02.applied"] == 5L &&
            manager.metrics.snapshot()["bootstrap.ready"] == 5L)
        insist("E_PATCH02_CONTEXT_ISOLATION", results.indices.all { i ->
            results.indices.all { j -> i == j || (results[i] !== results[j] &&
                results[i].branchTrace !== results[j].branchTrace &&
                results[i].diagnostics !== results[j].diagnostics) }
        })
        println("STAGE05_PATCH_GREEN_0")
        println("STAGE05_WITNESSES_GREEN_5")
        println("STAGE05_OWNERSHIP_PASS")

        // Cynnal y graith goch yn union, ac osgoi llygru'r llwybrau cynharach.
        val oldResults = cases.map { manager.observeLegacyDayTag(f, it.second, it.second) }
        insist("E_PATCH02_LEGACY_PRESERVED", oldResults.map { it.discovery02Output } == oldValues &&
            oldResults.indices.count { oldResults[it].discovery02Output != outputs[it] } == 3)
        insist("E_PATCH02_PREVIOUS_STAGES", manager.applySavePatch(f, f, NormativeCore.M).patch01Output == NormativeCore.M &&
            manager.observeLegacyRemainder(f, f, NormativeCore.M).discovery01Output == ExactInt.ZERO)
        println("STAGE05_DISCOVERY02_SCAR_RED_3")
        println("STAGE05_EARLIER_ROUTES_PASS")

        // Prawf gardau cyn BOOT, diffyg mewnbwn, ac ail-anfon cyd-destun.
        val unready = BaseMonsterContext(f, f, phase = "PATCH_02", patch02Input = f)
        val beforeInvalid = manager.metrics.snapshot()
        insist("E_PATCH02_UNREADY", rejected { manager.dispatcher.dispatch(unready) } ==
            "E_PATCH02_CONTEXT_NOT_READY" && unready.patch02Output == null &&
            unready.patch02LegacyOutput == null && unready.branchTrace.isEmpty() &&
            manager.metrics.snapshot() == beforeInvalid)
        val missing = manager.prepare(f, f)
        missing.phase = "PATCH_02"
        val beforeMissing = manager.metrics.snapshot()
        insist("E_PATCH02_MISSING", rejected { manager.dispatcher.dispatch(missing) } ==
            "E_PATCH02_NO_INPUT" && missing.patch02Output == null &&
            missing.branchTrace == listOf("BOOT") &&
            manager.metrics.snapshot() == beforeMissing)
        val replay = results[0]
        val originalTrace = replay.branchTrace.toList()
        val originalDiagnostics = replay.diagnostics.toList()
        val originalOutput = replay.patch02Output
        insist("E_PATCH02_REPLAY", rejected { manager.dispatcher.dispatch(replay) } ==
            "E_PATCH02_CONTEXT_NOT_READY" && replay.patch02Output == originalOutput &&
            replay.branchTrace == originalTrace && replay.diagnostics == originalDiagnostics &&
            manager.metrics.snapshot() == beforeMissing)
        val wrapper = DayTagPatchWrapper()
        val negativeCode = try {
            wrapper.dayTagWithFoundationScar(f, ExactInt.of(-1)); "NO_ERROR"
        } catch (e: IllegalArgumentException) { e.message ?: "ERROR" }
        insist("E_PATCH02_NEGATIVE_REJECTED", negativeCode == "E_PATCH02_NEGATIVE_LEGACY_TAG")
        insist("E_PATCH02_FOUNDATION_REDUNDANT", wrapper.dayTagWithFoundationScar(f, ExactInt.ZERO) == ExactInt.ONE)
        println("STAGE05_GUARDS_AND_REPLAY_PASS")

        // 331 diwrnod, yn cynnwys Sylfaen, yn union yr un oracl â Cham 4.
        var tested = 0
        val initialMetrics = manager.metrics.snapshot()
        for (offset in -165..165) {
            val day = f + offset.toLong()
            val actual = manager.applyDayTagPatch(f - 100L, f + 100L, day)
            insist("E_PATCH02_RANGE_$offset", actual.patch02Output == NormativeCore.dayCount(day))
            insist("E_PATCH02_OLD_RANGE_$offset", actual.patch02LegacyOutput ==
                ExactInt.of((kotlin.math.abs(offset) * 2).toLong()))
            insist("E_PATCH02_DISTINCT_DAY_$offset", actual.calculationDay == f - 100L &&
                actual.targetDay == f + 100L && actual.patch02Input == day)
            tested++
        }
        insist("E_PATCH02_RANGE_TOTAL", tested == 331)
        println("STAGE05_RANGE_GREEN_331")

        // Gwerthoedd y tu hwnt i Long ac uwchlaw 256 did: nid oes colled manylder.
        val magnitudes = (1..24).map { ExactInt.parse("1" + "0".repeat(it * 12)) } +
            listOf(NormativeCore.M - ExactInt.ONE, NormativeCore.M,
                NormativeCore.M + ExactInt.ONE, NormativeCore.M.square(),
                NormativeCore.M.multiplyByInt(2), NormativeCore.M.multiplyByInt(3))
        var wide = 0
        for (mag in magnitudes) for (positive in listOf(false, true)) {
            val day = f + if (positive) mag else -mag
            val patched = manager.applyDayTagPatch(f, f, day)
            val oldExpected = mag.multiplyByInt(2)
            insist("E_PATCH02_WIDE_LEGACY_$wide", patched.patch02LegacyOutput == oldExpected)
            insist("E_PATCH02_WIDE_PATCH_$wide", patched.patch02Output ==
                oldExpected + if (positive) 1L else 0L)
            insist("E_PATCH02_WIDE_NORMATIVE_$wide", patched.patch02Output == NormativeCore.dayCount(day))
            wide++
        }
        insist("E_PATCH02_WIDE_COUNT", wide == 60)
        insist("E_PATCH02_WIDE_METRICS", manager.metrics.snapshot()["patch02.applied"] ==
            (initialMetrics["patch02.applied"] ?: 0L) + tested.toLong() + wide.toLong() &&
            manager.metrics.snapshot()["patch02.legacy.calls"] ==
            (initialMetrics["patch02.legacy.calls"] ?: 0L) + tested.toLong() + wide.toLong())
        insist("E_PATCH02_PREVIOUS_RESULTS_STABLE", results[0].patch02Output == originalOutput &&
            results[0].branchTrace == originalTrace && results[0].diagnostics == originalDiagnostics)
        println("STAGE05_WIDE_GREEN_60")
        println("STAGE05_METRICS_AND_IMMUTABILITY_PASS")
        println("STAGE05_COMPLETE_GREEN")
    }
}
