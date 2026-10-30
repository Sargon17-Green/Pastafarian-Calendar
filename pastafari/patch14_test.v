module pastafari

// ደረጃ 29፦ bounded reference model, including the extreme negative-step witness.
fn test_patch14_rejection_jump_exhaustive_small_spaces() {
	for base in [3, 5, 7] {
		space_i := base * base
		end := space_i + 1
		space := big_from_int(space_i)
		for n in 1 .. end {
			limit_i := (space_i / n) * n
			for x in 1 .. end {
				for step in [-1, 1] {
					jump := patch14_rejection_jump(big_from_int(x), big_from_int(limit_i),
						space, step) or { panic(err.msg()) }
					mut accepted := x
					mut count := 0
					for accepted > limit_i {
						accepted = 1 + (accepted - 1 + step + space_i) % space_i
						count++
					}
					assert big_eq(jump.accepted, big_from_int(accepted))
					assert big_eq(jump.rejected, big_from_int(count))
				}
			}
		}
	}
}

fn test_patch14_legacy_wide_order_remains_an_independent_witness() {
	m := legacy_m_old()
	n := big_mul(m, m)
	s := AnswerStream{
		first: big_one()
		step:  1
	}
	old := old_wide_pick_high_first(s, n) or { panic(err.msg()) }
	new := patch14_wide_pick_little_first(s, n) or { panic(err.msg()) }
	assert big_eq(old.rank, big_from_int(2))
	assert big_eq(new.rank, big_add(m, big_one()))
	assert big_eq(calendar_choose_rank_spaghetti(s, n) or { big_zero() }, new.rank)
}

fn test_patch14_negative_direction_huge_rejection_is_constant_time() {
	m := legacy_m_old()
	space := big_mul(m, m)
	n := big_floor_div(big_add(space, big_one()), big_from_int(2))
	trace := patch14_wide_pick_little_first(AnswerStream{
		first: m
		step:  -1
	}, n) or { panic(err.msg()) }
	assert trace.places == 2
	assert big_eq(trace.space, space)
	assert big_eq(trace.raw_wide, big_sub(space, m))
	assert big_eq(trace.limit, n)
	assert big_eq(trace.rejected_count, big_sub(big_sub(space, m), n))
	assert big_eq(trace.accepted_wide, n)
	assert big_eq(trace.rank, n)
}

fn test_patch14_positive_direction_huge_digit_order_no_rejection() {
	m := legacy_m_old()
	space := big_mul(m, m)
	n := big_floor_div(big_add(space, big_one()), big_from_int(2))
	trace := patch14_wide_pick_little_first(AnswerStream{
		first: m
		step:  1
	}, n) or { panic(err.msg()) }
	assert trace.places == 2
	assert big_eq(trace.raw_wide, m)
	assert big_eq(trace.rejected_count, big_zero())
	assert big_eq(trace.rank, m)
}

fn test_patch14_rejection_rejects_invalid_bounds_and_steps() {
	mut failures := 0
	for step in [-2, 0, 2] {
		_ = patch14_rejection_jump(big_from_int(2), big_from_int(3), big_from_int(5), step) or {
			failures++
			Patch14RejectionResult{}
		}
	}
	assert failures == 3
}
