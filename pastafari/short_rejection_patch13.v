module pastafari

// ደረጃ 27 — PATCH 13፦ በአንድ stream ላይ rejection በፊት፣ legacy ከዚያ በኋላ።
// ታሪካዊ old_biased_pick እና የlegacy adapter አይለወጡም።
pub struct ShortRejectionPatch13 {}

pub struct ShortRejectionResult13 {
pub:
	rank           BigInt
	accepted_x     BigInt
	rejected_count BigInt
	limit          BigInt
}

pub fn (_ ShortRejectionPatch13) choose(stream AnswerStream, n BigInt) !ShortRejectionResult13 {
	m := legacy_m_old()
	if big_cmp(n, big_one()) < 0 || big_cmp(n, m) > 0 {
		return error('PATCH 13፦ n ከ1 እስከ M መሆን አለበት')
	}
	limit := big_mul(big_floor_div(m, n), n)
	mut k := big_zero()
	for {
		x := calendar_answer_at_spaghetti(stream, k)!
		if big_cmp(x, limit) <= 0 {
			rank := new_base_dispatcher().dispatch_legacy_biased_pick(x, n)!
			return ShortRejectionResult13{
				rank:           rank
				accepted_x:     x
				rejected_count: k
				limit:          limit
			}
		}
		k = big_add(k, big_one())
	}
	return error('PATCH 13፦ የrejection ዙር አልተጠናቀቀም')
}

pub fn (_ BaseDispatcher) dispatch_short_rejection_patch13(stream AnswerStream, n BigInt) !ShortRejectionResult13 {
	return ShortRejectionPatch13{}.choose(stream, n)
}
