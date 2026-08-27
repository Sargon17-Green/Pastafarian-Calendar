module pastafari

struct OracleWorkCounts {
	action     BigInt
	target     BigInt
	distance   BigInt
	connection BigInt
	direction  int
}

struct OracleStone {
	w BigInt
	b BigInt
	s BigInt
	m BigInt
	r BigInt
}

struct OracleSauceResult {
	bowls           []BigInt
	order_at_drop46 []int
}

struct OracleAnswerStream {
	first BigInt
	step  int
}

struct OracleYear {
	number           BigInt
	open_gate_index  BigInt
	close_gate_index BigInt
	open_gate_day    BigInt
	close_gate_day   BigInt
}

struct OracleCutlet {
	name_index       int
	open_gate_index  BigInt
	close_gate_index BigInt
	first_day        BigInt
	last_day         BigInt
}

struct OracleYearStructure {
	cutlet_count     int
	cutlet_partition []int
	cutlet_names     []int
	cutlets          []OracleCutlet
	month_count      int
	month_lengths    []int
	month_weaving    []int
	month_names      []int
}

struct OracleGateCache {
mut:
	gates     map[string]BigInt
	min_index BigInt
	max_index BigInt
}

struct OracleEngine {
mut:
	gate_cache OracleGateCache
}

fn new_oracle_engine() OracleEngine {
	foundation := big_from_i64(-15_055_671)
	mut gates := map[string]BigInt{}
	gates['0'] = foundation
	return OracleEngine{
		gate_cache: OracleGateCache{
			gates:     gates
			min_index: big_zero()
			max_index: big_zero()
		}
	}
}

fn oracle_m() BigInt {
	return big_sub(big_pow_small(big_from_int(2), 127), big_one())
}

fn oracle_foundation_day() BigInt {
	return big_from_i64(-15_055_671)
}

fn oracle_tablets_day() BigInt {
	return big_from_i64(-278_522)
}

fn oracle_save(x BigInt) BigInt {
	return big_add(big_one(), big_regular_mod(big_sub(x, big_one()), oracle_m()))
}

fn oracle_ceil_div_nonnegative(a BigInt, b BigInt) BigInt {
	return big_floor_div(big_add(a, big_sub(b, big_one())), b)
}

fn oracle_wrap1(position int, size int) int {
	mut r := (position - 1) % size
	if r < 0 {
		r += size
	}
	return r + 1
}

fn oracle_day_count(day BigInt) BigInt {
	foundation := oracle_foundation_day()
	cmp := big_cmp(day, foundation)
	if cmp == 0 {
		return big_one()
	}
	if cmp > 0 {
		return big_add(big_mul_small(big_sub(day, foundation), 2), big_one())
	}
	return big_mul_small(big_sub(foundation, day), 2)
}

fn oracle_work_counts(calculation_day BigInt, target_day BigInt) OracleWorkCounts {
	action := oracle_day_count(calculation_day)
	target := oracle_day_count(target_day)
	distance := big_add(big_abs(big_sub(target_day, calculation_day)), big_one())
	connection := big_add(action, target)
	direction := if big_cmp(target_day, calculation_day) < 0 {
		1
	} else if big_cmp(target_day, calculation_day) == 0 {
		2
	} else {
		3
	}
	return OracleWorkCounts{
		action:     action
		target:     target
		distance:   distance
		connection: connection
		direction:  direction
	}
}

fn oracle_build_stones() []OracleStone {
	mut stones := []OracleStone{cap: 46}
	stones << OracleStone{
		w: big_from_int(17)
		b: big_from_int(29)
		s: big_from_int(43)
		m: big_from_int(71)
		r: big_from_int(101)
	}
	for i in 2 .. 47 {
		old := stones[i - 2]
		next_w := oracle_save(big_add(big_add(big_square(old.w), big_mul_small(old.b, 3)),
			big_from_int(i)))
		next_b := oracle_save(big_add(big_add(big_square(old.b), big_mul_small(old.s, 5)), old.w))
		next_s := oracle_save(big_add(big_add(big_square(old.s), big_mul_small(old.m, 7)), old.b))
		next_m := oracle_save(big_add(big_add(big_square(old.m), big_mul_small(old.r, 11)), old.s))
		next_r := oracle_save(big_add(big_add(big_square(old.r), big_mul_small(old.w, 13)), old.m))
		stones << OracleStone{
			w: next_w
			b: next_b
			s: next_s
			m: next_m
			r: next_r
		}
	}
	return stones
}

fn oracle_stone_component(stone OracleStone, kind int) BigInt {
	return match kind {
		1 { stone.w }
		2 { stone.b }
		3 { stone.s }
		4 { stone.m }
		5 { stone.r }
		else { big_zero() }
	}
}

fn oracle_hidden_coeff(k int) []int {
	return match k {
		1 { [3, 4, 6, 8] }
		2 { [5, 7, 10, 12] }
		3 { [7, 10, 14, 16] }
		4 { [9, 13, 18, 20] }
		5 { [11, 16, 22, 24] }
		6 { [13, 19, 26, 28] }
		7 { [15, 22, 30, 32] }
		else { []int{} }
	}
}

fn oracle_hidden_grind_kind(grind int) int {
	return [1, 2, 3, 4, 5, 1, 2][grind - 1]
}

fn oracle_build_hidden_drops(counts OracleWorkCounts, stones []OracleStone) []BigInt {
	mut hidden := []BigInt{cap: 7}
	for k in 1 .. 8 {
		coeff := oracle_hidden_coeff(k)
		mut x := counts.action
		x = big_add(x, big_mul_small(counts.target, u32(coeff[0])))
		x = big_add(x, big_mul_small(counts.distance, u32(coeff[1])))
		x = big_add(x, big_mul_small(counts.connection, u32(coeff[2])))
		x = big_add(x, big_mul_small(big_from_int(counts.direction), u32(coeff[3])))
		stone := stones[k - 1]
		x = big_add(x, stone.w)
		x = big_add(x, stone.b)
		x = big_add(x, stone.s)
		x = big_add(x, stone.m)
		x = big_add(x, stone.r)
		x = oracle_save(x)
		for grind in 1 .. 8 {
			old_x := x
			mut mixed := big_square(old_x)
			mixed = big_add(mixed, big_mul_small(old_x, 3))
			mixed = big_add(mixed, oracle_stone_component(stone, oracle_hidden_grind_kind(grind)))
			mixed = big_add(mixed, big_from_int(grind))
			x = oracle_save(mixed)
		}
		hidden << x
	}
	return hidden
}

