module pastafari

// ደረጃ 2 — DISCOVERY 01፦ ይህ በሆነ ስህተት የቀረ ታሪካዊ መንገድ ነው።
// ዜሮን ወደ M የሚቀይር መጠገኛ ይህ ደረጃ ውስጥ አይገኝም።
fn legacy_m_old() BigInt {
	return big_sub(big_pow_small(big_from_int(2), 127), big_one())
}

pub fn old_remainder(x BigInt) BigInt {
	return big_regular_mod(x, legacy_m_old())
}

pub struct LegacyRemainderAdapter {}

pub fn (_ LegacyRemainderAdapter) save(x BigInt) BigInt {
	return old_remainder(x)
}

pub fn (_ BaseDispatcher) dispatch_legacy_save(x BigInt) BigInt {
	adapter := LegacyRemainderAdapter{}
	return adapter.save(x)
}

// በproduction የdispatcher መንገድ የሚገኝ ታሪካዊ SAVE።
pub fn calendar_save_spaghetti(x BigInt) BigInt {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_save(x)
}
