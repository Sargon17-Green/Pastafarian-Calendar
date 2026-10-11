module pastafari

// ደረጃ 8፦ አምስቱ ድንጋዮች ከቀድሞው ሁኔታ በአንድ ጊዜ መቆጠር አለባቸው።
// እነዚህ አራት ፈተናዎች PATCH 04 እስኪመጣ ሆን ተብሎ RED ናቸው።
fn test_discovery04_expected_red_barley_reads_old_wheat() {
	got := calendar_stones_spaghetti(2, initial_stones())
	assert got.b.str() == '1073'
}

fn test_discovery04_expected_red_salt_reads_old_barley() {
	got := calendar_stones_spaghetti(2, initial_stones())
	assert got.s.str() == '2375'
}

fn test_discovery04_expected_red_bitter_reads_old_salt() {
	got := calendar_stones_spaghetti(2, initial_stones())
	assert got.m.str() == '6195'
}

fn test_discovery04_expected_red_red_stone_reads_old_wheat_and_bitter() {
	got := calendar_stones_spaghetti(2, initial_stones())
	assert got.r.str() == '10493'
}

fn test_discovery04_control_wheat_uses_old_barley() {
	got := calendar_stones_spaghetti(2, initial_stones())
	assert got.w.str() == '378'
}

fn test_discovery04_control_initial_stones_are_untouched() {
	original := initial_stones()
	_ = calendar_stones_spaghetti(2, original)
	assert original.w.str() == '17'
	assert original.b.str() == '29'
	assert original.s.str() == '43'
	assert original.m.str() == '71'
	assert original.r.str() == '101'
}

fn test_discovery04_control_previous_patches() {
	foundation := big_from_i64(-15_055_671)
	assert calendar_day_tag_spaghetti(foundation).str() == '1'
	assert calendar_distance_spaghetti(foundation, foundation).str() == '1'
}
