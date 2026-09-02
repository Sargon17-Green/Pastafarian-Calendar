const std = @import("std");
const core = @import("normative_oracle.zig");
const exact = @import("exact.zig");
const catalog = @import("source_language_catalog.zig");

pub const Scalar = core.Scalar;
pub const Natural = core.Natural;
pub const FOUNDATION_DAY = core.FOUNDATION_DAY;
pub const YEAR_MIN_DAYS: Natural = 252;
pub const YEAR_MAX_DAYS: Natural = 5778;
pub const WeaveCount = u32768;

pub const Year = struct {
    number: Scalar,
    open_gate_index: i64,
    close_gate_index: i64,
    open_day: Scalar,
    close_day: Scalar,
};

pub const DateResult = struct {
    year_number: Scalar,
    cutlet_canonical_index: u8,
    day_in_cutlet: Natural,
    month_canonical_index: u8,
    day_in_month: Natural,

    pub fn cutletText(self: DateResult) ![]const u8 {
        return catalog.cutletText(self.cutlet_canonical_index);
    }

    pub fn monthText(self: DateResult) ![]const u8 {
        return catalog.monthText(self.month_canonical_index);
    }
};

pub const GateEngine = struct {
    allocator: std.mem.Allocator,
    positive: std.ArrayList(Scalar),
    negative: std.ArrayList(Scalar),

    pub fn init(allocator: std.mem.Allocator) !GateEngine {
        var positive = std.ArrayList(Scalar).init(allocator);
        errdefer positive.deinit();
        var negative = std.ArrayList(Scalar).init(allocator);
        errdefer negative.deinit();
        try positive.append(FOUNDATION_DAY);
        try negative.append(FOUNDATION_DAY);
        return .{ .allocator = allocator, .positive = positive, .negative = negative };
    }

    pub fn deinit(self: *GateEngine) void {
        self.positive.deinit();
        self.negative.deinit();
    }

    fn positiveGap(step: usize) Natural {
        const q = FOUNDATION_DAY + @as(Scalar, @intCast(step));
        const r = core.sauce(FOUNDATION_DAY, q);
        const stream = core.askBowl(r, 1, 1);
        return 41 + core.chooseRank(stream, 922);
    }

    fn negativeGap(step: usize) Natural {
        const q = FOUNDATION_DAY - @as(Scalar, @intCast(step));
        const r = core.sauce(FOUNDATION_DAY, q);
        const stream = core.askBowl(r, 1, 1);
        return 41 + core.chooseRank(stream, 922);
    }

    pub fn ensurePositive(self: *GateEngine, index: usize) !void {
        while (self.positive.items.len <= index) {
            const step = self.positive.items.len;
            const gap = positiveGap(step);
            const last = self.positive.items[self.positive.items.len - 1];
            try self.positive.append(last + @as(Scalar, @intCast(gap)));
        }
    }

    pub fn ensureNegativeMagnitude(self: *GateEngine, magnitude: usize) !void {
        while (self.negative.items.len <= magnitude) {
            const step = self.negative.items.len;
            const gap = negativeGap(step);
            const last = self.negative.items[self.negative.items.len - 1];
            try self.negative.append(last - @as(Scalar, @intCast(gap)));
        }
    }

    pub fn gate(self: *GateEngine, index: i64) !Scalar {
        if (index >= 0) {
            const i: usize = @intCast(index);
            try self.ensurePositive(i);
            return self.positive.items[i];
        }
        const magnitude: usize = @intCast(-index);
        try self.ensureNegativeMagnitude(magnitude);
        return self.negative.items[magnitude];
    }

    pub fn ensureCover(self: *GateEngine, low: Scalar, high: Scalar) !void {
        std.debug.assert(low <= high);
        while (self.negative.items[self.negative.items.len - 1] > low) {
            try self.ensureNegativeMagnitude(self.negative.items.len);
        }
        while (self.positive.items[self.positive.items.len - 1] < high) {
            try self.ensurePositive(self.positive.items.len);
        }
    }

    pub fn minKnownIndex(self: *const GateEngine) i64 {
        return -@as(i64, @intCast(self.negative.items.len - 1));
    }

    pub fn maxKnownIndex(self: *const GateEngine) i64 {
        return @intCast(self.positive.items.len - 1);
    }

    pub fn gateIndexAtOrBefore(self: *GateEngine, day: Scalar) !i64 {
        try self.ensureCover(day, day);
        if (day >= FOUNDATION_DAY) {
            var lo: usize = 0;
            var hi: usize = self.positive.items.len - 1;
            while (lo < hi) {
                const mid = lo + (hi - lo + 1) / 2;
                if (self.positive.items[mid] <= day) lo = mid else hi = mid - 1;
            }
            return @intCast(lo);
        }
        var lo: usize = 1;
        var hi: usize = self.negative.items.len - 1;
        while (lo < hi) {
            const mid = lo + (hi - lo) / 2;
            if (self.negative.items[mid] <= day) hi = mid else lo = mid + 1;
        }
        return -@as(i64, @intCast(lo));
    }

    pub fn exactGateIndex(self: *GateEngine, day: Scalar) !?i64 {
        const i = try self.gateIndexAtOrBefore(day);
        return if ((try self.gate(i)) == day) i else null;
    }
};

