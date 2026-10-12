module pastafari

fn test_discovery07_eleven_legacy_rows_exactly_preserved() {
	table := legacy_visible_grind_table()
	assert table.len == 11
	assert table[0] == [3, 5, 7, 11, 1]
	assert table[1] == [5, 7, 11, 13, 2]
	assert table[2] == [7, 11, 13, 17, 3]
	assert table[3] == [11, 13, 17, 19, 4]
	assert table[4] == [13, 17, 19, 23, 5]
	assert table[5] == [17, 19, 23, 29, 1]
	assert table[6] == [19, 23, 29, 31, 2]
	assert table[7] == [23, 29, 31, 37, 3]
	assert table[8] == [29, 31, 37, 41, 4]
	assert table[9] == [31, 37, 41, 43, 5]
	assert table[10] == [37, 41, 43, 47, 1]
}

fn test_discovery07_wrong_direct_index_skips_first_row() {
	dispatcher := new_base_dispatcher()
	table := legacy_visible_grind_table()
	for grind in 1 .. 11 {
		row := dispatcher.dispatch_legacy_grind(grind) or { []int{} }
		assert row == table[grind]
	}
	assert (old_grind_row(0) or { []int{} }) == [3, 5, 7, 11, 1]
	assert (old_grind_row(1) or { []int{} }) == [5, 7, 11, 13, 2]
	assert (old_grind_row(10) or { []int{} }) == [37, 41, 43, 47, 1]
}

fn test_discovery07_eleventh_grind_reports_out_of_bounds() {
	mut rejected := false
	_ = old_grind_row(11) or {
		rejected = true
		[]int{}
	}
	assert rejected
	rejected = false
	_ = new_base_dispatcher().dispatch_legacy_grind(11) or {
		rejected = true
		[]int{}
	}
	assert rejected
}

fn test_discovery07_bad_row_changes_single_grind_arithmetic() {
	x := big_from_int(2)
	p1 := big_from_int(3)
	p3 := big_from_int(5)
	p7 := big_from_int(7)
	stone := initial_stones()
	legacy := legacy_grind_once(1, x, p1, p3, p7, stone) or { big_zero() }
	assert legacy.str() == '210'
	mut normative := big_square(x)
	normative = big_add(normative, big_mul_small(x, 3))
	normative = big_add(normative, big_mul_small(p1, 5))
	normative = big_add(normative, big_mul_small(p3, 7))
	normative = big_add(normative, big_mul_small(p7, 11))
	normative = big_add(normative, stone.w)
	normative = calendar_save_spaghetti(normative)
	assert normative.str() == '154'
	assert !big_eq(legacy, normative)
}

fn test_discovery07_prior_patches_survive_new_grind_adapter() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert hidden.len == 7
	assert calendar_hidden_by_nearness(hidden, 1).str() == '119390830530032782664128530203002080344'
	visible := new_legacy_visible_drop_store()
	got := calendar_prior_spaghetti(visible, hidden, 1, 1) or { big_zero() }
	assert big_eq(got, calendar_hidden_by_nearness(hidden, 1))
}

fn test_discovery07_monster_diagnostic_keeps_old_index_error() {
	foundation := big_from_i64(-15_055_671)
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('PATCH_06 priorSlot0=')
	assert diagnostic.contains('DISCOVERY_07 oldGrind1A=5')
	assert diagnostic.contains('DISCOVERY_07 oldGrind11=ERROR')
}
