module pastafari

// ደረጃ 8 — DISCOVERY 04፤ አምስቱ ድንጋዮች በተከታታይ ይቀየራሉ።
pub struct Stones {
pub mut:
	w BigInt
	b BigInt
	s BigInt
	m BigInt
	r BigInt
}

// የታሪካዊ የመጀመሪያ አምስት ድንጋዮች።
pub fn initial_stones() Stones {
	return Stones{
		w: big_from_int(17)
		b: big_from_int(29)
		s: big_from_int(43)
		m: big_from_int(71)
		r: big_from_int(101)
	}
}

// የBigInt የውስጥ ቁጥር ክፍሎች ባለቤትነትን እንለያለን።
pub fn (stones Stones) deep_clone() Stones {
	return Stones{
		w: big_add(stones.w, big_zero())
		b: big_add(stones.b, big_zero())
		s: big_add(stones.s, big_zero())
		m: big_add(stones.m, big_zero())
		r: big_add(stones.r, big_zero())
	}
}

// የታሪካዊው ስህተት፦ እያንዳንዱ ሂሳብ ቀድሞ የተቀየረ ድንጋይ ያነባል።
// በደረጃ 8 ይህ የlegacy መንገድ ሆን ተብሎ አይጠገንም።
pub fn mutate_stones_wrong(i int, mut stones Stones) Stones {
	w_term := big_add(big_square(stones.w), big_mul_small(stones.b, 3))
	stones.w = calendar_save_spaghetti(big_add(w_term, big_from_int(i)))

	b_term := big_add(big_square(stones.b), big_mul_small(stones.s, 5))
	stones.b = calendar_save_spaghetti(big_add(b_term, stones.w))

	s_term := big_add(big_square(stones.s), big_mul_small(stones.m, 7))
	stones.s = calendar_save_spaghetti(big_add(s_term, stones.b))

	m_term := big_add(big_square(stones.m), big_mul_small(stones.r, 11))
	stones.m = calendar_save_spaghetti(big_add(m_term, stones.s))

	r_term := big_add(big_square(stones.r), big_mul_small(stones.w, 13))
	stones.r = calendar_save_spaghetti(big_add(r_term, stones.m))
	return stones
}

pub struct LegacyStonesAdapter {}

pub fn (_ LegacyStonesAdapter) mutate(i int, stones Stones) Stones {
	mut copy := stones.deep_clone()
	return mutate_stones_wrong(i, mut copy)
}

pub fn (_ BaseDispatcher) dispatch_legacy_stones(i int, stones Stones) Stones {
	adapter := LegacyStonesAdapter{}
	return adapter.mutate(i, stones)
}

// የproduction ንዑስ መግቢያ፤ ገና PATCH 04 አይጠቀምም።
pub fn calendar_stones_spaghetti(i int, stones Stones) Stones {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_stones(i, stones)
}

// የታሪካዊው ገንቢ የ1..46 ሰንጠረዥ በlegacy መንገድ ያዘጋጃል።
pub fn get_legacy_stone_table() []Stones {
	dispatcher := new_base_dispatcher()
	mut previous := initial_stones()
	mut table := []Stones{cap: 46}
	table << previous.deep_clone()
	for i in 2 .. 47 {
		previous = dispatcher.dispatch_legacy_stones(i, previous)
		table << previous.deep_clone()
	}
	return table
}
