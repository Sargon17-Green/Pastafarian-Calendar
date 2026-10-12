module pastafari

// ደረጃ 14፦ ሎጂካዊ የወፍጮ ቁጥር 1..11 የትክክለኛውን ረድፍ ይፈልጋል።
// አራቱ ፈተናዎች እስከ ደረጃ 15 PATCH 07 በሆን ተብሎ RED ናቸው።
fn test_discovery07_expected_red_first_grind_row() {
	row := calendar_grind_row_spaghetti(1) or { []int{} }
	assert row == [3, 5, 7, 11, 1]
}

fn test_discovery07_expected_red_second_grind_row() {
	row := calendar_grind_row_spaghetti(2) or { []int{} }
	assert row == [5, 7, 11, 13, 2]
}

fn test_discovery07_expected_red_tenth_grind_row() {
	row := calendar_grind_row_spaghetti(10) or { []int{} }
	assert row == [31, 37, 41, 43, 5]
}

fn test_discovery07_expected_red_eleventh_grind_row() {
	row := calendar_grind_row_spaghetti(11) or { []int{} }
	assert row == [37, 41, 43, 47, 1]
}

fn test_discovery07_control_legacy_zero_slot_still_first() {
	assert (old_grind_row(0) or { []int{} }) == [3, 5, 7, 11, 1]
}

fn test_discovery07_control_legacy_ten_is_last_row() {
	assert (old_grind_row(10) or { []int{} }) == [37, 41, 43, 47, 1]
}

fn test_discovery07_control_legacy_eleven_still_errors() {
	mut rejected := false
	_ = old_grind_row(11) or {
		rejected = true
		[]int{}
	}
	assert rejected
}

fn test_discovery07_control_all_previous_patches() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
}
