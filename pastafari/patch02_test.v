module pastafari

fn patch02_independent_day_count(day BigInt) BigInt {
	foundation := big_from_i64(-15_055_671)
	if big_cmp(day, foundation) < 0 {
		return big_mul_small(big_sub(foundation, day), 2)
	}
	return big_add(big_mul_small(big_sub(day, foundation), 2), big_one())
}

fn test_patch02_exact_foundation_and_neighbors() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_day_tag_spaghetti(big_sub(foundation, big_from_int(2))).str() == '4'
	assert calendar_day_tag_spaghetti(big_sub(foundation, big_one())).str() == '2'
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
	assert calendar_day_tag_spaghetti(big_add(foundation, big_one())).str() == '3'
	assert calendar_day_tag_spaghetti(big_add(foundation, big_from_int(2))).str() == '5'
	assert old_day_tag(foundation).str() == '0'
}

fn test_patch02_preserves_legacy_and_repairs_parity() {
	foundation := big_from_i64(-15_055_671)
	dispatcher := new_base_dispatcher()
	for offset in 0 .. 65 {
		delta := big_from_int(offset)
		before := big_sub(foundation, delta)
		after := big_add(foundation, delta)
		old_before := dispatcher.dispatch_legacy_day_tag(before)
		old_after := dispatcher.dispatch_legacy_day_tag(after)
		legacy_count := big_mul_small(delta, 2)
		assert big_eq(old_before, legacy_count)
		assert big_eq(old_after, legacy_count)
		assert big_eq(calendar_day_tag_spaghetti(before), if offset == 0 {
			big_one()
		} else {
			legacy_count
		})
		assert big_eq(calendar_day_tag_spaghetti(after), big_add(legacy_count, big_one()))
	}
}

fn test_patch02_arbitrary_precision_and_signed_coordinates() {
	foundation := big_from_i64(-15_055_671)
	huge := big_pow_small(big_from_int(2), 384)
	for delta in [big_one(), big_from_int(17), huge, big_add(huge, big_from_int(317))] {
		before := big_sub(foundation, delta)
		after := big_add(foundation, delta)
		assert big_eq(calendar_day_tag_spaghetti(before), patch02_independent_day_count(before))
		assert big_eq(calendar_day_tag_spaghetti(after), patch02_independent_day_count(after))
		assert big_eq(old_day_tag(after), big_sub(calendar_day_tag_spaghetti(after), big_one()))
		assert big_eq(old_day_tag(before), calendar_day_tag_spaghetti(before))
	}
}

fn test_patch02_foundation_guard_scar_is_retained() {
	patch := DayTagPatch02{}
	foundation := big_from_i64(-15_055_671)
	assert patch.apply(foundation, big_zero()).str() == '1'
	assert patch.apply(foundation, big_from_int(77)).str() == '1'
	assert patch.apply(big_add(foundation, big_one()), big_from_int(77)).str() == '78'
}

fn test_patch02_legacy_and_patched_dispatch_are_distinct() {
	dispatcher := new_base_dispatcher()
	foundation := big_from_i64(-15_055_671)
	assert dispatcher.dispatch_legacy_day_tag(foundation).str() == '0'
	assert dispatcher.dispatch_day_tag_patch02(foundation).str() == '1'
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
	assert dispatcher.dispatch_legacy_day_tag(big_add(foundation, big_one())).str() == '2'
	assert dispatcher.dispatch_day_tag_patch02(big_add(foundation, big_one())).str() == '3'
}

fn test_patch02_previous_save_patch_does_not_regress() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert old_remainder(m).str() == '0'
	assert big_eq(calendar_save_spaghetti(m), m)
	mut error_text := ''
	foundation := big_from_i64(-15_055_671)
	_ = calendar_date_spaghetti(foundation, foundation) or {
		error_text = err.msg()
		CalendarResult{}
	}
	assert error_text.contains('PATCH_01 SAVE=')
	assert error_text.contains('PATCH_02 dayTag=1')
}
