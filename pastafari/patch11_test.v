module pastafari

// ደረጃ 23፦ የorderAt46Latch ቅጂ እና 12ቱ የታሪክ ብስለቶች ይለያያሉ።
fn patch11_fixture_bowls() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

fn test_patch11_four_historic_red_order_cases_become_green() {
	bowls := patch11_fixture_bowls()
	for order in [[1, 2, 3, 4, 5, 6], [6, 5, 4, 3, 2, 1], [2, 3, 1, 4, 5, 6],
		[1, 3, 5, 2, 4, 6]] {
		production := calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
		legacy := new_base_dispatcher().dispatch_legacy_post_stir12(bowls, order) or {
			LegacyPostStir12Result{}
		}
		assert production.order_for_query == order
		assert legacy.order_for_query == [3, 5, 1, 4, 6, 2]
		assert production.overwrite_count == 12
		assert legacy.overwrite_count == 12
		assert production.final_stir_number == 12
		assert production.bowls == legacy.bowls
		assert big_eq(production.final_saved_sum, legacy.final_saved_sum)
	}
}

fn test_patch11_latch_is_complete_and_independent_of_store_writes() {
	patch := PostStirPatch11{}
	order := [6, 5, 4, 3, 2, 1]
	order_at_46_latch := patch.latch_order_at_46(order) or { []int{} }
	assert order_at_46_latch == order
	mut old_store := new_legacy_post_stir_order_store(order)
	old_store.old_overwrite_query_order([3, 6, 5, 4, 1, 2])
	old_store.old_overwrite_query_order([3, 5, 1, 4, 6, 2])
	assert old_store.overwrite_count == 2
	assert old_store.query_order == [3, 5, 1, 4, 6, 2]
	assert order_at_46_latch == [6, 5, 4, 3, 2, 1]
	assert order == [6, 5, 4, 3, 2, 1]
}

fn test_patch11_latch_validates_all_720_orders_without_reordering() {
	patch := PostStirPatch11{}
	mut seen := map[string]bool{}
	for rank0 in 0 .. 720 {
		order := old_permutation_unrank0(rank0) or { []int{} }
		latched := patch.latch_order_at_46(order) or { []int{} }
		assert latched.len == 6
		assert latched == order
		assert latched.str() !in seen
		seen[latched.str()] = true
	}
	assert seen.len == 720
}

fn test_patch11_full_twelve_stirs_retain_order_for_each_sample_rank() {
	bowls := patch11_fixture_bowls()
	for rank0 in [0, 1, 11, 19, 59, 120, 241, 359, 479, 598, 718, 719] {
		order := old_permutation_unrank0(rank0) or { []int{} }
		out := calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
		legacy := new_base_dispatcher().dispatch_legacy_post_stir12(bowls, order) or {
			LegacyPostStir12Result{}
		}
		assert out.order_for_query == order
		assert out.overwrite_count == 12
		assert out.bowls == legacy.bowls
		assert legacy.order_for_query == [3, 5, 1, 4, 6, 2]
	}
}

fn test_patch11_preserves_full_post_stir_arithmetic_and_save() {
	order := [1, 2, 3, 4, 5, 6]
	bowls := patch11_fixture_bowls()
	out := calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
	assert out.bowls[0].str() == '0'
	assert out.bowls[1].str() == '136215324145469545419479201619538607493'
	assert out.bowls[6].str() == '121878577507874381427169074335666166709'
	assert out.final_saved_sum.str() == '152983071395321360281688056688813299996'
	assert out.final_stir_number == 12
	assert out.order_for_query == [1, 2, 3, 4, 5, 6]
}

fn test_patch11_very_large_signed_bowls_and_reentrancy() {
	huge := big_pow_small(big_from_int(2), 512)
	bowls := [big_zero(), huge, big_neg(huge), big_one(), big_from_int(41),
		big_from_int(43), big_from_int(47)]
	order := [1, 5, 3, 4, 2, 6]
	for repeat in 0 .. 5 {
		out := calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
		legacy := new_base_dispatcher().dispatch_legacy_post_stir12(bowls, order) or {
			LegacyPostStir12Result{}
		}
		assert out.order_for_query == order
		assert out.bowls == legacy.bowls
		assert big_eq(out.final_saved_sum, legacy.final_saved_sum)
		assert bowls[1].str() == huge.str()
		assert bowls[2].str() == big_neg(huge).str()
		assert order == [1, 5, 3, 4, 2, 6]
	}
}

fn test_patch11_invalid_order_is_rejected_before_legacy_execution() {
	patch := PostStirPatch11{}
	bowls := patch11_fixture_bowls()
	for order in [[1, 2, 3], [1, 2, 3, 4, 5, 5], [1, 2, 3, 4, 5, 7]] {
		mut rejected := false
		_ = patch.latch_order_at_46(order) or {
			rejected = true
			[]int{}
		}
		assert rejected
		rejected = false
		_ = calendar_post_stir12_spaghetti(bowls, order) or {
			rejected = true
			LegacyPostStir12Result{}
		}
		assert rejected
	}
	assert bowls[1].str() == '10'
}

fn test_patch11_diagnostic_contains_legacy_scar_and_unwritten_latch() {
	foundation := big_from_i64(-15_055_671)
	mut message := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		message = err.msg()
		CalendarResult{}
	}
	assert message.contains('DISCOVERY_11 originalOrder=')
	assert message.contains('DISCOVERY_11 wrongQueryOrder=')
	assert message.contains('DISCOVERY_11 overwriteCount=12')
	assert message.contains('PATCH_11 latchedOrder=')
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
}