fn oracle_visible_grind_row(grind int) []int {
	return match grind {
		1 { [3, 5, 7, 11, 1] }
		2 { [5, 7, 11, 13, 2] }
		3 { [7, 11, 13, 17, 3] }
		4 { [11, 13, 17, 19, 4] }
		5 { [13, 17, 19, 23, 5] }
		6 { [17, 19, 23, 29, 1] }
		7 { [19, 23, 29, 31, 2] }
		8 { [23, 29, 31, 37, 3] }
		9 { [29, 31, 37, 41, 4] }
		10 { [31, 37, 41, 43, 5] }
		11 { [37, 41, 43, 47, 1] }
		else { []int{} }
	}
}

fn oracle_prior_drop(visible []BigInt, hidden []BigInt, i int, back int) BigInt {
	slot := i - back
	if slot >= 1 {
		return visible[slot - 1]
	}
	k := 1 - slot
	return hidden[k - 1]
}

fn oracle_build_visible_drops(counts OracleWorkCounts, stones []OracleStone, hidden []BigInt) []BigInt {
	mut visible := []BigInt{cap: 46}
	for i in 1 .. 47 {
		p1 := oracle_prior_drop(visible, hidden, i, 1)
		p3 := oracle_prior_drop(visible, hidden, i, 3)
		p7 := oracle_prior_drop(visible, hidden, i, 7)
		stone := stones[i - 1]
		mut x := big_mul(counts.action, stone.w)
		x = big_add(x, big_mul(counts.target, stone.b))
		x = big_add(x, big_mul(counts.distance, stone.s))
		x = big_add(x, big_mul(counts.connection, stone.m))
		x = big_add(x, big_mul(big_from_int(counts.direction), stone.r))
		x = big_add(x, p1)
		x = big_add(x, big_mul_small(p3, 3))
		x = big_add(x, big_mul_small(p7, 5))
		x = big_add(x, big_from_int(i))
		x = oracle_save(x)
		for grind in 1 .. 12 {
			row := oracle_visible_grind_row(grind)
			old_x := x
			mut mixed := big_square(old_x)
			mixed = big_add(mixed, big_mul_small(old_x, u32(row[0])))
			mixed = big_add(mixed, big_mul_small(p1, u32(row[1])))
			mixed = big_add(mixed, big_mul_small(p3, u32(row[2])))
			mixed = big_add(mixed, big_mul_small(p7, u32(row[3])))
			mixed = big_add(mixed, oracle_stone_component(stone, row[4]))
			x = oracle_save(mixed)
		}
		visible << x
	}
	return visible
}

fn oracle_factorial(n int) int {
	mut result := 1
	for i in 2 .. n + 1 {
		result *= i
	}
	return result
}

fn oracle_permutation_unrank1(rank1 int) []int {
	mut rank0 := rank1 - 1
	mut remaining := [1, 2, 3, 4, 5, 6]
	mut result := []int{cap: 6}
	for slots_left := 6; slots_left > 0; slots_left-- {
		block := oracle_factorial(slots_left - 1)
		q := rank0 / block
		rank0 %= block
		result << remaining[q]
		remaining.delete(q)
	}
	return result
}

fn oracle_bowl_order_from_drop(drop BigInt) []int {
	one_based := int(big_mod_small_nonnegative(big_sub(drop, big_one()), 720)) + 1
	return oracle_permutation_unrank1(one_based)
}

fn oracle_initial_bowls(counts OracleWorkCounts) []BigInt {
	primes := [17, 19, 23, 29, 31, 37]
	mut bowls := []BigInt{cap: 6}
	for bowl_id in 1 .. 7 {
		mut s := counts.action
		s = big_add(s, big_mul_small(counts.target, u32(bowl_id)))
		s = big_add(s, counts.distance)
		s = big_add(s, counts.connection)
		s = big_add(s, big_from_int(counts.direction))
		s = big_add(s, big_from_int(primes[bowl_id - 1] * primes[bowl_id - 1]))
		bowls << oracle_save(big_add(big_square(s), big_from_int(bowl_id)))
	}
	return bowls
}

fn oracle_apply_visible_drops_to_bowls(initial []BigInt, visible []BigInt, stones []OracleStone) OracleSauceResult {
	mut bowls := initial.clone()
	mut order_at_drop46 := []int{}
	stone_by_position := [1, 2, 3, 4, 5, 1]
	for i in 1 .. 47 {
		drop := visible[i - 1]
		order := oracle_bowl_order_from_drop(drop)
		old := bowls.clone()
		mut pour := []BigInt{len: 6, init: big_zero()}
		first_id := order[0]
		second_id := order[1]
		third_id := order[2]
		pour[0] = oracle_save(big_add(big_add(big_square(drop), big_mul(stones[i - 1].w,
			old[first_id - 1])), big_from_int(3 * i)))
		pour[1] = oracle_save(big_add(big_add(big_square(drop), big_mul(stones[i - 1].b,
			old[second_id - 1])), big_from_int(5 * i)))
		pour[2] = oracle_save(big_add(big_add(big_square(drop), big_mul(stones[i - 1].s,
			old[third_id - 1])), big_from_int(7 * i)))
		mut next_bowls := []BigInt{len: 6, init: big_zero()}
		for position in 1 .. 7 {
			id := order[position - 1]
			prev_id := order[oracle_wrap1(position - 1, 6) - 1]
			next_id := order[oracle_wrap1(position + 1, 6) - 1]
			mut s := old[id - 1]
			s = big_add(s, big_mul_small(old[prev_id - 1], 2))
			s = big_add(s, big_mul_small(old[next_id - 1], 3))
			s = big_add(s, pour[position - 1])
			s = big_add(s, drop)
			s = big_add(s, oracle_stone_component(stones[i - 1], stone_by_position[position - 1]))
			mut mixed := big_square(s)
			mixed = big_add(mixed, big_mul_small(big_mul(old[prev_id - 1], old[next_id - 1]), 5))
			mixed = big_add(mixed, big_from_int(i * position))
			next_bowls[id - 1] = oracle_save(mixed)
		}
		bowls = next_bowls.clone()
		if i == 46 {
			order_at_drop46 = order.clone()
		}
	}
	return OracleSauceResult{
		bowls:           bowls
		order_at_drop46: order_at_drop46
	}
}