fn yearLength(gates: *GateEngine, open_index: i64, close_index: i64) !Natural {
    const open = try gates.gate(open_index);
    const close = try gates.gate(close_index);
    return @intCast(close - open);
}

fn validYearPair(gates: *GateEngine, open_index: i64, close_index: i64) !bool {
    if (close_index - open_index < 6) return false;
    const len = try yearLength(gates, open_index, close_index);
    return len >= YEAR_MIN_DAYS and len <= YEAR_MAX_DAYS;
}

const YearCandidate = struct { open: i64, close: i64, len: Natural };

fn stableSortYearCandidates(items: []YearCandidate, tie_open: bool) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        const key = items[i];
        var j = i;
        while (j > 0) {
            const prev = items[j - 1];
            const before = key.len < prev.len or (tie_open and key.len == prev.len and key.open < prev.open);
            if (!before) break;
            items[j] = prev;
            j -= 1;
        }
        items[j] = key;
    }
}

pub fn year5000(allocator: std.mem.Allocator, gates: *GateEngine, calculation_day: Scalar) !Year {
    try gates.ensureCover(calculation_day - @as(Scalar, @intCast(YEAR_MAX_DAYS)), calculation_day + @as(Scalar, @intCast(YEAR_MAX_DAYS)));
    var candidates = std.ArrayList(YearCandidate).init(allocator);
    defer candidates.deinit();
    const low_index = try gates.gateIndexAtOrBefore(calculation_day - @as(Scalar, @intCast(YEAR_MAX_DAYS)));
    var high_index = try gates.gateIndexAtOrBefore(calculation_day + @as(Scalar, @intCast(YEAR_MAX_DAYS)));
    if ((try gates.gate(high_index)) < calculation_day + @as(Scalar, @intCast(YEAR_MAX_DAYS))) high_index += 1;
    _ = try gates.gate(high_index);
    var i = low_index;
    while (i < high_index) : (i += 1) {
        var j = i + 1;
        while (j <= high_index) : (j += 1) {
            const open = try gates.gate(i);
            const close = try gates.gate(j);
            const len: Natural = @intCast(close - open);
            if (len > YEAR_MAX_DAYS) break;
            if (j - i < 6 or len < YEAR_MIN_DAYS) continue;
            if (!(open < calculation_day and calculation_day <= close)) continue;
            try candidates.append(.{ .open = i, .close = j, .len = len });
        }
    }
    if (candidates.items.len == 0) return error.NoYearCandidate;
    stableSortYearCandidates(candidates.items, true);
    const sauce_result = core.sauce(calculation_day, calculation_day);
    const stream = core.askBowl(sauce_result, 1, 10);
    const rank = core.chooseRank(stream, @intCast(candidates.items.len));
    const c = candidates.items[@as(usize, @intCast(rank - 1))];
    return .{ .number = 5000, .open_gate_index = c.open, .close_gate_index = c.close, .open_day = try gates.gate(c.open), .close_day = try gates.gate(c.close) };
}

