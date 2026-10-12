module pastafari

// ደረጃ 20 — DISCOVERY 10፦ ከአንድ ቀድሞ ሁኔታ ፈንታ የተለወጡ ጎድጓዳ ሳህኖችን ያነባል።
// የlegacy ኮድ በተፈጥሮው በዚያው መያዣ ላይ ይጽፋል፤ የvaultOld/pending መንገድ እዚህ የለም።
pub fn legacy_stir_stone_by_position(stones Stones, position int) BigInt {
	return match position {
		1, 6 { stones.w }
		2 { stones.b }
		3 { stones.s }
		4 { stones.m }
		5 { stones.r }
		else { big_zero() }
	}
}

// በV የሰልፍ ቁጥር 0 ባዶ ነው። order ላይ position 1..6 ብቻ ይፈቀዳል።
fn legacy_validate_stir_inputs(i int, bowls []BigInt, order []int, pours []BigInt) ! {
	legacy_validate_pour_inputs(i, bowls, order)!
	if pours.len != 7 {
		return error('ስድስቱ የማፍሰሻ ቦታዎች እና sentinel መኖር አለባቸው')
	}
}

// ስህተቱ ሆን ተብሎ ይቀራል፦ የቀድሞ ማሰሮ ሁኔታ አይታሸግም።
// ከቦታ 1 በኋላ B[id] ወዲያው ይጻፋል፤ ቀጣዩ ቦታ የተቀየረውን B[prev] ያነባል።
pub fn old_stir_bowls_in_place(i int, drop BigInt, stones Stones, mut bowls []BigInt, order []int, pours []BigInt) ! {
	legacy_validate_stir_inputs(i, bowls, order, pours)!
	for position in 1 .. 7 {
		id := order[position - 1]
		prev_id := order[(position + 4) % 6]
		next_id := order[position % 6]
		stone := legacy_stir_stone_by_position(stones, position)
		mut sum := big_add(bowls[id], big_mul_small(bowls[prev_id], 2))
		sum = big_add(sum, big_mul_small(bowls[next_id], 3))
		sum = big_add(sum, pours[position])
		sum = big_add(sum, drop)
		sum = big_add(sum, stone)
		cross := big_mul_small(big_mul(bowls[prev_id], bowls[next_id]), 5)
		output := big_add(big_add(big_square(sum), cross), big_from_int(i * position))
		bowls[id] = calendar_save_spaghetti(output)
	}
}

// የproduction ጠሪ የጠቋሚ መያዣውን ይለያል፤ ውስጠኛው legacy ግን አሁንም in-place ይሠራል።
pub struct LegacyBowlStirAdapter {}

pub fn (_ LegacyBowlStirAdapter) stir(i int, drop BigInt, stones Stones, bowls []BigInt, order []int, pours []BigInt) ![]BigInt {
	legacy_validate_stir_inputs(i, bowls, order, pours)!
	mut copy := []BigInt{len: 7, init: big_zero()}
	for id in 0 .. 7 {
		copy[id] = big_add(bowls[id], big_zero())
	}
	old_stir_bowls_in_place(i, drop, stones, mut copy, order, pours)!
	return copy
}

pub fn (_ BaseDispatcher) dispatch_legacy_bowl_stir(i int, drop BigInt, stones Stones, bowls []BigInt, order []int, pours []BigInt) ![]BigInt {
	adapter := LegacyBowlStirAdapter{}
	return adapter.stir(i, drop, stones, bowls, order, pours)
}

// ደረጃ 20፦ የህይወት መንገዱ በተፈጥሮው የታሪክ የin-place መንገድ ላይ ይወድቃል።
pub fn calendar_stir_bowls_spaghetti(i int, drop BigInt, stones Stones, bowls []BigInt, order []int, pours []BigInt) ![]BigInt {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_bowl_stir(i, drop, stones, bowls, order, pours)
}
