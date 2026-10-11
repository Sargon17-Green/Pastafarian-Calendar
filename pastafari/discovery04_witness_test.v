module pastafari

fn test_discovery04_exact_sequential_stone_values_at_two() {
	initial := initial_stones()
	got := calendar_stones_spaghetti(2, initial)
	assert got.w.str() == '378'
	assert got.b.str() == '1434'
	assert got.s.str() == '3780'
	assert got.m.str() == '9932'
	assert got.r.str() == '25047'
	assert initial.w.str() == '17'
	assert initial.b.str() == '29'
	assert initial.s.str() == '43'
	assert initial.m.str() == '71'
	assert initial.r.str() == '101'
}

fn test_discovery04_legacy_reads_new_wheat_in_barley() {
	initial := initial_stones()
	got := calendar_stones_spaghetti(2, initial)
	legacy_barley := calendar_save_spaghetti(big_add(big_add(big_square(initial.b),
		big_mul_small(initial.s, 5)), got.w))
	assert big_eq(got.b, legacy_barley)
	assert got.b.str() == '1434'
}

fn test_discovery04_legacy_cascades_new_values_to_last_stone() {
	initial := initial_stones()
	got := calendar_stones_spaghetti(2, initial)
	salt := calendar_save_spaghetti(big_add(big_add(big_square(initial.s),
		big_mul_small(initial.m, 7)), got.b))
	bitter := calendar_save_spaghetti(big_add(big_add(big_square(initial.m),
		big_mul_small(initial.r, 11)), got.s))
	red := calendar_save_spaghetti(big_add(big_add(big_square(initial.r), big_mul_small(got.w, 13)),
		got.m))
	assert big_eq(got.s, salt)
	assert big_eq(got.m, bitter)
	assert big_eq(got.r, red)
}

fn test_discovery04_legacy_builds_full_table_without_state_leaks() {
	table := get_legacy_stone_table()
	assert table.len == 46
	assert table[0].w.str() == '17'
	assert table[0].r.str() == '101'
	assert table[1].w.str() == '378'
	assert table[1].b.str() == '1434'
	assert table[1].r.str() == '25047'
	for i in 1 .. table.len {
		assert table[i].w.sign > 0
		assert table[i].b.sign > 0
		assert table[i].s.sign > 0
		assert table[i].m.sign > 0
		assert table[i].r.sign > 0
	}
	for i in 0 .. 5 {
		_ = i
		assert initial_stones().w.str() == '17'
	}
}

fn test_discovery04_previous_patches_and_entrypoint_are_unchanged() {
	initial := initial_stones()
	stone := calendar_stones_spaghetti(2, initial)
	assert stone.b.str() == '1434'
	foundation := big_from_i64(-15_055_671)
	modulus := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert old_day_tag(foundation).str() == '0'
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
	assert old_distance(foundation, foundation).str() == '0'
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert old_remainder(modulus).str() == '0'
	assert big_eq(calendar_save_spaghetti(modulus), modulus)
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('DISCOVERY_04 oldStoneB=1434')
	assert diagnostic.contains('PATCH_03 distance=1')
}
