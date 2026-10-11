module pastafari

// የደረጃ 2 ታሪካዊ ማስረጃ፤ በPATCH 01 በኋላም ይቀራል።
fn test_discovery01_witness_multiples_are_zero() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	dispatcher := new_base_dispatcher()
	for multiplier in 1 .. 4 {
		x := big_mul_small(m, u32(multiplier))
		assert old_remainder(x).str() == '0'
		assert dispatcher.dispatch_legacy_save(x).str() == '0'
	}
}

fn test_discovery01_witness_m_plus_one_agrees() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	x := big_add(m, big_one())
	dispatcher := new_base_dispatcher()
	assert old_remainder(x).str() == '1'
	assert dispatcher.dispatch_legacy_save(big_one()).str() == '1'
}

fn test_discovery01_witness_negative_multiple() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert old_remainder(big_neg(m)).str() == '0'
}

fn test_discovery01_legacy_adapter_survives_patch01() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	dispatcher := new_base_dispatcher()
	assert dispatcher.dispatch_legacy_save(m).str() == '0'
	assert big_eq(dispatcher.dispatch_save_patch01(m), m)
}

fn test_discovery01_legacy_and_patched_routes_are_distinct() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert old_remainder(m).str() == '0'
	assert big_eq(calendar_save_spaghetti(m), m)
}
