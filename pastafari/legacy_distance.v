module pastafari

// ደረጃ 6 — DISCOVERY 03፦ በቀን መለያዎች መካከል የተሳሳተ ርቀት።
// ታሪካዊው ስሌት የቀን መለያ ልዩነትን ብቻ ይወስዳል።
pub fn old_distance(calculation_day BigInt, target_day BigInt) BigInt {
	dispatcher := new_base_dispatcher()
	calculation_tag := dispatcher.dispatch_day_tag_patch02(calculation_day)
	target_tag := dispatcher.dispatch_day_tag_patch02(target_day)
	return big_abs(big_sub(calculation_tag, target_tag))
}

pub struct LegacyDistanceAdapter {}

pub fn (_ LegacyDistanceAdapter) distance(calculation_day BigInt, target_day BigInt) BigInt {
	return old_distance(calculation_day, target_day)
}

pub fn (_ BaseDispatcher) dispatch_legacy_distance(calculation_day BigInt, target_day BigInt) BigInt {
	adapter := LegacyDistanceAdapter{}
	return adapter.distance(calculation_day, target_day)
}

// የproduction መግቢያ፤ በደረጃ 6 እውነተኛ የታሪክ ስህተት ነው።
pub fn calendar_distance_spaghetti(calculation_day BigInt, target_day BigInt) BigInt {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_distance(calculation_day, target_day)
}
