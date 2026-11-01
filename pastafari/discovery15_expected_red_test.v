module pastafari

// Stage 30: intentional RED until the actual five-part date assembly exists.
fn discovery15_assert_valid_public_date(calculation_day BigInt, target_day BigInt) {
	value := calendar_date_spaghetti(calculation_day, target_day) or { CalendarResult{} }
	assert discovery15_five_components(value).len == 5
	assert discovery15_output_shape_oracle(value)
}

fn test_discovery15_expected_red_foundation_same_day() {
	foundation := big_from_i64(-15_055_671)
	discovery15_assert_valid_public_date(foundation, foundation)
}

fn test_discovery15_expected_red_one_day_before_foundation() {
	foundation := big_from_i64(-15_055_671)
	discovery15_assert_valid_public_date(foundation, big_sub(foundation, big_one()))
}

fn test_discovery15_expected_red_one_day_after_foundation() {
	foundation := big_from_i64(-15_055_671)
	discovery15_assert_valid_public_date(foundation, big_add(foundation, big_one()))
}

fn test_discovery15_expected_red_distinct_calculation_day() {
	foundation := big_from_i64(-15_055_671)
	calculation_day := big_add(foundation, big_from_int(3))
	target_day := big_add(foundation, big_from_int(2))
	discovery15_assert_valid_public_date(calculation_day, target_day)
}
