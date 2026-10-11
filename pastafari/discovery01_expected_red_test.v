module pastafari

// ሆን ተብሎ RED የሚሆን ኖርማቲቭ ንጽጽር።
// ይህንን አለመሳካት በደረጃ 2 አትጠግኑ፤ PATCH 01 ደረጃ 3 ነው።
fn test_discovery01_expected_red_at_m() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert big_eq(calendar_save_spaghetti(m), m)
}

fn test_discovery01_expected_red_at_2m() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert big_eq(calendar_save_spaghetti(big_mul_small(m, 2)), m)
}

fn test_discovery01_expected_red_at_3m() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert big_eq(calendar_save_spaghetti(big_mul_small(m, 3)), m)
}

fn test_discovery01_expected_red_control_m_plus_one() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert calendar_save_spaghetti(big_add(m, big_one())).str() == '1'
}
