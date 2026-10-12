module pastafari

// ደረጃ 14 — DISCOVERY 07፦ አስራ አንዱ የታሪክ ወፍጮዎች ዜሮ-መሠረት ናቸው።
// የሚጠበቀው ቅርጽ [a, b, c, d, stone_kind] ነው።
pub fn legacy_visible_grind_table() [][]int {
	return [
		[3, 5, 7, 11, 1],
		[5, 7, 11, 13, 2],
		[7, 11, 13, 17, 3],
		[11, 13, 17, 19, 4],
		[13, 17, 19, 23, 5],
		[17, 19, 23, 29, 1],
		[19, 23, 29, 31, 2],
		[23, 29, 31, 37, 3],
		[29, 31, 37, 41, 4],
		[31, 37, 41, 43, 5],
		[37, 41, 43, 47, 1],
	]
}

// የታሪካዊው ጉድለት፦ grind ቁጥር እንደ ዜሮ-መሠረት index በቀጥታ ይጠቀማል።
// በV ሂደት እንዳይቋረጥ grind 11 በerror ይመለሳል።
// የPATCH 07 የsentinel ረድፍ እዚህ አይጨመርም።
pub fn old_grind_row(grind int) ![]int {
	table := legacy_visible_grind_table()
	if grind < 0 || grind >= table.len {
		return error('የታሪካዊው የወፍጮ ሰልፍ የለም')
	}
	return table[grind]
}

pub struct LegacyGrindAdapter {}

pub fn (_ LegacyGrindAdapter) row(grind int) ![]int {
	return old_grind_row(grind)
}

pub fn (_ BaseDispatcher) dispatch_legacy_grind(grind int) ![]int {
	adapter := LegacyGrindAdapter{}
	return adapter.row(grind)
}

// የproduction ንዑስ መግቢያ፤ በDISCOVERY 07 የlegacy index ይጠቀማል።
pub fn calendar_grind_row_spaghetti(grind int) ![]int {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_grind(grind)
}

// አንድ የወፍጮ ዙር በተሰጠ ረድፍ ይተገበራል፤ ስሌቱ አይሳሳትም።
fn grind_mix_spaghetti(row []int, x BigInt, p1 BigInt, p3 BigInt, p7 BigInt, stone Stones) BigInt {
	mut mixed := big_square(x)
	mixed = big_add(mixed, big_mul_small(x, u32(row[0])))
	mixed = big_add(mixed, big_mul_small(p1, u32(row[1])))
	mixed = big_add(mixed, big_mul_small(p3, u32(row[2])))
	mixed = big_add(mixed, big_mul_small(p7, u32(row[3])))
	mixed = big_add(mixed, hidden_stone_component(stone, row[4]))
	return calendar_save_spaghetti(mixed)
}

// ይህ የታሪካዊውን ረድፍ በእውነት ያነባል፤ PATCH 07 በኋላም አይጠፋም።
pub fn legacy_grind_once(grind int, x BigInt, p1 BigInt, p3 BigInt, p7 BigInt, stone Stones) !BigInt {
	row := old_grind_row(grind)!
	return grind_mix_spaghetti(row, x, p1, p3, p7, stone)
}

// የproduction ማስኬጃ በአሁኑ ደረጃ ወደ ታሪካዊው ሰልፍ ይሄዳል።
pub fn calendar_grind_once_spaghetti(grind int, x BigInt, p1 BigInt, p3 BigInt, p7 BigInt, stone Stones) !BigInt {
	row := calendar_grind_row_spaghetti(grind)!
	return grind_mix_spaghetti(row, x, p1, p3, p7, stone)
}
