module pastafari

// ደረጃ 19፦ የቋሚ-ID legacy ጉድለት ሳይጠፋ የposition alias ይፈተሻል።
fn patch09_fixture_bowls() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

fn patch09_independent_expected(i int, drop BigInt, stones Stones, bowls []BigInt, order []int) []BigInt {
	mut pours := []BigInt{len: 7, init: big_zero()}
	for position in 1 .. 4 {
		kind_stone := match position {
			1 { stones.w }
			2 { stones.b }
			else { stones.s }
		}
		mut value := big_square(drop)
		value = big_add(value, big_mul(kind_stone, bowls[order[position - 1]]))
		value = big_add(value, big_from_int((2 * position + 1) * i))
		pours[position] = calendar_save_spaghetti(value)
	}
	return pours
}

fn test_patch09_alias_is_one_based_order_mapping() {
	patch := PourPatch09{}
	identity := patch.install_bowl_alias([1, 2, 3, 4, 5, 6]) or { []int{} }
	reversed := patch.install_bowl_alias([6, 5, 4, 3, 2, 1]) or { []int{} }
	assert identity == [0, 1, 2, 3, 4, 5, 6]
	assert reversed == [0, 6, 5, 4, 3, 2, 1]
	assert (patch.install_bowl_alias([2, 3, 1, 4, 5, 6]) or { []int{} }) == [0,
		2, 3, 1, 4, 5, 6]
	bowls := patch09_fixture_bowls()
	for position in 1 .. 7 {
		value := patch.bowl_by_legacy_position(bowls, reversed, position) or { big_zero() }
		assert big_eq(value, bowls[reversed[position]])
	}
	assert bowls[1].str() == '10'
	assert bowls[6].str() == '60'
}

fn test_patch09_reversed_fixture_all_three_positions_and_history() {
	bowls := patch09_fixture_bowls()
	order := [6, 5, 4, 3, 2, 1]
	legacy := new_base_dispatcher().dispatch_legacy_pours(1, big_from_int(2),
		initial_stones(), bowls, order) or { []BigInt{} }
	patched := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(), bowls,
		order) or { []BigInt{} }
	assert legacy[1].str() == '177'
	assert legacy[2].str() == '589'
	assert legacy[3].str() == '1301'
	assert patched[1].str() == '1027'
	assert patched[2].str() == '1459'
	assert patched[3].str() == '1731'
	for position in 4 .. 7 {
		assert patched[position].str() == '0'
	}
	assert patched[0].str() == '0'
	assert patched == patch09_independent_expected(1, big_from_int(2), initial_stones(),
		bowls, order)
}

fn test_patch09_rotated_order_and_identity_compatibility() {
	bowls := patch09_fixture_bowls()
	stones := initial_stones()
	identity := [1, 2, 3, 4, 5, 6]
	rotated := [2, 3, 1, 4, 5, 6]
	identity_actual := calendar_pours_spaghetti(1, big_from_int(2), stones, bowls,
		identity) or { []BigInt{} }
	identity_old := old_pours_fixed_bowls(1, big_from_int(2), stones, bowls, identity) or {
		[]BigInt{}
	}
	assert identity_actual == identity_old
	rotated_actual := calendar_pours_spaghetti(1, big_from_int(2), stones, bowls,
		rotated) or { []BigInt{} }
	assert rotated_actual[1].str() == '347'
	assert rotated_actual[2].str() == '879'
	assert rotated_actual[3].str() == '441'
	assert rotated_actual == patch09_independent_expected(1, big_from_int(2), stones, bowls,
		rotated)
}

fn test_patch09_all_720_orders_exactly_match_independent_pours() {
	bowls := patch09_fixture_bowls()
	stones := initial_stones()
	for rank0 in 0 .. 720 {
		order := old_permutation_unrank0(rank0) or { []int{} }
		actual := calendar_pours_spaghetti(7, big_from_int(13), stones, bowls, order) or {
			[]BigInt{}
		}
		expected := patch09_independent_expected(7, big_from_int(13), stones, bowls,
			order)
		assert actual.len == 7
		for position in 0 .. 7 {
			assert big_eq(actual[position], expected[position])
		}
	}
}

