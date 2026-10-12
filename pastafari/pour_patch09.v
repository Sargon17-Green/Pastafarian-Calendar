module pastafari

// ደረጃ 19 — PATCH 09፦ የታሪክ ማፍሰሻ በቦታዎች የሚያነበውን
// የተለየ የalias ካርታ ይሰጠዋል፤ የlegacy ስሌት አይቀየርም።
pub struct PourPatch09 {}

// የV ሰልፍ 0 ያልተጠቀመ ምልክት ነው። ለposition=1..6 የID ካርታ ይሞላል።
pub fn (_ PourPatch09) install_bowl_alias(order []int) ![]int {
	if order.len != 6 {
		return error('የalias የቅደም ተከተል ብዛት 6 መሆን አለበት')
	}
	mut seen := []bool{len: 7}
	mut bowl_alias := []int{len: 7}
	for position in 1 .. 7 {
		id := order[position - 1]
		if id < 1 || id > 6 || seen[id] {
			return error('የalias ቅደም ተከተል ስድስቱን ID አንድ ጊዜ መያዝ አለበት')
		}
		seen[id] = true
		bowl_alias[position] = id
	}
	return bowl_alias
}

// የlegacy የቦታ ንባብ በቋሚ ID ሳይሆን በalias[position] ይመራል።
pub fn (_ PourPatch09) bowl_by_legacy_position(bowls []BigInt, bowl_alias []int, position int) !BigInt {
	if bowls.len != 7 || bowl_alias.len != 7 || position < 1 || position > 6 {
		return error('የalias ማንበቢያ ያልተፈቀደ ቦታ ወይም መያዣ ነው')
	}
	bowl_id := bowl_alias[position]
	if bowl_id < 1 || bowl_id > 6 {
		return error('የalias የጎድጓዳ ሳህን ID ከ1 እስከ6 መሆን አለበት')
	}
	return big_add(bowls[bowl_id], big_zero())
}

// የlegacy ኮድ እንዳለ ይጠራል፤ ለእሱ አዲስ የቦታ-መሠረት የእይታ ሰልፍ ይገነባል።
pub fn (patch PourPatch09) pour(i int, drop BigInt, stones Stones, bowls []BigInt, order []int) ![]BigInt {
	legacy_validate_pour_inputs(i, bowls, order)!
	bowl_alias := patch.install_bowl_alias(order)!
	mut legacy_view := []BigInt{len: 7, init: big_zero()}
	for position in 1 .. 7 {
		legacy_view[position] = patch.bowl_by_legacy_position(bowls, bowl_alias, position)!
	}
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_pours(i, drop, stones, legacy_view, order)
}

pub fn (_ BaseDispatcher) dispatch_pours_patch09(i int, drop BigInt, stones Stones, bowls []BigInt, order []int) ![]BigInt {
	patch := PourPatch09{}
	return patch.pour(i, drop, stones, bowls, order)
}
