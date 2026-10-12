module pastafari

// ደረጃ 17፦ የPATCH 08 ማስተካከያ እና የቀድሞው የታሪክ ስህተት በተለያዩ መንገዶች ይፈተሻሉ።
fn test_patch08_boundaries_and_explicit_permutation_fixtures() {
	patch := PermutationPatch08{}
	fixtures := [
		[1, 2, 3, 4, 5, 6],
		[1, 2, 3, 4, 6, 5],
		[1, 2, 3, 5, 4, 6],
	]
	for i in 0 .. fixtures.len {
		drop := big_from_int(i + 1)
		assert patch.legacy_rank0(drop) == i
		assert (calendar_bowl_order_spaghetti(drop) or { []int{} }) == fixtures[i]
	}
	assert patch.legacy_rank0(big_zero()) == 719
	assert patch.legacy_rank0(big_from_int(720)) == 719
	assert patch.legacy_rank0(big_from_int(721)) == 0
	assert (calendar_bowl_order_spaghetti(big_zero()) or { []int{} }) == [6, 5, 4, 3, 2, 1]
	assert (calendar_bowl_order_spaghetti(big_from_int(719)) or { []int{} }) == [6, 5, 4,
		3, 1, 2]
	assert (calendar_bowl_order_spaghetti(big_from_int(720)) or { []int{} }) == [6, 5, 4,
		3, 2, 1]
	assert (calendar_bowl_order_spaghetti(big_from_int(721)) or { []int{} }) == [1, 2, 3,
		4, 5, 6]
}

fn test_patch08_exhaustive_720_orders_match_old_zero_based_unrank() {
	patch := PermutationPatch08{}
	dispatcher := new_base_dispatcher()
	mut unique := map[string]bool{}
	for ordinal in 1 .. 721 {
		drop := big_from_int(ordinal)
		rank0 := patch.legacy_rank0(drop)
		assert rank0 == ordinal - 1
		expected := old_permutation_unrank0(ordinal - 1) or { []int{} }
		actual := calendar_bowl_order_spaghetti(drop) or { []int{} }
		assert actual == expected
		assert (dispatcher.dispatch_permutation_patch08(drop) or { []int{} }) == expected
		assert (patch.order_for_drop(drop) or { []int{} }) == expected
		assert actual.str() !in unique
		unique[actual.str()] = true
	}
	assert unique.len == 720
}

fn test_patch08_legacy_wrong_caller_remains_accessible() {
	dispatcher := new_base_dispatcher()
	assert (old_permutation_unrank0(0) or { []int{} }) == [1, 2, 3, 4, 5, 6]
	assert (dispatcher.dispatch_legacy_permutation(big_one()) or { []int{} }) == [1, 2,
		3, 4, 6, 5]
	assert (calendar_bowl_order_spaghetti(big_one()) or { []int{} }) == [1, 2, 3, 4, 5, 6]
	mut failed := false
	_ = dispatcher.dispatch_legacy_permutation(big_from_int(720)) or {
		failed = true
		[]int{}
	}
	assert failed
	assert (calendar_bowl_order_spaghetti(big_from_int(720)) or { []int{} }) == [6, 5,
		4, 3, 2, 1]
}

fn test_patch08_720_periodic_wrap_across_negative_and_positive_drops() {
	patch := PermutationPatch08{}
	for base in [-1441, -720, -719, -1, 0, 1, 2, 719, 720, 721, 1440, 1441] {
		for turns in [-3, -1, 0, 1, 3] {
			moved := base + turns * 720
			expected_rank := int(big_mod_small_nonnegative(big_sub(big_from_int(base), big_one()),
				720))
			actual_rank := patch.legacy_rank0(big_from_int(moved))
			assert actual_rank == expected_rank
			expected := calendar_bowl_order_spaghetti(big_from_int(base)) or { []int{} }
			actual := calendar_bowl_order_spaghetti(big_from_int(moved)) or { []int{} }
			assert actual == expected
		}
	}
}

fn test_patch08_huge_signed_drops_no_width_truncation() {
	patch := PermutationPatch08{}
	huge := big_mul_small(big_pow_small(big_from_int(2), 420), 720)
	for offset in [-721, -720, -719, -1, 0, 1, 2, 719, 720, 721] {
		ordinary := big_from_int(offset)
		positive_huge := big_add(huge, ordinary)
		negative_huge := big_add(big_neg(huge), ordinary)
		expected := calendar_bowl_order_spaghetti(ordinary) or { []int{} }
		assert (calendar_bowl_order_spaghetti(positive_huge) or { []int{} }) == expected
		assert (calendar_bowl_order_spaghetti(negative_huge) or { []int{} }) == expected
		assert patch.legacy_rank0(positive_huge) == patch.legacy_rank0(ordinary)
		assert patch.legacy_rank0(negative_huge) == patch.legacy_rank0(ordinary)
	}
}

fn test_patch08_reentrant_inputs_and_no_shared_registry_order() {
	first := big_from_int(313)
	second := big_from_int(720)
	expected_first := calendar_bowl_order_spaghetti(first) or { []int{} }
	expected_second := calendar_bowl_order_spaghetti(second) or { []int{} }
	assert expected_first.len == 6
	assert expected_second == [6, 5, 4, 3, 2, 1]
	for repeat in 0 .. 12 {
		assert (calendar_bowl_order_spaghetti(first) or { []int{} }) == expected_first
		assert (calendar_bowl_order_spaghetti(second) or { []int{} }) == expected_second
		assert (new_base_dispatcher().dispatch_permutation_patch08(first) or {
			[]int{}
		}) == expected_first
	}
}

fn test_patch08_prior_history_and_monster_diagnostics_still_match() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	assert (calendar_grind_row_spaghetti(1) or { []int{} }) == [3, 5, 7, 11, 1]
	assert (calendar_grind_row_spaghetti(11) or { []int{} }) == [37, 41, 43, 47, 1]
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert calendar_hidden_by_nearness(hidden, 1).str() == '119390830530032782664128530203002080344'
	prior := calendar_prior_spaghetti(new_legacy_visible_drop_store(), hidden, 1, 1) or {
		big_zero()
	}
	assert big_eq(prior, calendar_hidden_by_nearness(hidden, 1))
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('DISCOVERY_08 oldPermRank0=1')
	assert diagnostic.contains('DISCOVERY_08 oldPermOrder=[1, 2, 3, 4, 6, 5]')
	assert diagnostic.contains('PATCH_08 permRank0=0')
	assert diagnostic.contains('PATCH_08 permOrder=[1, 2, 3, 4, 5, 6]')
}
