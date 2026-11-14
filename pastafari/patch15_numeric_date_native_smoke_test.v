module pastafari

// Bounded Native smoke of the currently diagnostic numeric five-field entrypoint.
// This does not certify full-range conversion or compare separate engines.
fn test_patch15_numeric_date_foundation_native() {
	day := big_from_i64(-15_055_671)
	result := calendar_date_patch15_numeric_spaghetti(day, day) or {
		panic(err.msg())
	}
	assert big_cmp(result.year_number, big_from_int(5000)) == 0
	assert result.cutlet_name == (cutlet_name_by_index(10) or { panic(err.msg()) })
	assert big_cmp(result.day_in_cutlet, big_from_int(503)) == 0
	assert result.month_name == (month_name_by_index(20) or { panic(err.msg()) })
	assert big_cmp(result.day_in_month, big_from_int(56)) == 0
	assert discovery15_output_shape_oracle(result)
	println('V_AMHARIC_PATCH15_FOUNDATION_NATIVE_PASS FIELDS=5 CASES=1')
}
