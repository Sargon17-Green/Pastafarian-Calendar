module pastafari

// ደረጃ 23 — PATCH 11፦ ከ46ኛው ጠብታ የተሰጠውን ቅደም ተከተል
// ከ12ቱ የመጨረሻ ብስለቶች በፊት በራሱ መያዣ እንደገና ይቀዳል።
// የታሪኩ መደረስ በlegacy ውስጥ ይቀራል፤ ለquery ግን አይጠቀምም።
pub struct PostStirPatch11 {}

// የorderAt46Latch አንድ ጊዜ ቅጂ በምንም post-stir አይጻፍበትም።
pub fn (_ PostStirPatch11) latch_order_at_46(order []int) ![]int {
	if order.len != 6 {
		return error('የ46ኛው ጠብታ ቅደም ተከተል ስድስት መሆን አለበት')
	}
	mut seen := []bool{len: 7}
	mut order_at_46_latch := []int{len: 6}
	for index in 0 .. 6 {
		id := order[index]
		if id < 1 || id > 6 || seen[id] {
			return error('የ46ኛው ጠብታ ቅደም ተከተል ሁሉንም ID አንድ ጊዜ መያዝ አለበት')
		}
		seen[id] = true
		order_at_46_latch[index] = id
	}
	return order_at_46_latch
}

// እውነተኛ የlegacy ጥሪ 12ቱን ብስለቶች እና 12ቱን የታሪክ
// መደረሶች ያከናውናል። የPATCH 11 የተለየ መልስ ግን የላች ቅጂን ይይዛል።
pub fn (patch PostStirPatch11) post_stir(bowls []BigInt, order_at_drop46 []int) !LegacyPostStir12Result {
	legacy_validate_pour_inputs(1, bowls, order_at_drop46)!
	order_at_46_latch := patch.latch_order_at_46(order_at_drop46)!
	dispatcher := new_base_dispatcher()
	legacy_result := dispatcher.dispatch_legacy_post_stir12(bowls, order_at_drop46)!
	if legacy_result.final_stir_number != 12 || legacy_result.overwrite_count != 12
		|| legacy_result.bowls.len != 7 || legacy_result.order_for_query.len != 6 {
		return error('የlegacy 12 ብስለቶች ውጤት ተሟልቶ መመለስ አለበት')
	}
	return LegacyPostStir12Result{
		bowls:             legacy_result.bowls.clone()
		order_for_query:   order_at_46_latch.clone()
		overwrite_count:   legacy_result.overwrite_count
		final_saved_sum:   big_add(legacy_result.final_saved_sum, big_zero())
		final_stir_number: legacy_result.final_stir_number
	}
}

pub fn (_ BaseDispatcher) dispatch_post_stir_patch11(bowls []BigInt, order_at_drop46 []int) !LegacyPostStir12Result {
	patch := PostStirPatch11{}
	return patch.post_stir(bowls, order_at_drop46)
}
