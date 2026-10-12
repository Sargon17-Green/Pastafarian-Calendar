module pastafari

// ደረጃ 21፦ ከአንድ የቀድሞ ሁኔታ ስድስቱን ቦታዎች ራሱን የቻለ ማረጋገጫ።
fn patch10_fixture_bowls() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

fn patch10_independent_snapshot(i int, drop BigInt, stones Stones, bowls []BigInt, order []int, pours []BigInt) []BigInt {
	mut result := []BigInt{len: 7, init: big_zero()}
	for id in 0 .. 7 {
		result[id] = big_add(bowls[id], big_zero())
	}
	for position in 1 .. 7 {
		id := order[position - 1]
		prev_id := order[(position + 4) % 6]
		next_id := order[position % 6]
		stone := match position {
			1, 6 { stones.w }
			2 { stones.b }
			3 { stones.s }
			4 { stones.m }
			else { stones.r }
		}

		mut s := big_add(bowls[id], big_mul_small(bowls[prev_id], 2))
		s = big_add(s, big_mul_small(bowls[next_id], 3))
		s = big_add(s, pours[position])
		s = big_add(s, drop)
		s = big_add(s, stone)
		cross := big_mul_small(big_mul(bowls[prev_id], bowls[next_id]), 5)
		result[id] = calendar_save_spaghetti(big_add(big_add(big_square(s), cross),
			big_from_int(i * position)))
	}
	return result
}

fn test_patch10_identity_and_reversed_snapshots_are_correct() {
	bowls := patch10_fixture_bowls()
	stones := initial_stones()
	drop := big_from_int(2)
	for order in [[1, 2, 3, 4, 5, 6], [6, 5, 4, 3, 2, 1], [2, 3, 1, 4, 5, 6]] {
		pours := calendar_pours_spaghetti(1, drop, stones, bowls, order) or { []BigInt{} }
		actual := calendar_stir_bowls_spaghetti(1, drop, stones, bowls, order, pours) or {
			[]BigInt{}
		}
		expected := patch10_independent_snapshot(1, drop, stones, bowls, order, pours)
		assert actual == expected
	}
	pours := calendar_pours_spaghetti(1, drop, stones, bowls, [1, 2, 3, 4, 5, 6]) or { []BigInt{} }
	actual := calendar_stir_bowls_spaghetti(1, drop, stones, bowls, [1, 2, 3, 4, 5, 6], pours) or {
		[]BigInt{}
	}
	assert actual[1].str() == '154997'
	assert actual[2].str() == '564002'
	assert actual[6].str() == '46187'
}

fn test_patch10_original_legacy_still_produces_wrong_history() {
	bowls := patch10_fixture_bowls()
	order := [1, 2, 3, 4, 5, 6]
	stones := initial_stones()
	drop := big_from_int(2)
	pours := calendar_pours_spaghetti(1, drop, stones, bowls, order) or { []BigInt{} }
	legacy := new_base_dispatcher().dispatch_legacy_bowl_stir(1, drop, stones, bowls, order, pours) or {
		[]BigInt{}
	}
	correct := calendar_stir_bowls_spaghetti(1, drop, stones, bowls, order, pours) or { []BigInt{} }
	assert legacy[1].str() == '154997'
	assert legacy[2].str() == '96572653728'
	assert legacy[6].str() == '45533754091847225581732030291798637831'
	assert correct[2].str() == '564002'
	assert correct[6].str() == '46187'
	assert legacy != correct
}

fn test_patch10_all_720_orders_use_snapshot_for_each_bowl() {
	bowls := patch10_fixture_bowls()
	stones := initial_stones()
	drop := big_from_int(13)
	for rank0 in 0 .. 720 {
		order := old_permutation_unrank0(rank0) or { []int{} }
		pours := calendar_pours_spaghetti(7, drop, stones, bowls, order) or { []BigInt{} }
		actual := calendar_stir_bowls_spaghetti(7, drop, stones, bowls, order, pours) or {
			[]BigInt{}
		}
		expected := patch10_independent_snapshot(7, drop, stones, bowls, order, pours)
		assert actual.len == 7
		for id in 0 .. 7 {
			assert big_eq(actual[id], expected[id])
		}
	}
	assert bowls[1].str() == '10'
	assert bowls[6].str() == '60'
}

fn test_patch10_vault_and_pending_are_not_shared_with_caller() {
	patch := BowlStirPatch10{}
	bowls := patch10_fixture_bowls()
	clone := patch.clone_bowls(bowls)
	assert clone == bowls
	order := [6, 5, 4, 3, 2, 1]
	stones := initial_stones()
	drop := big_from_int(2)
	pours := calendar_pours_spaghetti(1, drop, stones, bowls, order) or { []BigInt{} }
	a := patch.stir(1, drop, stones, bowls, order, pours) or { []BigInt{} }
	b := patch.stir(1, drop, stones, bowls, order, pours) or { []BigInt{} }
	assert a == b
	assert bowls == patch10_fixture_bowls()
	assert clone == patch10_fixture_bowls()
	assert pours[1].str() == '1027'
	assert a[0].is_zero()
}

fn test_patch10_huge_negative_inputs_remain_exact_and_repeatable() {
	huge := big_pow_small(big_from_int(2), 420)
	drop := big_neg(huge)
	bowls := [big_zero(), huge, big_neg(huge), big_one(), big_from_int(41),
		big_from_int(43), big_from_int(47)]
	stones := initial_stones()
	order := [2, 3, 1, 4, 5, 6]
	pours := calendar_pours_spaghetti(46, drop, stones, bowls, order) or { []BigInt{} }
	expected := patch10_independent_snapshot(46, drop, stones, bowls, order, pours)
	first := calendar_stir_bowls_spaghetti(46, drop, stones, bowls, order, pours) or { []BigInt{} }
	second := calendar_stir_bowls_spaghetti(46, drop, stones, bowls, order, pours) or { []BigInt{} }
	assert first == expected
	assert second == expected
	assert bowls[1].str() == huge.str()
	assert bowls[2].str() == big_neg(huge).str()
	assert drop.str() == big_neg(huge).str()
}

fn test_patch10_fail_closed_before_commit_on_invalid_inputs() {
	bowls := patch10_fixture_bowls()
	drop := big_from_int(2)
	stones := initial_stones()
	order := [1, 2, 3, 4, 5, 6]
	pours := calendar_pours_spaghetti(1, drop, stones, bowls, order) or { []BigInt{} }
	for invalid_i in [-1, 0, 47] {
		mut rejected := false
		_ = calendar_stir_bowls_spaghetti(invalid_i, drop, stones, bowls, order, pours) or {
			rejected = true
			[]BigInt{}
		}
		assert rejected
	}
	for invalid_order in [[1, 2, 3], [1, 2, 3, 4, 5, 5], [1, 2, 3, 4, 5, 7]] {
		mut rejected := false
		_ = calendar_stir_bowls_spaghetti(1, drop, stones, bowls, invalid_order, pours) or {
			rejected = true
			[]BigInt{}
		}
		assert rejected
	}
	assert bowls == patch10_fixture_bowls()
}

fn test_patch10_monster_diagnostic_contains_wrong_and_correct() {
	foundation := big_from_i64(-15_055_671)
	mut msg := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		msg = err.msg()
		CalendarResult{}
	}
	assert msg.contains('PATCH_09 bowlAlias1=6')
	assert msg.contains('DISCOVERY_10 wrongStirBowl2=')
	assert msg.contains('DISCOVERY_10 orderFirst=6')
	assert msg.contains('PATCH_10 shadowStirBowl2=')
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
}
