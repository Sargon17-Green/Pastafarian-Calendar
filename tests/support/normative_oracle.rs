use num_bigint::{BigInt, BigUint, ToBigInt};
use num_integer::Integer;
use num_traits::{One, Signed, ToPrimitive, Zero};
use std::collections::{BTreeMap, HashMap};
use std::hash::{Hash, Hasher};

pub const TABLETS_DAY_I64: i64 = -278_522;
pub const FOUNDATION_DAY_I64: i64 = -15_055_671;
pub const GATE_GAP_MIN: usize = 42;
pub const GATE_GAP_MAX: usize = 963;
pub const YEAR_MIN_DAYS: usize = 252;
pub const YEAR_MAX_DAYS: usize = 5_778;
pub const MIN_GATE_GAPS_PER_YEAR: usize = 6;
pub const MIN_CUTLETS: usize = 6;
pub const MAX_CUTLETS: usize = 17;
pub const MIN_MONTHS: usize = 3;
pub const MAX_MONTHS: usize = 47;
pub const MIN_MONTH_DAYS: usize = 4;
pub const MAX_MONTH_DAYS: usize = 123;

pub const SEAL_GATE_GAP: u64 = 1;
pub const SEAL_YEAR_5000: u64 = 10;
pub const SEAL_NEXT_YEAR: u64 = 11;
pub const SEAL_PREVIOUS_YEAR: u64 = 12;
pub const SEAL_CUTLET_COUNT: u64 = 20;
pub const SEAL_CUTLET_PARTITION: u64 = 21;
pub const SEAL_CUTLET_NAMES: u64 = 22;
pub const SEAL_MONTH_COUNT: u64 = 30;
pub const SEAL_MONTH_LENGTHS: u64 = 31;
pub const SEAL_MONTH_WEAVING: u64 = 32;
pub const SEAL_MONTH_NAMES: u64 = 33;

pub fn foundation_day() -> BigInt {
    BigInt::from(FOUNDATION_DAY_I64)
}

pub fn tablets_day() -> BigInt {
    BigInt::from(TABLETS_DAY_I64)
}

pub fn m_bigint() -> BigInt {
    (BigInt::one() << 127usize) - BigInt::one()
}

pub fn m_biguint() -> BigUint {
    (BigUint::one() << 127usize) - BigUint::one()
}

pub fn regular_mod(x: &BigInt, d: &BigInt) -> BigInt {
    assert!(d > &BigInt::zero());
    x.mod_floor(d)
}

pub fn save(x: BigInt) -> BigInt {
    let m = m_bigint();
    BigInt::one() + regular_mod(&(x - BigInt::one()), &m)
}

pub fn ceil_div_usize(a: usize, b: usize) -> usize {
    assert!(b >= 1);
    (a + b - 1) / b
}

pub fn wrap1(position: isize, size: usize) -> usize {
    assert!(size >= 1);
    let s = size as isize;
    (((position - 1).rem_euclid(s)) + 1) as usize
}

