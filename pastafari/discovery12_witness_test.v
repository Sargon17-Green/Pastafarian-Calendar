module pastafari

// ደረጃ 24፦ የቋሚ ID የታሪክ ስህተት ሳይደበቅ ተግባራዊ ሆኖ ይፈተሻል።
fn discovery12_bowls_fixture() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

fn test_discovery12_historical_fixed_id_cycle() {
	for id in 1 .. 7 {
		actual := old_next_bowl_fixed_name(id) or { 0 }
		assert actual == (id % 6) + 1
	}
	assert (old_next_bowl_fixed_name(6) or { 0 }) == 1
}

fn test_discovery12_reversed_order_is_ignored_by_legacy_query() {
	order := [6, 5, 4, 3, 2, 1]
	assert (calendar_next_bowl_spaghetti(6, order) or { 0 }) == 1
	assert (calendar_next_bowl_spaghetti(1, order) or { 0 }) == 2
	assert order == [6, 5, 4, 3, 2, 1]
}

fn test_discovery12_rotated_and_shuffled_order_ignored() {
	rotated := [2, 3, 1, 4, 5, 6]
	shuffled := [1, 3, 5, 2, 4, 6]
	assert (calendar_next_bowl_spaghetti(3, rotated) or { 0 }) == 4
	assert (calendar_next_bowl_spaghetti(1, shuffled) or { 0 }) == 2
	assert (calendar_next_bowl_spaghetti(6, shuffled) or { 0 }) == 1
	assert rotated == [2, 3, 1, 4, 5, 6]
}

fn test_discovery12_all_720_permutations_take_same_fixed_name_route() {
	mut count := 0
	for rank0 in 0 .. 720 {
		order := old_permutation_unrank0(rank0) or { []int{} }
		for id in 1 .. 7 {
			got := calendar_next_bowl_spaghetti(id, order) or { 0 }
			assert got == (id % 6) + 1
			count++
		}
	}
	assert count == 4320
}

fn test_discovery12_live_post_stirs_keep_latch_but_query_ignores_it() {
	bowls := discovery12_bowls_fixture()
	order := [6, 5, 4, 3, 2, 1]
	after := calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
	assert after.order_for_query == order
	assert after.overwrite_count == 12
	assert (calendar_post_stir_next_bowl_spaghetti(bowls, order, 6) or { 0 }) == 1
	assert (calendar_post_stir_next_bowl_spaghetti(bowls, order, 1) or { 0 }) == 2
	assert bowls[6].str() == '60'
}

fn test_discovery12_legacy_adapter_and_public_dispatch_agree() {
	order := [1, 3, 5, 2, 4, 6]
	adapter := LegacyNextBowlAdapter{}
	dispatcher := new_base_dispatcher()
	for id in 1 .. 7 {
		direct := adapter.next(id, order) or { 0 }
		from_dispatch := dispatcher.dispatch_legacy_next_bowl(id, order) or { 0 }
		public := calendar_next_bowl_spaghetti(id, order) or { 0 }
		assert direct == public
		assert from_dispatch == public
	}
}

fn test_discovery12_invalid_queried_id_and_invalid_permutation_rejected() {
	good := [1, 2, 3, 4, 5, 6]
	for id in [-2, 0, 7, 15] {
		mut rejected := false
		_ = old_next_bowl_fixed_name(id) or {
			rejected = true
			0
		}
		assert rejected
		rejected = false
		_ = calendar_next_bowl_spaghetti(id, good) or {
			rejected = true
			0
		}
		assert rejected
	}
	for bad_order in [[1, 2, 3], [1, 2, 3, 4, 5, 5], [1, 2, 3, 4, 5, 7]] {
		mut rejected := false
		_ = calendar_next_bowl_spaghetti(1, bad_order) or {
			rejected = true
			0
		}
		assert rejected
	}
}

fn test_discovery12_repeated_queries_do_not_change_inputs() {
	bowls := discovery12_bowls_fixture()
	order := [2, 3, 1, 4, 5, 6]
	for round in 0 .. 15 {
		assert (calendar_post_stir_next_bowl_spaghetti(bowls, order, 3) or { 0 }) == 4
		assert (calendar_next_bowl_spaghetti(6, order) or { 0 }) == 1
	}
	assert bowls[1].str() == '10'
	assert bowls[6].str() == '60'
	assert order == [2, 3, 1, 4, 5, 6]
}

fn test_discovery12_monster_path_and_prior_patches_are_still_wired() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	mut message := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		message = err.msg()
		CalendarResult{}
	}
	assert message.contains('PATCH_11 latchedOrder=')
	assert message.contains('DISCOVERY_12 wrongNextBowl=')
	assert message.contains('DISCOVERY_12 queriedId=6')
}
