module pastafari

fn test_discovery03_historical_distance_is_zero_on_identical_days() {
	foundation := big_from_i64(-15_055_671)
	assert old_distance(foundation, foundation).str() == '0'
	assert old_distance(foundation, foundation).str() == '0'
}

fn test_discovery03_historical_distance_uses_tag_gap_not_day_gap() {
	foundation := big_from_i64(-15_055_671)
	plus_two := big_add(foundation, big_from_int(2))
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
	assert calendar_day_tag_spaghetti(plus_two).str() == '5'
	assert old_distance(foundation, plus_two).str() == '4'
	assert old_distance(plus_two, foundation).str() == '4'
}

fn test_discovery03_cross_foundation_tags_have_small_difference() {
	foundation := big_from_i64(-15_055_671)
	before := big_sub(foundation, big_one())
	after := big_add(foundation, big_one())
	assert calendar_day_tag_spaghetti(before).str() == '2'
	assert calendar_day_tag_spaghetti(after).str() == '3'
	assert old_distance(before, after).str() == '1'
	assert old_distance(after, before).str() == '1'
}

fn test_discovery03_far_cross_foundation_historical_distance_is_one() {
	foundation := big_from_i64(-15_055_671)
	delta := big_pow_small(big_from_int(2), 300)
	before := big_sub(foundation, delta)
	after := big_add(foundation, delta)
	assert old_distance(before, after).str() == '1'
	assert old_distance(after, before).str() == '1'
}

fn test_discovery03_legacy_adapter_retains_original_result() {
	foundation := big_from_i64(-15_055_671)
	before := big_sub(foundation, big_one())
	after := big_add(foundation, big_one())
	dispatcher := new_base_dispatcher()
	assert big_eq(dispatcher.dispatch_legacy_distance(before, after), old_distance(before, after))
	assert big_eq(new_base_dispatcher().dispatch_legacy_distance(before, after), old_distance(before, after))
	mut diagnostic := ''
	_ = calendar_date_spaghetti(before, after) or {
		diagnostic = err.msg()
		CalendarResult{}
	}
	assert diagnostic.contains('DISCOVERY_03 oldDistance=1')
	assert diagnostic.contains('PATCH_03 distance=3')
	assert diagnostic.contains('PATCH_01 SAVE=')
	assert diagnostic.contains('PATCH_02 dayTag=3')
}

fn test_discovery03_previous_patches_remain_correct() {
	foundation := big_from_i64(-15_055_671)
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
	assert old_day_tag(foundation).str() == '0'
	assert big_eq(calendar_save_spaghetti(m), m)
	assert old_remainder(m).str() == '0'
}
