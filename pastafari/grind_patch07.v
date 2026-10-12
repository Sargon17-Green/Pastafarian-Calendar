module pastafari

// ደረጃ 15 — PATCH 07፦ የታሪክ 0..10 ሰንጠረዥ አይቀየርም።
// የተለየ አዲስ ሰንጠረዥ በindex 0 የsentinel ረድፍ ይይዛል።
pub struct GrindPatch07 {}

// በዚህ አዲስ ሰንጠረዥ አንድ-መሠረት የታሪክ ንባብ ይጠበቃል።
// የመጀመሪያው ረድፍ ባዶ የsentinel ምልክት ነው፤ አይሰረዝም።
pub fn (_ GrindPatch07) table_with_sentinel() [][]int {
	mut table := [][]int{cap: 12}
	table << [0, 0, 0, 0, 0]
	for historical_row in legacy_visible_grind_table() {
		table << historical_row.clone()
	}
	return table
}

// ቁጥር grind 1..11 በቀጥታ በtable[grind] ይነበባል።
// የታሪክ የቀጥታ-ኢንዴክስ መንገድ አልተሰረዘም፣ ሰንጠረዡ ብቻ ተዘጋጅቷል።
pub fn (patch GrindPatch07) row(grind int) ![]int {
	if grind < 1 || grind > 11 {
		return error('የተጠገነው የወፍጮ ቁጥር ከ1 እስከ11 መሆን አለበት')
	}
	table := patch.table_with_sentinel()
	return table[grind]
}

pub fn (_ BaseDispatcher) dispatch_grind_patch07(grind int) ![]int {
	patch := GrindPatch07{}
	return patch.row(grind)
}
