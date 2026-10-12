module pastafari

// ደረጃ 22 — DISCOVERY 11፦ የ46ኛው ጠብታ ቅደም ተከተል የሚጠበቅበት
// ተመሳሳይ መያዣ በ12 ተከታታይ የመጨረሻ ብስለቶች ይደረሳል።
// የPATCH 11 orderAt46Latch እዚህ አይገነባም።
pub struct LegacyPostStirOrderStore {
pub mut:
	query_order     []int
	overwrite_count int
}

// በዚህ የታሪክ መያዣ የቀድሞው ቅደም ተከተል ተለይቶ አይቀመጥም።
pub fn new_legacy_post_stir_order_store(order []int) LegacyPostStirOrderStore {
	mut copied := []int{len: order.len}
	for position in 0 .. order.len {
		copied[position] = order[position]
	}
	return LegacyPostStirOrderStore{
		query_order:     copied
		overwrite_count: 0
	}
}

pub fn (mut store LegacyPostStirOrderStore) old_overwrite_query_order(order []int) {
	mut copied := []int{len: order.len}
	for position in 0 .. order.len {
		copied[position] = order[position]
	}
	store.query_order = copied
	store.overwrite_count++
}

pub struct LegacyPostStir12Result {
pub:
	bowls             []BigInt
	order_for_query   []int
	overwrite_count   int
	final_saved_sum   BigInt
	final_stir_number int
}

// የ12ቱ ብስለቶች ትክክለኛ የቦውል ሂሳብ አለ፤ ስህተቱ በምርመራ
// ለሚጠቀመው query_order ላይ ብቻ ነው።
pub fn old_post_stirs_overwrite_drop46_order(bowls []BigInt, order_at_drop46 []int) !LegacyPostStir12Result {
	legacy_validate_pour_inputs(1, bowls, order_at_drop46)!
	copy_patch := BowlStirPatch10{}
	mut working := copy_patch.clone_bowls(bowls)
	mut old_store := new_legacy_post_stir_order_store(order_at_drop46)
	mut final_saved_sum := big_zero()
	for stir in 1 .. 13 {
		old := copy_patch.clone_bowls(working)
		mut total := big_mul_small(big_from_int(stir), 149)
		for bowl_id in 1 .. 7 {
			total = big_add(total, old[bowl_id])
		}
		saved_bowl_sum := calendar_save_spaghetti(total)
		final_saved_sum = saved_bowl_sum
		post_order := calendar_bowl_order_spaghetti(saved_bowl_sum)!
		old_store.old_overwrite_query_order(post_order)
		mut pending := copy_patch.clone_bowls(old)
		for position in 1 .. 7 {
			bowl_id := post_order[position - 1]
			prev_id := post_order[(position + 4) % 6]
			next_id := post_order[position % 6]
			mut sum := big_add(old[bowl_id], big_mul_small(old[prev_id], 3))
			sum = big_add(sum, big_mul_small(old[next_id], 5))
			sum = big_add(sum, saved_bowl_sum)
			sum = big_add(sum, big_from_int(stir + position * position))
			cross := big_mul_small(big_mul(old[prev_id], old[next_id]), 7)
			pending[bowl_id] = calendar_save_spaghetti(big_add(big_square(sum), cross))
		}
		working = pending.clone()
	}
	return LegacyPostStir12Result{
		bowls:             working
		order_for_query:   old_store.query_order
		overwrite_count:   old_store.overwrite_count
		final_saved_sum:   final_saved_sum
		final_stir_number: 12
	}
}

pub struct LegacyPostStir12Adapter {}

pub fn (_ LegacyPostStir12Adapter) post_stir(bowls []BigInt, order_at_drop46 []int) !LegacyPostStir12Result {
	return old_post_stirs_overwrite_drop46_order(bowls, order_at_drop46)
}

pub fn (_ BaseDispatcher) dispatch_legacy_post_stir12(bowls []BigInt, order_at_drop46 []int) !LegacyPostStir12Result {
	adapter := LegacyPostStir12Adapter{}
	return adapter.post_stir(bowls, order_at_drop46)
}

// የproduction መንገድ በDISCOVERY 11 የ12ኛውን የpost-stir order
// ለምርመራ መመለሱን ይቀጥላል።
pub fn calendar_post_stir12_spaghetti(bowls []BigInt, order_at_drop46 []int) !LegacyPostStir12Result {
	dispatcher := new_base_dispatcher()
	return dispatcher.dispatch_legacy_post_stir12(bowls, order_at_drop46)
}