fn test_patch09_arbitrary_precision_signed_values_and_no_input_mutation() {
	huge := big_pow_small(big_from_int(2), 390)
	bowls := [big_zero(), huge, big_neg(huge), big_one(), big_from_int(400),
		big_from_int(500), big_from_int(600)]
	stones := Stones{
		w: big_neg(huge)
		b: huge
		s: big_from_int(-77)
		m: big_zero()
		r: big_from_int(101)
	}
	drop := big_add(big_neg(huge), big_from_int(42))
	order := [6, 5, 4, 3, 2, 1]
	first := calendar_pours_spaghetti(46, drop, stones, bowls, order) or { []BigInt{} }
	second := calendar_pours_spaghetti(46, drop, stones, bowls, order) or { []BigInt{} }
	expected := patch09_independent_expected(46, drop, stones, bowls, order)
	for position in 0 .. 7 {
		assert big_eq(first[position], expected[position])
		assert big_eq(second[position], first[position])
	}
	assert bowls[1].str() == huge.str()
	assert bowls[2].str() == big_neg(huge).str()
	assert stones.w.str() == big_neg(huge).str()
	assert drop.str() == big_add(big_neg(huge), big_from_int(42)).str()
	assert order == [6, 5, 4, 3, 2, 1]
}

fn test_patch09_alias_and_pour_validation_fail_closed() {
	patch := PourPatch09{}
	bowls := patch09_fixture_bowls()
	for order in [[1, 2, 3], [1, 2, 3, 4, 5, 5], [1, 2, 3, 4, 5, 7]] {
		mut rejected := false
		_ = patch.install_bowl_alias(order) or {
			rejected = true
			[]int{}
		}
		assert rejected
		rejected = false
		_ = calendar_pours_spaghetti(1, big_one(), initial_stones(), bowls, order) or {
			rejected = true
			[]BigInt{}
		}
		assert rejected
	}
	alias := patch.install_bowl_alias([1, 2, 3, 4, 5, 6]) or { []int{} }
	for position in [-1, 0, 7, 8] {
		mut rejected := false
		_ = patch.bowl_by_legacy_position(bowls, alias, position) or {
			rejected = true
			big_zero()
		}
		assert rejected
	}
	for invalid_i in [-4, 0, 47] {
		mut rejected := false
		_ = calendar_pours_spaghetti(invalid_i, big_one(), initial_stones(), bowls,
			[1, 2, 3, 4, 5, 6]) or {
			rejected = true
			[]BigInt{}
		}
		assert rejected
	}
}

fn test_patch09_permutation_dispatch_and_reentrancy_are_stable() {
	first := big_from_int(720)
	second := big_from_int(2)
	bowls := patch09_fixture_bowls()
	stone := initial_stones()
	reverse_order := calendar_bowl_order_spaghetti(first) or { []int{} }
	almost_identity := calendar_bowl_order_spaghetti(second) or { []int{} }
	assert reverse_order == [6, 5, 4, 3, 2, 1]
	assert almost_identity == [1, 2, 3, 4, 6, 5]
	expected_reverse := patch09_independent_expected(1, first, stone, bowls, reverse_order)
	expected_second := patch09_independent_expected(2, second, stone, bowls, almost_identity)
	for repeat in 0 .. 15 {
		a := calendar_pours_spaghetti(1, first, stone, bowls, reverse_order) or { []BigInt{} }
		b := calendar_pours_spaghetti(2, second, stone, bowls, almost_identity) or {
			[]BigInt{}
		}
		assert a == expected_reverse
		assert b == expected_second
		assert (PourPatch09{}.install_bowl_alias(reverse_order) or { []int{} }) == [0,
			6, 5, 4, 3, 2, 1]
	}
}

fn test_patch09_monster_probe_preserves_legacy_and_new_branch() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	assert (calendar_grind_row_spaghetti(11) or { []int{} }) == [37, 41, 43, 47, 1]
	assert (calendar_bowl_order_spaghetti(big_from_int(720)) or { []int{} }) == [6,
		5, 4, 3, 2, 1]
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('DISCOVERY_09 oldPour1=')
	assert diagnostic.contains('DISCOVERY_09 firstOrderedBowl=6')
	assert diagnostic.contains('PATCH_09 bowlAlias1=6')
	assert diagnostic.contains('PATCH_09 pour1=')
	assert diagnostic.contains('PATCH_08 permRank0=0')
}
