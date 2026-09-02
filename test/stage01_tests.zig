const std = @import("std");
const catalog = @import("../src/source_language_catalog.zig");
const exact = @import("../src/exact.zig");
const core = @import("../src/normative_oracle.zig");
const oracle = @import("../src/calendar_oracle.zig");
const monster = @import("../src/monster_base.zig");

test "Stage 1: бастапқы каталог" {
    try catalog.validateFrozenCatalog();
    try std.testing.expectEqual(@as(usize, 17), catalog.cutlets.len);
    try std.testing.expectEqual(@as(usize, 47), catalog.months.len);
}

test "Stage 1: SAVE және M" {
    try std.testing.expectEqual(exact.M, exact.save(@intCast(exact.M)));
    try std.testing.expectEqual(exact.M, exact.save(@intCast(exact.M * 2)));
    try std.testing.expectEqual(@as(exact.Natural, 1), exact.save(@intCast(exact.M + 1)));
}

test "Stage 1: күн санағы" {
    try std.testing.expectEqual(@as(exact.Natural, 1), core.dayCount(core.FOUNDATION_DAY));
    try std.testing.expectEqual(@as(exact.Natural, 3), core.dayCount(core.FOUNDATION_DAY + 1));
    try std.testing.expectEqual(@as(exact.Natural, 2), core.dayCount(core.FOUNDATION_DAY - 1));
}

test "Stage 1: соус өздігінен детерминді" {
    const a = core.sauce(core.FOUNDATION_DAY, core.FOUNDATION_DAY);
    const b = core.sauce(core.FOUNDATION_DAY, core.FOUNDATION_DAY);
    try std.testing.expectEqual(a.bowls, b.bowls);
    try std.testing.expectEqual(a.order_at_drop_46, b.order_at_drop_46);
}

test "Stage 1: толық oracle модулі материалдандырылған" {
    try std.testing.expect(core.completeness() == .full_calendar_materialized);
    var gates = try oracle.GateEngine.init(std.testing.allocator);
    defer gates.deinit();
    try std.testing.expectEqual(core.FOUNDATION_DAY, try gates.gate(0));
}

test "Stage 1: бейтарап монстр қабаты" {
    const ctx = try monster.MonsterManager.prepare(core.FOUNDATION_DAY, core.FOUNDATION_DAY);
    try std.testing.expect(ctx.status == .ready);
    try std.testing.expectEqual(@as(u64, 1), ctx.metrics.dispatch_count);
}
