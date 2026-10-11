module pastafari

// ደረጃ 4 — DISCOVERY 02። ይህ የቀን መለያ የታሪካዊ ስህተት ነው።
// FOUNDATION በኋላ የሚያስፈልገው አንድ መጨመር እዚህ የለም።
fn legacy_foundation_day() BigInt {
	return big_from_i64(-15_055_671)
}

pub fn old_day_tag(day BigInt) BigInt {
	delta := big_sub(day, legacy_foundation_day())
	return big_mul_small(big_abs(delta), 2)
}

pub struct LegacyDayTagAdapter {}

pub fn (_ LegacyDayTagAdapter) day_tag(day BigInt) BigInt {
	return old_day_tag(day)
}

pub fn (_ BaseDispatcher) dispatch_legacy_day_tag(day BigInt) BigInt {
	adapter := LegacyDayTagAdapter{}
	return adapter.day_tag(day)
}

// የታሪካዊ ስህተቱን ከproduction dispatcher ያሳያል።
pub fn calendar_day_tag_spaghetti(day BigInt) BigInt {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_day_tag(day)
}
