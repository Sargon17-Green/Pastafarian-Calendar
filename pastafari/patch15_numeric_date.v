module pastafari

// Stage 31 numerical candidate. Oracle remains test-only; sauce, answer and
// rejection selection all follow corrected production PATCH routes.
fn patch15_foundation_day() BigInt {
	return big_from_i64(-15_055_671)
}

fn patch15_sauce(calculation_day BigInt, target_day BigInt) Patch15SauceChainResult {
	return calendar_patch15_sauce_chain_spaghetti(calculation_day, target_day) or {
		panic(err.msg())
	}
}

fn patch15_ask_bowl(result Patch15SauceChainResult, queried_id int, seal int) AnswerStream {
	return calendar_answer_stream_spaghetti(result.bowls, result.order_at_drop46, queried_id,
		big_from_int(seal)) or { panic(err.msg()) }
}

fn patch15_choose_rank(stream AnswerStream, n BigInt) BigInt {
	return calendar_choose_rank_spaghetti(stream, n) or { panic(err.msg()) }
}

struct Patch15Year {
	number           BigInt
	open_gate_index  BigInt
	close_gate_index BigInt
	open_gate_day    BigInt
	close_gate_day   BigInt
}

struct Patch15Cutlet {
	name_index       int
	open_gate_index  BigInt
	close_gate_index BigInt
	first_day        BigInt
	last_day         BigInt
}

struct Patch15YearStructure {
	cutlet_count     int
	cutlet_partition []int
	cutlet_names     []int
	cutlets          []Patch15Cutlet
	month_count      int
	month_lengths    []int
	month_weaving    []int
	month_names      []int
}

struct Patch15GateCache {
mut:
	gates     map[string]BigInt
	min_index BigInt
	max_index BigInt
}

struct Patch15Engine {
mut:
	gate_cache Patch15GateCache
}

fn new_patch15_engine() Patch15Engine {
	foundation := big_from_i64(-15_055_671)
	mut gates := map[string]BigInt{}
	gates['0'] = foundation
	return Patch15Engine{
		gate_cache: Patch15GateCache{
			gates:     gates
			min_index: big_zero()
			max_index: big_zero()
		}
	}
}

fn patch15_falling_factorial(n int, k int) BigInt {
	mut result := big_one()
	for j in 0 .. k {
		result = big_mul_small(result, u32(n - j))
	}
	return result
}

