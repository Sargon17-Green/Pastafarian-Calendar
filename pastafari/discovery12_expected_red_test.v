module pastafari

// ደረጃ 24 — DISCOVERY 12፦ ትክክለኛው ቀጣይ ጎድጓዳ ሳህን
// በorderAt46Latch ውስጥ ካለው queriedId በኋላ ያለው circular successor ነው።
// አራቱ assertions እስከ PATCH 12 ድረስ ሆን ብለው RED ናቸው።
fn test_discovery12_expected_red_reversed_six_to_five() {
	assert (calendar_next_bowl_spaghetti(6, [6, 5, 4, 3, 2, 1]) or { 0 }) == 5
}

fn test_discovery12_expected_red_reversed_one_to_six() {
	assert (calendar_next_bowl_spaghetti(1, [6, 5, 4, 3, 2, 1]) or { 0 }) == 6
}

fn test_discovery12_expected_red_rotated_three_to_one() {
	assert (calendar_next_bowl_spaghetti(3, [2, 3, 1, 4, 5, 6]) or { 0 }) == 1
}

fn test_discovery12_expected_red_shuffled_one_to_three() {
	assert (calendar_next_bowl_spaghetti(1, [1, 3, 5, 2, 4, 6]) or { 0 }) == 3
}

fn test_discovery12_control_identity_remains_same() {
	assert (calendar_next_bowl_spaghetti(1, [1, 2, 3, 4, 5, 6]) or { 0 }) == 2
	assert (calendar_next_bowl_spaghetti(6, [1, 2, 3, 4, 5, 6]) or { 0 }) == 1
}

fn test_discovery12_control_rotated_two_to_three_remains_same() {
	assert (calendar_next_bowl_spaghetti(2, [2, 3, 1, 4, 5, 6]) or { 0 }) == 3
}

fn test_discovery12_control_previous_latch_keeps_reversed_order() {
	bowls := [big_zero(), big_from_int(10), big_from_int(20),
		big_from_int(30), big_from_int(40), big_from_int(50),
		big_from_int(60)]
	order := [6, 5, 4, 3, 2, 1]
	after := calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
	assert after.order_for_query == order
	assert after.overwrite_count == 12
}
