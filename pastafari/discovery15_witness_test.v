module pastafari

// Stage 30 GREEN: validate shape independently and preserve the diagnostic witness.
fn discovery15_reference_fixture() CalendarResult {
	return CalendarResult{
		year_number:   big_from_int(-3)
		cutlet_name:   cutlet_name_by_index(12) or { panic(err.msg()) }
		day_in_cutlet: big_from_int(2)
		month_name:    month_name_by_index(44) or { panic(err.msg()) }
		day_in_month:  big_from_int(4)
	}
}

fn test_discovery15_five_components_order_is_fixed() {
	fixture := discovery15_reference_fixture()
	fields := discovery15_five_components(fixture)
	assert fields.len == 5
	assert fields[0] == '-3'
	assert fields[1] == fixture.cutlet_name
	assert fields[2] == '2'
	assert fields[3] == fixture.month_name
	assert fields[4] == '4'
	assert discovery15_output_shape_oracle(fixture)
}

fn test_discovery15_shape_oracle_has_four_negative_controls() {
	fixture := discovery15_reference_fixture()
	assert !discovery15_output_shape_oracle(CalendarResult{
		year_number:   fixture.year_number
		cutlet_name:   ''
		day_in_cutlet: fixture.day_in_cutlet
		month_name:    fixture.month_name
		day_in_month:  fixture.day_in_month
	})
	assert !discovery15_output_shape_oracle(CalendarResult{
		year_number:   fixture.year_number
		cutlet_name:   fixture.cutlet_name
		day_in_cutlet: big_zero()
		month_name:    fixture.month_name
		day_in_month:  fixture.day_in_month
	})
	assert !discovery15_output_shape_oracle(CalendarResult{
		year_number:   fixture.year_number
		cutlet_name:   fixture.cutlet_name
		day_in_cutlet: fixture.day_in_cutlet
		month_name:    ''
		day_in_month:  fixture.day_in_month
	})
	assert !discovery15_output_shape_oracle(CalendarResult{
		year_number:   fixture.year_number
		cutlet_name:   fixture.cutlet_name
		day_in_cutlet: fixture.day_in_cutlet
		month_name:    fixture.month_name
		day_in_month:  big_zero()
	})
}

fn test_discovery15_valid_anchor_inputs_still_return_a_diagnostic() {
	foundation := big_from_i64(-15_055_671)
	for offset in [-2, -1, 0, 1, 2] {
		target := big_add(foundation, big_from_int(offset))
		mut failed := false
		mut diagnostic := ''
		_ = calendar_date_spaghetti(foundation, target) or {
			failed = true
			diagnostic = err.msg()
			CalendarResult{}
		}
		assert failed
		assert diagnostic.contains('PATCH_12 nextBowl=')
	}
}
