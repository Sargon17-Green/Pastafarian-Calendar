module pastafari

// ደረጃ 20፦ የቀድሞ ሁኔታ ምትክ ተለውጦ የተጻፈ ማሰሮ የሚነበብበትን ስህተት ይመረምራል።
fn discovery10_fixture_bowls() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

fn discovery10_fixture_result(order []int) []BigInt {
	bowls := discovery10_fixture_bowls()
	drop := big_from_int(2)
	stones := initial_stones()
	pours := calendar_pours_spaghetti(1, drop, stones, bowls, order) or { []BigInt{} }
	return calendar_stir_bowls_spaghetti(1, drop, stones, bowls, order, pours) or {
		[]BigInt{}
	}
}

fn test_discovery10_identity_order_shows_sequential_contamination() {
	actual := discovery10_fixture_result([1, 2, 3, 4, 5, 6])
	assert actual.len == 7
	assert actual[0].str() == '0'
	assert actual[1].str() == '154997'
	assert actual[2].str() == '96572653728'
	assert actual[3].str() == '37305110389478062083907'
	assert actual[6].str() == '45533754091847225581732030291798637831'
}

fn test_discovery10_legacy_is_really_mutating_in_place() {
	orig := discovery10_fixture_bowls()
	mut working := discovery10_fixture_bowls()
	order := [1, 2, 3, 4, 5, 6]
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(), orig,
		order) or { []BigInt{} }
	old_stir_bowls_in_place(1, big_from_int(2), initial_stones(), mut working, order,
		pours) or {
		assert false
		return
	}
	assert working[1].str() == '154997'
	assert working[2].str() == '96572653728'
	assert orig[1].str() == '10'
	assert orig[2].str() == '20'
}

fn test_discovery10_legacy_wrapper_separates_caller_input() {
	bowls := discovery10_fixture_bowls()
	order := [1, 2, 3, 4, 5, 6]
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(), bowls,
		order) or { []BigInt{} }
	first := calendar_stir_bowls_spaghetti(1, big_from_int(2), initial_stones(), bowls,
		order, pours) or { []BigInt{} }
	second := new_base_dispatcher().dispatch_legacy_bowl_stir(1, big_from_int(2),
		initial_stones(), bowls, order, pours) or { []BigInt{} }
	assert first == second
	assert bowls[1].str() == '10'
	assert bowls[6].str() == '60'
	assert pours[1].str() == '177'
}

fn test_discovery10_reversed_and_rotated_legacy_bug_witnesses() {
	reversed := discovery10_fixture_result([6, 5, 4, 3, 2, 1])
	assert reversed[6].str() == '1630677'
	assert reversed[5].str() == '10647586499598'
	assert reversed[4].str() == '453484393148460699268154107'
	rotated := discovery10_fixture_result([2, 3, 1, 4, 5, 6])
	assert rotated[2].str() == '364217'
	assert rotated[3].str() == '532048406068'
}

fn test_discovery10_position_stone_selection_stays_correct() {
	stones := initial_stones()
	assert legacy_stir_stone_by_position(stones, 1).str() == '17'
	assert legacy_stir_stone_by_position(stones, 2).str() == '29'
	assert legacy_stir_stone_by_position(stones, 3).str() == '43'
	assert legacy_stir_stone_by_position(stones, 4).str() == '71'
	assert legacy_stir_stone_by_position(stones, 5).str() == '101'
	assert legacy_stir_stone_by_position(stones, 6).str() == '17'
}

fn test_discovery10_reject_invalid_inputs_before_mutation() {
	bowls := discovery10_fixture_bowls()
	mut working := discovery10_fixture_bowls()
	order := [1, 2, 3, 4, 5, 6]
	valid := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(), bowls,
		order) or { []BigInt{} }
	for invalid_i in [-1, 0, 47] {
		mut rejected := false
		old_stir_bowls_in_place(invalid_i, big_from_int(2), initial_stones(), mut working,
			order, valid) or { rejected = true }
		assert rejected
	}
	mut rejected := false
	old_stir_bowls_in_place(1, big_from_int(2), initial_stones(), mut working,
		[1, 2, 3, 4, 5, 5], valid) or { rejected = true }
	assert rejected
	rejected = false
	old_stir_bowls_in_place(1, big_from_int(2), initial_stones(), mut working, order,
		[big_zero()]) or { rejected = true }
	assert rejected
	assert working == bowls
}

fn test_discovery10_large_negative_inputs_stable() {
	huge := big_pow_small(big_from_int(2), 380)
	drop := big_neg(huge)
	bowls := [big_zero(), huge, big_neg(huge), big_one(), big_from_int(17),
		big_from_int(29), big_from_int(43)]
	stones := initial_stones()
	order := [6, 5, 4, 3, 2, 1]
	pours := calendar_pours_spaghetti(46, drop, stones, bowls, order) or { []BigInt{} }
	first := calendar_stir_bowls_spaghetti(46, drop, stones, bowls, order, pours) or {
		[]BigInt{}
	}
	second := calendar_stir_bowls_spaghetti(46, drop, stones, bowls, order, pours) or {
		[]BigInt{}
	}
	assert first == second
	assert bowls[1].str() == huge.str()
	assert bowls[2].str() == big_neg(huge).str()
	assert drop.str() == big_neg(huge).str()
	for id in 1 .. 7 {
		assert !first[id].is_zero()
	}
}

fn test_discovery10_all_720_orders_keep_legacy_sequential_path() {
	bowls := discovery10_fixture_bowls()
	stones := initial_stones()
	for rank0 in 0 .. 720 {
		order := old_permutation_unrank0(rank0) or { []int{} }
		pours := calendar_pours_spaghetti(2, big_from_int(17), stones, bowls, order) or {
			[]BigInt{}
		}
		result := calendar_stir_bowls_spaghetti(2, big_from_int(17), stones, bowls,
			order, pours) or { []BigInt{} }
		assert result.len == 7
		assert result[0].is_zero()
		for id in 1 .. 7 {
			assert !result[id].is_zero()
		}
	}
	assert bowls[1].str() == '10'
}

fn test_discovery10_previous_patches_and_monster_probe() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	assert (calendar_grind_row_spaghetti(11) or { []int{} }) == [37, 41, 43, 47, 1]
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('PATCH_09 bowlAlias1=6')
	assert diagnostic.contains('DISCOVERY_10 wrongStirBowl2=')
	assert diagnostic.contains('DISCOVERY_10 orderFirst=6')
}
