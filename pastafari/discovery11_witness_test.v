module pastafari

// ደረጃ 22፦ የ12 post-stirs ሂሳብ ተመሳሳይ ሲሆን የquery order ማከማቻው ይደረሳል።
fn discovery11_fixture_bowls() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

fn test_discovery11_twelve_stirs_overwrite_original_identity_order() {
	original := [1, 2, 3, 4, 5, 6]
	result := calendar_post_stir12_spaghetti(discovery11_fixture_bowls(), original) or {
		LegacyPostStir12Result{}
	}
	assert result.final_stir_number == 12
	assert result.overwrite_count == 12
	assert result.order_for_query == [3, 5, 1, 4, 6, 2]
	assert original == [1, 2, 3, 4, 5, 6]
	assert result.final_saved_sum.str() == '152983071395321360281688056688813299996'
	assert result.bowls.len == 7
	assert result.bowls[0].str() == '0'
	assert result.bowls[1].str() == '136215324145469545419479201619538607493'
	assert result.bowls[6].str() == '121878577507874381427169074335666166709'
}

fn test_discovery11_legacy_store_discards_incoming_order_instead_of_latching() {
	mut store := new_legacy_post_stir_order_store([6, 5, 4, 3, 2, 1])
	assert store.query_order == [6, 5, 4, 3, 2, 1]
	assert store.overwrite_count == 0
	store.old_overwrite_query_order([2, 3, 1, 4, 5, 6])
	assert store.query_order == [2, 3, 1, 4, 5, 6]
	assert store.overwrite_count == 1
	store.old_overwrite_query_order([3, 5, 1, 4, 6, 2])
	assert store.query_order == [3, 5, 1, 4, 6, 2]
	assert store.overwrite_count == 2
}

fn test_discovery11_different_incoming_orders_share_final_post_stir_order() {
	bowls := discovery11_fixture_bowls()
	original_orders := [
		[1, 2, 3, 4, 5, 6],
		[6, 5, 4, 3, 2, 1],
		[2, 3, 1, 4, 5, 6],
		[1, 3, 5, 2, 4, 6],
	]
	mut expected := []BigInt{}
	for idx, order in original_orders {
		out := calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
		assert out.order_for_query == [3, 5, 1, 4, 6, 2]
		assert out.overwrite_count == 12
		if idx == 0 {
			expected = out.bowls
		} else {
			assert out.bowls == expected
		}
	}
	assert bowls[1].str() == '10'
	assert bowls[6].str() == '60'
}

fn test_discovery11_legacy_dispatcher_and_public_entry_match() {
	order := [6, 5, 4, 3, 2, 1]
	bowls := discovery11_fixture_bowls()
	public_result := calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
	dispatcher := new_base_dispatcher()
	legacy_result := dispatcher.dispatch_legacy_post_stir12(bowls, order) or {
		LegacyPostStir12Result{}
	}
	assert public_result.order_for_query == legacy_result.order_for_query
	assert public_result.overwrite_count == legacy_result.overwrite_count
	assert public_result.bowls == legacy_result.bowls
	assert order == [6, 5, 4, 3, 2, 1]
}

fn test_discovery11_first_post_stir_sum_and_rank_are_grounded() {
	bowls := discovery11_fixture_bowls()
	mut sum := big_from_int(149)
	for bowl_id in 1 .. 7 {
		sum = big_add(sum, bowls[bowl_id])
	}
	saved := calendar_save_spaghetti(sum)
	assert saved.str() == '359'
	assert (calendar_bowl_order_spaghetti(saved) or { []int{} }) == [3, 6, 5, 4, 1, 2]
}

fn test_discovery11_all_720_inputs_are_valid_for_overwrite_store() {
	mut found := map[string]bool{}
	for rank0 in 0 .. 720 {
		original := old_permutation_unrank0(rank0) or { []int{} }
		mut store := new_legacy_post_stir_order_store(original)
		assert store.query_order == original
		store.old_overwrite_query_order([3, 6, 5, 4, 1, 2])
		assert store.query_order == [3, 6, 5, 4, 1, 2]
		assert store.overwrite_count == 1
		assert original.str() !in found
		found[original.str()] = true
	}
	assert found.len == 720
}

fn test_discovery11_post_stirs_large_bowls_and_no_input_mutation() {
	huge := big_pow_small(big_from_int(2), 412)
	bowls := [big_zero(), huge, big_neg(huge), big_from_int(7), huge, big_from_int(41),
		big_from_int(43)]
	original := [2, 3, 1, 4, 5, 6]
	first := calendar_post_stir12_spaghetti(bowls, original) or { LegacyPostStir12Result{} }
	second := calendar_post_stir12_spaghetti(bowls, original) or { LegacyPostStir12Result{} }
	assert first.bowls == second.bowls
	assert first.order_for_query == second.order_for_query
	assert first.overwrite_count == 12
	assert bowls[1].str() == huge.str()
	assert bowls[2].str() == big_neg(huge).str()
	assert original == [2, 3, 1, 4, 5, 6]
	for id in 1 .. 7 {
		assert !first.bowls[id].is_zero()
	}
}

fn test_discovery11_rejects_invalid_order_and_bowl_count() {
	bowls := discovery11_fixture_bowls()
	for bad_order in [[1, 2, 3], [1, 2, 3, 4, 5, 5], [1, 2, 3, 4, 5, 7]] {
		mut rejected := false
		_ = calendar_post_stir12_spaghetti(bowls, bad_order) or {
			rejected = true
			LegacyPostStir12Result{}
		}
		assert rejected
	}
	mut rejected := false
	_ = calendar_post_stir12_spaghetti([big_zero()], [1, 2, 3, 4, 5, 6]) or {
		rejected = true
		LegacyPostStir12Result{}
	}
	assert rejected
}

fn test_discovery11_previous_patches_and_monster_probe() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	assert (calendar_bowl_order_spaghetti(big_from_int(720)) or { []int{} }) == [6, 5, 4, 3, 2,
		1]
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('PATCH_10 shadowStirBowl2=')
	assert diagnostic.contains('DISCOVERY_11 originalOrder=')
	assert diagnostic.contains('DISCOVERY_11 wrongQueryOrder=')
	assert diagnostic.contains('DISCOVERY_11 overwriteCount=12')
}