fn oracle_post_stir12(initial []BigInt) []BigInt {
	mut bowls := initial.clone()
	for stir in 1 .. 13 {
		old := bowls.clone()
		mut raw_sum := big_zero()
		for value in old {
			raw_sum = big_add(raw_sum, value)
		}
		saved_bowl_sum := oracle_save(big_add(raw_sum, big_from_int(149 * stir)))
		order_number := int(big_mod_small_nonnegative(big_sub(saved_bowl_sum, big_one()), 720)) + 1
		order := oracle_permutation_unrank1(order_number)
		mut next_bowls := []BigInt{len: 6, init: big_zero()}
		for position in 1 .. 7 {
			id := order[position - 1]
			prev_id := order[oracle_wrap1(position - 1, 6) - 1]
			next_id := order[oracle_wrap1(position + 1, 6) - 1]
			mut s := old[id - 1]
			s = big_add(s, big_mul_small(old[prev_id - 1], 3))
			s = big_add(s, big_mul_small(old[next_id - 1], 5))
			s = big_add(s, saved_bowl_sum)
			s = big_add(s, big_from_int(stir))
			s = big_add(s, big_from_int(position * position))
			mut mixed := big_square(s)
			mixed = big_add(mixed, big_mul_small(big_mul(old[prev_id - 1], old[next_id - 1]), 7))
			next_bowls[id - 1] = oracle_save(mixed)
		}
		bowls = next_bowls.clone()
	}
	return bowls
}

fn oracle_sauce(calculation_day BigInt, target_day BigInt) OracleSauceResult {
	counts := oracle_work_counts(calculation_day, target_day)
	stones := oracle_build_stones()
	hidden := oracle_build_hidden_drops(counts, stones)
	visible := oracle_build_visible_drops(counts, stones, hidden)
	bowls := oracle_initial_bowls(counts)
	after_drops := oracle_apply_visible_drops_to_bowls(bowls, visible, stones)
	final_bowls := oracle_post_stir12(after_drops.bowls)
	return OracleSauceResult{
		bowls:           final_bowls
		order_at_drop46: after_drops.order_at_drop46
	}
}

fn oracle_next_bowl_in_drop46_order(result OracleSauceResult, queried_id int) int {
	mut position := -1
	for i, id in result.order_at_drop46 {
		if id == queried_id {
			position = i
			break
		}
	}
	if position < 0 {
		panic('የተጠየቀው ሳህን በ46ኛው ቅደም ተከተል ውስጥ አልተገኘም')
	}
	return result.order_at_drop46[(position + 1) % 6]
}

fn oracle_ask_bowl(result OracleSauceResult, queried_id int, seal int) OracleAnswerStream {
	next_id := oracle_next_bowl_in_drop46_order(result, queried_id)
	mut first_left := big_add(result.bowls[queried_id - 1], big_from_int(seal + 181))
	first_left = big_square(first_left)
	mut first := big_add(first_left, big_mul_small(result.bowls[next_id - 1], 179))
	first = big_add(first, big_from_int(seal))
	first = oracle_save(first)
	mut direction_left := big_add(first, big_from_int(seal + 194))
	direction_left = big_square(direction_left)
	mut direction_number := big_add(direction_left, big_mul_small(first, 193))
	direction_number = big_add(direction_number, big_mul_small(result.bowls[5], 197))
	direction_number = oracle_save(direction_number)
	step := if big_mod_small_nonnegative(direction_number, 2) == 1 { 1 } else { -1 }
	return OracleAnswerStream{
		first: first
		step:  step
	}
}

fn oracle_answer_at(stream OracleAnswerStream, k BigInt) BigInt {
	offset := if stream.step > 0 { k } else { big_neg(k) }
	return big_add(big_one(), big_regular_mod(big_add(big_sub(stream.first, big_one()), offset),
		oracle_m()))
}

fn oracle_choose_rank_short(stream OracleAnswerStream, n BigInt) BigInt {
	m := oracle_m()
	acceptance_limit := big_mul(big_floor_div(m, n), n)
	mut k := big_zero()
	for {
		x := oracle_answer_at(stream, k)
		if big_cmp(x, acceptance_limit) <= 0 {
			return big_add(big_one(), big_regular_mod(big_sub(x, big_one()), n))
		}
		k = big_add(k, big_one())
	}
	return big_zero()
}

fn oracle_choose_rank_wide(stream OracleAnswerStream, n BigInt) BigInt {
	m := oracle_m()
	mut places := 1
	mut space := m
	for big_cmp(space, n) < 0 {
		places++
		space = big_mul(space, m)
	}
	mut wide := big_one()
	mut weight := big_one()
	for j in 0 .. places {
		digit := big_sub(oracle_answer_at(stream, big_from_int(j)), big_one())
		wide = big_add(wide, big_mul(digit, weight))
		weight = big_mul(weight, m)
	}
	acceptance_limit := big_mul(big_floor_div(space, n), n)
	for big_cmp(wide, acceptance_limit) > 0 {
		step := if stream.step > 0 { big_one() } else { big_neg(big_one()) }
		wide = big_add(big_one(), big_regular_mod(big_add(big_sub(wide, big_one()), step), space))
	}
	return big_add(big_one(), big_regular_mod(big_sub(wide, big_one()), n))
}

fn oracle_choose_rank(stream OracleAnswerStream, n BigInt) BigInt {
	if big_cmp(n, oracle_m()) <= 0 {
		return oracle_choose_rank_short(stream, n)
	}
	return oracle_choose_rank_wide(stream, n)
}

