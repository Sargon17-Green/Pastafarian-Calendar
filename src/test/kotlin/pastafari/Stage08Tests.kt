package pastafari

/** Cam 8: yr oracl gwreiddiol ar ochr y prawf yn unig. */
object Stage08Tests {
    private fun insist(code: String, result: Boolean) { check(result) { code } }
    private fun errorCode(block: () -> Unit): String = try {
        block(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY04_ARGUMENTS" }
        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val builder = LegacyStoneBuilder()
        val result = manager.observeLegacyStones(f, f)
        val old = result.discovery04LegacyStoneRows ?: error("E_DISCOVERY04_NO_ROWS")
        val oracle = NormativeCore.STONES
        insist("E_DISCOVERY04_SIZE", old.size == 47 && result.discovery04BuiltRows == 46)
        insist("E_DISCOVERY04_SENTINEL", old[0].components() == List(5) { ExactInt.ZERO })
        insist("E_DISCOVERY04_INITIAL", old[1].components() == oracle[1].toList() &&
            old[1].components() == listOf(17L,29L,43L,71L,101L).map(ExactInt::of))
        var red = 0
        var match = 0
        for (i in 2..46) {
            for (k in 0..4) {
                if (old[i].components()[k] == oracle[i][k]) match++ else red++
            }
            if (i == 2 || i == 3 || i == 46) {
                println("STAGE08_ROW_${i}_EXPECTED_RED")
            }
        }
        insist("E_DISCOVERY04_DIFF_224", red == 224 && match == 1)
        insist("E_DISCOVERY04_ROW2", old[2].wheat == oracle[2][0] &&
            old[2].barley != oracle[2][1] && old[2].salt != oracle[2][2] &&
            old[2].bitter != oracle[2][3] && old[2].red != oracle[2][4])
        insist("E_DISCOVERY04_CONTEXT", result.phase == "DISCOVERY_04" &&
            result.status == "LEGACY_STONES_OBSERVED" &&
            result.branchTrace == listOf("BOOT", "DISCOVERY_04") &&
            result.diagnostics == listOf("DISCOVERY_04_LEGACY_SEQUENTIAL_STONES") &&
            result.patch03Output == null && result.discovery03Output == null)
        insist("E_DISCOVERY04_METRIC", manager.metrics.snapshot()["discovery04.legacy.builds"] == 1L)
        println("STAGE08_EXPECTED_RED_224")
        println("STAGE08_MATCH_1")
        println("STAGE08_ROWS_46_PASS")

        // Y nam yn newid yr un gwrthrych byw yn hytrach na chreu rhes newydd.
        val mutable = MutableStoneRow(ExactInt.of(17), ExactInt.of(29),
            ExactInt.of(43), ExactInt.of(71), ExactInt.of(101))
        val original = mutable.copy()
        val identity = builder.mutateStonesWrong(mutable, 2)
        insist("E_DISCOVERY04_MUTATION_IDENTITY", identity === mutable && mutable != original &&
            mutable.components() == old[2].components())
        insist("E_DISCOVERY04_ROW_RANGE", try {
            builder.mutateStonesWrong(mutable, 1); false
        } catch (e: IllegalArgumentException) { true })
        println("STAGE08_INPLACE_SEQUENTIAL_PASS")

        // Mae pob rhes wedi'i chadw ar ei phen ei hun; dim alias o'r gwrthrych byw.
        insist("E_DISCOVERY04_ROWS_NOT_ALIASED", (0..46).all { i ->
            (0..46).all { j -> i == j || old[i] !== old[j] }
        })
        val second = manager.observeLegacyStones(f + 1L, f - 1L)
        val otherRows = second.discovery04LegacyStoneRows ?: error("E_DISCOVERY04_SECOND_ROWS")
        insist("E_DISCOVERY04_SEPARATE_CONTEXTS", second !== result && otherRows !== old &&
            otherRows.zip(old).all { (a,b) -> a !== b && a == b } &&
            second.calculationDay != result.calculationDay &&
            second.discovery04BuiltRows == 46)
        val initialSaved = old[1].copy()
        val lastSaved = old[46].copy()
        otherRows[2].wheat = ExactInt.ZERO
        insist("E_DISCOVERY04_NO_ALIAS_LEAK", old[2].wheat != ExactInt.ZERO &&
            old[1] == initialSaved && old[46] == lastSaved)
        println("STAGE08_OWNERSHIP_PASS")

        val previous = manager.metrics.snapshot()
        val trace = result.branchTrace.toList()
        val diagnostic = result.diagnostics.toList()
        insist("E_DISCOVERY04_REPLAY", errorCode { manager.dispatcher.dispatch(result) } ==
            "E_DISCOVERY04_CONTEXT_NOT_READY" && old === result.discovery04LegacyStoneRows &&
            result.discovery04BuiltRows == 46 && result.branchTrace == trace &&
            result.diagnostics == diagnostic && manager.metrics.snapshot() == previous)
        val noBoot = BaseMonsterContext(f, f, phase = "DISCOVERY_04")
        insist("E_DISCOVERY04_BOOT_GUARD", errorCode { manager.dispatcher.dispatch(noBoot) } ==
            "E_DISCOVERY04_CONTEXT_NOT_READY" && noBoot.discovery04LegacyStoneRows == null &&
            noBoot.discovery04BuiltRows == 0 && manager.metrics.snapshot() == previous)
        println("STAGE08_GUARDS_REPLAY_PASS")

        // Y tri PATCH blaenorol yn dal yn alwadadwy a chywir.
        insist("E_DISCOVERY04_PATCH1", manager.applySavePatch(f, f, NormativeCore.M).patch01Output == NormativeCore.M)
        insist("E_DISCOVERY04_PATCH2", manager.applyDayTagPatch(f, f, f).patch02Output == ExactInt.ONE)
        insist("E_DISCOVERY04_PATCH3", manager.applyDistancePatch(f,f).patch03Output == ExactInt.ONE)
        insist("E_DISCOVERY04_OLD_DISTANCE", manager.observeLegacyDistance(f,f).discovery03Output == ExactInt.ZERO)
        println("STAGE08_EARLIER_ROUTES_PASS")
        println("STAGE08_DISCOVERY_COMPLETE_EXPECTED_RED")
    }
}
