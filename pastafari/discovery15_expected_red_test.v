module pastafari

// Stage 30: intentional RED until the actual five-part date assembly exists.
fn discovery15_has_valid_public_date_shape(calculation_day BigInt, target_day BigInt) bool {
	value := calendar_date_spaghetti(calculation_day, target_day) or { CalendarResult{} }
	if discovery15_five_components(value).len != 5 {
		return false
	}
	return discovery15_output_shape_oracle(value)
}

fn test_discovery15_expected_red_foundation_same_day() {
	foundation := big_from_i64(-15_055_671)
	assert discovery15_has_valid_public_date_shape(foundation, foundation)
}

fn test_discovery15_expected_red_one_day_before_foundation() {
	foundation := big_from_i64(-15_055_671)
	target_day := big_sub(foundation, big_one())
	assert discovery15_has_valid_public_date_shape(foundation, target_day)
}

fn test_discovery15_expected_red_one_day_after_foundation() {
	foundation := big_from_i64(-15_055_671)
	target_day := big_add(foundation, big_one())
	assert discovery15_has_valid_public_date_shape(foundation, target_day)
}

fn test_discovery15_expected_red_distinct_calculation_day() {
	foundation := big_from_i64(-15_055_671)
	calculation_day := big_add(foundation, big_from_int(3))
	target_day := big_add(foundation, big_from_int(2))
	assert discovery15_has_valid_public_date_shape(calculation_day, target_day)
}
