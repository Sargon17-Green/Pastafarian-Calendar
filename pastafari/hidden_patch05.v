module pastafari

// ደረጃ 11 — PATCH 05፦ ሰባቱ ጠብታዎች በተገላቢጦሽ እንደነበሩ ይቀራሉ።
pub struct HiddenPatch05 {}

// ሎጂካዊ k በ1..7 ነው። ታሪካዊው ሰንጠረዥ በ1-መሠረት 8-k
// ይጠቀማል፤ በV ዜሮ-መሠረት የarray ማውጫው 7-k ነው።
pub fn (_ HiddenPatch05) by_nearness(backward []BigInt, k int) BigInt {
	return backward[7 - k]
}

// የታሪካዊው old_hidden_slot አልተቀየረም፤ የproduction ጥሪ ተለየ።
pub fn (_ BaseDispatcher) dispatch_hidden_patch05(backward []BigInt, k int) BigInt {
	patch := HiddenPatch05{}
	return patch.by_nearness(backward, k)
}
