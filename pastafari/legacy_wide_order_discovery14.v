module pastafari

// ደረጃ 28 DISCOVERY 14፦ የታሪኩ high-first የbase-M አሃዞች ስህተት።
pub struct LegacyWideOrderTrace {
pub:
	rank           BigInt
	raw_wide       BigInt
	accepted_wide  BigInt
	space          BigInt
	limit          BigInt
	rejected_count BigInt
	places         int
}

pub fn old_wide_pick_high_first(stream AnswerStream, n BigInt) !LegacyWideOrderTrace {
	m := legacy_m_old()
	if big_cmp(n, m) <= 0 {
		return error('የታሪኩ wide ምርጫ፦ n>M መሆን አለበት')
	}
	mut places := 1
	mut space := m
	for big_cmp(space, n) < 0 {
		places++
		space = big_mul(space, m)
	}
	mut accumulator := big_zero()
	for j in 0 .. places {
		x := calendar_answer_at_spaghetti(stream, big_from_int(j))!
		digit := big_sub(x, big_one())
		// የታሪክ ጉድለት፦ የመጀመሪያው digit ከፍተኛ አሃዝ ተደርጓል።
		accumulator = big_add(big_mul(accumulator, m), digit)
	}
	raw := big_add(accumulator, big_one())
	limit := big_mul(big_floor_div(space, n), n)
	mut accepted := raw
	mut rejected := big_zero()
	step := if stream.step == 1 { big_one() } else { big_neg(big_one()) }
	for big_cmp(accepted, limit) > 0 {
		accepted = big_add(big_one(), big_regular_mod(big_add(big_sub(accepted, big_one()), step),
			space))
		rejected = big_add(rejected, big_one())
	}
	return LegacyWideOrderTrace{
		rank:           big_add(big_one(), big_regular_mod(big_sub(accepted, big_one()), n))
		raw_wide:       raw
		accepted_wide:  accepted
		space:          space
		limit:          limit
		rejected_count: rejected
		places:         places
	}
}

pub struct LegacyWideOrderAdapter {}

pub fn (_ LegacyWideOrderAdapter) pick(stream AnswerStream, n BigInt) !LegacyWideOrderTrace {
	return old_wide_pick_high_first(stream, n)
}

pub fn (_ BaseDispatcher) dispatch_legacy_wide_order(stream AnswerStream, n BigInt) !LegacyWideOrderTrace {
	return LegacyWideOrderAdapter{}.pick(stream, n)
}

// PATCH 14፦ n<=M የPATCH 13 መንገድ አይቀየርም፤ n>M little-first ይጠቀማል።
pub fn calendar_choose_rank_spaghetti(stream AnswerStream, n BigInt) !BigInt {
	if big_cmp(n, big_one()) < 0 {
		return error('ምርጫ n አዎንታዊ መሆን አለበት')
	}
	if big_cmp(n, legacy_m_old()) <= 0 {
		return calendar_choose_rank_short_spaghetti(stream, n)
	}
	trace := new_base_dispatcher().dispatch_patch14_wide_order(stream, n)!
	return trace.rank
}

pub fn calendar_ask_bowl_rank_spaghetti(bowls []BigInt, order_at_46_latch []int, queried_id int, seal BigInt, n BigInt) !BigInt {
	stream := calendar_answer_stream_spaghetti(bowls, order_at_46_latch, queried_id, seal)!
	return calendar_choose_rank_spaghetti(stream, n)
}

pub fn calendar_post_stir_ask_bowl_rank_spaghetti(bowls_at_46 []BigInt, order_at_46 []int, queried_id int, seal BigInt, n BigInt) !BigInt {
	stream :=
		calendar_post_stir_answer_stream_spaghetti(bowls_at_46, order_at_46, queried_id, seal)!
	return calendar_choose_rank_spaghetti(stream, n)
}
