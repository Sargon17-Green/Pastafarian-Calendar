module pastafari

fn test_discovery05_reversed_coefficients_are_exact() {
	coeff := legacy_hidden_coefficients_reversed()
	assert coeff.len == 7
	assert coeff[0] == [15, 22, 30, 32]
	assert coeff[1] == [13, 19, 26, 28]
	assert coeff[2] == [11, 16, 22, 24]
	assert coeff[3] == [9, 13, 18, 20]
	assert coeff[4] == [7, 10, 14, 16]
	assert coeff[5] == [5, 7, 10, 12]
	assert coeff[6] == [3, 4, 6, 8]
}

fn test_discovery05_hidden_counts_use_existing_patches() {
	foundation := big_from_i64(-15_055_671)
	counts := hidden_counts_spaghetti(foundation, foundation)
	assert counts.action.str() == '1'
	assert counts.target.str() == '1'
	assert counts.distance.str() == '1'
	assert counts.connection.str() == '2'
	assert counts.direction == 2
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
}

fn test_discovery05_hidden_values_match_independent_stage01_fixtures() {
	foundation := big_from_i64(-15_055_671)
	stones := get_stone_table_through_legacy_builder()
	counts := hidden_counts_spaghetti(foundation, foundation)
	values := [
		'119390830530032782664128530203002080344',
		'11877236279154673426874867061566696749',
		'24217814924229232987463457533828175476',
		'166629231917547214614573522551290204247',
		'81202913407267092008896220686064041568',
		'73551520026920072430116213847585486272',
		'6164285870955721082771365327359496898',
	]
	for k in 1 .. 8 {
		assert make_hidden_drop_spaghetti(k, counts, stones).str() == values[k - 1]
	}
}

fn test_discovery05_backward_storage_is_actual_public_result() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert hidden.len == 7
	assert hidden[0].str() == '6164285870955721082771365327359496898'
	assert hidden[1].str() == '73551520026920072430116213847585486272'
	assert hidden[2].str() == '81202913407267092008896220686064041568'
	assert hidden[3].str() == '166629231917547214614573522551290204247'
	assert hidden[4].str() == '24217814924229232987463457533828175476'
	assert hidden[5].str() == '11877236279154673426874867061566696749'
	assert hidden[6].str() == '119390830530032782664128530203002080344'
	assert old_hidden_slot(hidden, 1).str() == hidden[0].str()
	assert old_hidden_slot(hidden, 7).str() == hidden[6].str()
}

fn test_discovery05_all_seven_physical_positions_are_reversed() {
	foundation := big_from_i64(-15_055_671)
	counts := hidden_counts_spaghetti(foundation, foundation)
	stones := get_stone_table_through_legacy_builder()
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	for k in 1 .. 8 {
		assert big_eq(hidden[k - 1], make_hidden_drop_spaghetti(8 - k, counts, stones))
	}
}

fn test_discovery05_repeated_invocation_does_not_share_mutable_hidden_storage() {
	foundation := big_from_i64(-15_055_671)
	mut before := calendar_hidden_spaghetti(foundation, foundation)
	unchanged := before[0].str()
	before[0] = big_zero()
	again := calendar_hidden_spaghetti(foundation, foundation)
	assert again[0].str() == unchanged
	assert again.len == 7
}

fn test_discovery05_prior_patches_and_production_path_are_intact() {
	foundation := big_from_i64(-15_055_671)
	hidden := calendar_hidden_spaghetti(foundation, foundation)
	assert hidden.len == 7
	assert calendar_stones_spaghetti(2, initial_stones()).b.str() == '1073'
	assert old_distance(foundation, foundation).str() == '0'
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	mut diagnostic := ''
	_ = calendar_date_spaghetti(foundation, foundation) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('DISCOVERY_05 oldHidden1=')
	assert diagnostic.contains(hidden[0].str())
	assert diagnostic.contains('PATCH_04 stoneB=1073')
}