pub fn day_count(day: &BigInt) -> BigInt {
    let foundation = foundation_day();
    if day == &foundation {
        return BigInt::one();
    }
    if day > &foundation {
        return BigInt::from(2u8) * (day - &foundation) + BigInt::one();
    }
    BigInt::from(2u8) * (&foundation - day)
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WorkCounts {
    pub action: BigInt,
    pub target: BigInt,
    pub distance: BigInt,
    pub connection: BigInt,
    pub direction: u8,
}

pub fn work_counts(calculation_day: &BigInt, target_day: &BigInt) -> WorkCounts {
    let action = day_count(calculation_day);
    let target = day_count(target_day);
    let distance = (target_day - calculation_day).abs() + BigInt::one();
    let connection = &action + &target;
    let direction = if target_day < calculation_day {
        1
    } else if target_day == calculation_day {
        2
    } else {
        3
    };
    WorkCounts {
        action,
        target,
        distance,
        connection,
        direction,
    }
}

pub type Stone = [BigInt; 5];

fn initial_stone() -> Stone {
    [17, 29, 43, 71, 101].map(BigInt::from)
}

pub fn build_stones() -> Vec<Stone> {
    let mut table = Vec::with_capacity(46);
    table.push(initial_stone());
    for i in 2u64..=46 {
        let old = table.last().expect("daş cədvəli boş qala bilməz").clone();
        let next = [
            save(&old[0] * &old[0] + BigInt::from(3u8) * &old[1] + BigInt::from(i)),
            save(&old[1] * &old[1] + BigInt::from(5u8) * &old[2] + &old[0]),
            save(&old[2] * &old[2] + BigInt::from(7u8) * &old[3] + &old[1]),
            save(&old[3] * &old[3] + BigInt::from(11u8) * &old[4] + &old[2]),
            save(&old[4] * &old[4] + BigInt::from(13u8) * &old[0] + &old[3]),
        ];
        table.push(next);
    }
    table
}

const HIDDEN_COEFF: [[u64; 4]; 7] = [
    [3, 4, 6, 8],
    [5, 7, 10, 12],
    [7, 10, 14, 16],
    [9, 13, 18, 20],
    [11, 16, 22, 24],
    [13, 19, 26, 28],
    [15, 22, 30, 32],
];

const HIDDEN_GRIND_STONE: [usize; 7] = [0, 1, 2, 3, 4, 0, 1];

pub fn build_hidden_drops(counts: &WorkCounts, stones: &[Stone]) -> Vec<BigInt> {
    let mut hidden = Vec::with_capacity(7);
    for k0 in 0usize..7 {
        let [a, b, c, d] = HIDDEN_COEFF[k0];
        let stone = &stones[k0];
        let mut x = &counts.action
            + BigInt::from(a) * &counts.target
            + BigInt::from(b) * &counts.distance
            + BigInt::from(c) * &counts.connection
            + BigInt::from(d) * BigInt::from(counts.direction);
        for value in stone {
            x += value;
        }
        x = save(x);
        for grind0 in 0usize..7 {
            let old = x;
            x = save(
                &old * &old
                    + BigInt::from(3u8) * &old
                    + &stone[HIDDEN_GRIND_STONE[grind0]]
                    + BigInt::from(grind0 + 1),
            );
        }
        hidden.push(x);
    }
    hidden
}

const VISIBLE_GRINDS: [[u64; 5]; 11] = [
    [3, 5, 7, 11, 0],
    [5, 7, 11, 13, 1],
    [7, 11, 13, 17, 2],
    [11, 13, 17, 19, 3],
    [13, 17, 19, 23, 4],
    [17, 19, 23, 29, 0],
    [19, 23, 29, 31, 1],
    [23, 29, 31, 37, 2],
    [29, 31, 37, 41, 3],
    [31, 37, 41, 43, 4],
    [37, 41, 43, 47, 0],
];

pub fn build_visible_drops(
    counts: &WorkCounts,
    stones: &[Stone],
    hidden: &[BigInt],
) -> Vec<BigInt> {
    let mut timeline: BTreeMap<i32, BigInt> = BTreeMap::new();
    for k0 in 0usize..7 {
        timeline.insert(-(k0 as i32), hidden[k0].clone());
    }
    for i in 1i32..=46 {
        let p1 = timeline
            .get(&(i - 1))
            .expect("birinci əvvəlki damcı tapılmalıdır")
            .clone();
        let p3 = timeline
            .get(&(i - 3))
            .expect("üçüncü əvvəlki damcı tapılmalıdır")
            .clone();
        let p7 = timeline
            .get(&(i - 7))
            .expect("yeddinci əvvəlki damcı tapılmalıdır")
            .clone();
        let stone = &stones[(i - 1) as usize];
        let mut x = save(
            &stone[0] * &counts.action
                + &stone[1] * &counts.target
                + &stone[2] * &counts.distance
                + &stone[3] * &counts.connection
                + &stone[4] * BigInt::from(counts.direction)
                + &p1
                + BigInt::from(3u8) * &p3
                + BigInt::from(5u8) * &p7
                + BigInt::from(i),
        );
        for row in VISIBLE_GRINDS {
            let old = x;
            let kind = row[4] as usize;
            x = save(
                &old * &old
                    + BigInt::from(row[0]) * &old
                    + BigInt::from(row[1]) * &p1
                    + BigInt::from(row[2]) * &p3
                    + BigInt::from(row[3]) * &p7
                    + &stone[kind],
            );
        }
        timeline.insert(i, x);
    }
    (1i32..=46)
        .map(|i| timeline.get(&i).expect("görünən damcı olmalıdır").clone())
        .collect()
}

pub fn permutation_unrank1(rank1: usize, items_ascending: &[u8]) -> Vec<u8> {
    assert!(rank1 >= 1);
    let mut rank0 = rank1 - 1;
    let mut remaining = items_ascending.to_vec();
    let mut result = Vec::with_capacity(remaining.len());
    while !remaining.is_empty() {
        let slots_left = remaining.len();
        let block = factorial_usize(slots_left - 1);
        let q = rank0 / block;
        rank0 %= block;
        result.push(remaining.remove(q));
    }
    result
}

fn factorial_usize(n: usize) -> usize {
    (1..=n).product::<usize>().max(1)
}

pub fn bowl_order_from_number(order_number: usize) -> [u8; 6] {
    assert!((1..=720).contains(&order_number));
    let v = permutation_unrank1(order_number, &[1, 2, 3, 4, 5, 6]);
    [v[0], v[1], v[2], v[3], v[4], v[5]]
}

pub fn bowl_order_from_drop(drop_value: &BigInt) -> [u8; 6] {
    let rank = regular_mod(&(drop_value - BigInt::one()), &BigInt::from(720u16))
        + BigInt::one();
    bowl_order_from_number(rank.to_usize().expect("sıra nömrəsi usize daxilindədir"))
}

pub type Bowls = [BigInt; 6];

const BOWL_PRIME: [u64; 6] = [17, 19, 23, 29, 31, 37];
const BOWL_STIR_STONE_BY_POSITION: [usize; 6] = [0, 1, 2, 3, 4, 0];

pub fn initial_bowls(counts: &WorkCounts) -> Bowls {
    std::array::from_fn(|idx| {
        let bowl_id = idx + 1;
        let s = &counts.action
            + BigInt::from(bowl_id) * &counts.target
            + &counts.distance
            + &counts.connection
            + BigInt::from(counts.direction)
            + BigInt::from(BOWL_PRIME[idx] * BOWL_PRIME[idx]);
        save(&s * &s + BigInt::from(bowl_id))
    })
}

pub fn apply_visible_drops_to_bowls(
    mut bowls: Bowls,
    visible: &[BigInt],
    stones: &[Stone],
) -> (Bowls, [u8; 6]) {
    let mut order_at_46 = [0u8; 6];
    for i0 in 0usize..46 {
        let i = i0 + 1;
        let drop = &visible[i0];
        let order = bowl_order_from_drop(drop);
        let old = bowls.clone();
        let first = usize::from(order[0] - 1);
        let second = usize::from(order[1] - 1);
        let third = usize::from(order[2] - 1);
        let mut pour = [BigInt::zero(), BigInt::zero(), BigInt::zero(), BigInt::zero(), BigInt::zero(), BigInt::zero()];
        pour[0] = save(drop * drop + &stones[i0][0] * &old[first] + BigInt::from(3usize * i));
        pour[1] = save(drop * drop + &stones[i0][1] * &old[second] + BigInt::from(5usize * i));
        pour[2] = save(drop * drop + &stones[i0][2] * &old[third] + BigInt::from(7usize * i));
        let mut next = old.clone();
        for position0 in 0usize..6 {
            let position = position0 + 1;
            let bowl_id = usize::from(order[position0] - 1);
            let prev_position = wrap1(position as isize - 1, 6) - 1;
            let next_position = wrap1(position as isize + 1, 6) - 1;
            let prev_id = usize::from(order[prev_position] - 1);
            let next_id = usize::from(order[next_position] - 1);
            let s = &old[bowl_id]
                + BigInt::from(2u8) * &old[prev_id]
                + BigInt::from(3u8) * &old[next_id]
                + &pour[position0]
                + drop
                + &stones[i0][BOWL_STIR_STONE_BY_POSITION[position0]];
            next[bowl_id] = save(
                &s * &s
                    + BigInt::from(5u8) * &old[prev_id] * &old[next_id]
                    + BigInt::from(i * position),
            );
        }
        bowls = next;
        if i == 46 {
            order_at_46 = order;
        }
    }
    (bowls, order_at_46)
}

pub fn post_stir12(mut bowls: Bowls) -> Bowls {
    for stir in 1usize..=12 {
        let old = bowls.clone();
        let mut raw = BigInt::zero();
        for value in &old {
            raw += value;
        }
        let saved_bowl_sum = save(raw + BigInt::from(149usize * stir));
        let order_number = regular_mod(
            &(&saved_bowl_sum - BigInt::one()),
            &BigInt::from(720u16),
        ) + BigInt::one();
        let order = bowl_order_from_number(
            order_number
                .to_usize()
                .expect("qarışdırma sıra nömrəsi usize daxilindədir"),
        );
        let mut next = old.clone();
        for position0 in 0usize..6 {
            let position = position0 + 1;
            let bowl_id = usize::from(order[position0] - 1);
            let prev_position = wrap1(position as isize - 1, 6) - 1;
            let next_position = wrap1(position as isize + 1, 6) - 1;
            let prev_id = usize::from(order[prev_position] - 1);
            let next_id = usize::from(order[next_position] - 1);
            let s = &old[bowl_id]
                + BigInt::from(3u8) * &old[prev_id]
                + BigInt::from(5u8) * &old[next_id]
                + &saved_bowl_sum
                + BigInt::from(stir)
                + BigInt::from(position * position);
            next[bowl_id] = save(
                &s * &s + BigInt::from(7u8) * &old[prev_id] * &old[next_id],
            );
        }
        bowls = next;
    }
    bowls
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SauceResult {
    pub bowls: Bowls,
    pub order_at_drop_46: [u8; 6],
}

pub fn sauce(calculation_day: &BigInt, target_day: &BigInt) -> SauceResult {
    let counts = work_counts(calculation_day, target_day);
    let stones = build_stones();
    let hidden = build_hidden_drops(&counts, &stones);
    let visible = build_visible_drops(&counts, &stones, &hidden);
    let bowls = initial_bowls(&counts);
    let (after_drops, order_at_drop_46) = apply_visible_drops_to_bowls(bowls, &visible, &stones);
    let bowls = post_stir12(after_drops);
    SauceResult {
        bowls,
        order_at_drop_46,
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AnswerStream {
    pub first: BigUint,
    pub direction_step: i8,
}

pub fn next_bowl_in_drop46_order(result: &SauceResult, queried_bowl_id: u8) -> u8 {
    let pos = result
        .order_at_drop_46
        .iter()
        .position(|id| *id == queried_bowl_id)
        .expect("soruşulan kasa sıra daxilində olmalıdır");
    result.order_at_drop_46[(pos + 1) % 6]
}

pub fn ask_bowl(result: &SauceResult, queried_bowl_id: u8, seal: u64) -> AnswerStream {
    let next_id = next_bowl_in_drop46_order(result, queried_bowl_id);
    let q = usize::from(queried_bowl_id - 1);
    let n = usize::from(next_id - 1);
    let first_int = save(
        (&result.bowls[q] + BigInt::from(seal + 181u64)).pow(2u32)
            + BigInt::from(179u16) * &result.bowls[n]
            + BigInt::from(seal),
    );
    let direction_number = save(
        (&first_int + BigInt::from(seal + 194u64)).pow(2u32)
            + BigInt::from(193u16) * &first_int
            + BigInt::from(197u16) * &result.bowls[5],
    );
    let direction_step = if regular_mod(&direction_number, &BigInt::from(2u8)) == BigInt::one() {
        1
    } else {
        -1
    };
    AnswerStream {
        first: first_int
            .to_biguint()
            .expect("saxlanmış cavab müsbət olmalıdır"),
        direction_step,
    }
}

pub fn answer_at(stream: &AnswerStream, k: usize) -> BigUint {
    let m = m_bigint();
    let first = stream.first.to_bigint().expect("müsbət cavab BigInt-ə çevrilməlidir");
    let delta = BigInt::from(stream.direction_step) * BigInt::from(k);
    let value = BigInt::one() + regular_mod(&(first - BigInt::one() + delta), &m);
    value.to_biguint().expect("halqa cavabı müsbət olmalıdır")
}

pub fn choose_rank_short(stream: &AnswerStream, n: &BigUint) -> BigUint {
    assert!(!n.is_zero());
    let m = m_biguint();
    assert!(n <= &m);
    let acceptance_limit = (&m / n) * n;
    let mut k = 0usize;
    loop {
        let x = answer_at(stream, k);
        if x <= acceptance_limit {
            return ((x - BigUint::one()) % n) + BigUint::one();
        }
        k += 1;
    }
}

pub fn smallest_power_count(base: &BigUint, n: &BigUint) -> (usize, BigUint) {
    let mut k = 1usize;
    let mut space = base.clone();
    while &space < n {
        k += 1;
        space *= base;
    }
    (k, space)
}

pub fn choose_rank_wide(stream: &AnswerStream, n: &BigUint) -> BigUint {
    let m = m_biguint();
    assert!(n > &m);
    let (k, space) = smallest_power_count(&m, n);
    let mut wide = BigUint::one();
    let mut weight = BigUint::one();
    for j in 0usize..k {
        wide += (answer_at(stream, j) - BigUint::one()) * &weight;
        weight *= &m;
    }
    let acceptance_limit = (&space / n) * n;
    while wide > acceptance_limit {
        if stream.direction_step > 0 {
            if wide == space {
                wide = BigUint::one();
            } else {
                wide += BigUint::one();
            }
        } else if wide == BigUint::one() {
            wide = space.clone();
        } else {
            wide -= BigUint::one();
        }
    }
    ((wide - BigUint::one()) % n) + BigUint::one()
}

pub fn choose_rank(stream: &AnswerStream, n: &BigUint) -> BigUint {
    assert!(!n.is_zero());
    if n <= &m_biguint() {
        choose_rank_short(stream, n)
    } else {
        choose_rank_wide(stream, n)
    }
}

pub fn falling_factorial(n: usize, k: usize) -> BigUint {
    assert!(k <= n);
    let mut out = BigUint::one();
    for j in 0usize..k {
        out *= BigUint::from(n - j);
    }
    out
}

pub fn unrank_distinct_indices(n: usize, k: usize, rank1: &BigUint) -> Vec<u8> {
    assert!(k <= n);
    let total = falling_factorial(n, k);
    assert!(rank1 >= &BigUint::one() && rank1 <= &total);
    let mut remaining: Vec<u8> = (1usize..=n).map(|x| x as u8).collect();
    let mut out = Vec::with_capacity(k);
    let mut r = rank1.clone();
    for position in 0usize..k {
        let suffix = k - position - 1;
        let block = falling_factorial(remaining.len() - 1, suffix);
        let mut chosen = None;
        for candidate in 0usize..remaining.len() {
            if r > block {
                r -= &block;
            } else {
                chosen = Some(candidate);
                break;
            }
        }
        let idx = chosen.expect("fərqli adların dərəcəsi açılmalıdır");
        out.push(remaining.remove(idx));
    }
    out
}

#[derive(Clone, Debug)]
pub struct BoundedCompositionCounter {
    total: usize,
    slots: usize,
    lo: usize,
    hi: usize,
    memo: HashMap<(usize, usize), BigUint>,
}

impl BoundedCompositionCounter {
    pub fn new(total: usize, slots: usize, lo: usize, hi: usize) -> Self {
        Self {
            total,
            slots,
            lo,
            hi,
            memo: HashMap::new(),
        }
    }

    fn count_suffix(&mut self, rem: usize, slots: usize) -> BigUint {
        if slots == 0 {
            return if rem == 0 { BigUint::one() } else { BigUint::zero() };
        }
        if rem < slots * self.lo || rem > slots * self.hi {
            return BigUint::zero();
        }
        if let Some(value) = self.memo.get(&(rem, slots)) {
            return value.clone();
        }
        let mut total = BigUint::zero();
        for x in self.lo..=self.hi {
            if x > rem {
                break;
            }
            total += self.count_suffix(rem - x, slots - 1);
        }
        self.memo.insert((rem, slots), total.clone());
        total
    }

    pub fn count_all(&mut self) -> BigUint {
        self.count_suffix(self.total, self.slots)
    }

    pub fn unrank1(&mut self, rank1: &BigUint) -> Vec<usize> {
        let total_count = self.count_all();
        assert!(rank1 >= &BigUint::one() && rank1 <= &total_count);
        let mut r = rank1.clone();
        let mut rem = self.total;
        let mut slots = self.slots;
        let mut out = Vec::with_capacity(slots);
        while slots > 0 {
            let mut picked = None;
            for x in self.lo..=self.hi {
                if x > rem {
                    break;
                }
                let block = self.count_suffix(rem - x, slots - 1);
                if r > block {
                    r -= block;
                } else {
                    picked = Some(x);
                    break;
                }
            }
            let x = picked.expect("məhdud kompozisiya dərəcəsi açılmalıdır");
            out.push(x);
            rem -= x;
            slots -= 1;
        }
        out
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Year {
    pub number: BigInt,
    pub open_gate_index: BigInt,
    pub close_gate_index: BigInt,
    pub open_gate_day: BigInt,
    pub close_gate_day: BigInt,
}

#[derive(Clone, Debug)]
pub struct GateCache {
    gates: BTreeMap<BigInt, BigInt>,
    min_known: BigInt,
    max_known: BigInt,
}

impl Default for GateCache {
    fn default() -> Self {
        let mut gates = BTreeMap::new();
        gates.insert(BigInt::zero(), foundation_day());
        Self {
            gates,
            min_known: BigInt::zero(),
            max_known: BigInt::zero(),
        }
    }
}

impl GateCache {
    pub fn gate(&self, index: &BigInt) -> BigInt {
        self.gates
            .get(index)
            .expect("istənən darvaza yaradılmış olmalıdır")
            .clone()
    }

    fn positive_gate_gap(n: &BigInt) -> usize {
        assert!(n > &BigInt::zero());
        let foundation = foundation_day();
        let target = &foundation + n;
        let result = sauce(&foundation, &target);
        let stream = ask_bowl(&result, 1, SEAL_GATE_GAP);
        let chosen = choose_rank(&stream, &BigUint::from(922u16));
        41 + chosen.to_usize().expect("darvaza boşluğu usize daxilindədir")
    }

    fn negative_gate_gap(n: &BigInt) -> usize {
        assert!(n > &BigInt::zero());
        let foundation = foundation_day();
        let target = &foundation - n;
        let result = sauce(&foundation, &target);
        let stream = ask_bowl(&result, 1, SEAL_GATE_GAP);
        let chosen = choose_rank(&stream, &BigUint::from(922u16));
        41 + chosen.to_usize().expect("darvaza boşluğu usize daxilindədir")
    }

    pub fn ensure_gate_index(&mut self, index: &BigInt) -> BigInt {
        if index > &self.max_known {
            let mut n = &self.max_known + BigInt::one();
            while &n <= index {
                let prev = &n - BigInt::one();
                let day = self.gate(&prev) + BigInt::from(Self::positive_gate_gap(&n));
                self.gates.insert(n.clone(), day);
                self.max_known = n.clone();
                n += BigInt::one();
            }
        }
        if index < &self.min_known {
            let mut n = &self.min_known - BigInt::one();
            while &n >= index {
                let next = &n + BigInt::one();
                let magnitude = -&n;
                let day = self.gate(&next) - BigInt::from(Self::negative_gate_gap(&magnitude));
                self.gates.insert(n.clone(), day);
                self.min_known = n.clone();
                n -= BigInt::one();
            }
        }
        self.gate(index)
    }

    pub fn ensure_gates_cover(&mut self, low_day: &BigInt, high_day: &BigInt) {
        assert!(low_day <= high_day);
        while self.gate(&self.min_known) > low_day.clone() {
            let next = &self.min_known - BigInt::one();
            self.ensure_gate_index(&next);
        }
        while self.gate(&self.max_known) < high_day.clone() {
            let next = &self.max_known + BigInt::one();
            self.ensure_gate_index(&next);
        }
    }

    pub fn ensure_gates_forward_through_day(&mut self, day: &BigInt) {
        let low = self.gate(&self.min_known);
        self.ensure_gates_cover(&low, day);
    }

    pub fn ensure_gates_backward_through_day(&mut self, day: &BigInt) {
        let high = self.gate(&self.max_known);
        self.ensure_gates_cover(day, &high);
    }

    pub fn gate_index_at_or_before(&mut self, day: &BigInt) -> BigInt {
        self.ensure_gates_cover(day, day);
        let mut lo = self.min_known.clone();
        let mut hi = self.max_known.clone();
        while lo < hi {
            let mid = &lo + ((&hi - &lo + BigInt::one()) / BigInt::from(2u8));
            if self.gate(&mid) <= day.clone() {
                lo = mid;
            } else {
                hi = mid - BigInt::one();
            }
        }
        lo
    }

    pub fn gate_index_at_or_after(&mut self, day: &BigInt) -> BigInt {
        let at_or_before = self.gate_index_at_or_before(day);
        if self.gate(&at_or_before) == day.clone() {
            return at_or_before;
        }
        let next = &at_or_before + BigInt::one();
        self.ensure_gate_index(&next);
        next
    }

    pub fn exact_gate_index(&mut self, day: &BigInt) -> Option<BigInt> {
        let idx = self.gate_index_at_or_before(day);
        if self.gate(&idx) == day.clone() {
            Some(idx)
        } else {
            None
        }
    }

    fn year_length(&self, open: &BigInt, close: &BigInt) -> usize {
        (&self.gate(close) - &self.gate(open))
            .to_usize()
            .expect("il uzunluğu usize daxilindədir")
    }

    fn valid_year_pair(&self, open: &BigInt, close: &BigInt) -> bool {
        if close - open < BigInt::from(MIN_GATE_GAPS_PER_YEAR) {
            return false;
        }
        let length = self.year_length(open, close);
        (YEAR_MIN_DAYS..=YEAR_MAX_DAYS).contains(&length)
    }

    pub fn year5000(&mut self, calculation_day: &BigInt) -> Year {
        let radius = BigInt::from(YEAR_MAX_DAYS);
        self.ensure_gates_cover(&(calculation_day - &radius), &(calculation_day + &radius));
        let mut indices = Vec::new();
        let mut idx = self.min_known.clone();
        while idx <= self.max_known {
            indices.push(idx.clone());
            idx += BigInt::one();
        }
        let mut candidates: Vec<(BigInt, BigInt)> = Vec::new();
        for i_pos in 0usize..indices.len() {
            for j_pos in (i_pos + 1)..indices.len() {
                let i = &indices[i_pos];
                let j = &indices[j_pos];
                if !self.valid_year_pair(i, j) {
                    continue;
                }
                let open_day = self.gate(i);
                let close_day = self.gate(j);
                if open_day < calculation_day.clone() && calculation_day.clone() <= close_day {
                    candidates.push((i.clone(), j.clone()));
                }
            }
        }
        candidates.sort_by(|(ia, ja), (ib, jb)| {
            let la = self.gate(ja) - self.gate(ia);
            let lb = self.gate(jb) - self.gate(ib);
            la.cmp(&lb).then_with(|| self.gate(ia).cmp(&self.gate(ib)))
        });
        assert!(!candidates.is_empty());
        let result = sauce(calculation_day, calculation_day);
        let stream = ask_bowl(&result, 1, SEAL_YEAR_5000);
        let rank = choose_rank(&stream, &BigUint::from(candidates.len()));
        let pos = rank.to_usize().expect("namizəd dərəcəsi usize daxilindədir") - 1;
        let (open, close) = candidates[pos].clone();
        Year {
            number: BigInt::from(5000u16),
            open_gate_index: open.clone(),
            close_gate_index: close.clone(),
            open_gate_day: self.gate(&open),
            close_gate_day: self.gate(&close),
        }
    }

    pub fn next_year(&mut self, calculation_day: &BigInt, known: &Year) -> Year {
        let open = known.close_gate_index.clone();
        let open_day = self.ensure_gate_index(&open);
        let limit_day = &open_day + BigInt::from(YEAR_MAX_DAYS);
        self.ensure_gates_cover(&open_day, &limit_day);
        let mut candidates: Vec<BigInt> = Vec::new();
        let mut close = &open + BigInt::one();
        loop {
            let close_day = self.ensure_gate_index(&close);
            if &close_day - &open_day > BigInt::from(YEAR_MAX_DAYS) {
                break;
            }
            if self.valid_year_pair(&open, &close) {
                candidates.push(close.clone());
            }
            close += BigInt::one();
        }
        candidates.sort_by_key(|j| self.gate(j) - &open_day);
        let result = sauce(calculation_day, &open_day);
        let stream = ask_bowl(&result, 1, SEAL_NEXT_YEAR);
        let rank = choose_rank(&stream, &BigUint::from(candidates.len()));
        let close = candidates[rank.to_usize().expect("növbəti il dərəcəsi usize daxilindədir") - 1].clone();
        Year {
            number: &known.number + BigInt::one(),
            open_gate_index: open.clone(),
            close_gate_index: close.clone(),
            open_gate_day: self.gate(&open),
            close_gate_day: self.gate(&close),
        }
    }

    pub fn previous_year(&mut self, calculation_day: &BigInt, known: &Year) -> Year {
        let close = known.open_gate_index.clone();
        let close_day = self.ensure_gate_index(&close);
        let limit_day = &close_day - BigInt::from(YEAR_MAX_DAYS);
        self.ensure_gates_cover(&limit_day, &close_day);
        let mut candidates: Vec<BigInt> = Vec::new();
        let mut open = &close - BigInt::one();
        loop {
            let open_day = self.ensure_gate_index(&open);
            if &close_day - &open_day > BigInt::from(YEAR_MAX_DAYS) {
                break;
            }
            if self.valid_year_pair(&open, &close) {
                candidates.push(open.clone());
            }
            open -= BigInt::one();
        }
        candidates.sort_by_key(|i| &close_day - self.gate(i));
        let result = sauce(calculation_day, &close_day);
        let stream = ask_bowl(&result, 1, SEAL_PREVIOUS_YEAR);
        let rank = choose_rank(&stream, &BigUint::from(candidates.len()));
        let open = candidates[rank.to_usize().expect("əvvəlki il dərəcəsi usize daxilindədir") - 1].clone();
        Year {
            number: &known.number - BigInt::one(),
            open_gate_index: open.clone(),
            close_gate_index: close.clone(),
            open_gate_day: self.gate(&open),
            close_gate_day: self.gate(&close),
        }
    }

    pub fn find_target_year(&mut self, calculation_day: &BigInt, target_day: &BigInt) -> Year {
        let mut year = self.year5000(calculation_day);
        while target_day > &year.close_gate_day {
            year = self.next_year(calculation_day, &year);
        }
        while target_day <= &year.open_gate_day {
            year = self.previous_year(calculation_day, &year);
        }
        assert!(&year.open_gate_day < target_day && target_day <= &year.close_gate_day);
        year
    }
}

#[derive(Clone, Debug)]
pub struct CutletPartitionCounter {
    g: usize,
    k: usize,
    required: Option<usize>,
    memo: HashMap<(usize, usize, usize, bool), BigUint>,
}

impl CutletPartitionCounter {
    pub fn new(g: usize, k: usize, required: Option<usize>) -> Self {
        Self {
            g,
            k,
            required,
            memo: HashMap::new(),
        }
    }

    fn count_state(&mut self, rem: usize, slots: usize, cumulative: usize, hit: bool) -> BigUint {
        if slots == 0 {
            if rem != 0 {
                return BigUint::zero();
            }
            return if self.required.is_none() || hit {
                BigUint::one()
            } else {
                BigUint::zero()
            };
        }
        if rem < slots {
            return BigUint::zero();
        }
        let key = (rem, slots, cumulative, hit);
        if let Some(value) = self.memo.get(&key) {
            return value.clone();
        }
        let mut total = BigUint::zero();
        let max_x = rem - (slots - 1);
        for x in 1usize..=max_x {
            let next_cumulative = cumulative + x;
            let mut next_hit = hit;
            if let Some(required) = self.required {
                if !hit {
                    if next_cumulative == required {
                        next_hit = true;
                    } else if next_cumulative > required {
                        continue;
                    }
                }
            }
            total += self.count_state(rem - x, slots - 1, next_cumulative, next_hit);
        }
        self.memo.insert(key, total.clone());
        total
    }

    pub fn count_all(&mut self) -> BigUint {
        self.count_state(self.g, self.k, 0, false)
    }

    pub fn unrank1(&mut self, rank1: &BigUint) -> Vec<usize> {
        let total = self.count_all();
        assert!(rank1 >= &BigUint::one() && rank1 <= &total);
        let mut r = rank1.clone();
        let mut rem = self.g;
        let mut slots = self.k;
        let mut cumulative = 0usize;
        let mut hit = false;
        let mut out = Vec::with_capacity(self.k);
        while slots > 0 {
            let max_x = rem - (slots - 1);
            let mut picked = None;
            for x in 1usize..=max_x {
                let next_cumulative = cumulative + x;
                let mut next_hit = hit;
                if let Some(required) = self.required {
                    if !hit {
                        if next_cumulative == required {
                            next_hit = true;
                        } else if next_cumulative > required {
                            continue;
                        }
                    }
                }
                let block = self.count_state(rem - x, slots - 1, next_cumulative, next_hit);
                if r > block {
                    r -= block;
                } else {
                    picked = Some((x, next_cumulative, next_hit));
                    break;
                }
            }
            let (x, next_cumulative, next_hit) = picked.expect("kotlet bölgüsü dərəcəsi açılmalıdır");
            out.push(x);
            rem -= x;
            slots -= 1;
            cumulative = next_cumulative;
            hit = next_hit;
        }
        out
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Cutlet {
    pub name_index: u8,
    pub open_gate_index: BigInt,
    pub close_gate_index: BigInt,
    pub first_day: BigInt,
    pub last_day: BigInt,
}

#[derive(Clone, Debug, Eq)]
struct WeaveKey {
    remaining: Vec<u16>,
    opened_up_to: u8,
    closed_up_to: u8,
}

impl PartialEq for WeaveKey {
    fn eq(&self, other: &Self) -> bool {
        self.remaining == other.remaining
            && self.opened_up_to == other.opened_up_to
            && self.closed_up_to == other.closed_up_to
    }
}

impl Hash for WeaveKey {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.remaining.hash(state);
        self.opened_up_to.hash(state);
        self.closed_up_to.hash(state);
    }
}

#[derive(Clone, Debug)]
pub struct WeavingCounter {
    lengths: Vec<u16>,
    memo: HashMap<WeaveKey, BigUint>,
}

impl WeavingCounter {
    pub fn new(lengths: &[usize]) -> Self {
        Self {
            lengths: lengths
                .iter()
                .map(|x| u16::try_from(*x).expect("ay uzunluğu u16 daxilindədir"))
                .collect(),
            memo: HashMap::new(),
        }
    }

    fn initial_state(&self) -> WeaveKey {
        WeaveKey {
            remaining: self.lengths.clone(),
            opened_up_to: 0,
            closed_up_to: 0,
        }
    }

    fn legal_move(&self, state: &WeaveKey, j0: usize) -> bool {
        if state.remaining[j0] == 0 {
            return false;
        }
        let j = (j0 + 1) as u8;
        let already_opened = state.remaining[j0] < self.lengths[j0];
        if !already_opened && j != state.opened_up_to + 1 {
            return false;
        }
        let will_close = state.remaining[j0] == 1;
        if will_close && j != state.closed_up_to + 1 {
            return false;
        }
        true
    }

    fn apply_move(&self, state: &WeaveKey, j0: usize) -> WeaveKey {
        let mut next = state.clone();
        let j = (j0 + 1) as u8;
        if next.remaining[j0] == self.lengths[j0] {
            next.opened_up_to = j;
        }
        next.remaining[j0] -= 1;
        if next.remaining[j0] == 0 {
            next.closed_up_to = j;
        }
        next
    }

    fn count_state(&mut self, state: &WeaveKey) -> BigUint {
        if state.remaining.iter().all(|x| *x == 0) {
            return BigUint::one();
        }
        if let Some(value) = self.memo.get(state) {
            return value.clone();
        }
        let mut total = BigUint::zero();
        for j0 in 0usize..self.lengths.len() {
            if self.legal_move(state, j0) {
                let next = self.apply_move(state, j0);
                total += self.count_state(&next);
            }
        }
        self.memo.insert(state.clone(), total.clone());
        total
    }

    pub fn count_all(&mut self) -> BigUint {
        let state = self.initial_state();
        self.count_state(&state)
    }

    pub fn unrank1(&mut self, rank1: &BigUint) -> Vec<u8> {
        let total = self.count_all();
        assert!(rank1 >= &BigUint::one() && rank1 <= &total);
        let mut state = self.initial_state();
        let mut r = rank1.clone();
        let total_days: usize = self.lengths.iter().map(|x| usize::from(*x)).sum();
        let mut out = Vec::with_capacity(total_days);
        while out.len() < total_days {
            let mut picked = None;
            for j0 in 0usize..self.lengths.len() {
                if !self.legal_move(&state, j0) {
                    continue;
                }
                let next = self.apply_move(&state, j0);
                let block = self.count_state(&next);
                if r > block {
                    r -= block;
                } else {
                    picked = Some((j0, next));
                    break;
                }
            }
            let (j0, next) = picked.expect("ay toxunuşu dərəcəsi açılmalıdır");
            out.push((j0 + 1) as u8);
            state = next;
        }
        out
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct YearStructure {
    pub cutlet_count: usize,
    pub cutlet_partition: Vec<usize>,
    pub cutlet_names: Vec<u8>,
    pub cutlets: Vec<Cutlet>,
    pub month_count: usize,
    pub month_lengths: Vec<usize>,
    pub month_weaving: Vec<u8>,
    pub month_names: Vec<u8>,
}

pub fn choose_cutlet_count(result: &SauceResult, year: &Year) -> usize {
    let gate_gaps = (&year.close_gate_index - &year.open_gate_index)
        .to_usize()
        .expect("darvaza boşluqlarının sayı usize daxilindədir");
    let candidates: Vec<usize> = (MIN_CUTLETS..=MAX_CUTLETS)
        .filter(|k| *k <= gate_gaps)
        .collect();
    let stream = ask_bowl(result, 2, SEAL_CUTLET_COUNT);
    let rank = choose_rank(&stream, &BigUint::from(candidates.len()));
    candidates[rank.to_usize().expect("kotlet sayı dərəcəsi usize daxilindədir") - 1]
}

pub fn choose_cutlet_partition(
    calculation_day: &BigInt,
    result: &SauceResult,
    year: &Year,
    cutlet_count: usize,
    gates: &mut GateCache,
) -> Vec<usize> {
    let g = (&year.close_gate_index - &year.open_gate_index)
        .to_usize()
        .expect("darvaza boşluqları usize daxilindədir");
    let exact = gates.exact_gate_index(calculation_day);
    let required = exact.and_then(|idx| {
        if &idx > &year.open_gate_index && &idx < &year.close_gate_index {
            Some(
                (&idx - &year.open_gate_index)
                    .to_usize()
                    .expect("daxili sərhəd usize daxilindədir"),
            )
        } else {
            None
        }
    });
    let mut family = CutletPartitionCounter::new(g, cutlet_count, required);
    let stream = ask_bowl(result, 2, SEAL_CUTLET_PARTITION);
    let rank = choose_rank(&stream, &family.count_all());
    family.unrank1(&rank)
}

pub fn choose_cutlet_names(result: &SauceResult, cutlet_count: usize) -> Vec<u8> {
    let n = falling_factorial(17, cutlet_count);
    let stream = ask_bowl(result, 5, SEAL_CUTLET_NAMES);
    let rank = choose_rank(&stream, &n);
    unrank_distinct_indices(17, cutlet_count, &rank)
}

pub fn materialize_cutlets(
    year: &Year,
    partition: &[usize],
    names: &[u8],
    gates: &mut GateCache,
) -> Vec<Cutlet> {
    let mut cursor = year.open_gate_index.clone();
    let mut out = Vec::with_capacity(partition.len());
    for (idx, part) in partition.iter().enumerate() {
        let open = cursor.clone();
        let close = &cursor + BigInt::from(*part);
        let first_day = gates.ensure_gate_index(&open) + BigInt::one();
        let last_day = gates.ensure_gate_index(&close);
        out.push(Cutlet {
            name_index: names[idx],
            open_gate_index: open,

            close_gate_index: close.clone(),
            first_day,
            last_day,
        });
        cursor = close;
    }
    out
}

pub fn choose_month_count(result: &SauceResult, year: &Year) -> usize {
    let length = (&year.close_gate_day - &year.open_gate_day)
        .to_usize()
        .expect("il uzunluğu usize daxilindədir");
    let min_months = ceil_div_usize(length, MAX_MONTH_DAYS);
    let max_months = MAX_MONTHS.min(length / MIN_MONTH_DAYS);
    assert!(MIN_MONTHS <= min_months && min_months <= max_months && max_months <= MAX_MONTHS);
    let count = max_months - min_months + 1;
    let stream = ask_bowl(result, 3, SEAL_MONTH_COUNT);
    let rank = choose_rank(&stream, &BigUint::from(count));
    min_months + rank.to_usize().expect("ay sayı dərəcəsi usize daxilindədir") - 1
}

pub fn choose_month_lengths(result: &SauceResult, year: &Year, month_count: usize) -> Vec<usize> {
    let length = (&year.close_gate_day - &year.open_gate_day)
        .to_usize()
        .expect("il uzunluğu usize daxilindədir");
    let mut family = BoundedCompositionCounter::new(length, month_count, MIN_MONTH_DAYS, MAX_MONTH_DAYS);
    let stream = ask_bowl(result, 3, SEAL_MONTH_LENGTHS);
    let rank = choose_rank(&stream, &family.count_all());
    family.unrank1(&rank)
}

pub fn choose_month_weaving(result: &SauceResult, month_lengths: &[usize]) -> Vec<u8> {
    let mut family = WeavingCounter::new(month_lengths);
    let count = family.count_all();
    let stream = ask_bowl(result, 4, SEAL_MONTH_WEAVING);
    let rank = choose_rank(&stream, &count);
    family.unrank1(&rank)
}

pub fn choose_month_names(result: &SauceResult, month_count: usize) -> Vec<u8> {
    let n = falling_factorial(47, month_count);
    let stream = ask_bowl(result, 5, SEAL_MONTH_NAMES);
    let rank = choose_rank(&stream, &n);
    unrank_distinct_indices(47, month_count, &rank)
}

pub fn build_year_structure(
    calculation_day: &BigInt,
    year: &Year,
    gates: &mut GateCache,
) -> YearStructure {
    let first_day = &year.open_gate_day + BigInt::one();
    let result = sauce(calculation_day, &first_day);
    let cutlet_count = choose_cutlet_count(&result, year);
    let cutlet_partition = choose_cutlet_partition(calculation_day, &result, year, cutlet_count, gates);
    let cutlet_names = choose_cutlet_names(&result, cutlet_count);
    let cutlets = materialize_cutlets(year, &cutlet_partition, &cutlet_names, gates);
    let month_count = choose_month_count(&result, year);
    let month_lengths = choose_month_lengths(&result, year, month_count);
    let month_weaving = choose_month_weaving(&result, &month_lengths);
    let month_names = choose_month_names(&result, month_count);
    YearStructure {
        cutlet_count,
        cutlet_partition,
        cutlet_names,
        cutlets,
        month_count,
        month_lengths,
        month_weaving,
        month_names,
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct OracleDate {
    pub year_number: BigInt,
    pub cutlet_canonical_index: u8,
    pub day_in_cutlet: BigInt,
    pub month_canonical_index: u8,
    pub day_in_month: BigInt,
}

pub fn calendar_date(calculation_day: &BigInt, target_day: &BigInt) -> OracleDate {
    let mut gates = GateCache::default();
    let year = gates.find_target_year(calculation_day, target_day);
    let structure = build_year_structure(calculation_day, &year, &mut gates);
    let cutlet = structure
        .cutlets
        .iter()
        .find(|c| &c.first_day <= target_day && target_day <= &c.last_day)
        .expect("hədəf gün bir kotlet daxilində olmalıdır");
    let day_in_cutlet = target_day - &cutlet.first_day + BigInt::one();
    let offset = (target_day - (&year.open_gate_day + BigInt::one()))
        .to_usize()
        .expect("il daxili mövqe usize daxilindədir");
    let month_id = structure.month_weaving[offset];
    let month_index = structure.month_names[usize::from(month_id - 1)];
    let mut day_in_month = 0usize;
    for id in &structure.month_weaving[..=offset] {
        if *id == month_id {
            day_in_month += 1;
        }
    }
    OracleDate {
        year_number: year.number,
        cutlet_canonical_index: cutlet.name_index,
        day_in_cutlet,
        month_canonical_index: month_index,
        day_in_month: BigInt::from(day_in_month),
    }
}

pub fn validate_embedded_constants() {
    assert_eq!(tablets_day() - foundation_day(), BigInt::from(14_777_149u64));
    assert_eq!(GATE_GAP_MIN, 42);
    assert_eq!(GATE_GAP_MAX, 963);
    assert_eq!(YEAR_MIN_DAYS, 252);
    assert_eq!(YEAR_MAX_DAYS, 5_778);
    assert_eq!(MIN_GATE_GAPS_PER_YEAR, 6);
    assert_eq!(MIN_CUTLETS, 6);
    assert_eq!(MAX_CUTLETS, 17);
    assert_eq!(MIN_MONTHS, 3);
    assert_eq!(MAX_MONTHS, 47);
    assert_eq!(MIN_MONTH_DAYS, 4);
    assert_eq!(MAX_MONTH_DAYS, 123);
}
