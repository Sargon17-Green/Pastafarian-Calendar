module pastafari

fn test_discovery06_legacy_store_has_visible_one_based_sentinel() {
	empty := new_legacy_visible_drop_store()
	assert empty.len == 1
	assert empty[0].str() == '0'
	visible := [big_zero(), big_from_int(101), big_from_int(202), big_from_int(303)]
	assert (legacy_prior(visible, 4, 1) or { big_zero() }).str() == '303'
	assert (legacy_prior(visible, 4, 2) or { big_zero() }).str() == '202'
	assert (legacy_prior(visible, 4, 3) or { big_zero() }).str() == '101'
}

fn test_discovery06_valid_visible_slots_still_use_legacy() {
	visible := [big_zero(), big_from_int(111), big_from_int(222), big_from_int(333), big_from_int(444), big_from_int(555), big_from_int(666), big_from_int(777)]
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	dispatcher := new_base_dispatcher()
	for back in 1 .. 8 {
		expected := visible[8 - back]
		got := calendar_prior_spaghetti(visible, hidden, 8, back) or { big_zero() }
		legacy := dispatcher.dispatch_legacy_prior(visible, 8, back) or { big_zero() }
		assert big_eq(got, expected)
		assert big_eq(legacy, expected)
	}
}

fn test_discovery06_missing_zero_and_negative_slots_report_legacy_error() {
	visible := new_legacy_visible_drop_store()
	for slot in [0, -1, -2, -3, -4, -5, -6] {
		mut rejected := false
		_ = legacy_prior(visible, 1, 1 - slot) or {
			rejected = true
			big_zero()
		}
		assert rejected
	}
}

fn test_discovery06_seven_hidden_values_exist_but_are_ignored() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	visible := new_legacy_visible_drop_store()
	assert hidden.len == 7
	mut rejected := 0
	for back in 1 .. 8 {
		_ = calendar_prior_spaghetti(visible, hidden, 1, back) or {
			rejected++
			big_zero()
		}
	}
	assert rejected == 7
	assert calendar_hidden_by_nearness(hidden, 1).str() == '119390830530032782664128530203002080344'
	assert calendar_hidden_by_nearness(hidden, 7).str() == '6164285870955721082771365327359496898'
}

fn test_discovery06_store_does_not_consume_current_or_future_drop() {
	visible := [big_zero(), big_from_int(11), big_from_int(22)]
	for index in [2, 3, 4, 100] {
		mut rejected := false
		_ = legacy_prior(visible, index, 1) or {
			rejected = true
			big_zero()
		}
		assert rejected == (index > 3)
	}
	assert visible.len == 3
	assert visible[0].str() == '0'
}

fn test_discovery06_prior_patches_and_diagnostic_stay_available() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert calendar_hidden_by_nearness(hidden, 1).str() == '119390830530032782664128530203002080344'
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('PATCH_05 hidden1=')
	assert diagnostic.contains('DISCOVERY_06 oldPriorSlot0=ERROR')
}
