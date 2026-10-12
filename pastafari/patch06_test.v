module pastafari

// ደረጃ 13፦ የቀደሙ ሰባት ስውር ጠብታዎችን ይፈትሻል።
fn test_patch06_all_seven_hidden_offsets() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	visible := new_legacy_visible_drop_store()
	for k in 1 .. 8 {
		got := calendar_prior_spaghetti(visible, hidden, 1, k) or { big_zero() }
		assert big_eq(got, calendar_hidden_by_nearness(hidden, k))
	}
}

fn test_patch06_visible_slots_match_unchanged_legacy() {
	visible := [big_zero(), big_from_int(101), big_from_int(202),
		big_from_int(303)]
	hidden := []BigInt{}
	dispatcher := new_base_dispatcher()
	for back in 1 .. 4 {
		legacy := dispatcher.dispatch_legacy_prior(visible, 4, back) or { big_zero() }
		got := calendar_prior_spaghetti(visible, hidden, 4, back) or { big_zero() }
		assert big_eq(got, legacy)
		assert big_eq(got, visible[4 - back])
	}
}

fn test_patch06_synthetic_negative_index_mapping() {
	visible := new_legacy_visible_drop_store()
	hidden := [
		big_from_int(700),
		big_from_int(600),
		big_from_int(500),
		big_from_int(400),
		big_from_int(300),
		big_from_int(200),
		big_from_int(100),
	]
	dispatcher := new_base_dispatcher()
	for k in 1 .. 8 {
		mut legacy_failed := false
		_ = dispatcher.dispatch_legacy_prior(visible, 1, k) or {
			legacy_failed = true
			big_zero()
		}
		assert legacy_failed
		got := calendar_prior_spaghetti(visible, hidden, 1, k) or { big_zero() }
		assert big_eq(got, big_from_int(k * 100))
	}
}

fn test_patch06_outside_seven_hidden_positions_returns_error() {
	visible := new_legacy_visible_drop_store()
	mut rejected := false
	_ = calendar_prior_spaghetti(visible, []BigInt{}, 1, 1) or {
		rejected = true
		big_zero()
	}
	assert rejected
	rejected = false
	_ = calendar_prior_spaghetti(visible, []BigInt{}, 1, 8) or {
		rejected = true
		big_zero()
	}
	assert rejected
	rejected = false
	_ = calendar_prior_spaghetti(visible, []BigInt{}, 8, 1) or {
		rejected = true
		big_zero()
	}
	assert rejected
}

fn test_patch06_diagnostic_and_previous_patches() {
	foundation := big_from_i64(-15_055_671)
	assert old_distance(foundation, foundation).str() == '0'
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('DISCOVERY_06 oldPriorSlot0=ERROR')
	assert diagnostic.contains('PATCH_06 priorSlot0=' + calendar_hidden_by_nearness(hidden, 1).str())
}
