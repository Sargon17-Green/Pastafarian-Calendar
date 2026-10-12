module pastafari

// ደረጃ 21 — PATCH 10፦ አሮጌው የin-place መስመር አይሰረዝም።
// የታሪክ ሂደት በተለየ የሙከራ መያዣ ውስጥ ይጠራል፤ ውጤቱ አይመለስም።
pub struct BowlStirPatch10 {}

// የBigInt የውስጥ መያዣ ሊጋራ ስለሚችል የእያንዳንዱን እሴት ቅጂ እንፈጥራለን።
pub fn (_ BowlStirPatch10) clone_bowls(bowls []BigInt) []BigInt {
	mut clone := []BigInt{len: bowls.len, init: big_zero()}
	for id in 0 .. bowls.len {
		clone[id] = big_add(bowls[id], big_zero())
	}
	return clone
}

// vault_old የቀድሞውን ስድስት ጎድጓዳ ሳህኖች እስከመጨረሻው ይጠብቃል።
// pending ብቻ ይጻፋል፤ ስድስቱ ከተሰሉ በኋላ ነው የጋራ commit የሚደረገው።
pub fn (patch BowlStirPatch10) stir(i int, drop BigInt, stones Stones, bowls []BigInt, order []int, pours []BigInt) ![]BigInt {
	legacy_validate_stir_inputs(i, bowls, order, pours)!
	vault_old := patch.clone_bowls(bowls)
	mut pending := patch.clone_bowls(bowls)
	dispatcher := new_base_dispatcher()

	// የታሪካዊው ጥሪ እንዳለ ይቀራል፤ የተበከለውን ውጤት አንጠቀምም።
	legacy_garbage := dispatcher.dispatch_legacy_bowl_stir(i, drop, stones, vault_old,
		order, pours)!
	if legacy_garbage.len != 7 {
		return error('የታሪክ ምርመራ ሰልፍ የተሳሳተ ብዛት አለው')
	}

	for position in 1 .. 7 {
		id := order[position - 1]
		prev_id := order[(position + 4) % 6]
		next_id := order[position % 6]
		stone := legacy_stir_stone_by_position(stones, position)
		mut sum := big_add(vault_old[id], big_mul_small(vault_old[prev_id], 2))
		sum = big_add(sum, big_mul_small(vault_old[next_id], 3))
		sum = big_add(sum, pours[position])
		sum = big_add(sum, drop)
		sum = big_add(sum, stone)
		cross := big_mul_small(big_mul(vault_old[prev_id], vault_old[next_id]), 5)
		total := big_add(big_add(big_square(sum), cross), big_from_int(i * position))
		pending[id] = calendar_save_spaghetti(total)
	}

	// የመጨረሻው የcommit እርምጃ ብቻ ወደ አዲስ ሰልፍ ይጽፋል።
	mut committed := patch.clone_bowls(vault_old)
	for id in 1 .. 7 {
		committed[id] = big_add(pending[id], big_zero())
	}
	return committed
}

pub fn (_ BaseDispatcher) dispatch_bowl_stir_patch10(i int, drop BigInt, stones Stones, bowls []BigInt, order []int, pours []BigInt) ![]BigInt {
	patch := BowlStirPatch10{}
	return patch.stir(i, drop, stones, bowls, order, pours)
}
