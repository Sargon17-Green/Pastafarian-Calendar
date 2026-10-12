module pastafari

fn discovery09_red_fixture_bowls() []BigInt {
	return [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
}

// ደረጃ 18፦ ማፍሰሻ 1..3 ከorder ውስጥ የየቦታውን የጎድጓዳ ሳህን ID ማንበብ አለበት።
// የሚከተሉት 4 assertions በDISCOVERY 09 RED በPATCH 09 GREEN መሆን አለባቸው።
fn test_discovery09_expected_red_first_pour_reversed_order() {
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(),
		discovery09_red_fixture_bowls(), [6, 5, 4, 3, 2, 1]) or { []BigInt{} }
	assert pours[1].str() == '1027'
}

fn test_discovery09_expected_red_second_pour_reversed_order() {
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(),
		discovery09_red_fixture_bowls(), [6, 5, 4, 3, 2, 1]) or { []BigInt{} }
	assert pours[2].str() == '1459'
}

fn test_discovery09_expected_red_third_pour_reversed_order() {
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(),
		discovery09_red_fixture_bowls(), [6, 5, 4, 3, 2, 1]) or { []BigInt{} }
	assert pours[3].str() == '1731'
}

fn test_discovery09_expected_red_first_pour_rotated_order() {
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(),
		discovery09_red_fixture_bowls(), [2, 3, 1, 4, 5, 6]) or { []BigInt{} }
	assert pours[1].str() == '347'
}

fn test_discovery09_control_identity_order_matches_first_three_pours() {
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(),
		discovery09_red_fixture_bowls(), [1, 2, 3, 4, 5, 6]) or { []BigInt{} }
	assert pours[1].str() == '177'
	assert pours[2].str() == '589'
	assert pours[3].str() == '1301'
}

fn test_discovery09_control_positions_four_to_six_have_zero_pour() {
	pours := calendar_pours_spaghetti(1, big_from_int(2), initial_stones(),
		discovery09_red_fixture_bowls(), [6, 5, 4, 3, 2, 1]) or { []BigInt{} }
	for position in 4 .. 7 {
		assert pours[position].str() == '0'
	}
}

fn test_discovery09_control_previous_permutation_patch() {
	assert (calendar_bowl_order_spaghetti(big_from_int(720)) or { []int{} }) == [6, 5, 4, 3, 2,
		1]
}
