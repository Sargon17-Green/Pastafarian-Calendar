module pastafari

// ደረጃ 16 — DISCOVERY 08፦ ስድስት ጎድጓዳ ሳህኖች 720 ትዕዛዞች አላቸው።
// የታሪካዊው የቅደም ተከተል መፍቻ ራሱ ትክክለኛ ዜሮ-መሠረት ሒሳብ ነው።
fn legacy_permutation_factorial(n int) int {
	mut value := 1
	for i in 2 .. n + 1 {
		value *= i
	}
	return value
}

// የታሪክ መፍቻውን አንሰርዝም፤ የሚቀበለው rank0 ከ0 እስከ719 ነው።
pub fn old_permutation_unrank0(rank0 int) ![]int {
	if rank0 < 0 || rank0 >= 720 {
		return error('የታሪካዊው የቅደም ተከተል ደረጃ ከ0 እስከ719 መሆን አለበት')
	}
	mut rank := rank0
	mut available := [1, 2, 3, 4, 5, 6]
	mut order := []int{cap: 6}
	for places := 6; places > 0; places-- {
		block := legacy_permutation_factorial(places - 1)
		choice := rank / block
		rank %= block
		order << available[choice]
		available.delete(choice)
	}
	return order
}

pub struct LegacyPermutationAdapter {}

// የተሳሳተው ታሪካዊ አገናኝ፦ oneBased ወደ rank0 በቀጥታ ይተላለፋል።
// እውነተኛው የrank0 መፍቻ አይበላሽም፤ ጉድለቱ በጥሪው ላይ ነው።
pub fn (_ LegacyPermutationAdapter) order_for_drop(drop BigInt) ![]int {
	one_based := int(big_mod_small_nonnegative(big_sub(drop, big_one()), 720)) + 1
	return old_permutation_unrank0(one_based)
}

pub fn (_ BaseDispatcher) dispatch_legacy_permutation(drop BigInt) ![]int {
	adapter := LegacyPermutationAdapter{}
	return adapter.order_for_drop(drop)
}

// ደረጃ 17፦ የproduction ጥሪ PATCH 08 ያልፋል፤ የታሪክ adapter ይቀራል።
pub fn calendar_bowl_order_spaghetti(drop BigInt) ![]int {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_permutation_patch08(drop)
}
