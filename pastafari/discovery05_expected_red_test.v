module pastafari

// ደረጃ 10፦ አካላዊ ሰልፍ ሳይተረጎም ሎጂክ hidden k በትክክል አይመለስም።
// እነዚህ አራት RED የሚሆኑ ፈተናዎች ለPATCH 05 ይቀራሉ።
fn test_discovery05_expected_red_nearest_hidden_one() {
	foundation := big_from_i64(-15_055_671)
	counts := hidden_counts_spaghetti(foundation, foundation)
	stones := get_stone_table_through_legacy_builder()
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert big_eq(calendar_hidden_by_nearness(hidden, 1), make_hidden_drop_spaghetti(1, counts, stones))
}

fn test_discovery05_expected_red_hidden_two() {
	foundation := big_from_i64(-15_055_671)
	counts := hidden_counts_spaghetti(foundation, foundation)
	stones := get_stone_table_through_legacy_builder()
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert big_eq(calendar_hidden_by_nearness(hidden, 2), make_hidden_drop_spaghetti(2, counts, stones))
}

fn test_discovery05_expected_red_hidden_three() {
	foundation := big_from_i64(-15_055_671)
	counts := hidden_counts_spaghetti(foundation, foundation)
	stones := get_stone_table_through_legacy_builder()
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert big_eq(calendar_hidden_by_nearness(hidden, 3), make_hidden_drop_spaghetti(3, counts, stones))
}

fn test_discovery05_expected_red_farthest_hidden_seven() {
	foundation := big_from_i64(-15_055_671)
	counts := hidden_counts_spaghetti(foundation, foundation)
	stones := get_stone_table_through_legacy_builder()
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert big_eq(calendar_hidden_by_nearness(hidden, 7), make_hidden_drop_spaghetti(7, counts, stones))
}

fn test_discovery05_control_middle_hidden_four() {
	foundation := big_from_i64(-15_055_671)
	counts := hidden_counts_spaghetti(foundation, foundation)
	stones := get_stone_table_through_legacy_builder()
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert big_eq(calendar_hidden_by_nearness(hidden, 4), make_hidden_drop_spaghetti(4, counts, stones))
}

fn test_discovery05_control_all_seven_hidden_drops_are_present() {
	foundation := big_from_i64(-15_055_671)
	counts := hidden_counts_spaghetti(foundation, foundation)
	stones := get_stone_table_through_legacy_builder()
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert hidden.len == 7
	for k in 1 .. 8 {
		mut seen := false
		needle := make_hidden_drop_spaghetti(k, counts, stones)
		for entry in hidden {
			if big_eq(entry, needle) {
				seen = true
			}
		}
		assert seen
	}
}

fn test_discovery05_control_previous_snapshot_patch() {
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
}