pub fn nextYear(allocator: std.mem.Allocator, gates: *GateEngine, calculation_day: Scalar, known: Year) !Year {
    const open_index = known.close_gate_index;
    const open_day = try gates.gate(open_index);
    try gates.ensureCover(open_day, open_day + @as(Scalar, @intCast(YEAR_MAX_DAYS)));
    var candidates = std.ArrayList(YearCandidate).init(allocator);
    defer candidates.deinit();
    var j = open_index + 1;
    while (true) : (j += 1) {
        const close_day = try gates.gate(j);
        const len: Natural = @intCast(close_day - open_day);
        if (len > YEAR_MAX_DAYS) break;
        if (try validYearPair(gates, open_index, j)) try candidates.append(.{ .open = open_index, .close = j, .len = len });
    }
    if (candidates.items.len == 0) return error.NoNextYearCandidate;
    stableSortYearCandidates(candidates.items, false);
    const r = core.sauce(calculation_day, open_day);
    const stream = core.askBowl(r, 1, 11);
    const rank = core.chooseRank(stream, @intCast(candidates.items.len));
    const c = candidates.items[@as(usize, @intCast(rank - 1))];
    return .{ .number = known.number + 1, .open_gate_index = c.open, .close_gate_index = c.close, .open_day = open_day, .close_day = try gates.gate(c.close) };
}

pub fn previousYear(allocator: std.mem.Allocator, gates: *GateEngine, calculation_day: Scalar, known: Year) !Year {
    const close_index = known.open_gate_index;
    const close_day = try gates.gate(close_index);
    try gates.ensureCover(close_day - @as(Scalar, @intCast(YEAR_MAX_DAYS)), close_day);
    var candidates = std.ArrayList(YearCandidate).init(allocator);
    defer candidates.deinit();
    var i = close_index - 1;
    while (true) : (i -= 1) {
        const open_day = try gates.gate(i);
        const len: Natural = @intCast(close_day - open_day);
        if (len > YEAR_MAX_DAYS) break;
        if (try validYearPair(gates, i, close_index)) try candidates.append(.{ .open = i, .close = close_index, .len = len });
    }
    if (candidates.items.len == 0) return error.NoPreviousYearCandidate;
    stableSortYearCandidates(candidates.items, false);
    const r = core.sauce(calculation_day, close_day);
    const stream = core.askBowl(r, 1, 12);
    const rank = core.chooseRank(stream, @intCast(candidates.items.len));
    const c = candidates.items[@as(usize, @intCast(rank - 1))];
    return .{ .number = known.number - 1, .open_gate_index = c.open, .close_gate_index = c.close, .open_day = try gates.gate(c.open), .close_day = close_day };
}

pub fn findTargetYear(allocator: std.mem.Allocator, gates: *GateEngine, calculation_day: Scalar, target_day: Scalar) !Year {
    var y = try year5000(allocator, gates, calculation_day);
    while (target_day > y.close_day) y = try nextYear(allocator, gates, calculation_day, y);
    while (target_day <= y.open_day) y = try previousYear(allocator, gates, calculation_day, y);
    if (!(y.open_day < target_day and target_day <= y.close_day)) return error.TargetOutsideYear;
    return y;
}

