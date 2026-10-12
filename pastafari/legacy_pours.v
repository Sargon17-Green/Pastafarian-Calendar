module pastafari

// ደረጃ 18 — DISCOVERY 09፦ የታሪክ ማፍሰሻ ቅደም ተከተሉን ይዘነጋል።
// ስድስቱ ጎድጓዳ ሳህኖች በቋሚ ID 1..6 ይመዘገባሉ።
// የV index 0 አካላዊ መያዣ ብቻ ነው።
pub fn calendar_initial_bowls_spaghetti(counts HiddenCounts) []BigInt {
	primes := [17, 19, 23, 29, 31, 37]
	mut bowls := []BigInt{len: 7, init: big_zero()}
	for bowl_id in 1 .. 7 {
		mut sum := big_add(counts.action, big_mul_small(counts.target, u32(bowl_id)))
		sum = big_add(sum, counts.distance)
		sum = big_add(sum, counts.connection)
		sum = big_add(sum, big_from_int(counts.direction))
		sum = big_add(sum, big_from_int(primes[bowl_id - 1] * primes[bowl_id - 1]))
		bowls[bowl_id] = calendar_save_spaghetti(big_add(big_square(sum), big_from_int(bowl_id)))
	}
	return bowls
}

fn legacy_validate_pour_inputs(i int, bowls []BigInt, order []int) ! {
	if i < 1 || i > 46 || bowls.len != 7 || order.len != 6 {
		return error('የማፍሰሻ ዙር ወይም የጎድጓዳ ሳህን ብዛት አይስማማም')
	}
	mut found := []bool{len: 7}
	for bowl_id in order {
		if bowl_id < 1 || bowl_id > 6 || found[bowl_id] {
			return error('የማፍሰሻ ቅደም ተከተል ስድስቱን ID አንድ ጊዜ መያዝ አለበት')
		}
		found[bowl_id] = true
	}
}

// የታሪክ ጉድለት፦ በorder ውስጥ ያሉትን የቦታ መለያዎች አይጠቀምም።
// ማፍሰሻ 1፣ 2፣ 3 ከቋሚ bowls[1]፣ bowls[2]፣ bowls[3] ያነባል።
pub fn old_pours_fixed_bowls(i int, drop BigInt, stones Stones, bowls []BigInt, order []int) ![]BigInt {
	legacy_validate_pour_inputs(i, bowls, order)!
	mut pours := []BigInt{len: 7, init: big_zero()}
	drop_squared := big_square(drop)
	first := big_add(drop_squared, big_mul(stones.w, bowls[1]))
	second := big_add(drop_squared, big_mul(stones.b, bowls[2]))
	third := big_add(drop_squared, big_mul(stones.s, bowls[3]))
	pours[1] = calendar_save_spaghetti(big_add(first, big_from_int(3 * i)))
	pours[2] = calendar_save_spaghetti(big_add(second, big_from_int(5 * i)))
	pours[3] = calendar_save_spaghetti(big_add(third, big_from_int(7 * i)))
	return pours
}

pub struct LegacyPourAdapter {}

pub fn (_ LegacyPourAdapter) pour(i int, drop BigInt, stones Stones, bowls []BigInt, order []int) ![]BigInt {
	return old_pours_fixed_bowls(i, drop, stones, bowls, order)
}

pub fn (_ BaseDispatcher) dispatch_legacy_pours(i int, drop BigInt, stones Stones, bowls []BigInt, order []int) ![]BigInt {
	adapter := LegacyPourAdapter{}
	return adapter.pour(i, drop, stones, bowls, order)
}

// ደረጃ 19፦ የproduction ማፍሰሻዎች በPATCH 09 የቦታ-ID መተርጎሚያ ያልፋሉ።
pub fn calendar_pours_spaghetti(i int, drop BigInt, stones Stones, bowls []BigInt, order []int) ![]BigInt {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_pours_patch09(i, drop, stones, bowls, order)
}
