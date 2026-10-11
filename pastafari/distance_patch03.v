module pastafari

// ደረጃ 7 — PATCH 03፤ የታሪክ ስህተትን ሳይሰርዝ እውነተኛ ርቀት ይመልሳል።
pub struct DistancePatch03 {}

// የርቀት ጠባሳ፦ የlegacy ውጤትን መጀመሪያ ይቀበላል።
pub fn (_ DistancePatch03) apply(calculation_day BigInt, target_day BigInt, legacy_result BigInt) BigInt {
	mut legacy := legacy_result
	chronological := big_abs(big_sub(target_day, calculation_day))
	if !big_eq(legacy, chronological) {
		legacy = chronological
	}
	return big_add(legacy, big_one())
}

// መጀመሪያ ታሪካዊው adapter በእውነት ይጠራል።
pub fn (dispatcher BaseDispatcher) dispatch_distance_patch03(calculation_day BigInt, target_day BigInt) BigInt {
	legacy := dispatcher.dispatch_legacy_distance(calculation_day, target_day)
	patch := DistancePatch03{}
	return patch.apply(calculation_day, target_day, legacy)
}
