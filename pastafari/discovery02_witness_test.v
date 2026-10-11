module pastafari

fn test_discovery02_old_tag_is_even_on_both_sides() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_day_tag_spaghetti(foundation).str() == '0'
	for offset in 1 .. 7 {
		delta := big_from_int(offset)
		expected := big_mul_small(delta, 2)
		assert big_eq(old_day_tag(big_add(foundation, delta)), expected)
		assert big_eq(old_day_tag(big_sub(foundation, delta)), expected)
	}
}

fn test_discovery02_old_tag_on_large_signed_days() {
	foundation := big_from_i64(-15_055_671)
	distance := big_pow_small(big_from_int(2), 300)
	expected := big_mul_small(distance, 2)
	assert big_eq(calendar_day_tag_spaghetti(big_add(foundation, distance)), expected)
	assert big_eq(calendar_day_tag_spaghetti(big_sub(foundation, distance)), expected)
}

fn test_discovery02_entrypoint_exposes_legacy_tag() {
	foundation := big_from_i64(-15_055_671)
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('DISCOVERY_02 oldDayTag=0')
	assert diagnostic.contains('PATCH_01 SAVE=')
}

fn test_discovery02_adapter_does_not_change_patch01() {
	foundation := big_from_i64(-15_055_671)
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert old_day_tag(foundation).str() == '0'
	assert big_eq(calendar_save_spaghetti(m), m)
	assert old_remainder(m).str() == '0'
}
