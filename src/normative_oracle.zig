const std = @import("std");
const exact = @import("exact.zig");

pub const Scalar = exact.Scalar;
pub const Natural = exact.Natural;
pub const M = exact.M;
pub const TABLETS_DAY: Scalar = -278522;
pub const FOUNDATION_DAY: Scalar = -15055671;

pub const WorkCounts = struct {
    action: Natural,
    target: Natural,
    distance: Natural,
    connection: Natural,
    direction: Natural,
};

pub const SauceResult = struct {
    bowls: [6]Natural,
    order_at_drop_46: [6]u8,
};

pub const AnswerStream = struct {
    first: Natural,
    direction_step: i2,
};

pub fn dayCount(day: Scalar) Natural {
    if (day == FOUNDATION_DAY) return 1;
    if (day > FOUNDATION_DAY) return @intCast(2 * (day - FOUNDATION_DAY) + 1);
    return @intCast(2 * (FOUNDATION_DAY - day));
}

pub fn workCounts(calculation_day: Scalar, target_day: Scalar) WorkCounts {
    const c = dayCount(calculation_day);
    const t = dayCount(target_day);
    const connection = c + t;
    const direction: Natural = if (target_day < calculation_day) 1 else if (target_day == calculation_day) 2 else 3;
    return .{
        .action = c,
        .target = t,
        .distance = exact.absDiff(target_day, calculation_day) + 1,
        .connection = connection,
        .direction = direction,
    };
}

const Stone = [5]Natural;
const WHEAT: usize = 0;
const BARLEY: usize = 1;
const SALT: usize = 2;
const BITTER: usize = 3;
const RED: usize = 4;

fn ssave(x: Natural) Natural {
    return exact.saveNatural(x);
}

pub fn buildStones() [46]Stone {
    var table: [46]Stone = undefined;
    table[0] = .{ 17, 29, 43, 71, 101 };
    var i: usize = 1;
    while (i < 46) : (i += 1) {
        const old = table[i - 1];
        const n: Natural = @intCast(i + 1);
        table[i] = .{
            ssave(old[WHEAT] * old[WHEAT] + 3 * old[BARLEY] + n),
            ssave(old[BARLEY] * old[BARLEY] + 5 * old[SALT] + old[WHEAT]),
            ssave(old[SALT] * old[SALT] + 7 * old[BITTER] + old[BARLEY]),
            ssave(old[BITTER] * old[BITTER] + 11 * old[RED] + old[SALT]),
            ssave(old[RED] * old[RED] + 13 * old[WHEAT] + old[BITTER]),
        };
    }
    return table;
}

const hidden_coeff = [7][4]Natural{
    .{ 3, 4, 6, 8 }, .{ 5, 7, 10, 12 }, .{ 7, 10, 14, 16 }, .{ 9, 13, 18, 20 },
    .{ 11, 16, 22, 24 }, .{ 13, 19, 26, 28 }, .{ 15, 22, 30, 32 },
};
const hidden_grind_stone = [7]usize{ WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY };

pub fn buildHiddenDrops(counts: WorkCounts, stones: *const [46]Stone) [7]Natural {
    var hidden: [7]Natural = undefined;
    var k: usize = 0;
    while (k < 7) : (k += 1) {
        const c = hidden_coeff[k];
        var x = counts.action + c[0] * counts.target + c[1] * counts.distance + c[2] * counts.connection + c[3] * counts.direction;
        for (stones[k]) |v| x += v;
        x = ssave(x);
        var g: usize = 0;
        while (g < 7) : (g += 1) {
            const old = x;
            x = ssave(old * old + 3 * old + stones[k][hidden_grind_stone[g]] + @as(Natural, @intCast(g + 1)));
        }
        hidden[k] = x;
    }
    return hidden;
}

const Grind = struct { a: Natural, b: Natural, c: Natural, d: Natural, kind: usize };
const visible_grinds = [11]Grind{
    .{ .a = 3, .b = 5, .c = 7, .d = 11, .kind = WHEAT },
    .{ .a = 5, .b = 7, .c = 11, .d = 13, .kind = BARLEY },
    .{ .a = 7, .b = 11, .c = 13, .d = 17, .kind = SALT },
    .{ .a = 11, .b = 13, .c = 17, .d = 19, .kind = BITTER },
    .{ .a = 13, .b = 17, .c = 19, .d = 23, .kind = RED },
    .{ .a = 17, .b = 19, .c = 23, .d = 29, .kind = WHEAT },
    .{ .a = 19, .b = 23, .c = 29, .d = 31, .kind = BARLEY },
    .{ .a = 23, .b = 29, .c = 31, .d = 37, .kind = SALT },
    .{ .a = 29, .b = 31, .c = 37, .d = 41, .kind = BITTER },
    .{ .a = 31, .b = 37, .c = 41, .d = 43, .kind = RED },
    .{ .a = 37, .b = 41, .c = 43, .d = 47, .kind = WHEAT },
};

