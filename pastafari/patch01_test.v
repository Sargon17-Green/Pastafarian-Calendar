module pastafari

fn patch01_spec_save(x BigInt) BigInt {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	return big_add(big_one(), big_regular_mod(big_sub(x, big_one()), m))
}

fn test_patch01_restores_positive_and_negative_multiples() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	for factor in -5 .. 6 {
		x := big_mul(m, big_from_int(factor))
		assert big_eq(calendar_save_spaghetti(x), m)
		assert old_remainder(x).is_zero()
	}
}

fn test_patch01_matches_spec_across_signed_and_large_integers() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	huge := big_pow_small(big_from_int(2), 384)
	values := [
		big_zero(),
		big_one(),
		big_neg(big_one()),
		m,
		big_neg(m),
		big_add(m, big_one()),
		big_sub(m, big_one()),
		big_add(huge, big_from_int(42)),
		big_neg(big_add(huge, big_from_int(42))),
	]
	for x in values {
		assert big_eq(calendar_save_spaghetti(x), patch01_spec_save(x))
	}
}

fn test_patch01_entrypoint_reaches_fixed_output() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	mut error_text := ''
	_ = calendar_date_spaghetti(m, m) or {
		error_text = err.msg()
		CalendarResult{}
	}
	assert error_text.contains('PATCH_01 SAVE=' + m.str())
}

fn test_patch01_entrypoint_control_m_plus_one() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	x := big_add(m, big_one())
	mut error_text := ''
	_ = calendar_date_spaghetti(x, x) or {
		error_text = err.msg()
		CalendarResult{}
	}
	assert error_text.contains('PATCH_01 SAVE=1')
}

fn test_patch01_is_idempotent_across_calls() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	for _ in 0 .. 10 {
		assert big_eq(calendar_save_spaghetti(m), m)
		assert old_remainder(m).is_zero()
	}
}
