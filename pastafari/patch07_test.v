module pastafari

// ደረጃ 15፦ የታሪክ ሰንጠረዡንና አዲሱን 12-ረድፍ ሰንጠረዥ ለይቶ ይፈትሻል።
fn test_patch07_sentinel_row_zero_and_eleven_real_rows() {
	patch := GrindPatch07{}
	table := patch.table_with_sentinel()
	old := legacy_visible_grind_table()
	assert table.len == 12
	assert old.len == 11
	assert table[0] == [0, 0, 0, 0, 0]
	for grind in 1 .. 12 {
		assert table[grind] == old[grind - 1]
		actual := calendar_grind_row_spaghetti(grind) or { []int{} }
		assert actual == old[grind - 1]
	}
	assert table[1] == [3, 5, 7, 11, 1]
	assert table[11] == [37, 41, 43, 47, 1]
	assert old[0] == [3, 5, 7, 11, 1]
	assert old[10] == [37, 41, 43, 47, 1]
}

fn test_patch07_retains_broken_legacy_index_for_all_positions() {
	patch := GrindPatch07{}
	dispatcher := new_base_dispatcher()
	table := patch.table_with_sentinel()
	for index in 0 .. 11 {
		legacy := dispatcher.dispatch_legacy_grind(index) or { []int{} }
		assert legacy == table[index + 1]
	}
	assert (old_grind_row(1) or { []int{} }) == [5, 7, 11, 13, 2]
	assert (calendar_grind_row_spaghetti(1) or { []int{} }) == [3, 5, 7, 11, 1]
	mut old_eleven_rejected := false
	_ = old_grind_row(11) or {
		old_eleven_rejected = true
		[]int{}
	}
	assert old_eleven_rejected
	assert (calendar_grind_row_spaghetti(11) or { []int{} }) == [37, 41, 43, 47, 1]
}

fn test_patch07_native_grind_once_matches_independent_small_fixture() {
	x := big_from_int(2)
	p1 := big_from_int(3)
	p3 := big_from_int(5)
	p7 := big_from_int(7)
	stone := initial_stones()
	legacy := legacy_grind_once(1, x, p1, p3, p7, stone) or { big_zero() }
	patched := calendar_grind_once_spaghetti(1, x, p1, p3, p7, stone) or { big_zero() }
	assert legacy.str() == '210'
	assert patched.str() == '154'
	assert !big_eq(legacy, patched)
	mut direct := big_square(x)
	direct = big_add(direct, big_mul_small(x, 3))
	direct = big_add(direct, big_mul_small(p1, 5))
	direct = big_add(direct, big_mul_small(p3, 7))
	direct = big_add(direct, big_mul_small(p7, 11))
	direct = big_add(direct, stone.w)
	assert big_eq(patched, calendar_save_spaghetti(direct))
}

fn test_patch07_all_eleven_grinds_apply_the_right_coefficients() {
	mut x := big_from_int(13)
	p1 := big_from_int(101)
	p3 := big_from_int(103)
	p7 := big_from_int(107)
	stone := initial_stones()
	patch := GrindPatch07{}
	table := patch.table_with_sentinel()
	for grind in 1 .. 12 {
		row := table[grind]
		mut reference := big_square(x)
		reference = big_add(reference, big_mul_small(x, u32(row[0])))
		reference = big_add(reference, big_mul_small(p1, u32(row[1])))
		reference = big_add(reference, big_mul_small(p3, u32(row[2])))
		reference = big_add(reference, big_mul_small(p7, u32(row[3])))
		reference = big_add(reference, hidden_stone_component(stone, row[4]))
		reference = calendar_save_spaghetti(reference)
		actual := calendar_grind_once_spaghetti(grind, x, p1, p3, p7, stone) or {
			big_zero()
		}
		assert big_eq(actual, reference)
		x = actual
	}
}

fn test_patch07_large_numbers_signed_inputs_and_repeated_runs() {
	huge := big_pow_small(big_from_int(2), 390)
	x := big_neg(huge)
	p1 := huge
	p3 := big_neg(big_add(huge, big_one()))
	p7 := big_from_int(0)
	stone := Stones{
		w: huge
		b: big_neg(huge)
		s: big_one()
		m: big_zero()
		r: big_from_int(13)
	}
	for grind in [1, 2, 5, 10, 11] {
		row := calendar_grind_row_spaghetti(grind) or { []int{} }
		mut expected := big_square(x)
		expected = big_add(expected, big_mul_small(x, u32(row[0])))
		expected = big_add(expected, big_mul_small(p1, u32(row[1])))
		expected = big_add(expected, big_mul_small(p3, u32(row[2])))
		expected = big_add(expected, big_mul_small(p7, u32(row[3])))
		expected = big_add(expected, hidden_stone_component(stone, row[4]))
		expected = calendar_save_spaghetti(expected)
		first := calendar_grind_once_spaghetti(grind, x, p1, p3, p7, stone) or {
			big_zero()
		}
		second := calendar_grind_once_spaghetti(grind, x, p1, p3, p7, stone) or {
			big_zero()
		}
		assert big_eq(first, expected)
		assert big_eq(second, expected)
	}
	assert x.str() == big_neg(huge).str()
	assert p1.str() == huge.str()
	assert p7.str() == '0'
}

fn test_patch07_sentinel_cannot_be_selected_as_real_grind() {
	patch := GrindPatch07{}
	for invalid in [-7, -1, 0, 12, 13, 100] {
		mut rejected := false
		_ = patch.row(invalid) or {
			rejected = true
			[]int{}
		}
		assert rejected
		rejected = false
		_ = calendar_grind_row_spaghetti(invalid) or {
			rejected = true
			[]int{}
		}
		assert rejected
	}
	table := patch.table_with_sentinel()
	assert table[0] == [0, 0, 0, 0, 0]
}

fn test_patch07_history_and_all_previous_patches_still_accessible() {
	foundation := big_from_i64(-15_055_671)
	assert old_distance(foundation, foundation).str() == '0'
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert new_base_dispatcher().dispatch_legacy_stones(2, initial_stones()).b.str() == '1434'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
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
	assert diagnostic.contains('DISCOVERY_07 oldGrind1A=5')
	assert diagnostic.contains('DISCOVERY_07 oldGrind11=ERROR')
	assert diagnostic.contains('PATCH_07 grind1A=3')
	assert diagnostic.contains('PATCH_07 grind11A=37')
}