fn patch15_unrank_distinct_names(n int, k int, rank1 BigInt) []int {
	mut remaining := []int{cap: n}
	for i in 1 .. n + 1 {
		remaining << i
	}
	mut out := []int{cap: k}
	mut rank := rank1
	for position in 0 .. k {
		suffix_length := k - position - 1
		block := patch15_falling_factorial(remaining.len - 1, suffix_length)
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

struct Patch15BoundedCompositionCounter {
	total int
	slots int
	lo    int
	hi    int
mut:
	memo map[string]BigInt
}

fn new_patch15_bounded_counter(total int, slots int, lo int, hi int) Patch15BoundedCompositionCounter {
	return Patch15BoundedCompositionCounter{
		total: total
		slots: slots
		lo:    lo
		hi:    hi
		memo:  map[string]BigInt{}
	}
}

fn (mut c Patch15BoundedCompositionCounter) count(rem int, slots int) BigInt {
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

fn (mut c Patch15BoundedCompositionCounter) count_all() BigInt {
	return c.count(c.total, c.slots)
}

fn (mut c Patch15BoundedCompositionCounter) unrank1(rank1 BigInt) []int {
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

struct Patch15CutletPartitionCounter {
	g        int
	k        int
	required int
mut:
	memo map[string]BigInt
}

fn new_patch15_cutlet_partition_counter(g int, k int, required int) Patch15CutletPartitionCounter {
	return Patch15CutletPartitionCounter{
		g:        g
		k:        k
		required: required
		memo:     map[string]BigInt{}
	}
}

fn (mut c Patch15CutletPartitionCounter) count(rem int, slots int, cumulative int, hit bool) BigInt {
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

fn (mut c Patch15CutletPartitionCounter) count_all() BigInt {
	return c.count(c.g, c.k, 0, false)
}

fn (mut c Patch15CutletPartitionCounter) unrank1(rank1 BigInt) []int {
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

struct Patch15WeaveState {
	remaining    []int
	opened_up_to int
	closed_up_to int
}

struct Patch15WeaveCounter {
	lengths []int
mut:
	memo          map[string]BigInt
	factor_matrix [][]BigInt
}

fn new_patch15_weave_counter(lengths []int) Patch15WeaveCounter {
	return Patch15WeaveCounter{
		lengths: lengths.clone()
		memo:    map[string]BigInt{}
	}
}

fn patch15_weave_state_key(state Patch15WeaveState) string {
	mut key := '${state.opened_up_to}:${state.closed_up_to}:'
	for i, value in state.remaining {
		if i > 0 {
			key += ','
		}
		key += value.str()
	}
	return key
}

fn (c Patch15WeaveCounter) legal_move(state Patch15WeaveState, j int) bool {
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

fn (c Patch15WeaveCounter) apply_move(state Patch15WeaveState, j int) Patch15WeaveState {
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
	return Patch15WeaveState{
		remaining:    remaining
		opened_up_to: opened
		closed_up_to: closed
	}
}

/*
An exact insertion DP for the same first/last-constrained multiset words.
This production implementation is independent of OracleEngine. For a new
month, choose its first position, force its last occurrence to be last, and
count the interior insertions with exact binomial coefficients. Every
intermediate BigInt division below has a mathematically integral result.
*/
fn patch15_weave_div_small(value BigInt, divisor int) BigInt {
	if divisor <= 0 || value.sign < 0 {
		panic('nonnegative exact weave division required')
	}
	if value.is_zero() {
		return big_zero()
	}
	mut limbs := []u32{len: value.limbs.len, init: 0}
	mut remainder := u64(0)
	for step in 0 .. value.limbs.len {
		i := value.limbs.len - 1 - step
		partial := remainder * bigint_base + u64(value.limbs[i])
		limbs[i] = u32(partial / u64(divisor))
		remainder = partial % u64(divisor)
	}
	if remainder != 0 {
		panic('non-exact weave division')
	}
	return big_normalized(1, limbs)
}

fn patch15_weave_choose_exact(n int, k int) BigInt {
	if k < 0 || k > n {
		return big_zero()
	}
	mut r := k
	if r > n - r {
		r = n - r
	}
	mut answer := big_one()
	for step in 1 .. r + 1 {
		product := big_mul_small(answer, u32(n - r + step))
		answer = patch15_weave_div_small(product, step)
	}
	return answer
}

/*
For k opened labels and L remaining opened-label occurrences, let s be
the length of the next unopened label. The exact insertion-factor recurrence:
F(k,L) = F(k,L-1) + C(L+s-2,s-2)*F(k+1,L+s-1),
F(k,0) = F(k+1,s-1), F(last,L) = 1.
This independent bottom-up table is shared by successive unrank calls.
*/
fn (mut c Patch15WeaveCounter) prepare_factor_matrix() {
	if c.factor_matrix.len > 0 {
		return
	}
	month_total := c.lengths.len
	mut prefix := []int{len: month_total + 1}
	for i in 0 .. month_total {
		prefix[i + 1] = prefix[i] + c.lengths[i]
	}
	mut factors := [][]BigInt{len: month_total + 1}
	factors[month_total] = []BigInt{len: prefix[month_total] + 1, init: big_one()}
	for delta in 1 .. month_total {
		opened := month_total - delta
		size := c.lengths[opened]
		mut row := []BigInt{len: prefix[opened] + 1, init: big_zero()}
		row[0] = factors[opened + 1][size - 1]
		mut coefficient := big_one()
		for left in 1 .. prefix[opened] + 1 {
			product := big_mul_small(coefficient, u32(left + size - 2))
			coefficient = patch15_weave_div_small(product, left)
			row[left] = big_add(row[left - 1], big_mul(coefficient, factors[opened + 1][left +
				size - 1]))
		}
		factors[opened] = row.clone()
	}
	c.factor_matrix = factors.clone()
}

fn (mut c Patch15WeaveCounter) count(state Patch15WeaveState) BigInt {
	mut unfinished := false
	for value in state.remaining {
		if value != 0 {
			unfinished = true
			break
		}
	}
	if !unfinished {
		return big_one()
	}
	if state.opened_up_to == 0 {
		return c.count(c.apply_move(state, 1))
	}
	key := patch15_weave_state_key(state)
	if key in c.memo {
		return c.memo[key]
	}
	mut ways_fixed := big_one()
	mut left := state.remaining[0]
	for j in 2 .. state.opened_up_to + 1 {
		rest := state.remaining[j - 1]
		if rest == 0 {
			if left > 0 {
				c.memo[key] = big_zero()
				return big_zero()
			}
		} else {
			ways_fixed = big_mul(ways_fixed, patch15_weave_choose_exact(left + rest - 1, rest - 1))
		}
		left += rest
	}
	c.prepare_factor_matrix()
	result := big_mul(ways_fixed, c.factor_matrix[state.opened_up_to][left])
	c.memo[key] = result
	return result
}

fn (mut c Patch15WeaveCounter) initial_state() Patch15WeaveState {
	return Patch15WeaveState{
		remaining:    c.lengths.clone()
		opened_up_to: 0
		closed_up_to: 0
	}
}

fn (mut c Patch15WeaveCounter) count_all() BigInt {
	return c.count(c.initial_state())
}

fn (mut c Patch15WeaveCounter) unrank1(rank1 BigInt) []int {
	mut state := c.initial_state()
	mut rank := rank1
	mut target_length := 0
	for value in c.lengths {
		target_length += value
	}
	mut out := []int{cap: target_length}
	c.prepare_factor_matrix()
	for out.len < target_length {
		if state.opened_up_to == 0 {
			out << 1
			state = c.apply_move(state, 1)
			continue
		}
		opened := state.opened_up_to
		closed := state.closed_up_to
		mut prefix := []BigInt{len: opened + 1, init: big_one()}
		mut suffix := []BigInt{len: opened + 1, init: big_one()}
		mut removed := []BigInt{len: opened, init: big_zero()}
		mut shifted := []BigInt{len: opened, init: big_one()}
		mut left := 0
		for i in closed .. opened {
			remaining := state.remaining[i]
			left += remaining
			prefix[i + 1] = big_mul(prefix[i], patch15_weave_choose_exact(left - 1,
				remaining - 1))
			if remaining > 1 {
				removed[i] = patch15_weave_choose_exact(left - 2, remaining - 2)
			} else if i == closed {
				removed[i] = big_one()
			}
			if i > closed {
				shifted[i] = patch15_weave_choose_exact(left - 2, remaining - 1)
			}
		}
		for offset in 0 .. opened - closed {
			i := opened - 1 - offset
			suffix[i] = big_mul(suffix[i + 1], shifted[i])
		}
		mut old_tail := big_zero()
		if left > 0 {
			old_tail = c.factor_matrix[opened][left - 1]
		}
		mut found := false
		for j in 1 .. c.lengths.len + 1 {
			if !c.legal_move(state, j) {
				continue
			}
			mut block := big_zero()
			if j <= opened {
				weight := big_mul(prefix[j - 1], removed[j - 1])
				block = big_mul(big_mul(weight, suffix[j]), old_tail)
			} else {
				size := c.lengths[opened]
				if size == 1 {
					block = big_mul(prefix[opened], c.factor_matrix[opened + 1][left])
				} else {
					weight := patch15_weave_choose_exact(left + size - 2, size - 2)
					block = big_mul(big_mul(prefix[opened], weight),
						c.factor_matrix[opened + 1][left + size - 1])
				}
			}
			if big_cmp(rank, block) > 0 {
				rank = big_sub(rank, block)
			} else {
				out << j
				state = c.apply_move(state, j)
				found = true
				break
			}
		}
		if !found {
			panic('invalid month weaving rank')
		}
	}
	return out
}

fn (mut e Patch15Engine) positive_gate_gap(n BigInt) int {
	target := big_add(patch15_foundation_day(), n)
	result := patch15_sauce(patch15_foundation_day(), target)
	stream := patch15_ask_bowl(result, 1, 1)
	rank := patch15_choose_rank(stream, big_from_int(922))
	return 41 + (big_to_int(rank) or { panic(err.msg()) })
}

fn (mut e Patch15Engine) negative_gate_gap(n BigInt) int {
	target := big_sub(patch15_foundation_day(), n)
	result := patch15_sauce(patch15_foundation_day(), target)
	stream := patch15_ask_bowl(result, 1, 1)
	rank := patch15_choose_rank(stream, big_from_int(922))
	return 41 + (big_to_int(rank) or { panic(err.msg()) })
}

fn (mut e Patch15Engine) gate_value(index BigInt) BigInt {
	key := index.str()
	if key !in e.gate_cache.gates {
		return e.ensure_gate_index(index)
	}
	return e.gate_cache.gates[key]
}

fn (mut e Patch15Engine) ensure_gate_index(index BigInt) BigInt {
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

fn (mut e Patch15Engine) ensure_gates_cover(low_day BigInt, high_day BigInt) {
	for big_cmp(e.gate_cache.gates[e.gate_cache.min_index.str()], low_day) > 0 {
		e.ensure_gate_index(big_sub(e.gate_cache.min_index, big_one()))
	}
	for big_cmp(e.gate_cache.gates[e.gate_cache.max_index.str()], high_day) < 0 {
		e.ensure_gate_index(big_add(e.gate_cache.max_index, big_one()))
	}
}

fn (mut e Patch15Engine) gate_index_at_or_before(day BigInt) BigInt {
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

fn (mut e Patch15Engine) exact_gate_index(day BigInt) (bool, BigInt) {
	index := e.gate_index_at_or_before(day)
	if big_eq(e.gate_cache.gates[index.str()], day) {
		return true, index
	}
	return false, big_zero()
}

struct Patch15YearCandidate {
	open_index  BigInt
	close_index BigInt
	length      BigInt
	open_day    BigInt
}

fn patch15_valid_year_pair(mut e Patch15Engine, open_index BigInt, close_index BigInt) bool {
	gaps := big_sub(close_index, open_index)
	if big_cmp(gaps, big_from_int(6)) < 0 {
		return false
	}
	open_day := e.gate_value(open_index)
	close_day := e.gate_value(close_index)
	length := big_sub(close_day, open_day)
	return big_cmp(length, big_from_int(252)) >= 0 && big_cmp(length, big_from_int(5778)) <= 0
}

fn patch15_sort_anchor_candidates(mut list []Patch15YearCandidate) {
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

fn patch15_sort_year_candidates_stable(mut list []Patch15YearCandidate) {
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

fn (mut e Patch15Engine) year5000(calculation_day BigInt) Patch15Year {
	span := big_from_int(5778)
	e.ensure_gates_cover(big_sub(calculation_day, span), big_add(calculation_day, span))
	mut candidates := []Patch15YearCandidate{}
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
			if patch15_valid_year_pair(mut e, i, j) && big_cmp(open_day, calculation_day) < 0
				&& big_cmp(calculation_day, close_day) <= 0 {
				candidates << Patch15YearCandidate{
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
	patch15_sort_anchor_candidates(mut candidates)
	result := patch15_sauce(calculation_day, calculation_day)
	stream := patch15_ask_bowl(result, 1, 10)
	rank := patch15_choose_rank(stream, big_from_int(candidates.len))
	index := (big_to_int(rank) or { panic(err.msg()) }) - 1
	chosen := candidates[index]
	return Patch15Year{
		number:           big_from_int(5000)
		open_gate_index:  chosen.open_index
		close_gate_index: chosen.close_index
		open_gate_day:    e.gate_value(chosen.open_index)
		close_gate_day:   e.gate_value(chosen.close_index)
	}
}

fn (mut e Patch15Engine) next_year(calculation_day BigInt, known Patch15Year) Patch15Year {
	open_index := known.close_gate_index
	open_day := e.gate_value(open_index)
	e.ensure_gates_cover(e.gate_cache.gates[e.gate_cache.min_index.str()], big_add(open_day,
		big_from_int(5778)))
	mut candidates := []Patch15YearCandidate{}
	mut close_index := big_add(open_index, big_one())
	for {
		close_day := e.ensure_gate_index(close_index)
		length := big_sub(close_day, open_day)
		if big_cmp(length, big_from_int(5778)) > 0 {
			break
		}
		if patch15_valid_year_pair(mut e, open_index, close_index) {
			candidates << Patch15YearCandidate{
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
	patch15_sort_year_candidates_stable(mut candidates)
	result := patch15_sauce(calculation_day, open_day)
	stream := patch15_ask_bowl(result, 1, 11)
	rank := patch15_choose_rank(stream, big_from_int(candidates.len))
	index := (big_to_int(rank) or { panic(err.msg()) }) - 1
	chosen := candidates[index]
	return Patch15Year{
		number:           big_add(known.number, big_one())
		open_gate_index:  chosen.open_index
		close_gate_index: chosen.close_index
		open_gate_day:    open_day
		close_gate_day:   e.gate_value(chosen.close_index)
	}
}

fn (mut e Patch15Engine) previous_year(calculation_day BigInt, known Patch15Year) Patch15Year {
	close_index := known.open_gate_index
	close_day := e.gate_value(close_index)
	e.ensure_gates_cover(big_sub(close_day, big_from_int(5778)),
		e.gate_cache.gates[e.gate_cache.max_index.str()])
	mut candidates := []Patch15YearCandidate{}
	mut open_index := big_sub(close_index, big_one())
	for {
		open_day := e.ensure_gate_index(open_index)
		length := big_sub(close_day, open_day)
		if big_cmp(length, big_from_int(5778)) > 0 {
			break
		}
		if patch15_valid_year_pair(mut e, open_index, close_index) {
			candidates << Patch15YearCandidate{
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
	patch15_sort_year_candidates_stable(mut candidates)
	result := patch15_sauce(calculation_day, close_day)
	stream := patch15_ask_bowl(result, 1, 12)
	rank := patch15_choose_rank(stream, big_from_int(candidates.len))
	index := (big_to_int(rank) or { panic(err.msg()) }) - 1
	chosen := candidates[index]
	return Patch15Year{
		number:           big_sub(known.number, big_one())
		open_gate_index:  chosen.open_index
		close_gate_index: chosen.close_index
		open_gate_day:    e.gate_value(chosen.open_index)
		close_gate_day:   close_day
	}
}

fn (mut e Patch15Engine) find_target_year(calculation_day BigInt, target_day BigInt) Patch15Year {
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

fn (mut e Patch15Engine) choose_cutlet_count(structure_sauce Patch15SauceChainResult, year Patch15Year) int {
	gaps_big := big_sub(year.close_gate_index, year.open_gate_index)
	gaps := big_to_int(gaps_big) or { panic(err.msg()) }
	mut candidates := []int{}
	for k in 6 .. 18 {
		if k <= gaps {
			candidates << k
		}
	}
	stream := patch15_ask_bowl(structure_sauce, 2, 20)
	rank := patch15_choose_rank(stream, big_from_int(candidates.len))
	return candidates[(big_to_int(rank) or { panic(err.msg()) }) - 1]
}

fn (mut e Patch15Engine) choose_cutlet_partition(calculation_day BigInt, structure_sauce Patch15SauceChainResult,
	year Patch15Year, cutlet_count int) []int {
	gaps := big_to_int(big_sub(year.close_gate_index, year.open_gate_index)) or { panic(err.msg()) }
	has_gate, gate_index := e.exact_gate_index(calculation_day)
	mut required := -1
	if has_gate && big_cmp(year.open_gate_index, gate_index) < 0
		&& big_cmp(gate_index, year.close_gate_index) < 0 {
		required = big_to_int(big_sub(gate_index, year.open_gate_index)) or { panic(err.msg()) }
	}
	mut family := new_patch15_cutlet_partition_counter(gaps, cutlet_count, required)
	count := family.count_all()
	stream := patch15_ask_bowl(structure_sauce, 2, 21)
	rank := patch15_choose_rank(stream, count)
	return family.unrank1(rank)
}

fn patch15_choose_cutlet_names(structure_sauce Patch15SauceChainResult, cutlet_count int) []int {
	count := patch15_falling_factorial(17, cutlet_count)
	stream := patch15_ask_bowl(structure_sauce, 5, 22)
	rank := patch15_choose_rank(stream, count)
	return patch15_unrank_distinct_names(17, cutlet_count, rank)
}

fn (mut e Patch15Engine) materialize_cutlets(year Patch15Year, partition []int, names []int) []Patch15Cutlet {
	mut cursor := year.open_gate_index
	mut cutlets := []Patch15Cutlet{cap: partition.len}
	for i, width in partition {
		open_index := cursor
		close_index := big_add(cursor, big_from_int(width))
		cutlets << Patch15Cutlet{
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

fn patch15_choose_month_count(structure_sauce Patch15SauceChainResult, year Patch15Year) int {
	length := big_to_int(big_sub(year.close_gate_day, year.open_gate_day)) or { panic(err.msg()) }
	min_months := (length + 122) / 123
	mut max_months := length / 4
	if max_months > 47 {
		max_months = 47
	}
	if min_months < 3 || min_months > max_months || max_months > 47 {
		panic('የወር ብዛት ወሰን የማይቻል ሁኔታ ፈጥሯል')
	}
	stream := patch15_ask_bowl(structure_sauce, 3, 30)
	rank := patch15_choose_rank(stream, big_from_int(max_months - min_months + 1))
	return min_months + (big_to_int(rank) or { panic(err.msg()) }) - 1
}

fn patch15_choose_month_lengths(structure_sauce Patch15SauceChainResult, year Patch15Year, month_count int) []int {
	length := big_to_int(big_sub(year.close_gate_day, year.open_gate_day)) or { panic(err.msg()) }
	mut family := new_patch15_bounded_counter(length, month_count, 4, 123)
	count := family.count_all()
	stream := patch15_ask_bowl(structure_sauce, 3, 31)
	rank := patch15_choose_rank(stream, count)
	return family.unrank1(rank)
}

fn patch15_choose_month_weaving(structure_sauce Patch15SauceChainResult, month_lengths []int) []int {
	mut family := new_patch15_weave_counter(month_lengths)
	count := family.count_all()
	stream := patch15_ask_bowl(structure_sauce, 4, 32)
	rank := patch15_choose_rank(stream, count)
	return family.unrank1(rank)
}

fn patch15_choose_month_names(structure_sauce Patch15SauceChainResult, month_count int) []int {
	count := patch15_falling_factorial(47, month_count)
	stream := patch15_ask_bowl(structure_sauce, 5, 33)
	rank := patch15_choose_rank(stream, count)
	return patch15_unrank_distinct_names(47, month_count, rank)
}

fn (mut e Patch15Engine) build_year_structure(calculation_day BigInt, year Patch15Year) Patch15YearStructure {
	first_day := big_add(year.open_gate_day, big_one())
	result := patch15_sauce(calculation_day, first_day)
	cutlet_count := e.choose_cutlet_count(result, year)
	partition := e.choose_cutlet_partition(calculation_day, result, year, cutlet_count)
	cutlet_names := patch15_choose_cutlet_names(result, cutlet_count)
	cutlets := e.materialize_cutlets(year, partition, cutlet_names)
	month_count := patch15_choose_month_count(result, year)
	month_lengths := patch15_choose_month_lengths(result, year, month_count)
	month_weaving := patch15_choose_month_weaving(result, month_lengths)
	month_names := patch15_choose_month_names(result, month_count)
	return Patch15YearStructure{
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

fn (mut e Patch15Engine) calendar_date_numeric(calculation_day BigInt, target_day BigInt) CalendarResult {
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

// The diagnostic legacy entrypoint remains unchanged until Native acceptance.
pub fn calendar_date_patch15_numeric_spaghetti(calculation_day BigInt, target_day BigInt) !CalendarResult {
	mut engine := new_patch15_engine()
	result := engine.calendar_date_numeric(calculation_day, target_day)
	if !discovery15_output_shape_oracle(result) {
		return error('PATCH15 numeric candidate violates five-field contract')
	}
	return result
}
