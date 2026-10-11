module pastafari

// ደረጃ 9 — PATCH 04፦ ምንጭ ድንጋዮች ከአንድ snapshot ይነበባሉ።
pub struct StonePatch04 {}

// የlegacy ጥሪው አይሰረዝም፤ ውጤቱ በአምስት የተስተካከሉ እሴቶች ይተካል።
pub fn (_ StonePatch04) apply(i int, stones Stones) Stones {
	old := stones.deep_clone()
	mut garbage := stones.deep_clone()
	_ = mutate_stones_wrong(i, mut garbage)

	w_term := big_add(big_square(old.w), big_mul_small(old.b, 3))
	garbage.w = calendar_save_spaghetti(big_add(w_term, big_from_int(i)))

	b_term := big_add(big_square(old.b), big_mul_small(old.s, 5))
	garbage.b = calendar_save_spaghetti(big_add(b_term, old.w))

	s_term := big_add(big_square(old.s), big_mul_small(old.m, 7))
	garbage.s = calendar_save_spaghetti(big_add(s_term, old.b))

	m_term := big_add(big_square(old.m), big_mul_small(old.r, 11))
	garbage.m = calendar_save_spaghetti(big_add(m_term, old.s))

	r_term := big_add(big_square(old.r), big_mul_small(old.w, 13))
	garbage.r = calendar_save_spaghetti(big_add(r_term, old.m))
	return garbage
}

// እውነተኛው የlegacy ግቤት ከdispatcher ይለያል፤ አሮጌው መንገድ ይኖራል።
pub fn (_ BaseDispatcher) dispatch_stones_patch04(i int, stones Stones) Stones {
	patch := StonePatch04{}
	return patch.apply(i, stones)
}

// የ1..46 ድንጋይ ጠረጴዛ በታሪካዊ ገንቢ ቅርጽ ውስጥ ተጠግኗል።
pub fn get_stone_table_through_legacy_builder() []Stones {
	mut previous := initial_stones()
	mut table := []Stones{cap: 46}
	table << previous.deep_clone()
	for i in 2 .. 47 {
		previous = calendar_stones_spaghetti(i, previous)
		table << previous.deep_clone()
	}
	return table
}
