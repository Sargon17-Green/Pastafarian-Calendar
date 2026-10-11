module pastafari

fn test_discovery01_witness_multiples_are_zero() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	for multiplier in 1 .. 4 {
		x := big_mul_small(m, u32(multiplier))
		assert old_remainder(x).str() == '0'
		assert calendar_save_spaghetti(x).str() == '0'
	}
}

fn test_discovery01_witness_m_plus_one_agrees() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	x := big_add(m, big_one())
	assert calendar_save_spaghetti(x).str() == '1'
	assert calendar_save_spaghetti(big_one()).str() == '1'
}

fn test_discovery01_witness_negative_multiple() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert calendar_save_spaghetti(big_neg(m)).str() == '0'
}

fn test_discovery01_calendar_entrypoint_reaches_legacy_adapter() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	mut error_text := ''
	_ = calendar_date_spaghetti(m, m) or {
		error_text = err.msg()
		CalendarResult{}
	}
	assert error_text.contains('DISCOVERY_01 oldRemainder=0')
}

fn test_discovery01_calendar_entrypoint_control_m_plus_one() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	x := big_add(m, big_one())
	mut error_text := ''
	_ = calendar_date_spaghetti(x, x) or {
		error_text = err.msg()
		CalendarResult{}
	}
	assert error_text.contains('DISCOVERY_01 oldRemainder=1')
}
