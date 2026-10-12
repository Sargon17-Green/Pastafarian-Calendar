module pastafari

// ደረጃ 25 — PATCH 12፦ የ46ኛው ጠብታ ቅደም ተከተል ቀጣይ ቦውልን ይወስናል።
// የታሪክ ቋሚ-ID አሰራር አይሰረዝም፣ በተለየ dispatcher በእውነት ይጠራል።
pub struct NextBowlPatch12 {}

// ለquery ቅደም ተከተል ከPATCH 11 ያልተደረሰ ላች ቅጂ ይጠቀማል።
// የlegacy መልስ ለታሪካዊ ምርመራ ብቻ ነው፤ ምርጫውን አይወስንም።
pub fn (_ NextBowlPatch12) next(queried_id int, order_at_46_latch []int) !int {
	latch := PostStirPatch11{}.latch_order_at_46(order_at_46_latch)!
	dispatcher := new_base_dispatcher()
	legacy_next := dispatcher.dispatch_legacy_next_bowl(queried_id, latch)!
	if legacy_next < 1 || legacy_next > 6 {
		return error('የታሪክ ቀጣይ ቦውል ከ1 እስከ6 መሆን አለበት')
	}
	for position, bowl_id in latch {
		if bowl_id == queried_id {
			return latch[(position + 1) % 6]
		}
	}
	return error('የተጠየቀው ቦውል በላች ቅደም ተከተል አልተገኘም')
}

pub fn (_ BaseDispatcher) dispatch_next_bowl_patch12(queried_id int, order_at_46_latch []int) !int {
	patch := NextBowlPatch12{}
	return patch.next(queried_id, order_at_46_latch)
}
