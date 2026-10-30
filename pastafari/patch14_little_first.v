module pastafari

// ደረጃ 29 PATCH 14፦ little-first wide; historical high-first stays unchanged.
pub struct Patch14RejectionResult {
pub:
	accepted BigInt
	rejected BigInt
}

pub fn patch14_rejection_jump(raw BigInt, limit BigInt, space BigInt, step int) !Patch14RejectionResult {
	if big_cmp(raw, big_one()) < 0 || big_cmp(raw, space) > 0 || big_cmp(limit, big_one()) < 0
		|| big_cmp(limit, space) > 0 || (step != 1 && step != -1) {
		return error('PATCH 14፦ invalid rejection bounds or direction')
	}
	if big_cmp(raw, limit) <= 0 {
		return Patch14RejectionResult{
			accepted: raw
			rejected: big_zero()
		}
	}
	if step == 1 {
		return Patch14RejectionResult{
			accepted: big_one()
			rejected: big_add(big_sub(space, raw), big_one())
		}
	}
	return Patch14RejectionResult{
		accepted: limit
		rejected: big_sub(raw, limit)
	}
}

pub struct Patch14WideTrace {
pub:
	rank           BigInt
	raw_wide       BigInt
	accepted_wide  BigInt
	space          BigInt
	limit          BigInt
	rejected_count BigInt
	places         int
}

pub fn patch14_wide_pick_little_first(stream AnswerStream, n BigInt) !Patch14WideTrace {
	m := legacy_m_old()
	if big_cmp(n, m) <= 0 {
		return error('PATCH 14፦ n must exceed M')
	}
	mut places := 1
	mut space := m
	for big_cmp(space, n) < 0 {
		places++
		space = big_mul(space, m)
	}
	mut accumulator := big_one()
	mut weight := big_one()
	for j in 0 .. places {
		x := calendar_answer_at_spaghetti(stream, big_from_int(j))!
		digit := big_sub(x, big_one())
		accumulator = big_add(accumulator, big_mul(digit, weight))
		weight = big_mul(weight, m)
	}
	limit := big_mul(big_floor_div(space, n), n)
	jump := patch14_rejection_jump(accumulator, limit, space, stream.step)!
	return Patch14WideTrace{
		rank:           big_add(big_one(), big_regular_mod(big_sub(jump.accepted, big_one()), n))
		raw_wide:       accumulator
		accepted_wide:  jump.accepted
		space:          space
		limit:          limit
		rejected_count: jump.rejected
		places:         places
	}
}

pub fn (_ BaseDispatcher) dispatch_patch14_wide_order(stream AnswerStream, n BigInt) !Patch14WideTrace {
	return patch14_wide_pick_little_first(stream, n)
}
