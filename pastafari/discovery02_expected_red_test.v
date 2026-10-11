module pastafari

// እነዚህ የተሟላውን ኖርማቲቭ የቀን መለያ ሕግ ይፈትሻሉ።
// ደረጃ 4 ላይ ሆን ተብሎ RED ናቸው፤ PATCH 02 እስከ ደረጃ 5 አይጨመርም።
fn test_discovery02_expected_red_at_foundation() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
}

fn test_discovery02_expected_red_at_foundation_plus_one() {
	foundation := big_from_i64(-15_055_671)
	day := big_add(foundation, big_one())
	assert calendar_day_tag_spaghetti(day).str() == '3'
}

fn test_discovery02_expected_red_at_foundation_plus_two() {
	foundation := big_from_i64(-15_055_671)
	day := big_add(foundation, big_from_int(2))
	assert calendar_day_tag_spaghetti(day).str() == '5'
}

fn test_discovery02_expected_red_far_future() {
	foundation := big_from_i64(-15_055_671)
	distance := big_pow_small(big_from_int(2), 200)
	day := big_add(foundation, distance)
	expected := big_add(big_mul_small(distance, 2), big_one())
	assert big_eq(calendar_day_tag_spaghetti(day), expected)
}

fn test_discovery02_control_before_foundation() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_day_tag_spaghetti(big_sub(foundation, big_one())).str() == '2'
}

fn test_discovery02_control_previous_patch_stays_green() {
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert big_eq(calendar_save_spaghetti(m), m)
}
