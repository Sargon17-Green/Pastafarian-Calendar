module pastafari

// ደረጃ 27፦ የrejection ቅደም ተከተል እና የlegacy ማስረጃ።
fn patch13_m() BigInt {
	return big_sub(big_pow_small(big_from_int(2), 127), big_one())
}

fn patch13_stream(first BigInt, step int) AnswerStream {
	return AnswerStream{
		first: first
		step:  step
	}
}

// ለtest ብቻ ተለይቶ የተጻፈ ቀላል reference።
fn patch13_reference(first BigInt, step int, n BigInt) (BigInt, BigInt, BigInt) {
	m := patch13_m()
	limit := big_mul(big_floor_div(m, n), n)
	mut k := big_zero()
	for attempt in 0 .. 110 {
		delta := if step == 1 { k } else { big_neg(k) }
		x := big_add(big_one(), big_regular_mod(big_add(big_sub(first, big_one()),
			delta), m))
		if big_cmp(x, limit) <= 0 {
			return big_add(big_one(), big_regular_mod(big_sub(x, big_one()), n)), x, k
		}
		k = big_add(k, big_one())
	}
	panic('የtest reference 110 እርምጃዎችን ተሻግሯል')
}

fn test_patch13_four_original_expected_red_boundaries() {
	m := patch13_m()
	half := big_add(big_floor_div(m, big_from_int(2)), big_one())
	near := big_sub(m, big_from_int(3))
	firsts := [m, big_sub(m, big_one()), m, m]
	steps := [1, 1, -1, 1]
	ranges := [half, half, near, near]
	expected := [big_one(), big_one(), near, big_one()]
	for i in 0 .. 4 {
		got := calendar_choose_rank_short_spaghetti(patch13_stream(firsts[i], steps[i]),
			ranges[i]) or { big_zero() }
		assert big_eq(got, expected[i])
	}
}

fn test_patch13_rejection_count_and_accepted_x() {
	m := patch13_m()
	half := big_add(big_floor_div(m, big_from_int(2)), big_one())
	near := big_sub(m, big_from_int(3))
	firsts := [m, big_sub(m, big_one()), m, m]
	steps := [1, 1, -1, 1]
	ranges := [half, half, near, near]
	expected_rejected := [1, 2, 3, 1]
	for i in 0 .. 4 {
		result := ShortRejectionPatch13{}.choose(patch13_stream(firsts[i], steps[i]),
			ranges[i]) or { panic(err.msg()) }
		rank, x, k := patch13_reference(firsts[i], steps[i], ranges[i])
		assert big_eq(result.rank, rank)
		assert big_eq(result.accepted_x, x)
		assert big_eq(result.rejected_count, k)
		assert big_eq(result.rejected_count, big_from_int(expected_rejected[i]))
		assert big_cmp(result.accepted_x, result.limit) <= 0
		assert big_eq(result.limit, big_mul(big_floor_div(m, ranges[i]), ranges[i]))
	}
}

fn test_patch13_no_rejection_when_n_divides_m() {
	m := patch13_m()
	for n in [big_one(), m] {
		for x in [big_one(), big_from_int(2), big_sub(m, big_one()), m] {
			for step in [-1, 1] {
				got := ShortRejectionPatch13{}.choose(patch13_stream(x, step), n) or {
					panic(err.msg())
				}
				assert got.rejected_count.str() == '0'
				assert big_eq(got.accepted_x, x)
				expected := if big_eq(n, big_one()) { big_one() } else { x }
				assert big_eq(got.rank, expected)
			}
		}
	}
}

fn test_patch13_hundred_rejections_backward_but_one_forward() {
	m := patch13_m()
	n := big_sub(m, big_from_int(100))
	for step in [-1, 1] {
		got := ShortRejectionPatch13{}.choose(patch13_stream(m, step), n) or {
			panic(err.msg())
		}
		rank, x, k := patch13_reference(m, step, n)
		assert big_eq(got.rank, rank)
		assert big_eq(got.accepted_x, x)
		assert big_eq(got.rejected_count, k)
		assert got.rejected_count.str() == (if step == -1 { '100' } else { '1' })
	}
}

