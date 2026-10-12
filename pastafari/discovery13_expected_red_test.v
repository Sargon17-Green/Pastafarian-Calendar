module pastafari

// ደረጃ 26፦ አራት ሆን ተብለው EXPECTED_RED normative ምስክሮች።
fn discovery13_reference_short(first BigInt, step int, n BigInt) BigInt {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	limit := big_mul(big_floor_div(m, n), n)
	mut k := big_zero()
	for iteration in 0 .. 8 {
		offset := if step > 0 { k } else { big_neg(k) }
		x := big_add(big_one(), big_regular_mod(big_add(big_sub(first, big_one()),
			offset), m))
		if big_cmp(x, limit) <= 0 {
			return big_add(big_one(), big_regular_mod(big_sub(x, big_one()), n))
		}
		k = big_add(k, big_one())
	}
	return big_zero()
}

fn test_discovery13_expected_red_forward_m_skips_one() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	n := big_add(big_floor_div(m, big_from_int(2)), big_one())
	expected := discovery13_reference_short(m, 1, n)
	actual := calendar_choose_rank_short_spaghetti(AnswerStream{first: m, step: 1}, n) or {
		big_zero()
	}
	assert expected.str() == '1'
	assert big_eq(actual, expected)
}

fn test_discovery13_expected_red_forward_m_minus_one_skips_two() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	n := big_add(big_floor_div(m, big_from_int(2)), big_one())
	first := big_sub(m, big_one())
	expected := discovery13_reference_short(first, 1, n)
	actual := calendar_choose_rank_short_spaghetti(AnswerStream{first: first, step: 1},
		n) or { big_zero() }
	assert expected.str() == '1'
	assert big_eq(actual, expected)
}

fn test_discovery13_expected_red_reverse_m_skips_three() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	n := big_sub(m, big_from_int(3))
	expected := discovery13_reference_short(m, -1, n)
	actual := calendar_choose_rank_short_spaghetti(AnswerStream{first: m, step: -1}, n) or {
		big_zero()
	}
	assert big_eq(expected, n)
	assert big_eq(actual, expected)
}

fn test_discovery13_expected_red_forward_m_boundary() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	n := big_sub(m, big_from_int(3))
	expected := discovery13_reference_short(m, 1, n)
	actual := calendar_choose_rank_short_spaghetti(AnswerStream{first: m, step: 1}, n) or {
		big_zero()
	}
	assert expected.str() == '1'
	assert big_eq(actual, expected)
}