fn timelineAt(timeline: *const [53]Natural, i: usize, back: usize) Natural {
    return timeline[i + 7 - back];
}

pub fn buildVisibleDrops(counts: WorkCounts, stones: *const [46]Stone, hidden: [7]Natural) [46]Natural {
    var timeline: [53]Natural = [_]Natural{0} ** 53;
    var k: usize = 0;
    while (k < 7) : (k += 1) timeline[6 - k] = hidden[k];
    var visible: [46]Natural = undefined;
    var i: usize = 0;
    while (i < 46) : (i += 1) {
        const p1 = timelineAt(&timeline, i, 1);
        const p3 = timelineAt(&timeline, i, 3);
        const p7 = timelineAt(&timeline, i, 7);
        const n: Natural = @intCast(i + 1);
        var x = ssave(stones[i][WHEAT] * counts.action + stones[i][BARLEY] * counts.target + stones[i][SALT] * counts.distance + stones[i][BITTER] * counts.connection + stones[i][RED] * counts.direction + p1 + 3 * p3 + 5 * p7 + n);
        for (visible_grinds) |row| {
            const old = x;
            x = ssave(old * old + row.a * old + row.b * p1 + row.c * p3 + row.d * p7 + stones[i][row.kind]);
        }
        timeline[i + 7] = x;
        visible[i] = x;
    }
    return visible;
}

pub fn permutationUnrank1(rank1: Natural) [6]u8 {
    std.debug.assert(rank1 >= 1 and rank1 <= 720);
    var remaining = [6]u8{ 1, 2, 3, 4, 5, 6 };
    var remaining_len: usize = 6;
    var out: [6]u8 = undefined;
    var rank0 = rank1 - 1;
    var pos: usize = 0;
    while (pos < 6) : (pos += 1) {
        const slots_left: u8 = @intCast(remaining_len);
        const block = exact.factorial(slots_left - 1);
        const q: usize = @intCast(rank0 / block);
        rank0 %= block;
        out[pos] = remaining[q];
        var j = q;
        while (j + 1 < remaining_len) : (j += 1) remaining[j] = remaining[j + 1];
        remaining_len -= 1;
    }
    return out;
}

pub fn bowlOrderFromDrop(drop: Natural) [6]u8 {
    return permutationUnrank1(((drop - 1) % 720) + 1);
}

pub fn initialBowls(counts: WorkCounts) [6]Natural {
    const primes = [6]Natural{ 17, 19, 23, 29, 31, 37 };
    var bowls: [6]Natural = undefined;
    var id: usize = 0;
    while (id < 6) : (id += 1) {
        const bid: Natural = @intCast(id + 1);
        const s = counts.action + counts.target * bid + counts.distance + counts.connection + counts.direction + primes[id] * primes[id];
        bowls[id] = ssave(s * s + bid);
    }
    return bowls;
}

fn wrap6(pos: isize) usize {
    var x = (pos, 6);
    if (x < 0) x += 6;
    return @intCast(x);
}

pub fn applyVisibleDropsToBowls(start: [6]Natural, visible: [46]Natural, stones: *const [46]Stone) struct { bowls: [6]Natural, order: [6]u8 } {
    const stone_by_position = [6]usize{ WHEAT, BARLEY, SALT, BITTER, RED, WHEAT };
    var bowls = start;
    var order46: [6]u8 = undefined;
    var i: usize = 0;
    while (i < 46) : (i += 1) {
        const drop = visible[i];
        const order = bowlOrderFromDrop(drop);
        const old = bowls;
        var pour = [_]Natural{0} ** 6;
        const first = order[0] - 1;
        const second = order[1] - 1;
        const third = order[2] - 1;
        const n: Natural = @intCast(i + 1);
        pour[0] = ssave(drop * drop + stones[i][WHEAT] * old[first] + 3 * n);
        pour[1] = ssave(drop * drop + stones[i][BARLEY] * old[second] + 5 * n);
        pour[2] = ssave(drop * drop + stones[i][SALT] * old[third] + 7 * n);
        var next: [6]Natural = undefined;
        var p: usize = 0;
        while (p < 6) : (p += 1) {
            const id: usize = order[p] - 1;
            const prev: usize = order[wrap6(@as(isize, @intCast(p)) - 1)] - 1;
            const nxt: usize = order[wrap6(@as(isize, @intCast(p)) + 1)] - 1;
            const s = old[id] + 2 * old[prev] + 3 * old[nxt] + pour[p] + drop + stones[i][stone_by_position[p]];
            next[id] = ssave(s * s + 5 * old[prev] * old[nxt] + n * @as(Natural, @intCast(p + 1)));
        }
        bowls = next;
        if (i == 45) order46 = order;
    }
    return .{ .bowls = bowls, .order = order46 };
}

