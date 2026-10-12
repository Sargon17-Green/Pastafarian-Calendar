module pastafari

fn test_discovery08_legacy_unrank_zero_and_last_are_exact() {
	assert (old_permutation_unrank0(0) or { []int{} }) == [1, 2, 3, 4, 5, 6]
	assert (old_permutation_unrank0(1) or { []int{} }) == [1, 2, 3, 4, 6, 5]
	assert (old_permutation_unrank0(2) or { []int{} }) == [1, 2, 3, 5, 4, 6]
	assert (old_permutation_unrank0(718) or { []int{} }) == [6, 5, 4, 3, 1, 2]
	assert (old_permutation_unrank0(719) or { []int{} }) == [6, 5, 4, 3, 2, 1]
}

fn test_discovery08_legacy_unrank_rejects_invalid_rank0() {
	for invalid in [-100, -1, 720, 721, 999] {
		mut rejected := false
		_ = old_permutation_unrank0(invalid) or {
			rejected = true
			[]int{}
		}
		assert rejected
	}
}

fn test_discovery08_all_720_legacy_permutations_are_unique_and_valid() {
	mut seen := map[string]bool{}
	for rank0 in 0 .. 720 {
		order := old_permutation_unrank0(rank0) or { []int{} }
		assert order.len == 6
		mut sorted := order.clone()
		sorted.sort()
		assert sorted == [1, 2, 3, 4, 5, 6]
		key := order.str()
		assert key !in seen
		seen[key] = true
	}
	assert seen.len == 720
}

fn test_discovery08_historical_caller_uses_one_based_as_rank0() {
	dispatcher := new_base_dispatcher()
	assert (dispatcher.dispatch_legacy_permutation(big_one()) or { []int{} }) == [1, 2, 3, 4, 6,
		5]
	assert (dispatcher.dispatch_legacy_permutation(big_from_int(2)) or { []int{} }) == [1, 2,
		3, 5, 4, 6]
	assert (dispatcher.dispatch_legacy_permutation(big_from_int(719)) or { []int{} }) == [6,
		5, 4, 3, 2, 1]
	assert (dispatcher.dispatch_legacy_permutation(big_from_int(721)) or { []int{} }) == [1,
		2, 3, 4, 6, 5]
}

fn test_discovery08_historical_drop_720_rejects_one_based_rank_720() {
	dispatcher := new_base_dispatcher()
	for drop in [big_zero(), big_from_int(720), big_from_int(1440),
		big_from_int(-720)] {
		mut rejected := false
		_ = dispatcher.dispatch_legacy_permutation(drop) or {
			rejected = true
			[]int{}
		}
		assert rejected
	}
}

fn test_discovery08_large_and_negative_drops_keep_legacy_modulo_behavior() {
	huge := big_mul_small(big_pow_small(big_from_int(2), 384), 720)
	dispatcher := new_base_dispatcher()
	for drop in [
		big_add(huge, big_one()),
		big_add(big_neg(huge), big_one()),
		big_from_int(-719),
	] {
		assert (dispatcher.dispatch_legacy_permutation(drop) or { []int{} }) == [1, 2, 3, 4,
			6, 5]
	}
}

fn test_discovery08_previous_patches_and_production_probe_still_work() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	assert (calendar_grind_row_spaghetti(1) or { []int{} }) == [3, 5, 7, 11, 1]
	assert (calendar_grind_row_spaghetti(11) or { []int{} }) == [37, 41, 43, 47, 1]
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('PATCH_07 grind1A=3')
	assert diagnostic.contains('DISCOVERY_08 oldPermRank0=1')
	assert diagnostic.contains('DISCOVERY_08 oldPermOrder=[1, 2, 3, 4, 6, 5]')
	assert diagnostic.contains('PATCH_08 permRank0=0')
	assert diagnostic.contains('PATCH_08 permOrder=[1, 2, 3, 4, 5, 6]')
}