fn binomial(n: usize, k_in: usize) Natural {
    if (k_in > n) return 0;
    var k = k_in;
    if (k > n - k) k = n - k;
    var r: Natural = 1;
    var i: usize = 1;
    while (i <= k) : (i += 1) {
        r = (r * @as(Natural, @intCast(n - k + i))) / @as(Natural, @intCast(i));
    }
    return r;
}

fn positiveCompositionCount(total: usize, slots: usize) Natural {
    if (slots == 0) return if (total == 0) 1 else 0;
    if (total < slots) return 0;
    return binomial(total - 1, slots - 1);
}

fn partitionSuffixCount(rem: usize, slots: usize, cumulative: usize, required: ?usize, hit: bool) Natural {
    if (slots == 0) {
        if (rem != 0) return 0;
        if (required == null) return 1;
        return if (hit) 1 else 0;
    }
    if (rem < slots) return 0;
    if (required == null or hit) return positiveCompositionCount(rem, slots);
    const boundary = required.?;
    if (cumulative >= boundary) return 0;
    const delta = boundary - cumulative;
    if (delta >= rem) return 0;
    var total: Natural = 0;
    var r: usize = 1;
    while (r < slots) : (r += 1) {
        total += positiveCompositionCount(delta, r) * positiveCompositionCount(rem - delta, slots - r);
    }
    return total;
}

fn unrankCutletPartition(allocator: std.mem.Allocator, total: usize, slots_in: usize, required: ?usize, rank1: Natural) ![]u16 {
    var out = try allocator.alloc(u16, slots_in);
    errdefer allocator.free(out);
    var rank = rank1;
    var rem = total;
    var slots = slots_in;
    var cumulative: usize = 0;
    var hit = false;
    var position: usize = 0;
    while (slots > 0) {
        const max_x = rem - (slots - 1);
        var x: usize = 1;
        var chosen = false;
        while (x <= max_x) : (x += 1) {
            const next_cumulative = cumulative + x;
            var next_hit = hit;
            if (required) |b| {
                if (!hit) {
                    if (next_cumulative == b) next_hit = true else if (next_cumulative > b) continue;
                }
            }
            const block = partitionSuffixCount(rem - x, slots - 1, next_cumulative, required, next_hit);
            if (rank > block) {
                rank -= block;
            } else {
                out[position] = @intCast(x);
                rem -= x;
                slots -= 1;
                cumulative = next_cumulative;
                hit = next_hit;
                position += 1;
                chosen = true;
                break;
            }
        }
        if (!chosen) return error.InvalidPartitionRank;
    }
    return out;
}

fn unrankDistinctIndices(allocator: std.mem.Allocator, n: u8, k: u8, rank1: Natural) ![]u8 {
    var remaining = try allocator.alloc(u8, n);
    defer allocator.free(remaining);
    var i: usize = 0;
    while (i < n) : (i += 1) remaining[i] = @intCast(i + 1);
    var remaining_len: usize = n;
    var out = try allocator.alloc(u8, k);
    errdefer allocator.free(out);
    var rank = rank1;
    var pos: usize = 0;
    while (pos < k) : (pos += 1) {
        const suffix_len: Natural = @intCast(k - @as(u8, @intCast(pos)) - 1);
        const block = exact.fallingFactorial(@intCast(remaining_len - 1), suffix_len);
        var candidate: usize = 0;
        while (candidate < remaining_len) : (candidate += 1) {
            if (rank > block) rank -= block else {
                out[pos] = remaining[candidate];
                var j = candidate;
                while (j + 1 < remaining_len) : (j += 1) remaining[j] = remaining[j + 1];
                remaining_len -= 1;
                break;
            }
        }
    }
    return out;
}

