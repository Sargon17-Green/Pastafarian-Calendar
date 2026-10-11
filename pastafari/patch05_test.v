module pastafari

// የደረጃ 11 ሙከራዎች የታሪካዊ መንገድንና የproduction ንባብን ይለያሉ።
fn test_patch05_all_seven_hidden_values_in_nearness_order() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	expected := [
		'119390830530032782664128530203002080344',
		'11877236279154673426874867061566696749',
		'24217814924229232987463457533828175476',
		'166629231917547214614573522551290204247',
		'81202913407267092008896220686064041568',
		'73551520026920072430116213847585486272',
		'6164285870955721082771365327359496898',
	]
	assert hidden.len == 7
	for k in 1 .. 8 {
		assert calendar_hidden_by_nearness(hidden, k).str() == expected[k - 1]
		assert hidden[7 - k].str() == expected[k - 1]
	}
}

fn test_patch05_legacy_slot_is_still_wrong_and_storage_still_backward() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert hidden.len == 7
	assert hidden[0].str() == '6164285870955721082771365327359496898'
	assert hidden[6].str() == '119390830530032782664128530203002080344'
	for k in 1 .. 8 {
		patched := calendar_hidden_by_nearness(hidden, k)
		legacy := old_hidden_slot(hidden, k)
		assert big_eq(patched, hidden[7 - k])
		assert big_eq(legacy, hidden[k - 1])
		if k == 4 {
			assert big_eq(legacy, patched)
		} else {
			assert !big_eq(legacy, patched)
		}
	}
}

fn test_patch05_synthetic_storage_maps_exactly_to_8_minus_k() {
	storage := [
		big_from_int(700),
		big_from_int(600),
		big_from_int(500),
		big_from_int(400),
		big_from_int(300),
		big_from_int(200),
		big_from_int(100),
	]
	dispatcher := new_base_dispatcher()
	patch := HiddenPatch05{}
	for k in 1 .. 8 {
		translated := big_from_int(k * 100)
		assert big_eq(calendar_hidden_by_nearness(storage, k), translated)
		assert big_eq(dispatcher.dispatch_hidden_patch05(storage, k), translated)
		assert big_eq(patch.by_nearness(storage, k), translated)
		assert big_eq(old_hidden_slot(storage, k), big_from_int((8 - k) * 100))
	}
	assert storage[0].str() == '700'
	assert storage[6].str() == '100'
}

fn test_patch05_varied_calculation_and_target_days() {
	foundation := big_from_i64(-15_055_671)
	huge := big_pow_small(big_from_int(2), 290)
	days := [
		foundation,
		big_sub(foundation, big_one()),
		big_add(foundation, big_one()),
		big_from_int(1),
		big_zero(),
		big_sub(foundation, huge),
		big_add(foundation, huge),
	]
	stones := get_stone_table_through_legacy_builder()
	for c in days {
		for t in [foundation, big_add(foundation, big_from_int(13))] {
			counts := hidden_counts_spaghetti(c, t)
			physical := calendar_hidden_spaghetti(c, t)
			assert physical.len == 7
			for k in 1 .. 8 {
				expected := make_hidden_drop_spaghetti(k, counts, stones)
				assert big_eq(calendar_hidden_by_nearness(physical, k), expected)
				assert big_eq(physical[7 - k], expected)
			}
		}
	}
}

fn test_patch05_preserves_input_and_avoids_shared_state() {
	foundation := big_from_i64(-15_055_671)
	mut first := calendar_hidden_spaghetti(foundation, foundation)
	original_near := calendar_hidden_by_nearness(first, 1).str()
	original_far := calendar_hidden_by_nearness(first, 7).str()
	first[6] = big_from_int(999)
	assert calendar_hidden_by_nearness(first, 1).str() == '999'
	assert calendar_hidden_by_nearness(first, 7).str() == original_far
	second := calendar_hidden_spaghetti(foundation, foundation)
	assert calendar_hidden_by_nearness(second, 1).str() == original_near
	assert calendar_hidden_by_nearness(second, 7).str() == original_far
}

fn test_patch05_previous_history_and_diags_remain_accessible() {
	foundation := big_from_i64(-15_055_671)
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert old_remainder(m).str() == '0'
	assert big_eq(calendar_save_spaghetti(m), m)
	assert old_day_tag(foundation).str() == '0'
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
	assert old_distance(foundation, foundation).str() == '0'
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert new_base_dispatcher().dispatch_legacy_stones(2, initial_stones()).b.str() == '1434'
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('DISCOVERY_05 oldHidden1=' + old_hidden_slot(hidden, 1).str())
	assert diagnostic.contains('PATCH_05 hidden1=' + calendar_hidden_by_nearness(hidden, 1).str())
	assert diagnostic.contains('PATCH_04 stoneB=1073')
	assert diagnostic.contains('PATCH_03 distance=1')
}
