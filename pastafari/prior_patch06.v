module pastafari

// ደረጃ 13 — PATCH 06፦ የታሪካዊውን ጥሪ ሳይሰርዝ ስውር ቀዳሚዎችን ያነባል።
pub struct PriorPatch06 {}

// በpositive slot ላይ የታሪክ መስመር በእውነት ይጠራል።
// slot=0 → hidden1፣ slot=-1 → hidden2፣ ...፣ slot=-6 → hidden7።
pub fn (_ PriorPatch06) prior(drop_store []BigInt, hidden []BigInt, i int, back int) !BigInt {
	slot := i - back
	if slot >= 1 {
		dispatcher := new_base_dispatcher()
		return dispatcher.dispatch_legacy_prior(drop_store, i, back)
	}
	hidden_k := 1 - slot
	if hidden_k < 1 || hidden_k > 7 || hidden.len != 7 {
		return error('የስውር ጠብታዎች ትክክለኛ ሰልፍ አልተገኘም')
	}
	return calendar_hidden_by_nearness(hidden, hidden_k)
}

// የproduction dispatcher በተለየ wrapper የlegacy ሂደትን ይጠብቃል።
pub fn (_ BaseDispatcher) dispatch_prior_patch06(drop_store []BigInt, hidden []BigInt, i int, back int) !BigInt {
	patch := PriorPatch06{}
	return patch.prior(drop_store, hidden, i, back)
}
