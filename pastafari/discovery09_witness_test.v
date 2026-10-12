module pastafari

fn discovery09_fixture_bowls() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

fn test_discovery09_initial_bowls_use_canonical_prime_squares() {
	counts := HiddenCounts{
		action:     big_zero()
		target:     big_zero()
		distance:   big_zero()
		connection: big_zero()
		direction:  0
	}
	bowls := calendar_initial_bowls_spaghetti(counts)
	assert bowls.len == 7
	assert bowls[0].str() == '0'
	assert bowls[1].str() == '83522'
	assert bowls[6].str() == '1874167'
	assert (calendar_initial_bowls_spaghetti(counts))[1].str() == bowls[1].str()
}

fn test_discovery09_legacy_fixed_ids_match_identity_order() {
	order := [1, 2, 3, 4, 5, 6]
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(),
		discovery09_fixture_bowls(), order) or { []BigInt{} }
	assert pours.len == 7
	assert pours[0].str() == '0'
	assert pours[1].str() == '177'
	assert pours[2].str() == '589'
	assert pours[3].str() == '1301'
	for position in 4 .. 7 {
		assert pours[position].str() == '0'
	}
}

fn test_discovery09_wrong_fixed_bowl_ids_ignore_reversed_order() {
	bowls := discovery09_fixture_bowls()
	identity := [1, 2, 3, 4, 5, 6]
	reversed := [6, 5, 4, 3, 2, 1]
	dispatcher := new_base_dispatcher()
	first := dispatcher.dispatch_legacy_pours(1, big_from_int(2), initial_stones(), bowls, identity) or {
		[]BigInt{}
	}
	second := dispatcher.dispatch_legacy_pours(1, big_from_int(2), initial_stones(), bowls, reversed) or {
		[]BigInt{}
	}
	assert first.len == 7
	assert second.len == 7
	for position in 0 .. 7 {
		assert big_eq(first[position], second[position])
	}
	assert second[1].str() == '177'
	assert second[2].str() == '589'
	assert second[3].str() == '1301'
}

fn test_discovery09_legacy_order_change_never_changes_pours() {
	bowls := discovery09_fixture_bowls()
	orders := [
		[1, 2, 3, 4, 5, 6],
		[2, 3, 1, 4, 5, 6],
		[6, 5, 4, 3, 2, 1],
		[3, 6, 2, 4, 1, 5],
	]
	for order in orders {
		pours := new_base_dispatcher().dispatch_legacy_pours(7, big_from_int(13), initial_stones(), bowls, order) or {
			[]BigInt{}
		}
		assert pours[1].str() == '360'
		assert pours[2].str() == '784'
		assert pours[3].str() == '1508'
	}
}

fn test_discovery09_bad_orders_and_missing_bowls_fail_without_crash() {
	bowls := discovery09_fixture_bowls()
	for order in [[1, 2, 3, 4, 5, 5], [1, 2, 3, 4, 5, 7], [1, 2, 3]] {
		mut rejected := false
		_ = calendar_pours_spaghetti(1, big_one(), initial_stones(), bowls, order) or {
			rejected = true
			[]BigInt{}
		}
		assert rejected
	}
	for invalid_i in [-1, 0, 47] {
		mut rejected := false
		_ = calendar_pours_spaghetti(invalid_i, big_one(), initial_stones(), bowls, [
			1,
			2,
			3,
			4,
			5,
			6,
		]) or {
			rejected = true
			[]BigInt{}
		}
		assert rejected
	}
}

fn test_discovery09_preserves_inputs_and_works_with_large_signed_numbers() {
	huge := big_pow_small(big_from_int(2), 375)
	bowls := [big_zero(), huge, big_neg(huge), big_one(), big_from_int(400),
		big_from_int(500), big_from_int(600)]
	drop := big_neg(huge)
	stones := initial_stones()
	order := [6, 5, 4, 3, 2, 1]
	pours := new_base_dispatcher().dispatch_legacy_pours(46, drop, stones, bowls, order) or { []BigInt{} }
	expected := calendar_save_spaghetti(big_add(big_add(big_square(drop), big_mul(stones.w,
		bowls[1])), big_from_int(138)))
	assert big_eq(pours[1], expected)
	assert bowls[1].str() == huge.str()
	assert bowls[2].str() == big_neg(huge).str()
	assert drop.str() == big_neg(huge).str()
	assert stones.w.str() == '17'
}

fn test_discovery09_actual_permutation_and_monster_probe() {
	foundation := big_from_i64(-15_055_671)
	order := calendar_bowl_order_spaghetti(big_from_int(720)) or { []int{} }
	assert order == [6, 5, 4, 3, 2, 1]
	bowls := calendar_initial_bowls_spaghetti(hidden_counts_spaghetti(foundation, foundation))
	pours := new_base_dispatcher().dispatch_legacy_pours(1, big_from_int(720), initial_stones(), bowls, order) or {
		[]BigInt{}
	}
	assert pours.len == 7
	assert pours[1].str() == calendar_save_spaghetti(big_add(big_add(big_square(big_from_int(720)), big_mul(initial_stones().w,
		bowls[1])), big_from_int(3))).str()
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('PATCH_08 permOrder=[1, 2, 3, 4, 5, 6]')
	assert diagnostic.contains('DISCOVERY_09 oldPour1=')
	assert diagnostic.contains('DISCOVERY_09 firstOrderedBowl=6')
	assert diagnostic.contains('PATCH_09 bowlAlias1=6')
	assert diagnostic.contains('PATCH_09 pour1=')
}