fn oracle_falling_factorial(n int, k int) BigInt {
	mut result := big_one()
	for j in 0 .. k {
		result = big_mul_small(result, u32(n - j))
	}
	return result
}

fn oracle_unrank_distinct_names(n int, k int, rank1 BigInt) []int {
	mut remaining := []int{cap: n}
	for i in 1 .. n + 1 {
		remaining << i
	}
	mut out := []int{cap: k}
	mut rank := rank1
	for position in 0 .. k {
		suffix_length := k - position - 1
		block := oracle_falling_factorial(remaining.len - 1, suffix_length)
		mut chosen := -1
		for candidate in 0 .. remaining.len {
			if big_cmp(rank, block) > 0 {
				rank = big_sub(rank, block)
			} else {
				chosen = candidate
				break
			}
		}
		if chosen < 0 {
			panic('የተለያዩ ስሞች ደረጃ ከቤተሰቡ ወሰን ውጭ ነው')
		}
		out << remaining[chosen]
		remaining.delete(chosen)
	}
	return out
}

struct OracleBoundedCompositionCounter {
	total int
	slots int
	lo    int
	hi    int
mut:
	memo map[string]BigInt
}

fn new_oracle_bounded_counter(total int, slots int, lo int, hi int) OracleBoundedCompositionCounter {
	return OracleBoundedCompositionCounter{
		total: total
		slots: slots
		lo:    lo
		hi:    hi
		memo:  map[string]BigInt{}
	}
}

fn (mut c OracleBoundedCompositionCounter) count(rem int, slots int) BigInt {
	if slots == 0 {
		return if rem == 0 { big_one() } else { big_zero() }
	}
	if rem < slots * c.lo || rem > slots * c.hi {
		return big_zero()
	}
	key := '${rem}:${slots}'
	if key in c.memo {
		return c.memo[key]
	}
	mut total := big_zero()
	for x in c.lo .. c.hi + 1 {
		total = big_add(total, c.count(rem - x, slots - 1))
	}
	c.memo[key] = total
	return total
}

fn (mut c OracleBoundedCompositionCounter) count_all() BigInt {
	return c.count(c.total, c.slots)
}

fn (mut c OracleBoundedCompositionCounter) unrank1(rank1 BigInt) []int {
	mut rank := rank1
	mut rem := c.total
	mut out := []int{cap: c.slots}
	for position in 0 .. c.slots {
		for x in c.lo .. c.hi + 1 {
			block := c.count(rem - x, c.slots - position - 1)
			if big_cmp(rank, block) > 0 {
				rank = big_sub(rank, block)
			} else {
				out << x
				rem -= x
				break
			}
		}
	}
	return out
}

struct OracleCutletPartitionCounter {
	g        int
	k        int
	required int
mut:
	memo map[string]BigInt
}

fn new_oracle_cutlet_partition_counter(g int, k int, required int) OracleCutletPartitionCounter {
	return OracleCutletPartitionCounter{
		g:        g
		k:        k
		required: required
		memo:     map[string]BigInt{}
	}
}

fn (mut c OracleCutletPartitionCounter) count(rem int, slots int, cumulative int, hit bool) BigInt {
	if slots == 0 {
		if rem != 0 {
			return big_zero()
		}
		if c.required < 0 {
			return big_one()
		}
		return if hit { big_one() } else { big_zero() }
	}
	if rem < slots {
		return big_zero()
	}
	key := '${rem}:${slots}:${cumulative}:${hit}'
	if key in c.memo {
		return c.memo[key]
	}
	mut total := big_zero()
	max_x := rem - (slots - 1)
	for x in 1 .. max_x + 1 {
		next_cumulative := cumulative + x
		mut next_hit := hit
		if c.required >= 0 && !hit {
			if next_cumulative == c.required {
				next_hit = true
			} else if next_cumulative > c.required {
				continue
			}
		}
		total = big_add(total, c.count(rem - x, slots - 1, next_cumulative, next_hit))
	}
	c.memo[key] = total
	return total
}

fn (mut c OracleCutletPartitionCounter) count_all() BigInt {
	return c.count(c.g, c.k, 0, false)
}

fn (mut c OracleCutletPartitionCounter) unrank1(rank1 BigInt) []int {
	mut rank := rank1
	mut rem := c.g
	mut slots := c.k
	mut cumulative := 0
	mut hit := false
	mut out := []int{cap: c.k}
	for slots > 0 {
		max_x := rem - (slots - 1)
		for x in 1 .. max_x + 1 {
			next_cumulative := cumulative + x
			mut next_hit := hit
			if c.required >= 0 && !hit {
				if next_cumulative == c.required {
					next_hit = true
				} else if next_cumulative > c.required {
					continue
				}
			}
			block := c.count(rem - x, slots - 1, next_cumulative, next_hit)
			if big_cmp(rank, block) > 0 {
				rank = big_sub(rank, block)
			} else {
				out << x
				rem -= x
				slots--
				cumulative = next_cumulative
				hit = next_hit
				break
			}
		}
	}
	return out
}

struct OracleWeaveState {
	remaining    []int
	opened_up_to int
	closed_up_to int
}

struct OracleWeaveCounter {
	lengths []int
mut:
	memo map[string]BigInt
}

fn new_oracle_weave_counter(lengths []int) OracleWeaveCounter {
	return OracleWeaveCounter{
		lengths: lengths.clone()
		memo:    map[string]BigInt{}
	}
}

fn oracle_weave_state_key(state OracleWeaveState) string {
	mut key := '${state.opened_up_to}:${state.closed_up_to}:'
	for i, value in state.remaining {
		if i > 0 {
			key += ','
		}
		key += value.str()
	}
	return key
}

fn (c OracleWeaveCounter) legal_move(state OracleWeaveState, j int) bool {
	idx := j - 1
	if state.remaining[idx] == 0 {
		return false
	}
	already_opened := state.remaining[idx] < c.lengths[idx]
	if !already_opened && j != state.opened_up_to + 1 {
		return false
	}
	will_close := state.remaining[idx] == 1
	if will_close && j != state.closed_up_to + 1 {
		return false
	}
	return true
}

