module pastafari

// ደረጃ 28፦ የhigh-first legacy ጉድለት እንዳለ የሚያረጋግጡ GREEN tests።
fn discovery14_m() BigInt {
	return big_sub(big_pow_small(big_from_int(2), 127), big_one())
}

fn discovery14_stream(first BigInt, step int) AnswerStream {
	return AnswerStream{
		first: first
		step:  step
	}
}

fn test_discovery14_two_digits_first_one_forward_is_reversed() {
	m := discovery14_m()
	n := big_mul(m, m)
	s := discovery14_stream(big_one(), 1)
	old := old_wide_pick_high_first(s, n) or { panic(err.msg()) }
	assert old.places == 2
	assert big_eq(old.space, n)
	assert old.raw_wide.str() == '2'
	assert old.rank.str() == '2'
	assert big_eq(calendar_choose_rank_spaghetti(s, n) or { big_zero() }, big_add(m, big_one()))
	assert !big_eq(old.rank, big_add(m, big_one()))
}

fn test_discovery14_two_digits_first_one_backward_is_reversed() {
	m := discovery14_m()
	n := big_mul(m, m)
	s := discovery14_stream(big_one(), -1)
	old := old_wide_pick_high_first(s, n) or { panic(err.msg()) }
	assert old.places == 2
	assert big_eq(old.rank, m)
	assert !big_eq(old.rank, big_add(big_sub(n, m), big_one()))
	assert old.rejected_count.str() == '0'
}

fn test_discovery14_two_digits_seed_seventeen_is_reversed() {
	m := discovery14_m()
	n := big_mul(m, m)
	old := new_base_dispatcher().dispatch_legacy_wide_order(discovery14_stream(big_from_int(17), 1), n) or {
		panic(err.msg())
	}
	assert big_eq(old.rank, big_add(big_mul_small(m, 16), big_from_int(18)))
	assert !big_eq(old.rank, big_add(big_mul_small(m, 17), big_from_int(17)))
}

fn test_discovery14_three_digits_first_one_is_reversed() {
	m := discovery14_m()
	m2 := big_mul(m, m)
	n := big_add(m2, big_one())
	trace := old_wide_pick_high_first(discovery14_stream(big_one(), 1), n) or { panic(err.msg()) }
	assert trace.places == 3
	assert big_eq(trace.space, big_mul(m2, m))
	assert big_eq(trace.rank, big_add(m, big_from_int(3)))
	assert !big_eq(trace.rank, big_sub(m, big_one()))
	assert trace.rejected_count.str() == '0'
}

fn test_discovery14_minimum_places_for_2_to_5_base_m_digits() {
	m := discovery14_m()
	m2 := big_mul(m, m)
	m3 := big_mul(m2, m)
	m4 := big_mul(m3, m)
	m5 := big_mul(m4, m)
	sizes := [big_add(m, big_one()), m2, big_add(m2, big_one()), m3, big_add(m3, big_one()),
		m5]
	expected_places := [2, 2, 3, 3, 4, 5]
	expected_spaces := [m2, m2, m3, m3, m4, m5]
	for i in 0 .. sizes.len {
		t := old_wide_pick_high_first(discovery14_stream(big_one(), 1), sizes[i]) or {
			panic(err.msg())
		}
		assert t.places == expected_places[i]
		assert big_eq(t.space, expected_spaces[i])
		assert big_cmp(t.space, sizes[i]) >= 0
	}
}

fn test_discovery14_wide_rejection_moves_in_original_direction() {
	m := discovery14_m()
	m2 := big_mul(m, m)
	n := big_sub(m2, big_from_int(3))
	s := discovery14_stream(m, -1)
	trace := old_wide_pick_high_first(s, n) or { panic(err.msg()) }
	assert trace.places == 2
	assert trace.rejected_count.str() == '2'
	assert big_eq(trace.raw_wide, big_sub(m2, big_one()))
	assert big_eq(trace.accepted_wide, n)
	assert big_eq(trace.limit, n)
	assert big_eq(trace.rank, n)
}

