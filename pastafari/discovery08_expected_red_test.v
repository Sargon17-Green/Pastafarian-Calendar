module pastafari

// ደረጃ 16፦ one-based የቅደም ተከተል ቁጥር ወደ rank0 ሳይቀየር ይላካል።
// እነዚህ 4 assertions በደረጃ 16 RED፣ በPATCH 08 ደረጃ 17 GREEN ይሆናሉ።
fn test_discovery08_expected_red_first_permutation() {
	actual := calendar_bowl_order_spaghetti(big_one()) or { []int{} }
	assert actual == [1, 2, 3, 4, 5, 6]
}

fn test_discovery08_expected_red_second_permutation() {
	actual := calendar_bowl_order_spaghetti(big_from_int(2)) or { []int{} }
	assert actual == [1, 2, 3, 4, 6, 5]
}

fn test_discovery08_expected_red_last_permutation() {
	actual := calendar_bowl_order_spaghetti(big_from_int(719)) or { []int{} }
	assert actual == [6, 5, 4, 3, 1, 2]
}

fn test_discovery08_expected_red_wrap_from_720() {
	actual := calendar_bowl_order_spaghetti(big_from_int(720)) or { []int{} }
	assert actual == [6, 5, 4, 3, 2, 1]
}

fn test_discovery08_control_unrank_zero_is_correct() {
	assert (old_permutation_unrank0(0) or { []int{} }) == [1, 2, 3, 4, 5, 6]
}

fn test_discovery08_control_unrank_last_is_correct() {
	assert (old_permutation_unrank0(719) or { []int{} }) == [6, 5, 4, 3, 2, 1]
}

fn test_discovery08_control_grind_and_hidden_remain_correct() {
	foundation := big_from_i64(-15_055_671)
	assert (calendar_grind_row_spaghetti(11) or { []int{} }) == [37, 41, 43, 47, 1]
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_hidden_by_nearness(calendar_hidden_spaghetti(foundation, foundation),
		1).str() == '119390830530032782664128530203002080344'
}
