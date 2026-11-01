module pastafari

// Stage 31 integration slice: assemble all 46 visible drops using patched
// production routes. The separate numeric date oracle stays test-only.
pub struct Patch15SauceChainResult {
pub:
	bowls           []BigInt
	order_at_drop46 []int
	visible_drops   []BigInt
}

pub fn calendar_patch15_sauce_chain_spaghetti(calculation_day BigInt, target_day BigInt) !Patch15SauceChainResult {
	counts := hidden_counts_spaghetti(calculation_day, target_day)
	stones := get_stone_table_through_legacy_builder()
	hidden := calendar_hidden_spaghetti(calculation_day, target_day)
	if stones.len != 46 || hidden.len != 7 {
		return error('PATCH15: invalid 46-stone or seven-hidden-drop structure')
	}
	mut visible := new_legacy_visible_drop_store()
	mut bowls := calendar_initial_bowls_spaghetti(counts)
	if bowls.len != 7 {
		return error('PATCH15: invalid initial bowl structure')
	}
	mut order_at_drop46 := []int{}
	for i in 1 .. 47 {
		p1 := calendar_prior_spaghetti(visible, hidden, i, 1)!
		p3 := calendar_prior_spaghetti(visible, hidden, i, 3)!
		p7 := calendar_prior_spaghetti(visible, hidden, i, 7)!
		stone := stones[i - 1]
		mut x := big_mul(counts.action, stone.w)
		x = big_add(x, big_mul(counts.target, stone.b))
		x = big_add(x, big_mul(counts.distance, stone.s))
		x = big_add(x, big_mul(counts.connection, stone.m))
		x = big_add(x, big_mul(big_from_int(counts.direction), stone.r))
		x = big_add(x, p1)
		x = big_add(x, big_mul_small(p3, 3))
		x = big_add(x, big_mul_small(p7, 5))
		x = calendar_save_spaghetti(big_add(x, big_from_int(i)))
		for grind in 1 .. 12 {
			x = calendar_grind_once_spaghetti(grind, x, p1, p3, p7, stone)!
		}
		visible << x
		order := calendar_bowl_order_spaghetti(x)!
		pours := calendar_pours_spaghetti(i, x, stone, bowls, order)!
		bowls = calendar_stir_bowls_spaghetti(i, x, stone, bowls, order, pours)!
		if i == 46 {
			order_at_drop46 = order.clone()
		}
	}
	if visible.len != 47 || order_at_drop46.len != 6 {
		return error('PATCH15: incomplete 46-drop production chain')
	}
	after := calendar_post_stir12_spaghetti(bowls, order_at_drop46)!
	return Patch15SauceChainResult{
		bowls:           after.bowls.clone()
		order_at_drop46: after.order_for_query.clone()
		visible_drops:   visible.clone()
	}
}
