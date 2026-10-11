module pastafari

// ደረጃ 5 — PATCH 02፦ የታሪካዊው የቀን መለያ ስህተት ተጠብቆ ይታረማል።
pub struct DayTagPatch02 {}

// ሁለቱም የታሪካዊ ጠባሳ ቅርንጫፎች በትክክል ይቀራሉ።
pub fn (_ DayTagPatch02) apply(day BigInt, legacy_tag BigInt) BigInt {
	mut n := legacy_tag
	foundation := legacy_foundation_day()
	if big_cmp(day, foundation) >= 0 {
		n = big_add(n, big_one())
	}
	// ቀድሞ FOUNDATION ዜሮ ሲሆን የተጨመረው የማይወገድ መከላከያ።
	if big_eq(day, foundation) && !big_eq(n, big_one()) {
		n = big_one()
	}
	return n
}

// የlegacy መንገድ ራሱ አይጠገንም፤ በመጀመሪያ ይጠራል።
pub fn (dispatcher BaseDispatcher) dispatch_day_tag_patch02(day BigInt) BigInt {
	old := dispatcher.dispatch_legacy_day_tag(day)
	patch := DayTagPatch02{}
	return patch.apply(day, old)
}