fn (c OracleWeaveCounter) apply_move(state OracleWeaveState, j int) OracleWeaveState {
	mut remaining := state.remaining.clone()
	mut opened := state.opened_up_to
	mut closed := state.closed_up_to
	idx := j - 1
	if remaining[idx] == c.lengths[idx] {
		opened = j
	}
	remaining[idx]--
	if remaining[idx] == 0 {
		closed = j
	}
	return OracleWeaveState{
		remaining:    remaining
		opened_up_to: opened
		closed_up_to: closed
	}
}

fn (mut c OracleWeaveCounter) count(state OracleWeaveState) BigInt {
	mut done := true
	for value in state.remaining {
		if value != 0 {
			done = false
			break
		}
	}
	if done {
		return big_one()
	}
	key := oracle_weave_state_key(state)
	if key in c.memo {
		return c.memo[key]
	}
	mut total := big_zero()
	for j in 1 .. c.lengths.len + 1 {
		if c.legal_move(state, j) {
			total = big_add(total, c.count(c.apply_move(state, j)))
		}
	}
	c.memo[key] = total
	return total
}

fn (mut c OracleWeaveCounter) initial_state() OracleWeaveState {
	return OracleWeaveState{
		remaining:    c.lengths.clone()
		opened_up_to: 0
		closed_up_to: 0
	}
}

fn (mut c OracleWeaveCounter) count_all() BigInt {
	return c.count(c.initial_state())
}

fn (mut c OracleWeaveCounter) unrank1(rank1 BigInt) []int {
	mut state := c.initial_state()
	mut rank := rank1
	mut target_length := 0
	for value in c.lengths {
		target_length += value
	}
	mut out := []int{cap: target_length}
	for out.len < target_length {
		for j in 1 .. c.lengths.len + 1 {
			if !c.legal_move(state, j) {
				continue
			}
			next := c.apply_move(state, j)
			block := c.count(next)
			if big_cmp(rank, block) > 0 {
				rank = big_sub(rank, block)
			} else {
				out << j
				state = next
				break
			}
		}
	}
	return out
}

fn (mut e OracleEngine) positive_gate_gap(n BigInt) int {
	target := big_add(oracle_foundation_day(), n)
	result := oracle_sauce(oracle_foundation_day(), target)
	stream := oracle_ask_bowl(result, 1, 1)
	rank := oracle_choose_rank(stream, big_from_int(922))
	return 41 + (big_to_int(rank) or { panic(err.msg()) })
}

fn (mut e OracleEngine) negative_gate_gap(n BigInt) int {
	target := big_sub(oracle_foundation_day(), n)
	result := oracle_sauce(oracle_foundation_day(), target)
	stream := oracle_ask_bowl(result, 1, 1)
	rank := oracle_choose_rank(stream, big_from_int(922))
	return 41 + (big_to_int(rank) or { panic(err.msg()) })
}

fn (mut e OracleEngine) gate_value(index BigInt) BigInt {
	key := index.str()
	if key !in e.gate_cache.gates {
		return e.ensure_gate_index(index)
	}
	return e.gate_cache.gates[key]
}

fn (mut e OracleEngine) ensure_gate_index(index BigInt) BigInt {
	if big_cmp(index, e.gate_cache.max_index) > 0 {
		mut n := big_add(e.gate_cache.max_index, big_one())
		for big_cmp(n, index) <= 0 {
			previous_index := big_sub(n, big_one())
			previous := e.gate_cache.gates[previous_index.str()]
			gap := e.positive_gate_gap(n)
			e.gate_cache.gates[n.str()] = big_add(previous, big_from_int(gap))
			e.gate_cache.max_index = n
			n = big_add(n, big_one())
		}
	}
	if big_cmp(index, e.gate_cache.min_index) < 0 {
		mut n := big_sub(e.gate_cache.min_index, big_one())
		for big_cmp(n, index) >= 0 {
			next_index := big_add(n, big_one())
			next_day := e.gate_cache.gates[next_index.str()]
			gap := e.negative_gate_gap(big_abs(n))
			e.gate_cache.gates[n.str()] = big_sub(next_day, big_from_int(gap))
			e.gate_cache.min_index = n
			n = big_sub(n, big_one())
		}
	}
	return e.gate_cache.gates[index.str()]
}

fn (mut e OracleEngine) ensure_gates_cover(low_day BigInt, high_day BigInt) {
	for big_cmp(e.gate_cache.gates[e.gate_cache.min_index.str()], low_day) > 0 {
		e.ensure_gate_index(big_sub(e.gate_cache.min_index, big_one()))
	}
	for big_cmp(e.gate_cache.gates[e.gate_cache.max_index.str()], high_day) < 0 {
		e.ensure_gate_index(big_add(e.gate_cache.max_index, big_one()))
	}
}

fn (mut e OracleEngine) gate_index_at_or_before(day BigInt) BigInt {
	e.ensure_gates_cover(day, day)
	mut low := e.gate_cache.min_index
	mut high := e.gate_cache.max_index
	for big_cmp(low, high) < 0 {
		distance := big_sub(high, low)
		mid := big_add(low, big_floor_div(big_add(distance, big_one()), big_from_int(2)))
		mid_day := e.gate_cache.gates[mid.str()]
		if big_cmp(mid_day, day) <= 0 {
			low = mid
		} else {
			high = big_sub(mid, big_one())
		}
	}
	return low
}

fn (mut e OracleEngine) exact_gate_index(day BigInt) (bool, BigInt) {
	index := e.gate_index_at_or_before(day)
	if big_eq(e.gate_cache.gates[index.str()], day) {
		return true, index
	}
	return false, big_zero()
}

struct OracleYearCandidate {
	open_index  BigInt
	close_index BigInt
	length      BigInt
	open_day    BigInt
}

fn oracle_valid_year_pair(mut e OracleEngine, open_index BigInt, close_index BigInt) bool {
	gaps := big_sub(close_index, open_index)
	if big_cmp(gaps, big_from_int(6)) < 0 {
		return false
	}
	open_day := e.gate_value(open_index)
	close_day := e.gate_value(close_index)
	length := big_sub(close_day, open_day)
	return big_cmp(length, big_from_int(252)) >= 0 && big_cmp(length, big_from_int(5778)) <= 0
}

