module pastafari

// ደረጃ 12፦ የማይታዩ የhistory መውጫዎች በPATCH 06 ብቻ ይጠገናሉ።
// በአሁኑ legacy መንገድ አራት assertions RED መሆን አለባቸው።
fn test_discovery06_expected_red_slot_zero_hidden_one() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	got := calendar_prior_spaghetti(new_legacy_visible_drop_store(), hidden, 1, 1) or { big_zero() }
	assert big_eq(got, calendar_hidden_by_nearness(hidden, 1))
}

fn test_discovery06_expected_red_slot_minus_one_hidden_two() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	got := calendar_prior_spaghetti(new_legacy_visible_drop_store(), hidden, 2, 3) or { big_zero() }
	assert big_eq(got, calendar_hidden_by_nearness(hidden, 2))
}

fn test_discovery06_expected_red_slot_minus_two_hidden_three() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	got := calendar_prior_spaghetti(new_legacy_visible_drop_store(), hidden, 1, 3) or { big_zero() }
	assert big_eq(got, calendar_hidden_by_nearness(hidden, 3))
}

fn test_discovery06_expected_red_slot_minus_six_hidden_seven() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	got := calendar_prior_spaghetti(new_legacy_visible_drop_store(), hidden, 1, 7) or { big_zero() }
	assert big_eq(got, calendar_hidden_by_nearness(hidden, 7))
}

fn test_discovery06_control_positive_slot_reads_visible_one() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	visible := [big_zero(), big_from_int(124), big_from_int(248), big_from_int(372)]
	got := calendar_prior_spaghetti(visible, hidden, 4, 3) or { big_zero() }
	assert got.str() == '124'
}

fn test_discovery06_control_positive_slot_reads_visible_three() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	visible := [big_zero(), big_from_int(124), big_from_int(248), big_from_int(372)]
	got := calendar_prior_spaghetti(visible, hidden, 4, 1) or { big_zero() }
	assert got.str() == '372'
}

fn test_discovery06_control_hidden_patch_remains_correct() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert calendar_hidden_by_nearness(hidden, 1).str() == '119390830530032782664128530203002080344'
	assert calendar_hidden_by_nearness(hidden, 7).str() == '6164285870955721082771365327359496898'
}
