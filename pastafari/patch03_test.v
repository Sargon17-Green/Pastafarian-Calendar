module pastafari

// ይህ የሙከራ ሕግ ከPATCH 03 መንገድ ራሱ የተለየ ነው።
fn patch03_expected_chronological(c BigInt, t BigInt) BigInt {
	if big_cmp(c, t) <= 0 {
		return big_add(big_sub(t, c), big_one())
	}
	return big_add(big_sub(c, t), big_one())
}

fn test_patch03_matches_spec_on_equal_and_neighbor_days() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
	assert old_distance(foundation, foundation).str() == '0'
	assert calendar_distance_spaghetti(foundation, big_add(foundation, big_one())).str() == '2'
	assert calendar_distance_spaghetti(big_add(foundation, big_one()), foundation).str() == '2'
	assert calendar_distance_spaghetti(foundation, big_add(foundation, big_from_int(2))).str() == '3'
	assert old_distance(foundation, big_add(foundation, big_from_int(2))).str() == '4'
}

fn test_patch03_cross_foundation_keeps_wrong_tag_distance_visible() {
	foundation := big_from_i64(-15_055_671)
	for offset in 1 .. 45 {
		delta := big_from_int(offset)
		before := big_sub(foundation, delta)
		after := big_add(foundation, delta)
		expected := big_add(big_mul_small(delta, 2), big_one())
		assert big_eq(calendar_distance_spaghetti(before, after), expected)
		assert big_eq(calendar_distance_spaghetti(after, before), expected)
		assert big_eq(old_distance(before, after), big_one())
	}
}

fn test_patch03_preserves_legacy_comparator_branch() {
	patch := DistancePatch03{}
	foundation := big_from_i64(-15_055_671)
	next := big_add(foundation, big_one())
	// የlegacy እና chronological ውጤቶች እኩል ሲሆኑ የቀድሞው እሴት ይቆያል።
	assert patch.apply(foundation, next, big_one()).str() == '2'
	// ልዩ ሲሆኑ ከlegacy ይልቅ የቀን ርቀቱ ይመረጣል።
	assert patch.apply(foundation, next, big_from_int(77)).str() == '2'
	assert patch.apply(foundation, foundation, big_zero()).str() == '1'
	assert patch.apply(foundation, foundation, big_from_int(77)).str() == '1'
}

fn test_patch03_far_signed_and_multi_precision_distances() {
	foundation := big_from_i64(-15_055_671)
	for exponent in [1, 32, 128, 256, 385, 768] {
		delta := big_pow_small(big_from_int(2), exponent)
		before := big_sub(foundation, delta)
		after := big_add(foundation, delta)
		assert big_eq(calendar_distance_spaghetti(before, after), patch03_expected_chronological(before,
			after))
		assert big_eq(calendar_distance_spaghetti(after, before), patch03_expected_chronological(after,
			before))
		assert old_distance(before, after).str() == '1'
	}
}

fn test_patch03_signed_day_pair_matrix() {
	values := [
		big_from_i64(-15_055_673),
		big_from_i64(-15_055_672),
		big_from_i64(-15_055_671),
		big_from_i64(-15_055_670),
		big_from_i64(-15_055_669),
		big_neg(big_pow_small(big_from_int(2), 256)),
		big_zero(),
		big_pow_small(big_from_int(2), 300),
	]
	for c in values {
		for t in values {
			expected := patch03_expected_chronological(c, t)
			assert big_eq(calendar_distance_spaghetti(c, t), expected)
			assert big_eq(calendar_distance_spaghetti(t, c), expected)
		}
	}
}

fn test_patch03_does_not_mutate_legacy_or_previous_patches() {
	foundation := big_from_i64(-15_055_671)
	m := big_sub(big_pow_small(big_from_int(2), 127), big_one())
	dispatcher := new_base_dispatcher()
	for _ in 0 .. 6 {
		assert old_distance(foundation, foundation).str() == '0'
		assert dispatcher.dispatch_legacy_distance(foundation, foundation).str() == '0'
		assert dispatcher.dispatch_distance_patch03(foundation, foundation).str() == '1'
		assert calendar_day_tag_spaghetti(foundation).str() == '1'
		assert old_day_tag(foundation).str() == '0'
		assert big_eq(calendar_save_spaghetti(m), m)
		assert old_remainder(m).str() == '0'
	}
}

fn test_patch03_production_entrypoint_uses_patched_distance() {
	foundation := big_from_i64(-15_055_671)
	before := big_sub(foundation, big_one())
	after := big_add(foundation, big_one())
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
