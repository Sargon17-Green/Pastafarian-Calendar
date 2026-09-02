<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Oracle;

use Pastafari\Stage01\BigInt;

use InvalidArgumentException;

final class NormativeMath
{
    public const FOUNDATION_DAY = -15055671;
    public const TABLETS_DAY = -278522;
    public const YEAR_MAX_DAYS = 5778;

    private static ?BigInt $m = null;

    public static function m(): BigInt
    {
        return self::$m ??= BigInt::fromString('170141183460469231731687303715884105727');
    }

    public static function bi(BigInt|int|string $value): BigInt
    {
        if ($value instanceof BigInt) {
            return $value;
        }
        return is_int($value) ? BigInt::fromInt($value) : BigInt::fromString($value);
    }

    public static function regularMod(BigInt $x, BigInt $d): BigInt
    {
        if ($d->compare(BigInt::one()) < 0) {
            throw new InvalidArgumentException('MOD_DIVISOR');
        }
        return $x->mod($d);
    }

    public static function save(BigInt|int|string $x): BigInt
    {
        $v = self::bi($x);
        return BigInt::one()->add($v->sub(BigInt::one())->mod(self::m()));
    }

    public static function square(BigInt $x): BigInt
    {
        return $x->square();
    }

    public static function ceilDivInt(int $a, int $b): int
    {
        if ($a < 0 || $b < 1) {
            throw new InvalidArgumentException('CEIL_DIV');
        }
        return intdiv($a + $b - 1, $b);
    }

    public static function wrap1(int $position, int $size): int
    {
        if ($size < 1) {
            throw new InvalidArgumentException('WRAP_SIZE');
        }
        $r = ($position - 1) % $size;
        if ($r < 0) {
            $r += $size;
        }
        return $r + 1;
    }

    public static function dayCount(int $day): BigInt
    {
        if ($day === self::FOUNDATION_DAY) {
            return BigInt::one();
        }
        if ($day > self::FOUNDATION_DAY) {
            return BigInt::fromInt($day - self::FOUNDATION_DAY)->mulSmall(2)->add(BigInt::one());
        }
        return BigInt::fromInt(self::FOUNDATION_DAY - $day)->mulSmall(2);
    }

    /** @return array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} */
    public static function workCounts(int $calculationDay, int $targetDay): array
    {
        $c = self::dayCount($calculationDay);
        $t = self::dayCount($targetDay);
        $distance = BigInt::fromInt(abs($targetDay - $calculationDay) + 1);
        $direction = $targetDay < $calculationDay ? 1 : ($targetDay === $calculationDay ? 2 : 3);
        return [
            'action' => $c,
            'target' => $t,
            'distance' => $distance,
            'connection' => $c->add($t),
            'direction' => $direction,
        ];
    }

    public static function fallingFactorial(int $n, int $k): BigInt
    {
        if ($n < 0 || $k < 0 || $k > $n) {
            throw new InvalidArgumentException('FALLING_FACTORIAL');
        }
        $r = BigInt::one();
        for ($j = 0; $j < $k; $j++) {
            $r = $r->mulSmall($n - $j);
        }
        return $r;
    }
}
