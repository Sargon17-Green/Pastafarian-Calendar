const std = @import("std");

pub const Scalar = i65535;
pub const Natural = u65535;
pub const M: Natural = (@as(Natural, 1) << 127) - 1;

pub fn regularMod(x: Scalar, d: Natural) Natural {
    std.debug.assert(d >= 1);
    const ds: Scalar = @intCast(d);
    const r: Scalar = @mod(x, ds);
    return @intCast(r);
}

pub fn save(x: Scalar) Natural {
    return 1 + regularMod(x - 1, M);
}

pub fn saveNatural(x: Natural) Natural {
    return 1 + ((x - 1) % M);
}

pub fn wrap1(position: Scalar, size: Natural) Natural {
    std.debug.assert(size >= 1);
    return 1 + regularMod(position - 1, size);
}

pub fn ceilDiv(a: Natural, b: Natural) Natural {
    std.debug.assert(b >= 1);
    return (a + b - 1) / b;
}

pub fn absDiff(a: Scalar, b: Scalar) Natural {
    if (a >= b) return @intCast(a - b);
    return @intCast(b - a);
}

pub fn checkedNaturalToScalar(x: Natural) !Scalar {
    if (x > @as(Natural, @intCast(std.math.maxInt(Scalar)))) return error.IntegerEnvelopeExceeded;
    return @intCast(x);
}

pub fn fallingFactorial(n: Natural, k: Natural) Natural {
    std.debug.assert(k <= n);
    var r: Natural = 1;
    var j: Natural = 0;
    while (j < k) : (j += 1) r *= n - j;
    return r;
}

pub fn factorial(n: u8) Natural {
    var r: Natural = 1;
    var i: u8 = 2;
    while (i <= n) : (i += 1) r *= i;
    return r;
}

pub fn smallestPowerCount(base: Natural, n: Natural) struct { places: usize, space: Natural } {
    std.debug.assert(base >= 2 and n >= 1);
    var places: usize = 1;
    var space = base;
    while (space < n) : (places += 1) space *= base;
    return .{ .places = places, .space = space };
}

test "SAVE шекаралары" {
    try std.testing.expectEqual(@as(Natural, 1), save(1));
    try std.testing.expectEqual(M - 1, save(@intCast(M - 1)));
    try std.testing.expectEqual(M, save(@intCast(M)));
    try std.testing.expectEqual(@as(Natural, 1), save(@intCast(M + 1)));
    try std.testing.expectEqual(M, save(@intCast(M * 2)));
}