fn boundedCompositionCount(total: usize, slots: usize, lo: usize, hi: usize) Natural {
    if (slots == 0) return if (total == 0) 1 else 0;
    if (total < slots * lo or total > slots * hi) return 0;
    const shifted = total - slots * lo;
    const width = hi - lo + 1;
    var sum: Scalar = 0;
    var j: usize = 0;
    while (j <= slots and j * width <= shifted) : (j += 1) {
        const top = shifted - j * width + slots - 1;
        const term = binomial(slots, j) * binomial(top, slots - 1);
        if (j % 2 == 0) sum += @as(Scalar, @intCast(term)) else sum -= @as(Scalar, @intCast(term));
    }
    std.debug.assert(sum >= 0);
    return @intCast(sum);
}

fn unrankBoundedComposition(allocator: std.mem.Allocator, total: usize, slots_in: usize, lo: usize, hi: usize, rank1: Natural) ![]u8 {
    var out = try allocator.alloc(u8, slots_in);
    errdefer allocator.free(out);
    var rem = total;
    var slots = slots_in;
    var rank = rank1;
    var pos: usize = 0;
    while (slots > 0) {
        var x = lo;
        var chosen = false;
        while (x <= hi) : (x += 1) {
            if (x > rem) break;
            const block = boundedCompositionCount(rem - x, slots - 1, lo, hi);
            if (rank > block) rank -= block else {
                out[pos] = @intCast(x);
                rem -= x;
                slots -= 1;
                pos += 1;
                chosen = true;
                break;
            }
        }
        if (!chosen) return error.InvalidBoundedCompositionRank;
    }
    return out;
}

const WeaveKey = struct {
    remaining: [47]u8,
    opened_up_to: u8,
    closed_up_to: u8,
};

const WeaveCounter = struct {
    allocator: std.mem.Allocator,
    lengths: [47]u8,
    month_count: u8,
    memo: std.AutoHashMap(WeaveKey, WeaveCount),

    fn init(allocator: std.mem.Allocator, lengths_slice: []const u8) WeaveCounter {
        var lengths = [_]u8{0} ** 47;
        for (lengths_slice, 0..) |v, i| lengths[i] = v;
        return .{ .allocator = allocator, .lengths = lengths, .month_count = @intCast(lengths_slice.len), .memo = std.AutoHashMap(WeaveKey, WeaveCount).init(allocator) };
    }

    fn deinit(self: *WeaveCounter) void {
        self.memo.deinit();
    }

    fn initial(self: *const WeaveCounter) WeaveKey {
        return .{ .remaining = self.lengths, .opened_up_to = 0, .closed_up_to = 0 };
    }

    fn isComplete(self: *const WeaveCounter, state: *const WeaveKey) bool {
        var i: usize = 0;
        while (i < self.month_count) : (i += 1) if (state.remaining[i] != 0) return false;
        return true;
    }

    fn legal(self: *const WeaveCounter, state: *const WeaveKey, j: usize) bool {
        if (j >= self.month_count or state.remaining[j] == 0) return false;
        const already_opened = state.remaining[j] < self.lengths[j];
        if (!already_opened and j != (usize, state.opened_up_to)) return false;
        const will_close = state.remaining[j] == 1;
        if (will_close and j != (usize, state.closed_up_to)) return false;
        return true;
    }

    fn moved(self: *const WeaveCounter, state: WeaveKey, j: usize) WeaveKey {
        var next = state;
        if (next.remaining[j] == self.lengths[j]) next.opened_up_to = @intCast(j + 1);
        next.remaining[j] -= 1;
        if (next.remaining[j] == 0) next.closed_up_to = @intCast(j + 1);
        return next;
    }

    fn count(self: *WeaveCounter, state: WeaveKey) !WeaveCount {
        if (self.isComplete(&state)) return 1;
        if (self.memo.get(state)) |v| return v;
        var total: WeaveCount = 0;
        var j: usize = 0;
        while (j < self.month_count) : (j += 1) {
            if (!self.legal(&state, j)) continue;
            total += try self.count(self.moved(state, j));
        }
        try self.memo.put(state, total);
        return total;
    }

    fn unrank(self: *WeaveCounter, rank1: WeaveCount) ![]u8 {
        var total_len: usize = 0;
        var i: usize = 0;
        while (i < self.month_count) : (i += 1) total_len += self.lengths[i];
        var out = try self.allocator.alloc(u8, total_len);
        errdefer self.allocator.free(out);
        var state = self.initial();
        var rank = rank1;
        var pos: usize = 0;
        while (pos < total_len) : (pos += 1) {
            var j: usize = 0;
            var chosen = false;
            while (j < self.month_count) : (j += 1) {
                if (!self.legal(&state, j)) continue;
                const next = self.moved(state, j);
                const block = try self.count(next);
                if (rank > block) rank -= block else {
                    out[pos] = @intCast(j + 1);
                    state = next;
                    chosen = true;
                    break;
                }
            }
            if (!chosen) return error.InvalidWeavingRank;
        }
        return out;
    }
};