fn oracle_sort_anchor_candidates(mut list []OracleYearCandidate) {
	for i in 1 .. list.len {
		value := list[i]
		mut j := i
		for j > 0 {
			left := list[j - 1]
			length_cmp := big_cmp(left.length, value.length)
			open_cmp := big_cmp(left.open_day, value.open_day)
			should_move := length_cmp > 0 || (length_cmp == 0 && open_cmp > 0)
			if !should_move {
				break
			}
			list[j] = list[j - 1]
			j--
		}
		list[j] = value
	}
}

fn oracle_sort_year_candidates_stable(mut list []OracleYearCandidate) {
	for i in 1 .. list.len {
		value := list[i]
		mut j := i
		for j > 0 && big_cmp(list[j - 1].length, value.length) > 0 {
			list[j] = list[j - 1]
			j--
		}
		list[j] = value
	}
}

fn (mut e OracleEngine) year5000(calculation_day BigInt) OracleYear {
	span := big_from_int(5778)
	e.ensure_gates_cover(big_sub(calculation_day, span), big_add(calculation_day, span))
	mut candidates := []OracleYearCandidate{}
	mut i := e.gate_cache.min_index
	for big_cmp(i, e.gate_cache.max_index) < 0 {
		mut j := big_add(i, big_one())
		for big_cmp(j, e.gate_cache.max_index) <= 0 {
			open_day := e.gate_cache.gates[i.str()]
			close_day := e.gate_cache.gates[j.str()]
			length := big_sub(close_day, open_day)
			if big_cmp(length, big_from_int(5778)) > 0 {
				break
			}
			if oracle_valid_year_pair(mut e, i, j) && big_cmp(open_day, calculation_day) < 0
				&& big_cmp(calculation_day, close_day) <= 0 {
				candidates << OracleYearCandidate{
					open_index:  i
					close_index: j
					length:      length
					open_day:    open_day
				}
			}
			j = big_add(j, big_one())
		}
		i = big_add(i, big_one())
	}
	if candidates.len == 0 {
		panic('የ5000ኛው ዓመት ተፈቃጅ አልተገኘም')
	}
	oracle_sort_anchor_candidates(mut candidates)
	result := oracle_sauce(calculation_day, calculation_day)
	stream := oracle_ask_bowl(result, 1, 10)
	rank := oracle_choose_rank(stream, big_from_int(candidates.len))
	index := (big_to_int(rank) or { panic(err.msg()) }) - 1
	chosen := candidates[index]
	return OracleYear{
		number:           big_from_int(5000)
		open_gate_index:  chosen.open_index
		close_gate_index: chosen.close_index
		open_gate_day:    e.gate_value(chosen.open_index)
		close_gate_day:   e.gate_value(chosen.close_index)
	}
}

fn (mut e OracleEngine) next_year(calculation_day BigInt, known OracleYear) OracleYear {
	open_index := known.close_gate_index
	open_day := e.gate_value(open_index)
	e.ensure_gates_cover(e.gate_cache.gates[e.gate_cache.min_index.str()], big_add(open_day,
		big_from_int(5778)))
	mut candidates := []OracleYearCandidate{}
	mut close_index := big_add(open_index, big_one())
	for {
		close_day := e.ensure_gate_index(close_index)
		length := big_sub(close_day, open_day)
		if big_cmp(length, big_from_int(5778)) > 0 {
			break
		}
		if oracle_valid_year_pair(mut e, open_index, close_index) {
			candidates << OracleYearCandidate{
				open_index:  open_index
				close_index: close_index
				length:      length
				open_day:    open_day
			}
		}
		close_index = big_add(close_index, big_one())
	}
	if candidates.len == 0 {
		panic('የሚቀጥለው ዓመት ተፈቃጅ አልተገኘም')
	}
	oracle_sort_year_candidates_stable(mut candidates)
	result := oracle_sauce(calculation_day, open_day)
	stream := oracle_ask_bowl(result, 1, 11)
	rank := oracle_choose_rank(stream, big_from_int(candidates.len))
	index := (big_to_int(rank) or { panic(err.msg()) }) - 1
	chosen := candidates[index]
	return OracleYear{
		number:           big_add(known.number, big_one())
		open_gate_index:  chosen.open_index
		close_gate_index: chosen.close_index
		open_gate_day:    open_day
		close_gate_day:   e.gate_value(chosen.close_index)
	}
}

fn (mut e OracleEngine) previous_year(calculation_day BigInt, known OracleYear) OracleYear {
	close_index := known.open_gate_index
	close_day := e.gate_value(close_index)
	e.ensure_gates_cover(big_sub(close_day, big_from_int(5778)),
		e.gate_cache.gates[e.gate_cache.max_index.str()])
	mut candidates := []OracleYearCandidate{}
	mut open_index := big_sub(close_index, big_one())
	for {
		open_day := e.ensure_gate_index(open_index)
		length := big_sub(close_day, open_day)
		if big_cmp(length, big_from_int(5778)) > 0 {
			break
		}
		if oracle_valid_year_pair(mut e, open_index, close_index) {
			candidates << OracleYearCandidate{
				open_index:  open_index
				close_index: close_index
				length:      length
				open_day:    open_day
			}
		}
		open_index = big_sub(open_index, big_one())
	}
	if candidates.len == 0 {
		panic('የቀድሞው ዓመት ተፈቃጅ አልተገኘም')
	}
	oracle_sort_year_candidates_stable(mut candidates)
	result := oracle_sauce(calculation_day, close_day)
	stream := oracle_ask_bowl(result, 1, 12)
	rank := oracle_choose_rank(stream, big_from_int(candidates.len))
	index := (big_to_int(rank) or { panic(err.msg()) }) - 1
	chosen := candidates[index]
	return OracleYear{
		number:           big_sub(known.number, big_one())
		open_gate_index:  chosen.open_index
		close_gate_index: chosen.close_index
		open_gate_day:    e.gate_value(chosen.open_index)
		close_gate_day:   close_day
	}
}

