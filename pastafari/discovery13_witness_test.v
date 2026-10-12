module pastafari

// ደረጃ 26፦ አዲሱ የመልስ ዙር GREEN መቆጣጠሪያዎች።
fn discovery13_m() BigInt {
	return big_sub(big_pow_small(big_from_int(2), 127), big_one())
}

fn discovery13_bowls() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

fn discovery13_stream(first BigInt, step int) AnswerStream {
	return AnswerStream{
		first: first
		step:  step
	}
}

fn test_discovery13_seed_uses_correct_circular_successor() {
	bowls := discovery13_bowls()
	order := [6, 5, 4, 3, 2, 1]
	seal := big_from_int(21)
	stream := calendar_answer_stream_spaghetti(bowls, order, 6, seal) or { panic(err.msg()) }
	assert (calendar_next_bowl_spaghetti(6, order) or { 0 }) == 5
	a := big_add(big_from_int(60), big_from_int(202))
	expected := calendar_save_spaghetti(big_add(big_add(big_square(a),
		big_mul_small(big_from_int(50), 179)), seal))
	assert big_eq(stream.first, expected)
	assert stream.step == 1 || stream.step == -1
	assert order == [6, 5, 4, 3, 2, 1]
	assert bowls[6].str() == '60'
}

fn test_discovery13_direction_uses_second_save_parity() {
	bowls := discovery13_bowls()
	stream := calendar_answer_stream_spaghetti(bowls, [2, 3, 1, 4, 5, 6], 3,
		big_from_int(31)) or { panic(err.msg()) }
	z := big_add(stream.first, big_from_int(225))
	d := calendar_save_spaghetti(big_add(big_add(big_square(z), big_mul_small(stream.first,
		193)), big_mul_small(bowls[6], 197)))
	assert stream.step == (if big_mod_small_nonnegative(d, 2) == 1 { 1 } else { -1 })
}

fn test_discovery13_forward_wrap_and_arbitrary_large_k() {
	m := discovery13_m()
	s := discovery13_stream(m, 1)
	assert big_eq(calendar_answer_at_spaghetti(s, big_zero()) or { big_zero() }, m)
	assert (calendar_answer_at_spaghetti(s, big_one()) or { big_zero() }).str() == '1'
	assert (calendar_answer_at_spaghetti(s, big_from_int(2)) or { big_zero() }).str() == '2'
	k := big_add(big_mul_small(m, 13), big_one())
	assert (calendar_answer_at_spaghetti(s, k) or { big_zero() }).str() == '1'
}

fn test_discovery13_backward_wrap_and_arbitrary_large_k() {
	m := discovery13_m()
	s := discovery13_stream(big_one(), -1)
	assert (calendar_answer_at_spaghetti(s, big_zero()) or { big_zero() }).str() == '1'
	assert big_eq(calendar_answer_at_spaghetti(s, big_one()) or { big_zero() }, m)
	assert big_eq(calendar_answer_at_spaghetti(s, big_from_int(2)) or { big_zero() },
		big_sub(m, big_one()))
	k := big_add(big_mul_small(m, 7), big_one())
	assert big_eq(calendar_answer_at_spaghetti(s, k) or { big_zero() }, m)
}

fn test_discovery13_modulo_bias_witness_and_legacy_dispatch() {
	m := discovery13_m()
	n := big_add(big_floor_div(m, big_from_int(2)), big_one())
	limit := big_mul(big_floor_div(m, n), n)
	assert big_eq(limit, n)
	assert big_cmp(m, limit) > 0
	legacy := new_base_dispatcher().dispatch_legacy_biased_pick(m, n) or {
		panic(err.msg())
	}
	assert big_eq(legacy, big_sub(n, big_one()))
	assert big_eq(calendar_choose_rank_short_spaghetti(discovery13_stream(m, 1), n) or {
		big_zero()
	}, legacy)
}

fn test_discovery13_dividing_ranges_have_no_bias() {
	m := discovery13_m()
	for x in [big_one(), big_from_int(2), big_sub(m, big_one()), m] {
		for step in [-1, 1] {
			s := discovery13_stream(x, step)
			assert big_eq(calendar_choose_rank_short_spaghetti(s, m) or { big_zero() }, x)
			assert big_eq(calendar_choose_rank_short_spaghetti(s, big_one()) or {
				big_zero()
			}, big_one())
		}
	}
}

