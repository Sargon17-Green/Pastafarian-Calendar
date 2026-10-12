module pastafari

// ደረጃ 26፦ የታሪክ modulo bias ስህተት በPATCH 13 ላይም ይጠበቃል።
pub fn old_biased_pick(x BigInt, n BigInt) !BigInt {
	m := legacy_m_old()
	if big_cmp(x, big_one()) < 0 || big_cmp(x, m) > 0 || big_cmp(n, big_one()) < 0
		|| big_cmp(n, m) > 0 {
		return error('የታሪክ አጭር ምርጫ፦ x እና n ከ1 እስከ M መሆን አለባቸው')
	}
	return big_add(big_one(), big_regular_mod(big_sub(x, big_one()), n))
}

pub struct LegacyBiasedPickAdapter {}

pub fn (_ LegacyBiasedPickAdapter) pick(x BigInt, n BigInt) !BigInt {
	return old_biased_pick(x, n)
}

pub fn (_ BaseDispatcher) dispatch_legacy_biased_pick(x BigInt, n BigInt) !BigInt {
	adapter := LegacyBiasedPickAdapter{}
	return adapter.pick(x, n)
}