pub fn postStir12(start: [6]Natural) [6]Natural {
    var bowls = start;
    var stir: usize = 1;
    while (stir <= 12) : (stir += 1) {
        const old = bowls;
        var raw: Natural = 0;
        for (old) |v| raw += v;
        const saved = ssave(raw + 149 * @as(Natural, @intCast(stir)));
        const order = permutationUnrank1(((saved - 1) % 720) + 1);
        var next: [6]Natural = undefined;
        var p: usize = 0;
        while (p < 6) : (p += 1) {
            const id: usize = order[p] - 1;
            const prev: usize = order[wrap6(@as(isize, @intCast(p)) - 1)] - 1;
            const nxt: usize = order[wrap6(@as(isize, @intCast(p)) + 1)] - 1;
            const pos: Natural = @intCast(p + 1);
            const s = old[id] + 3 * old[prev] + 5 * old[nxt] + saved + @as(Natural, @intCast(stir)) + pos * pos;
            next[id] = ssave(s * s + 7 * old[prev] * old[nxt]);
        }
        bowls = next;
    }
    return bowls;
}

pub fn sauce(calculation_day: Scalar, target_day: Scalar) SauceResult {
    const counts = workCounts(calculation_day, target_day);
    const stones = buildStones();
    const hidden = buildHiddenDrops(counts, &stones);
    const visible = buildVisibleDrops(counts, &stones, hidden);
    const initial = initialBowls(counts);
    const after = applyVisibleDropsToBowls(initial, visible, &stones);
    return .{ .bowls = postStir12(after.bowls), .order_at_drop_46 = after.order };
}

pub fn nextBowlInDrop46Order(result: SauceResult, queried_id: u8) u8 {
    var p: usize = 0;
    while (p < 6 and result.order_at_drop_46[p] != queried_id) : (p += 1) {}
    std.debug.assert(p < 6);
    return result.order_at_drop_46[(p + 1) % 6];
}

pub fn askBowl(result: SauceResult, queried_id: u8, seal: Natural) AnswerStream {
    const next_id = nextBowlInDrop46Order(result, queried_id);
    const q: usize = queried_id - 1;
    const n: usize = next_id - 1;
    const first_base = result.bowls[q] + seal + 181;
    const first = ssave(first_base * first_base + 179 * result.bowls[n] + seal);
    const direction_base = first + seal + 1 + 193;
    const direction_number = ssave(direction_base * direction_base + 193 * first + 197 * result.bowls[5]);
    return .{ .first = first, .direction_step = if (direction_number % 2 == 1) 1 else -1 };
}

pub fn answerAt(stream: AnswerStream, k: Natural) Natural {
    const first: Scalar = @intCast(stream.first);
    const kk: Scalar = @intCast(k);
    const delta: Scalar = if (stream.direction_step > 0) kk else -kk;
    return 1 + exact.regularMod(first - 1 + delta, M);
}

pub fn chooseRankShort(stream: AnswerStream, n: Natural) Natural {
    std.debug.assert(n >= 1 and n <= M);
    const limit = (M / n) * n;
    var k: Natural = 0;
    while (true) : (k += 1) {
        const x = answerAt(stream, k);
        if (x <= limit) return ((x - 1) % n) + 1;
    }
}

pub fn chooseRankWide(stream: AnswerStream, n: Natural) Natural {
    std.debug.assert(n > M);
    const power = exact.smallestPowerCount(M, n);
    var wide: Natural = 1;
    var weight: Natural = 1;
    var j: usize = 0;
    while (j < power.places) : (j += 1) {
        wide += (answerAt(stream, @intCast(j)) - 1) * weight;
        weight *= M;
    }
    const limit = (power.space / n) * n;
    while (wide > limit) {
        if (stream.direction_step > 0) {
            wide = 1 + (wide % power.space);
        } else {
            wide = if (wide == 1) power.space else wide - 1;
        }
    }
    return ((wide - 1) % n) + 1;
}

pub fn chooseRank(stream: AnswerStream, n: Natural) Natural {
    return if (n <= M) chooseRankShort(stream, n) else chooseRankWide(stream, n);
}

pub const OracleCompleteness = enum { core_complete, full_calendar_materialized };
pub fn completeness() OracleCompleteness {
    return .full_calendar_materialized;
}

test "күн санағының негізгі шекаралары" {
    try std.testing.expectEqual(@as(Natural, 1), dayCount(FOUNDATION_DAY));
    try std.testing.expectEqual(@as(Natural, 3), dayCount(FOUNDATION_DAY + 1));
    try std.testing.expectEqual(@as(Natural, 2), dayCount(FOUNDATION_DAY - 1));
    const same = workCounts(FOUNDATION_DAY, FOUNDATION_DAY);
    try std.testing.expectEqual(@as(Natural, 1), same.distance);
    try std.testing.expectEqual(@as(Natural, 2), same.direction);
}

test "пермутация шекаралары" {
    try std.testing.expectEqual([6]u8{ 1, 2, 3, 4, 5, 6 }, permutationUnrank1(1));
    try std.testing.expectEqual([6]u8{ 6, 5, 4, 3, 2, 1 }, permutationUnrank1(720));
}
