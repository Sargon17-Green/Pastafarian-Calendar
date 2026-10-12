module pastafari

// ደረጃ 25፦ ለቀጣዩ ቦውል የ46ኛውን የላች ቅደም ተከተል ብቻ እንጠቀማለን።
fn patch12_fixture_bowls() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

// ይህ የፈተና ምስክር የPATCH 12 ውስጣዊ ኮድን አይጠራም።
fn patch12_independent_successor(queried_id int, order []int) int {
	for position, id in order {
		if id == queried_id {
			return order[(position + 1) % 6]
		}
	}
	return 0
}

fn test_patch12_reversed_and_shuffled_order_successors() {
	assert (calendar_next_bowl_spaghetti(6, [6, 5, 4, 3, 2, 1]) or { 0 }) == 5
	assert (calendar_next_bowl_spaghetti(1, [6, 5, 4, 3, 2, 1]) or { 0 }) == 6
	assert (calendar_next_bowl_spaghetti(3, [2, 3, 1, 4, 5, 6]) or { 0 }) == 1
	assert (calendar_next_bowl_spaghetti(1, [1, 3, 5, 2, 4, 6]) or { 0 }) == 3
	assert (calendar_next_bowl_spaghetti(6, [1, 2, 3, 4, 5, 6]) or { 0 }) == 1
	assert (calendar_next_bowl_spaghetti(2, [2, 3, 1, 4, 5, 6]) or { 0 }) == 3
}

fn test_patch12_legacy_scar_still_ignores_latch() {
	original := [6, 5, 4, 3, 2, 1]
	patch := NextBowlPatch12{}
	assert (old_next_bowl_fixed_name(6) or { 0 }) == 1
	assert (new_base_dispatcher().dispatch_legacy_next_bowl(6, original) or { 0 }) == 1
	assert (patch.next(6, original) or { 0 }) == 5
	assert (old_next_bowl_fixed_name(1) or { 0 }) == 2
	assert (new_base_dispatcher().dispatch_legacy_next_bowl(1, original) or { 0 }) == 2
	assert (patch.next(1, original) or { 0 }) == 6
	assert original == [6, 5, 4, 3, 2, 1]
}

fn test_patch12_all_720_orders_and_all_six_ids_match_independent_successor() {
	mut checked := 0
	mut legacy_disagreements := 0
	for rank0 in 0 .. 720 {
		order := old_permutation_unrank0(rank0) or { []int{} }
		assert order.len == 6
		for queried_id in 1 .. 7 {
			expected := patch12_independent_successor(queried_id, order)
			actual := calendar_next_bowl_spaghetti(queried_id, order) or { 0 }
			assert actual == expected
			legacy := new_base_dispatcher().dispatch_legacy_next_bowl(queried_id, order) or { 0 }
			assert legacy == (queried_id % 6) + 1
			if legacy != actual {
				legacy_disagreements++
			}
			checked++
		}
	}
	assert checked == 4320
	assert legacy_disagreements > 0
}

fn test_patch12_successor_wraps_at_last_position_not_at_bowl_id_six() {
	for order in [[1, 2, 3, 4, 5, 6], [6, 5, 4, 3, 2, 1], [2, 3, 1, 4, 5, 6],
		[1, 3, 5, 2, 4, 6]] {
		first_id := order[0]
		last_id := order[5]
		assert (calendar_next_bowl_spaghetti(last_id, order) or { 0 }) == first_id
		assert (calendar_next_bowl_spaghetti(first_id, order) or { 0 }) == order[1]
	}
}

fn test_patch12_post_stir_real_call_uses_original_drop46_latch() {
	bowls := patch12_fixture_bowls()
	for order in [[1, 2, 3, 4, 5, 6], [6, 5, 4, 3, 2, 1], [2, 3, 1, 4, 5, 6],
		[1, 3, 5, 2, 4, 6]] {
		post := calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
		assert post.order_for_query == order
		assert post.overwrite_count == 12
		for queried_id in [order[0], order[3], order[5]] {
			from_chain := calendar_post_stir_next_bowl_spaghetti(bowls, order, queried_id) or { 0 }
			expected := patch12_independent_successor(queried_id, order)
			assert from_chain == expected
		}
	}
	assert bowls[1].str() == '10'
}

fn test_patch12_dispatcher_and_patch_agree_with_public_api() {
	patch := NextBowlPatch12{}
	dispatcher := new_base_dispatcher()
	order := [1, 3, 5, 2, 4, 6]
	for id in 1 .. 7 {
		direct := patch.next(id, order) or { 0 }
		routed := dispatcher.dispatch_next_bowl_patch12(id, order) or { 0 }
		public_result := calendar_next_bowl_spaghetti(id, order) or { 0 }
		assert direct == routed
		assert routed == public_result
		assert public_result == patch12_independent_successor(id, order)
	}
}

fn test_patch12_rejects_invalid_ids_and_permutations_before_selection() {
	valid := [1, 2, 3, 4, 5, 6]
	for queried_id in [-15, -1, 0, 7, 8, 500] {
		mut failed := false
		_ = calendar_next_bowl_spaghetti(queried_id, valid) or {
			failed = true
			0
		}
		assert failed
	}
	for bad_order in [[1, 2, 3], [1, 2, 3, 4, 5, 5], [1, 2, 3, 4, 5, 7],
		[0, 2, 3, 4, 5, 6]] {
		mut failed := false
		_ = calendar_next_bowl_spaghetti(1, bad_order) or {
			failed = true
			0
		}
		assert failed
	}
	assert valid == [1, 2, 3, 4, 5, 6]
}

fn test_patch12_repeated_interleaved_queries_preserve_latches_and_caller_input() {
	first := [6, 5, 4, 3, 2, 1]
	second := [2, 3, 1, 4, 5, 6]
	third := [1, 3, 5, 2, 4, 6]
	for round in 0 .. 25 {
		assert (calendar_next_bowl_spaghetti(6, first) or { 0 }) == 5
		assert (calendar_next_bowl_spaghetti(3, second) or { 0 }) == 1
		assert (calendar_next_bowl_spaghetti(1, third) or { 0 }) == 3
	}
	assert first == [6, 5, 4, 3, 2, 1]
	assert second == [2, 3, 1, 4, 5, 6]
	assert third == [1, 3, 5, 2, 4, 6]
}

fn test_patch12_monster_probe_preserves_legacy_and_patch_diagnostics() {
	foundation := big_from_i64(-15_055_671)
	mut message := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		message = err.msg()
		CalendarResult{}
	}
	assert message.contains('DISCOVERY_12 queriedId=6')
	assert message.contains('DISCOVERY_12 wrongNextBowl=1')
	assert message.contains('PATCH_12 nextBowl=5')
	assert message.contains('PATCH_11 latchedOrder=')
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
}
