const std = @import("std");
const oracle = @import("normative_oracle.zig");

pub const Phase = enum { entry, validate, idle, failed };
pub const Status = enum { fresh, active, ready, failed };

pub const Metrics = struct {
    dispatch_count: u64 = 0,
    validation_count: u64 = 0,
};

pub const MonsterContext = struct {
    calculation_day: oracle.Scalar,
    target_day: oracle.Scalar,
    phase: Phase = .entry,
    sub_phase: u32 = 0,
    status: Status = .fresh,
    retry_budget: u8 = 0,
    recovery_depth: u8 = 0,
    current_handler: u16 = 0,
    previous_handler: u16 = 0,
    metrics: Metrics = .{},
    validation_failures: u32 = 0,
};

pub const BaseValidationManager = struct {
    pub fn validateInputs(ctx: *MonsterContext) !void {
        ctx.metrics.validation_count += 1;
        if (ctx.calculation_day == std.math.minInt(oracle.Scalar)) return error.DayOutsideSafeEnvelope;
        if (ctx.target_day == std.math.minInt(oracle.Scalar)) return error.DayOutsideSafeEnvelope;
    }
};

pub const BaseDispatcher = struct {
    pub fn dispatch(ctx: *MonsterContext) !void {
        ctx.metrics.dispatch_count += 1;
        ctx.previous_handler = ctx.current_handler;
        ctx.current_handler = 1;
        ctx.phase = .validate;
        ctx.status = .active;
        try BaseValidationManager.validateInputs(ctx);
        ctx.phase = .idle;
        ctx.status = .ready;
    }
};

pub const MonsterManager = struct {
    pub fn prepare(calculation_day: oracle.Scalar, target_day: oracle.Scalar) !MonsterContext {
        var ctx = MonsterContext{ .calculation_day = calculation_day, .target_day = target_day };
        try BaseDispatcher.dispatch(&ctx);
        return ctx;
    }
};

test "негізгі контекст шақыруға ғана тиесілі" {
    var a = try MonsterManager.prepare(1, 2);
    var b = try MonsterManager.prepare(1, 2);
    a.metrics.dispatch_count += 10;
    try std.testing.expectEqual(@as(u64, 1), b.metrics.dispatch_count);
}
