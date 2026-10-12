module pastafari

// ደረጃ 24 — DISCOVERY 12፦ ቀጣዩ ጎድጓዳ ሳህን በቋሚ ID ስም
// እንጂ በ46ኛው ጠብታ የተያዘው ቅደም ተከተል አይመረጥም።
// የPATCH 12 ትክክለኛ የቅደም ተከተል ፍለጋ እዚህ አይደረግም።
pub fn old_next_bowl_fixed_name(queried_id int) !int {
	if queried_id < 1 || queried_id > 6 {
		return error('የተጠየቀው ጎድጓዳ ሳህን ID ከ1 እስከ6 መሆን አለበት')
	}
	// የታሪክ ስህተት፦ ሁሉም ID በ1,2,3,4,5,6 ስም ቅደም ተከተል ተያይዘዋል።
	return (queried_id % 6) + 1
}

pub struct LegacyNextBowlAdapter {}

// የታረመው orderAt46Latch ግቤት ይገኛል ግን legacy ሆን ብሎ ችላ ይለዋል።
pub fn (_ LegacyNextBowlAdapter) next(queried_id int, order_at_46_latch []int) !int {
	patch := PostStirPatch11{}
	_ = patch.latch_order_at_46(order_at_46_latch)!
	return old_next_bowl_fixed_name(queried_id)
}

pub fn (_ BaseDispatcher) dispatch_legacy_next_bowl(queried_id int, order_at_46_latch []int) !int {
	adapter := LegacyNextBowlAdapter{}
	return adapter.next(queried_id, order_at_46_latch)
}

// ደረጃ 24 የproduction query መስመር የቋሚ-ID ታሪኩን ይጠቀማል።
pub fn calendar_next_bowl_spaghetti(queried_id int, order_at_46_latch []int) !int {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_next_bowl(queried_id, order_at_46_latch)
}

// ከ12 post-stirs በኋላ የPATCH 11 የተጠበቀው order በእውነት ይተላለፋል፤
// ሆኖም ቀጣይ ምርጫው እሱን አያነብም።
pub fn calendar_post_stir_next_bowl_spaghetti(bowls []BigInt, order_at_drop46 []int, queried_id int) !int {
	post := calendar_post_stir12_spaghetti(bowls, order_at_drop46)!
	return calendar_next_bowl_spaghetti(queried_id, post.order_for_query)
}
