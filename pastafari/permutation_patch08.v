module pastafari

// ደረጃ 17 — PATCH 08፦ የታሪክ ዜሮ-መሠረት መፍቻ እንደነበረ ይቆያል።
pub struct PermutationPatch08 {}

// ለስድስቱ ጎድጓዳ ሳህኖች oneBased=1..720 በቅድሚያ ይሰላል።
// የlegacy መፍቻ 0..719 ስለሚፈልግ oneBased-1 ብቻ ይላካል።
pub fn (_ PermutationPatch08) legacy_rank0(drop BigInt) int {
	one_based := int(big_mod_small_nonnegative(big_sub(drop, big_one()), 720)) + 1
	return one_based - 1
}

pub fn (patch PermutationPatch08) order_for_drop(drop BigInt) ![]int {
	legacy_rank0 := patch.legacy_rank0(drop)
	return old_permutation_unrank0(legacy_rank0)
}

pub fn (_ BaseDispatcher) dispatch_permutation_patch08(drop BigInt) ![]int {
	patch := PermutationPatch08{}
	return patch.order_for_drop(drop)
}
