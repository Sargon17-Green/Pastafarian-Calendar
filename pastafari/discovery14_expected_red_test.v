module pastafari

// ደረጃ 28፦ አራቱ normative RED assertions በPATCH 14 የሚጠገኑ ናቸው።
// ይህንን test በደረጃ 29 አንቀይረውም።
fn discovery14_reference_little_first(stream AnswerStream, n BigInt) BigInt {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	mut places := 1
	mut space := m
	for big_cmp(space, n) < 0 {
		places++
		space = big_mul(space, m)
	}
	mut x := big_one()
	mut weight := big_one()
	for j in 0 .. places {
		digit := big_sub(calendar_answer_at_spaghetti(stream, big_from_int(j)) or {
			panic(err.msg())
		}, big_one())
		x = big_add(x, big_mul(digit, weight))
		weight = big_mul(weight, m)
	}
	limit := big_mul(big_floor_div(space, n), n)
	step := if stream.step == 1 { big_one() } else { big_neg(big_one()) }
	for big_cmp(x, limit) > 0 {
		x = big_add(big_one(), big_regular_mod(big_add(big_sub(x, big_one()), step), space))
	}
	return big_add(big_one(), big_regular_mod(big_sub(x, big_one()), n))
}

fn test_discovery14_expected_red_two_digits_first_one_forward() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	s := AnswerStream{
		first: big_one()
		step:  1
	}
	n := big_add(m, big_one())
	expected := discovery14_reference_little_first(s, n)
	actual := calendar_choose_rank_spaghetti(s, n) or { big_zero() }
	assert big_eq(expected, n)
	assert big_eq(actual, expected)
}

fn test_discovery14_expected_red_two_digits_first_one_reverse() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	s := AnswerStream{
		first: big_one()
		step:  -1
	}
	n := big_mul(m, m)
	expected := discovery14_reference_little_first(s, n)
	actual := calendar_choose_rank_spaghetti(s, n) or { big_zero() }
	assert big_eq(expected, big_add(big_sub(n, m), big_one()))
	assert big_eq(actual, expected)
}

fn test_discovery14_expected_red_two_digits_seed_seventeen() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	s := AnswerStream{
		first: big_from_int(17)
		step:  1
	}
	n := big_mul(m, m)
	expected := discovery14_reference_little_first(s, n)
	actual := calendar_choose_rank_spaghetti(s, n) or { big_zero() }
	assert big_eq(expected, big_add(big_mul_small(m, 17), big_from_int(17)))
	assert big_eq(actual, expected)
}

fn test_discovery14_expected_red_three_digits_first_one_forward() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	s := AnswerStream{
		first: big_one()
		step:  1
	}
	n := big_add(big_mul(m, m), big_one())
	expected := discovery14_reference_little_first(s, n)
	actual := calendar_choose_rank_spaghetti(s, n) or { big_zero() }
	assert big_eq(expected, big_sub(m, big_one()))
	assert big_eq(actual, expected)
}
