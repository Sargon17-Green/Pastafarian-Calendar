module pastafari

// ደረጃ 3 — PATCH 01። የታሪካዊው ቀሪ መንገድ አይለወጥም።
pub struct SavePatch01 {}

pub fn (_ SavePatch01) apply(legacy_remainder BigInt) BigInt {
	if legacy_remainder.is_zero() {
		return legacy_m_old()
	}
	return legacy_remainder
}

// መጠገኛው ከታሪካዊው adapter በኋላ እንጂ በውስጡ አይሠራም።
pub fn (dispatcher BaseDispatcher) dispatch_save_patch01(x BigInt) BigInt {
	raw := dispatcher.dispatch_legacy_save(x)
	patch := SavePatch01{}
	return patch.apply(raw)
}