pub const Cutlet = struct { name_index: u8, first_day: Scalar, last_day: Scalar };

pub const YearStructure = struct {
    allocator: std.mem.Allocator,
    cutlets: []Cutlet,
    month_lengths: []u8,
    weaving: []u8,
    month_names: []u8,

    pub fn deinit(self: *YearStructure) void {
        self.allocator.free(self.cutlets);
        self.allocator.free(self.month_lengths);
        self.allocator.free(self.weaving);
        self.allocator.free(self.month_names);
    }
};

pub fn buildYearStructure(allocator: std.mem.Allocator, gates: *GateEngine, calculation_day: Scalar, year: Year) !YearStructure {
    const first_day = year.open_day + 1;
    const r = core.sauce(calculation_day, first_day);
    const gate_gaps: usize = @intCast(year.close_gate_index - year.open_gate_index);
    const max_cutlets: usize = @min(17, gate_gaps);
    if (max_cutlets < 6) return error.InvalidYearGateCount;
    const cutlet_stream = core.askBowl(r, 2, 20);
    const cutlet_count: usize = 5 + @as(usize, @intCast(core.chooseRank(cutlet_stream, @intCast(max_cutlets - 5))));

    var required: ?usize = null;
    if (try gates.exactGateIndex(calculation_day)) |g| {
        if (year.open_gate_index < g and g < year.close_gate_index) required = @intCast(g - year.open_gate_index);
    }
    const partition_count = partitionSuffixCount(gate_gaps, cutlet_count, 0, required, false);
    if (partition_count == 0) return error.EmptyCutletPartitionFamily;
    const partition_stream = core.askBowl(r, 2, 21);
    const partition_rank = core.chooseRank(partition_stream, partition_count);
    const partition = try unrankCutletPartition(allocator, gate_gaps, cutlet_count, required, partition_rank);
    defer allocator.free(partition);

    const cutlet_name_space = exact.fallingFactorial(17, @intCast(cutlet_count));
    const cutlet_name_stream = core.askBowl(r, 5, 22);
    const cutlet_name_rank = core.chooseRank(cutlet_name_stream, cutlet_name_space);
    const cutlet_names = try unrankDistinctIndices(allocator, 17, @intCast(cutlet_count), cutlet_name_rank);
    defer allocator.free(cutlet_names);

    var cutlets = try allocator.alloc(Cutlet, cutlet_count);
    errdefer allocator.free(cutlets);
    var cursor = year.open_gate_index;
    var ci: usize = 0;
    while (ci < cutlet_count) : (ci += 1) {
        const open_index = cursor;
        const close_index = cursor + @as(i64, @intCast(partition[ci]));
        cutlets[ci] = .{ .name_index = cutlet_names[ci], .first_day = (try gates.gate(open_index)) + 1, .last_day = try gates.gate(close_index) };
        cursor = close_index;
    }

    const year_length: usize = @intCast(year.close_day - year.open_day);
    const low_months = @as(usize, @intCast(exact.ceilDiv(@intCast(year_length), 123)));
    const high_months = @min(47, year_length / 4);
    if (low_months < 3 or low_months > high_months) return error.InvalidMonthCountRange;
    const month_count_stream = core.askBowl(r, 3, 30);
    const month_count = low_months + @as(usize, @intCast(core.chooseRank(month_count_stream, @intCast(high_months - low_months + 1)))) - 1;

    const length_count = boundedCompositionCount(year_length, month_count, 4, 123);
    if (length_count == 0) return error.EmptyMonthLengthFamily;
    const length_stream = core.askBowl(r, 3, 31);
    const length_rank = core.chooseRank(length_stream, length_count);
    const month_lengths = try unrankBoundedComposition(allocator, year_length, month_count, 4, 123, length_rank);
    errdefer allocator.free(month_lengths);

    var weave_counter = WeaveCounter.init(allocator, month_lengths);
    defer weave_counter.deinit();
    const weave_count = try weave_counter.count(weave_counter.initial());
    if (weave_count == 0) return error.EmptyWeavingFamily;
    const weave_stream = core.askBowl(r, 4, 32);
    const weave_rank_natural = core.chooseRank(weave_stream, @as(Natural, @intCast(weave_count)));
    const weaving = try weave_counter.unrank(@intCast(weave_rank_natural));
    errdefer allocator.free(weaving);

    const month_name_space = exact.fallingFactorial(47, @intCast(month_count));
    const month_name_stream = core.askBowl(r, 5, 33);
    const month_name_rank = core.chooseRank(month_name_stream, month_name_space);
    const month_names = try unrankDistinctIndices(allocator, 47, @intCast(month_count), month_name_rank);
    errdefer allocator.free(month_names);

    return .{ .allocator = allocator, .cutlets = cutlets, .month_lengths = month_lengths, .weaving = weaving, .month_names = month_names };
}

