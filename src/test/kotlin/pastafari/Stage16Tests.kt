package pastafari

/** Tystiolaeth DISCOVERY 08: dim PATCH 08. */
object Stage16Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun machineCode(f: () -> Unit): String = try {
        f(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY08_ARGS" }
        val adapter = LegacyPermutationOrderAdapter()
        insist("E_DISCOVERY08_HELPER_FIRST",
            adapter.oldPermutationUnrank0(0) == listOf(1,2,3,4,5,6))
        insist("E_DISCOVERY08_HELPER_LAST",
            adapter.oldPermutationUnrank0(719) == listOf(6,5,4,3,2,1))
        for (invalid in listOf(-1,720)) {
            insist("E_DISCOVERY08_HELPER_RANGE", try {
                adapter.oldPermutationUnrank0(invalid); false
            } catch (e: IllegalArgumentException) {
                e.message == "E_DISCOVERY08_RANK0_RANGE"
            })
        }
        val unique = linkedSetOf<List<Int>>()
        for (rank0 in 0..719) {
            val order = adapter.oldPermutationUnrank0(rank0)
            insist("E_DISCOVERY08_HELPER_PERMUTATION_$rank0",
                order.sorted() == listOf(1,2,3,4,5,6) &&
                order == NormativeCore.permutationUnrank1(
                    rank0 + 1, intArrayOf(1,2,3,4,5,6)).toList())
            unique.add(order)
        }
        insist("E_DISCOVERY08_HELPER_BIJECTION", unique.size == 720)
        println("STAGE16_ZERO_BASED_HELPER_GREEN_720")

        var numeric = 0
        var undefined = 0
        var red = 0
        for (ordinal in 1..720) {
            val d = ExactInt.of(ordinal.toLong())
            val expected = NormativeCore.bowlOrderFromDrop(d).toList()
            val raw = adapter.legacyPermutationOrderFromDropWrong(d)
            insist("E_DISCOVERY08_DIRECT_RANK_$ordinal",
                raw.dropValue == d && raw.oneBased == ordinal &&
                raw.passedRank0 == ordinal && raw.legacyCalls == 1)
            if (ordinal == 720) {
                insist("E_DISCOVERY08_UNDEFINED_720",
                    raw.legacyOrder == null && raw.undefined &&
                    raw.errorId == "E_DISCOVERY08_RANK0_RANGE")
                undefined++
            } else {
                insist("E_DISCOVERY08_SHIFT_$ordinal",
                    raw.legacyOrder == adapter.oldPermutationUnrank0(ordinal) &&
                    raw.legacyOrder != expected && !raw.undefined &&
                    raw.errorId == null)
                numeric++
            }
            red++
        }
        insist("E_DISCOVERY08_EXPECTED_ALL_RED",
            red == 720 && numeric == 719 && undefined == 1)
        insist("E_DISCOVERY08_WRONG_FIRST",
            adapter.legacyPermutationOrderFromDropWrong(ExactInt.ONE)
                .legacyOrder == listOf(1,2,3,4,6,5))
        println("STAGE16_EXPECTED_RED_720")
        println("STAGE16_MATCH_0")
        println("STAGE16_SHIFTED_NUMERIC_719")
        println("STAGE16_UNDEFINED_720_PASS")
        println("STAGE16_RANK1_WRONG_ORDER_PASS")

        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val first = manager.observeLegacyPermutation(f,f)
        val firstOrder = first.discovery08LegacyOrder ?: error("E_DISCOVERY08_NO_ORDER")
        insist("E_DISCOVERY08_PRODUCTION_FIRST",
            first.phase == "DISCOVERY_08" &&
            first.status == "LEGACY_PERMUTATION_OBSERVED" &&
            first.branchTrace == listOf("BOOT","DISCOVERY_08") &&
            first.diagnostics == listOf("DISCOVERY_08_ONE_BASED_AS_RANK0") &&
            first.discovery08DropValue == ExactInt.ONE &&
            first.discovery08OneBased == 1 && first.discovery08PassedRank0 == 1 &&
            firstOrder == listOf(1,2,3,4,6,5) &&
            first.discovery08Undefined == false &&
            first.discovery08ErrorId == null &&
            first.discovery08LegacyCalls == 1 &&
            first.discovery08InvocationCount == 1)
        val last = manager.observeLegacyPermutation(f,f,ExactInt.of(720L))
        insist("E_DISCOVERY08_PRODUCTION_LAST",
            last.discovery08OneBased == 720 && last.discovery08PassedRank0 == 720 &&
            last.discovery08LegacyOrder == null && last.discovery08Undefined == true &&
            last.discovery08ErrorId == "E_DISCOVERY08_RANK0_RANGE" &&
            last.discovery08LegacyCalls == 1 &&
            last.discovery08InvocationCount == 1)
        insist("E_DISCOVERY08_PRODUCTION_COUNTER",
            manager.metrics.snapshot()["discovery08.legacy.unrank.calls"] == 2L)
        println("STAGE16_PRODUCTION_REAL_LEGACY_PASS")
        println("STAGE16_PRODUCTION_720_UNDEFINED_PASS")
        val before = manager.metrics.snapshot()
        val trace = first.branchTrace.toList()
        val diag = first.diagnostics.toList()
        insist("E_DISCOVERY08_REPLAY",
            machineCode { manager.dispatcher.dispatch(first) } ==
                "E_DISCOVERY08_CONTEXT_NOT_READY" &&
            first.discovery08LegacyOrder === firstOrder &&
            first.discovery08InvocationCount == 1 &&
            first.branchTrace == trace && first.diagnostics == diag &&
            manager.metrics.snapshot() == before)
        val unbooted = BaseMonsterContext(f,f,phase="DISCOVERY_08",
            discovery08DropValue=ExactInt.ONE)
        insist("E_DISCOVERY08_NO_BOOT",
            machineCode { manager.dispatcher.dispatch(unbooted) } ==
                "E_DISCOVERY08_CONTEXT_NOT_READY" &&
            unbooted.discovery08LegacyOrder == null &&
            unbooted.discovery08InvocationCount == 0 &&
            manager.metrics.snapshot() == before)
        val noDrop = BaseMonsterContext(f,f,status="READY",phase="DISCOVERY_08")
        insist("E_DISCOVERY08_NO_DROP",
            machineCode { manager.dispatcher.dispatch(noDrop) } ==
                "E_DISCOVERY08_NO_DROP" &&
            noDrop.discovery08InvocationCount == 0 &&
            manager.metrics.snapshot() == before)
        val other = manager.observeLegacyPermutation(f-99L,f+201L,ExactInt.of(721L))
        insist("E_DISCOVERY08_OWNERSHIP",
            other !== first && other.discovery08LegacyOrder !== firstOrder &&
            other.discovery08LegacyOrder == listOf(1,2,3,4,6,5) &&
            other.discovery08OneBased == 1 && first.discovery08OneBased == 1)
        println("STAGE16_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE16_CONTEXT_OWNERSHIP_PASS")
        val oldGrind = manager.observeLegacyGrind(f,f,11)
        val patchedGrind = manager.applyGrindPatch(f,f,11)
        insist("E_DISCOVERY08_PREVIOUS_GRIND_SCAR",
            oldGrind.discovery07Undefined == true &&
            oldGrind.discovery07LegacyRow == null)
        insist("E_DISCOVERY08_PREVIOUS_PATCH07",
            patchedGrind.patch07CorrectedRow == VisibleGrindRow(37,41,43,47,0) &&
            patchedGrind.patch07LegacyUndefined == true)
        val hidden = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f,f))
        insist("E_DISCOVERY08_PREVIOUS_PRIOR",
            manager.applyPriorPatch(f,f,1,7).patch06Output == hidden[7])
        println("STAGE16_EARLIER_ROUTES_PASS")
        println("STAGE16_NATIVE_EXPECTED_RED_COMPLETE")
    }
}
