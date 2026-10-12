module pastafari

// ደረጃ 20፦ አራቱ የቀድሞ አንድ-ጊዜ የቦውል ማንበቢያ መስፈርቶች።
// በDISCOVERY 10 እነዚህ ሆን ብለው RED ናቸው፤ በPATCH 10 ብቻ GREEN ይሆናሉ።
fn discovery10_red_fixture(order []int) []BigInt {
	bowls := [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
	drop := big_from_int(2)
	stones := initial_stones()
	pours := calendar_pours_spaghetti(1, drop, stones, bowls, order) or { []BigInt{} }
	return calendar_stir_bowls_spaghetti(1, drop, stones, bowls, order, pours) or {
		[]BigInt{}
	}
}

fn test_discovery10_expected_red_identity_second_bowl_snapshot() {
	actual := discovery10_red_fixture([1, 2, 3, 4, 5, 6])
	assert actual[2].str() == '564002'
}

fn test_discovery10_expected_red_identity_last_bowl_snapshot() {
	actual := discovery10_red_fixture([1, 2, 3, 4, 5, 6])
	assert actual[6].str() == '46187'
}

fn test_discovery10_expected_red_reversed_fifth_bowl_snapshot() {
	actual := discovery10_red_fixture([6, 5, 4, 3, 2, 1])
	assert actual[5].str() == '3180402'
}

fn test_discovery10_expected_red_rotated_third_bowl_snapshot() {
	actual := discovery10_red_fixture([2, 3, 1, 4, 5, 6])
	assert actual[3].str() == '1021102'
}

fn test_discovery10_control_first_bowl_uncontaminated() {
	actual := discovery10_red_fixture([1, 2, 3, 4, 5, 6])
	assert actual[1].str() == '154997'
}

fn test_discovery10_control_reversed_first_position_uncontaminated() {
	actual := discovery10_red_fixture([6, 5, 4, 3, 2, 1])
	assert actual[6].str() == '1630677'
}

fn test_discovery10_control_previous_patch09_pours_correct() {
	bowls := [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(), bowls,
		[6, 5, 4, 3, 2, 1]) or { []BigInt{} }
	assert pours[1].str() == '1027'
	assert pours[2].str() == '1459'
	assert pours[3].str() == '1731'
}
