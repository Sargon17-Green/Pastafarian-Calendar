module pastafari

// ደረጃ 26፦ የመልስ ዙር ትክክል ነው፤ rejection ግን በPATCH 13 ይመጣል።
pub struct AnswerStream {
pub:
	first BigInt
	step  int
}

// የቦውሎች መያዣ [sentinel, bowl1, ..., bowl6] ነው።
pub fn calendar_answer_stream_spaghetti(bowls []BigInt, order_at_46_latch []int, queried_id int, seal BigInt) !AnswerStream {
	m := legacy_m_old()
	if bowls.len != 7 || big_cmp(seal, big_one()) < 0 {
		return error('ስድስት ቦውሎችና አዎንታዊ seal ያስፈልጋሉ')
	}
	for id in 1 .. 7 {
		if big_cmp(bowls[id], big_one()) < 0 || big_cmp(bowls[id], m) > 0 {
			return error('የቦውል እሴት ከ1 እስከ M መሆን አለበት')
		}
	}
	next_id := calendar_next_bowl_spaghetti(queried_id, order_at_46_latch)!
	a := big_add(big_add(bowls[queried_id], seal), big_from_int(181))
	first := calendar_save_spaghetti(big_add(big_add(big_square(a), big_mul_small(bowls[next_id],
		179)), seal))
	b := big_add(big_add(first, seal), big_from_int(194))
	d := calendar_save_spaghetti(big_add(big_add(big_square(b), big_mul_small(first,
		193)), big_mul_small(bowls[6], 197)))
	step := if big_mod_small_nonnegative(d, 2) == 1 { 1 } else { -1 }
	return AnswerStream{
		first: first
		step:  step
	}
}

// k በBigInt ነው፤ የዙሩ መነሻና አቅጣጫ ሁልጊዜ ይጠበቃሉ።
pub fn calendar_answer_at_spaghetti(stream AnswerStream, k BigInt) !BigInt {
	m := legacy_m_old()
	if big_cmp(k, big_zero()) < 0 || big_cmp(stream.first, big_one()) < 0
		|| big_cmp(stream.first, m) > 0 || (stream.step != 1 && stream.step != -1) {
		return error('የመልስ ዙር ቦታ ወይም መነሻ ሕገ-ወጥ ነው')
	}
	offset := if stream.step == 1 { k } else { big_neg(k) }
	return big_add(big_one(), big_regular_mod(big_add(big_sub(stream.first, big_one()),
		offset), m))
}

// የታሪክ ስህተት፦ x>floor(M/n)*n እንኳ ሳይጣል ወዲያውኑ ይመረጣል።
pub fn calendar_choose_rank_short_spaghetti(stream AnswerStream, n BigInt) !BigInt {
	m := legacy_m_old()
	if big_cmp(n, big_one()) < 0 || big_cmp(n, m) > 0 {
		return error('የአጭር ምርጫ n ከ1 እስከ M መሆን አለበት')
	}
	x := calendar_answer_at_spaghetti(stream, big_zero())!
	return new_base_dispatcher().dispatch_legacy_biased_pick(x, n)
}

// PATCH 11 የተጠበቀውን የ46ኛው ቅደም ተከተል ያስተላልፋል።
pub fn calendar_post_stir_answer_stream_spaghetti(bowls_at_46 []BigInt, order_at_46 []int, queried_id int, seal BigInt) !AnswerStream {
	after := calendar_post_stir12_spaghetti(bowls_at_46, order_at_46)!
	return calendar_answer_stream_spaghetti(after.bowls, after.order_for_query, queried_id,
		seal)
}

pub fn calendar_ask_bowl_short_spaghetti(bowls []BigInt, order_at_46_latch []int, queried_id int, seal BigInt, n BigInt) !BigInt {
	stream := calendar_answer_stream_spaghetti(bowls, order_at_46_latch, queried_id, seal)!
	return calendar_choose_rank_short_spaghetti(stream, n)
}
