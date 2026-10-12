module pastafari

// ደረጃ 12 — DISCOVERY 06፦ ታሪካዊው የhistory ንባብ ስውር ጠብታን አያውቅም።

// የሚታዩ ጠብታዎች በ1-መሠረት ተመዝግበዋል።
// በV አካላዊ index 0 የታሪክ ማስቀመጫ sentinel ብቻ ነው።
pub fn new_legacy_visible_drop_store() []BigInt {
	return [big_zero()]
}

// የታሪክ ስህተት፦ i-back ብቻ ከሚታዩ ጠብታዎች ይነበባል።
// በV የሌለ ወይም አሉታዊ index ሂደቱን እንዳያቋርጥ
// error ይመለሳል፤ ከhidden ምንም አይነበብም።
pub fn legacy_prior(drop_store []BigInt, i int, back int) !BigInt {
	slot := i - back
	if slot < 1 || slot >= drop_store.len {
		return error('የታሪካዊው የጠብታ ማከማቻ ኢንዴክስ የለም')
	}
	return drop_store[slot]
}

pub struct LegacyPriorAdapter {}

pub fn (_ LegacyPriorAdapter) prior(drop_store []BigInt, i int, back int) !BigInt {
	return legacy_prior(drop_store, i, back)
}

pub fn (_ BaseDispatcher) dispatch_legacy_prior(drop_store []BigInt, i int, back int) !BigInt {
	adapter := LegacyPriorAdapter{}
	return adapter.prior(drop_store, i, back)
}

// ደረጃ 13፦ የproduction ጥሪ አሁን PATCH 06 ያልፋል።
pub fn calendar_prior_spaghetti(drop_store []BigInt, hidden []BigInt, i int, back int) !BigInt {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_prior_patch06(drop_store, hidden, i, back)
}
