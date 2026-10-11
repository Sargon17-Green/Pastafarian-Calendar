module pastafari

// ነጻ የሙከራ መመዘኛ፦ የመግቢያ እሴቶች ብቻ ይነበባሉ።
fn patch04_reference(i int, before Stones) Stones {
	w := big_add(big_add(big_square(before.w), big_mul_small(before.b, 3)), big_from_int(i))
	b := big_add(big_add(big_square(before.b), big_mul_small(before.s, 5)), before.w)
	s := big_add(big_add(big_square(before.s), big_mul_small(before.m, 7)), before.b)
	m := big_add(big_add(big_square(before.m), big_mul_small(before.r, 11)), before.s)
	r := big_add(big_add(big_square(before.r), big_mul_small(before.w, 13)), before.m)
	return Stones{
		w: calendar_save_spaghetti(w)
		b: calendar_save_spaghetti(b)
		s: calendar_save_spaghetti(s)
		m: calendar_save_spaghetti(m)
		r: calendar_save_spaghetti(r)
	}
}

fn patch04_stones_equal(a Stones, b Stones) bool {
	return big_eq(a.w, b.w) && big_eq(a.b, b.b) && big_eq(a.s, b.s)
		&& big_eq(a.m, b.m) && big_eq(a.r, b.r)
}

fn test_patch04_restores_five_snapshot_values_at_two() {
	input := initial_stones()
	got := calendar_stones_spaghetti(2, input)
	assert got.w.str() == '378'
	assert got.b.str() == '1073'
	assert got.s.str() == '2375'
	assert got.m.str() == '6195'
	assert got.r.str() == '10493'
	assert patch04_stones_equal(got, patch04_reference(2, input))
}

fn test_patch04_preserves_legacy_mutation_on_separate_copy() {
	input := initial_stones()
	dispatcher := new_base_dispatcher()
	legacy := dispatcher.dispatch_legacy_stones(2, input)
	patched := dispatcher.dispatch_stones_patch04(2, input)
	assert legacy.w.str() == '378'
	assert legacy.b.str() == '1434'
	assert legacy.s.str() == '3780'
	assert legacy.m.str() == '9932'
	assert legacy.r.str() == '25047'
	assert patched.b.str() == '1073'
	assert patched.s.str() == '2375'
	assert patched.m.str() == '6195'
	assert patched.r.str() == '10493'
	assert input.b.str() == '29'
	assert input.s.str() == '43'
}

fn test_patch04_independent_snapshot_arbitrary_precision() {
	huge := big_pow_small(big_from_int(2), 384)
	values := [
		initial_stones(),
		Stones{
			w: big_one()
			b: big_zero()
			s: big_from_int(3)
			m: big_from_int(5)
			r: big_from_int(7)
		},
		Stones{
			w: big_neg(huge)
			b: huge
			s: big_from_int(-12345)
			m: big_zero()
			r: big_one()
		},
		Stones{
			w: big_zero()
			b: big_zero()
			s: big_zero()
			m: big_zero()
			r: big_zero()
		},
	]
	for input in values {
		for index in [2, 3, 17, 46] {
			original := input.deep_clone()
			got := calendar_stones_spaghetti(index, input)
			reference := patch04_reference(index, original)
			assert patch04_stones_equal(got, reference)
			assert patch04_stones_equal(input, original)
			assert patch04_stones_equal(got, calendar_stones_spaghetti(index, input))
		}
	}
}

fn test_patch04_table_has_46_independent_snapshots() {
	table := get_stone_table_through_legacy_builder()
	assert table.len == 46
	assert patch04_stones_equal(table[0], initial_stones())
	assert patch04_stones_equal(table[1], patch04_reference(2, table[0]))
	for idx in 1 .. table.len {
		assert patch04_stones_equal(table[idx], patch04_reference(idx + 1, table[idx - 1]))
	}
	legacy_table := get_legacy_stone_table()
	assert legacy_table.len == 46
	assert legacy_table[1].b.str() == '1434'
	assert table[1].b.str() == '1073'
	assert legacy_table[1].s.str() == '3780'
	assert table[1].s.str() == '2375'
}

fn test_patch04_caller_values_do_not_change_across_calls() {
	mut input := initial_stones()
	saved := input.deep_clone()
	dispatcher := new_base_dispatcher()
	for _ in 0 .. 7 {
		_ = calendar_stones_spaghetti(2, input)
		_ = dispatcher.dispatch_legacy_stones(2, input)
		_ = dispatcher.dispatch_stones_patch04(2, input)
		assert patch04_stones_equal(input, saved)
	}
	_ = mutate_stones_wrong(2, mut input)
	assert input.b.str() == '1434'
	assert saved.b.str() == '29'
}

fn test_patch04_previous_patches_and_diagnostic_are_intact() {
	foundation := big_from_i64(-15_055_671)
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert old_day_tag(foundation).str() == '0'
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
	assert old_distance(foundation, foundation).str() == '0'
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert old_remainder(m).str() == '0'
	assert big_eq(calendar_save_spaghetti(m), m)
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('DISCOVERY_04 oldStoneB=1434')
	assert diagnostic.contains('PATCH_04 stoneB=1073')
	assert diagnostic.contains('PATCH_03 distance=1')
}
