module pastafari

// ደረጃ 22፦ ከ46ኛው ጠብታ የተሰጠው ቅደም ተከተል
// በ12 post-stirs መጨረሻ ለquery እንዳለ መቆየት አለበት።
// አራቱ የሚከተሉት assertions እስከ PATCH 11 ድረስ RED መሆን አለባቸው።
fn discovery11_red_result(order []int) LegacyPostStir12Result {
	bowls := [big_zero(), big_from_int(10), big_from_int(20), big_from_int(30),
		big_from_int(40), big_from_int(50), big_from_int(60)]
	return calendar_post_stir12_spaghetti(bowls, order) or { LegacyPostStir12Result{} }
}

fn test_discovery11_expected_red_identity_drop46_order_survives() {
	got := discovery11_red_result([1, 2, 3, 4, 5, 6])
	assert got.order_for_query == [1, 2, 3, 4, 5, 6]
}

fn test_discovery11_expected_red_reverse_drop46_order_survives() {
	got := discovery11_red_result([6, 5, 4, 3, 2, 1])
	assert got.order_for_query == [6, 5, 4, 3, 2, 1]
}

fn test_discovery11_expected_red_rotated_drop46_order_survives() {
	got := discovery11_red_result([2, 3, 1, 4, 5, 6])
	assert got.order_for_query == [2, 3, 1, 4, 5, 6]
}

fn test_discovery11_expected_red_shuffled_drop46_order_survives() {
	got := discovery11_red_result([1, 3, 5, 2, 4, 6])
	assert got.order_for_query == [1, 3, 5, 2, 4, 6]
}

fn test_discovery11_control_12_post_stirs_still_executed() {
	got := discovery11_red_result([1, 2, 3, 4, 5, 6])
	assert got.overwrite_count == 12
	assert got.final_stir_number == 12
	assert got.bowls[1].str() == '136215324145469545419479201619538607493'
}

fn test_discovery11_control_legacy_last_order_is_predictable() {
	got := discovery11_red_result([6, 5, 4, 3, 2, 1])
	assert got.overwrite_count == 12
	assert got.final_saved_sum.str() == '152983071395321360281688056688813299996'
}

fn test_discovery11_control_original_input_order_is_not_mutated() {
	order := [1, 2, 3, 4, 5, 6]
	_ = discovery11_red_result(order)
	assert order == [1, 2, 3, 4, 5, 6]
}
