module pastafari

// ደረጃ 6፦ ኖርማቲቭ የርቀት ሕግ abs(t-c)+1 ነው።
// የቀድሞ ስሌት በሆነ ስህተት የdayTag ልዩነት ይጠቀማል።
fn test_discovery03_expected_red_same_day() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
}

fn test_discovery03_expected_red_two_days_after_foundation() {
	foundation := big_from_i64(-15_055_671)
	after := big_add(foundation, big_from_int(2))
	assert calendar_distance_spaghetti(foundation, after).str() == '3'
}

fn test_discovery03_expected_red_cross_foundation() {
	foundation := big_from_i64(-15_055_671)
	before := big_sub(foundation, big_one())
	after := big_add(foundation, big_one())
	assert calendar_distance_spaghetti(before, after).str() == '3'
}

fn test_discovery03_expected_red_far_cross_foundation() {
	foundation := big_from_i64(-15_055_671)
	delta := big_pow_small(big_from_int(2), 300)
	before := big_sub(foundation, delta)
	after := big_add(foundation, delta)
	expected := big_add(big_mul_small(delta, 2), big_one())
	assert big_eq(calendar_distance_spaghetti(before, after), expected)
}

fn test_discovery03_control_adjacent_after_foundation() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, big_add(foundation, big_one())).str() == '2'
}

fn test_discovery03_control_day_tag_and_save_patches() {
	foundation := big_from_i64(-15_055_671)
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
	assert big_eq(calendar_save_spaghetti(m), m)
}
