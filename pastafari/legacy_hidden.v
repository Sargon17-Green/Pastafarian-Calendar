module pastafari

// ደረጃ 10 — DISCOVERY 05፦ ሰባቱ ስውር ጠብታዎች በተገላቢጦሽ ተከማችተዋል።
pub struct HiddenCounts {
pub:
	action BigInt
	target BigInt
	distance BigInt
	connection BigInt
	direction int
}

// ከተጠገኑት ቀን-ቆጣሪዎች ብቻ የሚመጣ የሥራ ሁኔታ።
pub fn hidden_counts_spaghetti(calculation_day BigInt, target_day BigInt) HiddenCounts {
	action := calendar_day_tag_spaghetti(calculation_day)
	target := calendar_day_tag_spaghetti(target_day)
	distance := calendar_distance_spaghetti(calculation_day, target_day)
	direction := if big_cmp(target_day, calculation_day) < 0 {
		1
	} else if big_cmp(target_day, calculation_day) == 0 {
		2
	} else {
		3
	}
	return HiddenCounts{
		action: action
		target: target
		distance: distance
		connection: big_add(action, target)
		direction: direction
	}
}

// የታሪካዊው ሰንጠረዥ ከሩቅ ወደ ቅርብ ተመዝግቧል።
pub fn legacy_hidden_coefficients_reversed() [][]int {
	return [
		[15, 22, 30, 32],
		[13, 19, 26, 28],
		[11, 16, 22, 24],
		[9, 13, 18, 20],
		[7, 10, 14, 16],
		[5, 7, 10, 12],
		[3, 4, 6, 8],
	]
}

fn hidden_coefficients_for_k(k int) []int {
	reversed := legacy_hidden_coefficients_reversed()
	return reversed[7 - k]
}

fn hidden_stone_component(stone Stones, kind int) BigInt {
	return match kind {
		1 { stone.w }
		2 { stone.b }
		3 { stone.s }
		4 { stone.m }
		5 { stone.r }
		else { big_zero() }
	}
}

// ስውር ጠብታ k በቅርበት ትርጉም ትክክለኛ ነው፤ ስህተቱ በአካላዊ ማከማቻው ነው።
pub fn make_hidden_drop_spaghetti(k int, counts HiddenCounts, stones []Stones) BigInt {
	coeff := hidden_coefficients_for_k(k)
	stone := stones[k - 1]
	mut x := big_add(counts.action, big_mul_small(counts.target, u32(coeff[0])))
	x = big_add(x, big_mul_small(counts.distance, u32(coeff[1])))
	x = big_add(x, big_mul_small(counts.connection, u32(coeff[2])))
	x = big_add(x, big_mul_small(big_from_int(counts.direction), u32(coeff[3])))
	for kind in 1 .. 6 {
		x = big_add(x, hidden_stone_component(stone, kind))
	}
	x = calendar_save_spaghetti(x)
	grind_stone_kinds := [1, 2, 3, 4, 5, 1, 2]
	for grind in 1 .. 8 {
		old_x := x
		mut mixed := big_square(old_x)
		mixed = big_add(mixed, big_mul_small(old_x, 3))
		mixed = big_add(mixed, hidden_stone_component(stone, grind_stone_kinds[grind - 1]))
		x = calendar_save_spaghetti(big_add(mixed, big_from_int(grind)))
	}
	return x
}

// አካላዊ ሰልፍ 1 = hidden7፣ አካላዊ ሰልፍ 7 = hidden1።
// ደረጃ 10 ውስጥ ማከማቻውን አንቀይርም፣ የPATCH 05 መተርጎሚያም አንጨምርም።
pub fn build_hidden_with_backward_storage(counts HiddenCounts, stones []Stones) []BigInt {
	mut backward := []BigInt{len: 7}
	for k in 1 .. 8 {
		backward[7 - k] = make_hidden_drop_spaghetti(k, counts, stones)
	}
	return backward
}

// የታሪካዊው የተሳሳተ ንባብ፦ የሎጂክ hidden k በአካላዊ k ይነበባል።
pub fn old_hidden_slot(backward []BigInt, k int) BigInt {
	return backward[k - 1]
}


// ደረጃ 10፦ የproduction የንባብ መግቢያም ገና የቀድሞውን ስህተት ይጠቀማል።
pub fn calendar_hidden_by_nearness(backward []BigInt, k int) BigInt {
	return old_hidden_slot(backward, k)
}

pub struct LegacyHiddenAdapter {}

pub fn (_ LegacyHiddenAdapter) build(counts HiddenCounts, stones []Stones) []BigInt {
	return build_hidden_with_backward_storage(counts, stones)
}

pub fn (_ BaseDispatcher) dispatch_legacy_hidden(counts HiddenCounts, stones []Stones) []BigInt {
	adapter := LegacyHiddenAdapter{}
	return adapter.build(counts, stones)
}

// የproduction መግቢያ፤ ገና ማንኛውንም የPATCH 05 መተርጎሚያ አያውቅም።
pub fn calendar_hidden_spaghetti(calculation_day BigInt, target_day BigInt) []BigInt {
	counts := hidden_counts_spaghetti(calculation_day, target_day)
	stones := get_stone_table_through_legacy_builder()
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_hidden(counts, stones)
}