pub fn calendarDate(allocator: std.mem.Allocator, calculation_day: Scalar, target_day: Scalar) !DateResult {
    var gates = try GateEngine.init(allocator);
    defer gates.deinit();
    const year = try findTargetYear(allocator, &gates, calculation_day, target_day);
    var structure = try buildYearStructure(allocator, &gates, calculation_day, year);
    defer structure.deinit();

    var cutlet_index: ?usize = null;
    for (structure.cutlets, 0..) |c, i| {
        if (c.first_day <= target_day and target_day <= c.last_day) {
            cutlet_index = i;
            break;
        }
    }
    if (cutlet_index == null) return error.NoContainingCutlet;
    const c = structure.cutlets[cutlet_index.?];
    const day_in_cutlet: Natural = @intCast(target_day - c.first_day + 1);

    const offset: usize = @intCast(target_day - (year.open_day + 1));
    if (offset >= structure.weaving.len) return error.TargetOffsetOutsideWeaving;
    const month_id = structure.weaving[offset];
    const month_name_index = structure.month_names[month_id - 1];
    var day_in_month: Natural = 0;
    var p: usize = 0;
    while (p <= offset) : (p += 1) if (structure.weaving[p] == month_id) day_in_month += 1;

    return .{
        .year_number = year.number,
        .cutlet_canonical_index = c.name_index,
        .day_in_cutlet = day_in_cutlet,
        .month_canonical_index = month_name_index,
        .day_in_month = day_in_month,
    };
}

test "шағын bounded composition санағы" {
    try std.testing.expectEqual(@as(Natural, 5), boundedCompositionCount(12, 2, 4, 8));
}

test "бір айлық тоқыманың жалғыз жолы" {
    var counter = WeaveCounter.init(std.testing.allocator, &[_]u8{4});
    defer counter.deinit();
    try std.testing.expectEqual(@as(WeaveCount, 1), try counter.count(counter.initial()));
    const row = try counter.unrank(1);
    defer std.testing.allocator.free(row);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 1, 1, 1 }, row);
}