fn (mut e OracleEngine) find_target_year(calculation_day BigInt, target_day BigInt) OracleYear {
	mut year := e.year5000(calculation_day)
	for big_cmp(target_day, year.close_gate_day) > 0 {
		year = e.next_year(calculation_day, year)
	}
	for big_cmp(target_day, year.open_gate_day) <= 0 {
		year = e.previous_year(calculation_day, year)
	}
	if !(big_cmp(year.open_gate_day, target_day) < 0
		&& big_cmp(target_day, year.close_gate_day) <= 0) {
		panic('የታለመው ቀን በተመረጠው ዓመት ውስጥ አይደለም')
	}
	return year
}

fn (mut e OracleEngine) choose_cutlet_count(structure_sauce OracleSauceResult, year OracleYear) int {
	gaps_big := big_sub(year.close_gate_index, year.open_gate_index)
	gaps := big_to_int(gaps_big) or { panic(err.msg()) }
	mut candidates := []int{}
	for k in 6 .. 18 {
		if k <= gaps {
			candidates << k
		}
	}
	stream := oracle_ask_bowl(structure_sauce, 2, 20)
	rank := oracle_choose_rank(stream, big_from_int(candidates.len))
	return candidates[(big_to_int(rank) or { panic(err.msg()) }) - 1]
}

fn (mut e OracleEngine) choose_cutlet_partition(calculation_day BigInt, structure_sauce OracleSauceResult,
	year OracleYear, cutlet_count int) []int {
	gaps := big_to_int(big_sub(year.close_gate_index, year.open_gate_index)) or { panic(err.msg()) }
	has_gate, gate_index := e.exact_gate_index(calculation_day)
	mut required := -1
	if has_gate && big_cmp(year.open_gate_index, gate_index) < 0
		&& big_cmp(gate_index, year.close_gate_index) < 0 {
		required = big_to_int(big_sub(gate_index, year.open_gate_index)) or { panic(err.msg()) }
	}
	mut family := new_oracle_cutlet_partition_counter(gaps, cutlet_count, required)
	count := family.count_all()
	stream := oracle_ask_bowl(structure_sauce, 2, 21)
	rank := oracle_choose_rank(stream, count)
	return family.unrank1(rank)
}

fn oracle_choose_cutlet_names(structure_sauce OracleSauceResult, cutlet_count int) []int {
	count := oracle_falling_factorial(17, cutlet_count)
	stream := oracle_ask_bowl(structure_sauce, 5, 22)
	rank := oracle_choose_rank(stream, count)
	return oracle_unrank_distinct_names(17, cutlet_count, rank)
}

fn (mut e OracleEngine) materialize_cutlets(year OracleYear, partition []int, names []int) []OracleCutlet {
	mut cursor := year.open_gate_index
	mut cutlets := []OracleCutlet{cap: partition.len}
	for i, width in partition {
		open_index := cursor
		close_index := big_add(cursor, big_from_int(width))
		cutlets << OracleCutlet{
			name_index:       names[i]
			open_gate_index:  open_index
			close_gate_index: close_index
			first_day:        big_add(e.gate_value(open_index), big_one())
			last_day:         e.gate_value(close_index)
		}
		cursor = close_index
	}
	return cutlets
}

fn oracle_choose_month_count(structure_sauce OracleSauceResult, year OracleYear) int {
	length := big_to_int(big_sub(year.close_gate_day, year.open_gate_day)) or { panic(err.msg()) }
	min_months := (length + 122) / 123
	mut max_months := length / 4
	if max_months > 47 {
		max_months = 47
	}
	if min_months < 3 || min_months > max_months || max_months > 47 {
		panic('የወር ብዛት ወሰን የማይቻል ሁኔታ ፈጥሯል')
	}
	stream := oracle_ask_bowl(structure_sauce, 3, 30)
	rank := oracle_choose_rank(stream, big_from_int(max_months - min_months + 1))
	return min_months + (big_to_int(rank) or { panic(err.msg()) }) - 1
}

fn oracle_choose_month_lengths(structure_sauce OracleSauceResult, year OracleYear, month_count int) []int {
	length := big_to_int(big_sub(year.close_gate_day, year.open_gate_day)) or { panic(err.msg()) }
	mut family := new_oracle_bounded_counter(length, month_count, 4, 123)
	count := family.count_all()
	stream := oracle_ask_bowl(structure_sauce, 3, 31)
	rank := oracle_choose_rank(stream, count)
	return family.unrank1(rank)
}

fn oracle_choose_month_weaving(structure_sauce OracleSauceResult, month_lengths []int) []int {
	mut family := new_oracle_weave_counter(month_lengths)
	count := family.count_all()
	stream := oracle_ask_bowl(structure_sauce, 4, 32)
	rank := oracle_choose_rank(stream, count)
	return family.unrank1(rank)
}

fn oracle_choose_month_names(structure_sauce OracleSauceResult, month_count int) []int {
	count := oracle_falling_factorial(47, month_count)
	stream := oracle_ask_bowl(structure_sauce, 5, 33)
	rank := oracle_choose_rank(stream, count)
	return oracle_unrank_distinct_names(47, month_count, rank)
}

fn (mut e OracleEngine) build_year_structure(calculation_day BigInt, year OracleYear) OracleYearStructure {
	first_day := big_add(year.open_gate_day, big_one())
	result := oracle_sauce(calculation_day, first_day)
	cutlet_count := e.choose_cutlet_count(result, year)
	partition := e.choose_cutlet_partition(calculation_day, result, year, cutlet_count)
	cutlet_names := oracle_choose_cutlet_names(result, cutlet_count)
	cutlets := e.materialize_cutlets(year, partition, cutlet_names)
	month_count := oracle_choose_month_count(result, year)
	month_lengths := oracle_choose_month_lengths(result, year, month_count)
	month_weaving := oracle_choose_month_weaving(result, month_lengths)
	month_names := oracle_choose_month_names(result, month_count)
	return OracleYearStructure{
		cutlet_count:     cutlet_count
		cutlet_partition: partition
		cutlet_names:     cutlet_names
		cutlets:          cutlets
		month_count:      month_count
		month_lengths:    month_lengths
		month_weaving:    month_weaving
		month_names:      month_names
	}
}