fn test_discovery13_legacy_equivalent_to_direct_formula() {
	m := discovery13_m()
	for n in [big_from_int(3), big_from_int(7), big_sub(m, big_from_int(3))] {
		for x in [big_one(), big_from_int(8), big_sub(m, big_one()), m] {
			expected := big_add(big_one(), big_regular_mod(big_sub(x, big_one()), n))
			assert big_eq(old_biased_pick(x, n) or { big_zero() }, expected)
		}
	}
}

fn test_discovery13_invalid_arguments_rejected() {
	m := discovery13_m()
	s := discovery13_stream(big_one(), 1)
	for n in [big_zero(), big_neg(big_one()), big_add(m, big_one())] {
		mut rejected := false
		_ = calendar_choose_rank_short_spaghetti(s, n) or {
			rejected = true
			big_zero()
		}
		assert rejected
	}
	for bad in [discovery13_stream(big_zero(), 1), discovery13_stream(big_one(), 0),
		discovery13_stream(big_one(), 2)] {
		mut rejected := false
		_ = calendar_answer_at_spaghetti(bad, big_zero()) or {
			rejected = true
			big_zero()
		}
		assert rejected
	}
	mut bad_k := false
	_ = calendar_answer_at_spaghetti(s, big_neg(big_one())) or {
		bad_k = true
		big_zero()
	}
	assert bad_k
}

fn test_discovery13_invalid_bowls_latch_and_seal_rejected() {
	bowls := discovery13_bowls()
	order := [1, 2, 3, 4, 5, 6]
	mut failed := false
	_ = calendar_answer_stream_spaghetti(bowls, order, 1, big_zero()) or {
		failed = true
		AnswerStream{}
	}
	assert failed
	failed = false
	_ = calendar_answer_stream_spaghetti(bowls, [1, 2, 3, 4, 5, 5], 1,
		big_one()) or {
		failed = true
		AnswerStream{}
	}
	assert failed
	failed = false
	_ = calendar_answer_stream_spaghetti(bowls[..6], order, 1, big_one()) or {
		failed = true
		AnswerStream{}
	}
	assert failed
	assert order == [1, 2, 3, 4, 5, 6]
}

fn test_discovery13_post_stir_chain_and_latch_reused() {
	bowls := discovery13_bowls()
	order := [1, 3, 5, 2, 4, 6]
	after := calendar_post_stir12_spaghetti(bowls, order) or { panic(err.msg()) }
	via_chain := calendar_post_stir_answer_stream_spaghetti(bowls, order, 1,
		big_from_int(21)) or { panic(err.msg()) }
	direct := calendar_answer_stream_spaghetti(after.bowls, after.order_for_query, 1,
		big_from_int(21)) or { panic(err.msg()) }
	assert big_eq(via_chain.first, direct.first)
	assert via_chain.step == direct.step
	assert after.order_for_query == order
	assert after.overwrite_count == 12
	assert bowls[1].str() == '10'
}

fn test_discovery13_interleaving_and_public_short_wrapper() {
	bowls := discovery13_bowls()
	a := [6, 5, 4, 3, 2, 1]
	b := [2, 3, 1, 4, 5, 6]
	m := discovery13_m()
	for round in 0 .. 5 {
		first := calendar_answer_stream_spaghetti(bowls, a, 6, big_from_int(21)) or {
			panic(err.msg())
		}
		assert big_eq(calendar_ask_bowl_short_spaghetti(bowls, a, 6, big_from_int(21),
			m) or { big_zero() }, first.first)
		second := calendar_answer_stream_spaghetti(bowls, b, 3, big_from_int(31)) or {
			panic(err.msg())
		}
		assert big_eq(calendar_ask_bowl_short_spaghetti(bowls, b, 3, big_from_int(31),
			m) or { big_zero() }, second.first)
	}
	assert a == [6, 5, 4, 3, 2, 1]
	assert b == [2, 3, 1, 4, 5, 6]
	assert bowls[6].str() == '60'
}

fn test_discovery13_existing_monster_diagnostics_remain_intact() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	mut message := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		message = err.msg()
		CalendarResult{}
	}
	assert message.contains('PATCH_12 nextBowl=5')
}