fn test_discovery14_legacy_adapter_dispatcher_public_call_agree() {
	m := discovery14_m()
	n := big_mul(m, m)
	s := discovery14_stream(big_from_int(17), 1)
	old := old_wide_pick_high_first(s, n) or { panic(err.msg()) }
	adapt := LegacyWideOrderAdapter{}.pick(s, n) or { panic(err.msg()) }
	dispatch := new_base_dispatcher().dispatch_legacy_wide_order(s, n) or { panic(err.msg()) }
	assert big_eq(old.rank, adapt.rank)
	assert big_eq(adapt.rank, dispatch.rank)
	assert big_eq(calendar_choose_rank_spaghetti(s, n) or { big_zero() }, big_add(big_mul_small(m, 17),
		big_from_int(17)))
	assert s.first.str() == '17'
	assert s.step == 1
}

fn test_discovery14_short_patch13_path_is_unchanged() {
	m := discovery14_m()
	n := big_sub(m, big_from_int(3))
	for step in [-1, 1] {
		for first in [big_one(), m] {
			s := discovery14_stream(first, step)
			assert big_eq(calendar_choose_rank_spaghetti(s, n) or { big_zero() }, calendar_choose_rank_short_spaghetti(s,
				n) or { big_zero() })
		}
	}
}

fn test_discovery14_invalid_ranges_or_streams_are_rejected() {
	m := discovery14_m()
	m2 := big_mul(m, m)
	good := discovery14_stream(big_one(), 1)
	for n in [big_zero(), big_neg(big_one())] {
		mut bad := false
		_ = calendar_choose_rank_spaghetti(good, n) or {
			bad = true
			big_zero()
		}
		assert bad
	}
	for n in [m, big_one()] {
		mut bad := false
		_ = old_wide_pick_high_first(good, n) or {
			bad = true
			LegacyWideOrderTrace{}
		}
		assert bad
	}
	for s in [discovery14_stream(big_zero(), 1), discovery14_stream(big_one(), 0),
		discovery14_stream(big_add(m, big_one()), 1)] {
		mut bad := false
		_ = calendar_choose_rank_spaghetti(s, m2) or {
			bad = true
			big_zero()
		}
		assert bad
	}
}

fn test_discovery14_interleaving_does_not_mutate_streams() {
	m := discovery14_m()
	n := big_mul(m, m)
	a := discovery14_stream(big_one(), 1)
	b := discovery14_stream(big_one(), -1)
	for repeat in 0 .. 7 {
		assert big_eq(calendar_choose_rank_spaghetti(a, n) or { big_zero() }, big_add(m, big_one()))
		assert big_eq(calendar_choose_rank_spaghetti(b, n) or { big_zero() }, big_add(big_sub(n,
			m), big_one()))
	}
	assert a.first.str() == '1'
	assert b.first.str() == '1'
	assert a.step == 1
	assert b.step == -1
}

fn test_discovery14_wide_bowl_and_post_stir_wrappers_preserve_caller() {
	bowls := [big_zero(), big_from_int(10), big_from_int(20),
		big_from_int(30), big_from_int(40), big_from_int(50),
		big_from_int(60)]
	order := [6, 5, 4, 3, 2, 1]
	m := discovery14_m()
	n := big_mul(m, m)
	stream := calendar_answer_stream_spaghetti(bowls, order, 6, big_from_int(21)) or {
		panic(err.msg())
	}
	from_wrapper := calendar_ask_bowl_rank_spaghetti(bowls, order, 6, big_from_int(21), n) or {
		panic(err.msg())
	}
	assert big_eq(from_wrapper, calendar_choose_rank_spaghetti(stream, n) or { big_zero() })
	post_stream := calendar_post_stir_answer_stream_spaghetti(bowls, order, 6, big_from_int(21)) or {
		panic(err.msg())
	}
	post_rank := calendar_post_stir_ask_bowl_rank_spaghetti(bowls, order, 6, big_from_int(21), n) or {
		panic(err.msg())
	}
	assert big_eq(post_rank, calendar_choose_rank_spaghetti(post_stream, n) or { big_zero() })
	assert bowls[6].str() == '60'
	assert order == [6, 5, 4, 3, 2, 1]
}