fn (mut e OracleEngine) calendar_date_normative(calculation_day BigInt, target_day BigInt) CalendarResult {
	year := e.find_target_year(calculation_day, target_day)
	structure := e.build_year_structure(calculation_day, year)
	mut chosen_cutlet := -1
	for i, cutlet in structure.cutlets {
		if big_cmp(cutlet.first_day, target_day) <= 0 && big_cmp(target_day, cutlet.last_day) <= 0 {
			chosen_cutlet = i
			break
		}
	}
	if chosen_cutlet < 0 {
		panic('የታለመውን ቀን የያዘ ቆራጭ አልተገኘም')
	}
	cutlet := structure.cutlets[chosen_cutlet]
	day_in_cutlet := big_add(big_sub(target_day, cutlet.first_day), big_one())
	year_offset := big_to_int(big_sub(target_day, big_add(year.open_gate_day, big_one()))) or {
		panic(err.msg())
	}
	month_id := structure.month_weaving[year_offset]
	mut day_in_month := 0
	for position in 0 .. year_offset + 1 {
		if structure.month_weaving[position] == month_id {
			day_in_month++
		}
	}
	return CalendarResult{
		year_number:   year.number
		cutlet_name:   cutlet_name_by_index(cutlet.name_index) or { panic(err.msg()) }
		day_in_cutlet: day_in_cutlet
		month_name:    month_name_by_index(structure.month_names[month_id - 1]) or {
			panic(err.msg())
		}
		day_in_month:  big_from_int(day_in_month)
	}
}

fn test_stage01_big_integer_exactness() {
	assert oracle_m().str() == '170141183460469231731687303715884105727'
	assert big_add(big_from_i64(999_999_999), big_from_i64(2)).str() == '1000000001'
	assert big_mul(big_from_i64(1_000_000_000), big_from_i64(1_000_000_000)).str() == '1000000000000000000'
	q1, r1 := big_div_mod_floor(big_from_i64(17), big_from_i64(5))
	assert q1.str() == '3'
	assert r1.str() == '2'
	q2, r2 := big_div_mod_floor(big_from_i64(-17), big_from_i64(5))
	assert q2.str() == '-4'
	assert r2.str() == '3'
}

fn test_stage01_anchor_and_save_fixtures() {
	assert big_sub(oracle_tablets_day(), oracle_foundation_day()).str() == '14777149'
	m := oracle_m()
	assert oracle_save(big_one()).str() == '1'
	assert oracle_save(big_sub(m, big_one())).str() == '170141183460469231731687303715884105726'
	assert oracle_save(m).str() == m.str()
	assert oracle_save(big_add(m, big_one())).str() == '1'
	assert oracle_save(big_mul_small(m, 2)).str() == m.str()
}

fn test_stage01_day_count_fixtures() {
	foundation := oracle_foundation_day()
	assert oracle_day_count(foundation).str() == '1'
	assert oracle_day_count(big_sub(foundation, big_one())).str() == '2'
	assert oracle_day_count(big_add(foundation, big_one())).str() == '3'
	counts := oracle_work_counts(foundation, foundation)
	assert counts.action.str() == '1'
	assert counts.target.str() == '1'
	assert counts.distance.str() == '1'
	assert counts.connection.str() == '2'
	assert counts.direction == 2
}

fn test_stage01_stone_snapshot_fixture() {
	stones := oracle_build_stones()
	assert stones.len == 46
	second := stones[1]
	assert second.w.str() == '378'
	assert second.b.str() == '1073'
	assert second.s.str() == '2375'
	assert second.m.str() == '6195'
	assert second.r.str() == '10493'
}

fn test_stage01_permutation_fixtures() {
	assert oracle_permutation_unrank1(1) == [1, 2, 3, 4, 5, 6]
	assert oracle_permutation_unrank1(720) == [6, 5, 4, 3, 2, 1]
}

fn test_stage01_local_combinatorial_fixtures() {
	mut bounded := new_oracle_bounded_counter(5, 2, 1, 4)
	assert bounded.count_all().str() == '4'
	assert bounded.unrank1(big_from_int(3)) == [3, 2]
	mut cutlets := new_oracle_cutlet_partition_counter(6, 3, 3)
	assert cutlets.count_all().str() == '4'
	assert cutlets.unrank1(big_from_int(3)) == [3, 1, 2]
	mut weave := new_oracle_weave_counter([2, 2])
	assert weave.count_all().str() == '2'
	assert weave.unrank1(big_from_int(1)) == [1, 1, 2, 2]
	assert weave.unrank1(big_from_int(2)) == [1, 2, 1, 2]
	assert oracle_falling_factorial(17, 6).str() == '8910720'
	assert oracle_unrank_distinct_names(4, 2, big_one()) == [1, 2]
}

fn test_stage01_source_language_catalog_is_index_stable() {
	catalog := source_language_catalog()
	assert source_language_catalog_version == '1.3.1'
	assert catalog.len == 64
	mut cutlets := 0
	mut months := 0
	for item in catalog {
		if item.kind == .cutlet {
			cutlets++
			assert item.canonical_index == cutlets
		} else {
			months++
			assert item.canonical_index == months
		}
	}
	assert cutlets == 17
	assert months == 47
	assert cutlet_name_by_index(12) or { '' } == 'ስንዴ'
	assert month_name_by_index(44) or { '' } == 'ጨው'
	mut altered := source_language_catalog()
	altered.delete(0)
	assert source_language_catalog().len == 64
}

fn test_stage01_base_monster_shell_is_neutral() {
	context := bootstrap_validate(oracle_foundation_day(), oracle_foundation_day()) or {
		panic(err.msg())
	}
	assert context.phase == 'BOOTSTRAP'
	assert context.mode == 'BASE_ONLY'
	assert context.status == 'READY_FOR_HISTORICAL_GROWTH'
	assert context.branch_trace == ['BOOTSTRAP_VALIDATED']
	assert context.metrics['bootstrap.validations'] == 1
}