fn test_patch13_short_small_n_independently_matches_reference() {
	m := patch13_m()
	for n in [big_from_int(3), big_from_int(7), big_from_int(11), big_from_int(19)] {
		for first in [big_one(), big_from_int(2), big_sub(m, big_one()), m] {
			for step in [-1, 1] {
				expected, x, count := patch13_reference(first, step, n)
				got := ShortRejectionPatch13{}.choose(patch13_stream(first, step), n) or {
					panic(err.msg())
				}
				assert big_eq(got.rank, expected)
				assert big_eq(got.accepted_x, x)
				assert big_eq(got.rejected_count, count)
				assert big_eq(got.rank, old_biased_pick(x, n) or { big_zero() })
			}
		}
	}
}

fn test_patch13_preserves_the_original_legacy_error() {
	m := patch13_m()
	n := big_add(big_floor_div(m, big_from_int(2)), big_one())
	wrong := big_sub(n, big_one())
	assert big_eq(old_biased_pick(m, n) or { big_zero() }, wrong)
	assert big_eq(new_base_dispatcher().dispatch_legacy_biased_pick(m, n) or {
		big_zero()
	}, wrong)
	assert (calendar_choose_rank_short_spaghetti(patch13_stream(m, 1), n) or {
		big_zero()
	}).str() == '1'
}

fn test_patch13_direct_dispatcher_and_public_selection_agree() {
	m := patch13_m()
	n := big_sub(m, big_from_int(3))
	for step in [-1, 1] {
		stream := patch13_stream(m, step)
		direct := ShortRejectionPatch13{}.choose(stream, n) or { panic(err.msg()) }
		routed := new_base_dispatcher().dispatch_short_rejection_patch13(stream, n) or {
			panic(err.msg())
		}
		public_result := calendar_choose_rank_short_spaghetti(stream, n) or { big_zero() }
		assert big_eq(direct.rank, routed.rank)
		assert big_eq(public_result, routed.rank)
	}
}

fn test_patch13_invalid_ranges_and_corrupt_streams_fail() {
	m := patch13_m()
	for invalid_n in [big_zero(), big_neg(big_one()), big_add(m, big_one())] {
		mut failed := false
		_ = ShortRejectionPatch13{}.choose(patch13_stream(big_one(), 1), invalid_n) or {
			failed = true
			ShortRejectionResult13{}
		}
		assert failed
	}
	for bad in [patch13_stream(big_zero(), 1), patch13_stream(big_one(), 0),
		patch13_stream(big_add(m, big_one()), 1)] {
		mut failed := false
		_ = calendar_choose_rank_short_spaghetti(bad, big_one()) or {
			failed = true
			big_zero()
		}
		assert failed
	}
}

fn test_patch13_repeated_interleaving_does_not_change_streams() {
	m := patch13_m()
	n := big_sub(m, big_from_int(3))
	first := patch13_stream(m, 1)
	second := patch13_stream(m, -1)
	for iteration in 0 .. 12 {
		assert (calendar_choose_rank_short_spaghetti(first, n) or { big_zero() }).str() == '1'
		assert big_eq(calendar_choose_rank_short_spaghetti(second, n) or { big_zero() }, n)
	}
	assert big_eq(first.first, m)
	assert first.step == 1
	assert big_eq(second.first, m)
	assert second.step == -1
}

fn test_patch13_real_post_stir_query_keeps_input_immutable() {
	bowls := [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
	order := [6, 5, 4, 3, 2, 1]
	after := calendar_post_stir12_spaghetti(bowls, order) or { panic(err.msg()) }
	from_chain := calendar_post_stir_answer_stream_spaghetti(bowls, order, 6,
		big_from_int(21)) or { panic(err.msg()) }
	direct := calendar_answer_stream_spaghetti(after.bowls, after.order_for_query, 6,
		big_from_int(21)) or { panic(err.msg()) }
	assert big_eq(from_chain.first, direct.first)
	assert from_chain.step == direct.step
	assert big_eq(calendar_choose_rank_short_spaghetti(from_chain, patch13_m()) or {
		big_zero()
	}, from_chain.first)
	assert bowls[6].str() == '60'
	assert order == [6, 5, 4, 3, 2, 1]
}
