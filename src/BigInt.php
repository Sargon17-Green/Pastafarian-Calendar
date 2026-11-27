<?php
declare(strict_types=1);

namespace Pastafari\Stage01;

use InvalidArgumentException;
use RuntimeException;

final class BigInt
{
    private const BASE = 1000000000;
    private const BASE_DIGITS = 9;

    private int $sign;
    /** @var list<int> */
    private array $limbs;

    /** @param list<int> $limbs */
    private function __construct(int $sign, array $limbs)
    {
        while (count($limbs) > 1 && $limbs[array_key_last($limbs)] === 0) {
            array_pop($limbs);
        }
        if ($limbs === [] || (count($limbs) === 1 && $limbs[0] === 0)) {
            $this->sign = 0;
            $this->limbs = [0];
            return;
        }
        $this->sign = $sign < 0 ? -1 : 1;
        $this->limbs = array_values($limbs);
    }

    public static function zero(): self
    {
        return new self(0, [0]);
    }

    public static function one(): self
    {
        return new self(1, [1]);
    }

    public static function fromInt(int $value): self
    {
        return self::fromString((string)$value);
    }

    public static function fromString(string $value): self
    {
        $value = trim($value);
        if (!preg_match('/^[+-]?\d+$/', $value)) {
            throw new InvalidArgumentException('BIGINT_FORMAT');
        }

        $sign = 1;
        if ($value[0] === '-') {
            $sign = -1;
            $value = substr($value, 1);
        } elseif ($value[0] === '+') {
            $value = substr($value, 1);
        }

        $value = ltrim($value, '0');
        if ($value === '') {
            return self::zero();
        }

        $limbs = [];
        for ($end = strlen($value); $end > 0; $end -= self::BASE_DIGITS) {
            $start = max(0, $end - self::BASE_DIGITS);
            $limbs[] = (int)substr($value, $start, $end - $start);
        }
        return new self($sign, $limbs);
    }

    public function isZero(): bool
    {
        return $this->sign === 0;
    }

    public function sign(): int
    {
        return $this->sign;
    }

    public function abs(): self
    {
        return new self($this->isZero() ? 0 : 1, $this->limbs);
    }

    public function neg(): self
    {
        return new self(-$this->sign, $this->limbs);
    }

    public function compare(self $other): int
    {
        if ($this->sign !== $other->sign) {
            return $this->sign <=> $other->sign;
        }
        if ($this->sign === 0) {
            return 0;
        }
        $cmp = self::compareAbsLimbs($this->limbs, $other->limbs);
        return $this->sign > 0 ? $cmp : -$cmp;
    }

    public function equals(self $other): bool
    {
        return $this->compare($other) === 0;
    }

    public function add(self $other): self
    {
        if ($this->sign === 0) {
            return new self($other->sign, $other->limbs);
        }
        if ($other->sign === 0) {
            return new self($this->sign, $this->limbs);
        }
        if ($this->sign === $other->sign) {
            return new self($this->sign, self::addAbsLimbs($this->limbs, $other->limbs));
        }

        $cmp = self::compareAbsLimbs($this->limbs, $other->limbs);
        if ($cmp === 0) {
            return self::zero();
        }
        if ($cmp > 0) {
            return new self($this->sign, self::subAbsLimbs($this->limbs, $other->limbs));
        }
        return new self($other->sign, self::subAbsLimbs($other->limbs, $this->limbs));
    }

    public function sub(self $other): self
    {
        return $this->add($other->neg());
    }

    public function mul(self $other): self
    {
        if ($this->isZero() || $other->isZero()) return self::zero();
        $out = self::multiplyAbsLimbs($this->limbs, $other->limbs);
        return new self($this->sign * $other->sign, $out);
    }

    /**
     * Exact c + a*b, opt-in for the Stage56 suffix experiment only.
     * All unsupported operands use the original signed multiply/add path.
     */
    public function addProduct56(self $a, self $b, bool $experiment = false): self
    {
        $na = count($a->limbs); $nb = count($b->limbs); $nc = count($this->limbs);
        if (!$experiment || PHP_INT_SIZE !== 8 || $this->sign < 0 ||
            $a->sign <= 0 || $b->sign <= 0 || min($na, $nb) < 24 ||
            min($na, $nb) > 32 || max($na, $nb) < 64 ||
            max($na, $nb, $nc) > 3000) {
            return $this->add($a->mul($b));
        }
        // Canonical limb bounds are enforced before grouped integer arithmetic.
        foreach ([$a->limbs, $b->limbs, $this->limbs] as $limbs) {
            foreach ($limbs as $limb) {
                if (!is_int($limb) || $limb < 0 || $limb >= self::BASE) {
                    return $this->add($a->mul($b));
                }
            }
        }
        $out = []; $carry = 0;
        $n = max($na + $nb - 1, $nc);
        for ($k = 0; $k < $n; ++$k) {
            $sum = $carry + ($this->limbs[$k] ?? 0);
            $carry = 0;
            $i = max(0, $k - $nb + 1);
            $last = min($na - 1, $k);
            while ($i <= $last) {
                $end = min($last + 1, $i + 8);
                for (; $i < $end; ++$i) {
                    $sum += $a->limbs[$i] * $b->limbs[$k - $i];
                }
                // At most eight products plus bounded incoming carry:
                // 8*(B-1)^2 + 3002*B < PHP_INT_MAX for B=10^9.
                $carry += intdiv($sum, self::BASE);
                $sum %= self::BASE;
            }
            $carry += intdiv($sum, self::BASE);
            $out[] = $sum % self::BASE;
        }
        while ($carry > 0) {
            $out[] = $carry % self::BASE;
            $carry = intdiv($carry, self::BASE);
        }
        return new self(1, $out);
    }

    /**
     * Karatsuba multiplication for large operands, with a schoolbook base case.
     * @param list<int> $a
     * @param list<int> $b
     * @return list<int>
     */
    private static function multiplyAbsLimbs(array $a, array $b): array
    {
        while (count($a) > 1 && $a[array_key_last($a)] === 0) array_pop($a);
        while (count($b) > 1 && $b[array_key_last($b)] === 0) array_pop($b);
        if ((count($a) === 1 && $a[0] === 0) || (count($b) === 1 && $b[0] === 0)) return [0];
        if (count($a) === 1 && $a[0] === 1) return $b;
        if (count($b) === 1 && $b[0] === 1) return $a;
        if (min(count($a), count($b)) <= 32) return self::multiplySchoolbookLimbs($a, $b);

        $split = intdiv(max(count($a), count($b)), 2);
        $a0 = array_slice($a, 0, $split);
        $a1 = array_slice($a, $split);
        $b0 = array_slice($b, 0, $split);
        $b1 = array_slice($b, $split);
        if ($a0 === []) $a0 = [0];
        if ($a1 === []) $a1 = [0];
        if ($b0 === []) $b0 = [0];
        if ($b1 === []) $b1 = [0];

        $z0 = self::multiplyAbsLimbs($a0, $b0);
        $z2 = self::multiplyAbsLimbs($a1, $b1);
        $z1 = self::multiplyAbsLimbs(self::addAbsLimbs($a0, $a1), self::addAbsLimbs($b0, $b1));
        $z1 = self::subAbsLimbs($z1, $z0);
        $z1 = self::subAbsLimbs($z1, $z2);

        $out = [];
        self::addShiftedLimbs($out, $z0, 0);
        self::addShiftedLimbs($out, $z1, $split);
        self::addShiftedLimbs($out, $z2, 2 * $split);
        while (count($out) > 1 && $out[array_key_last($out)] === 0) array_pop($out);
        return $out;
    }

    /** @param list<int> $a @param list<int> $b @return list<int> */
    private static function multiplySchoolbookLimbs(array $a, array $b): array
    {
        $out = array_fill(0, count($a) + count($b) + 1, 0);
        foreach ($a as $i => $left) {
            $carry = 0;
            foreach ($b as $j => $right) {
                $index = $i + $j;
                $current = $out[$index] + $left * $right + $carry;
                $out[$index] = $current % self::BASE;
                $carry = intdiv($current, self::BASE);
            }
            $index = $i + count($b);
            while ($carry > 0) {
                $current = $out[$index] + $carry;
                $out[$index] = $current % self::BASE;
                $carry = intdiv($current, self::BASE);
                ++$index;
            }
        }
        while (count($out) > 1 && $out[array_key_last($out)] === 0) array_pop($out);
        return $out;
    }

    /** @param list<int> $part */
    private static function addShiftedLimbs(array &$out, array $part, int $offset): void
    {
        $carry = 0;
        $length = count($part);
        for ($i = 0; $i < $length || $carry > 0; ++$i) {
            $index = $offset + $i;
            $current = ($out[$index] ?? 0) + ($part[$i] ?? 0) + $carry;
            $out[$index] = $current % self::BASE;
            $carry = intdiv($current, self::BASE);
        }
    }

    public function mulSmall(int $factor): self
    {
        if ($factor === 0 || $this->isZero()) {
            return self::zero();
        }
        if (abs($factor) >= self::BASE) {
            return $this->mul(self::fromInt($factor));
        }
        $sign = $factor < 0 ? -$this->sign : $this->sign;
        $factor = abs($factor);
        $out = [];
        $carry = 0;
        foreach ($this->limbs as $limb) {
            $cur = $limb * $factor + $carry;
            $out[] = $cur % self::BASE;
            $carry = intdiv($cur, self::BASE);
        }
        while ($carry > 0) {
            $out[] = $carry % self::BASE;
            $carry = intdiv($carry, self::BASE);
        }
        return new self($sign, $out);
    }

    /**
     * Divide exactly by a positive one-limb divisor without allocating a
     * BigInt divisor or remainder. The supported range keeps the intermediate
     * remainder * BASE + limb within a signed 64-bit PHP integer.
     */
    public function divSmallExact(int $divisor): self
    {
        if ($divisor <= 0 || $divisor >= self::BASE) {
            throw new InvalidArgumentException('DIV_SMALL_EXACT_DIVISOR');
        }
        if ($this->isZero()) return self::zero();
        if ($divisor === 1) return $this;

        $out = array_fill(0, count($this->limbs), 0);
        $remainder = 0;
        for ($i = count($this->limbs) - 1; $i >= 0; --$i) {
            $current = $remainder * self::BASE + $this->limbs[$i];
            $out[$i] = intdiv($current, $divisor);
            $remainder = $current % $divisor;
        }
        if ($remainder !== 0) {
            throw new RuntimeException('DIV_SMALL_EXACT_NONEXACT');
        }
        return new self($this->sign, $out);
    }

    public function square(): self
    {
        return $this->mul($this);
    }

    /** @return array{0:self,1:self} */
    public function divMod(self $divisor): array
    {
        if ($divisor->isZero()) {
            throw new InvalidArgumentException('DIVISION_BY_ZERO');
        }

        $d = $divisor->abs();
        $a = $this->abs();
        [$qAbs, $rAbs] = self::divModPositive($a, $d);

        // Bahagi lantai: a = divisor * quotient + remainder.
        // Baki sifar atau mempunyai tanda yang sama dengan pembahagi.
        $berlainanTanda = ($this->sign < 0) !== ($divisor->sign < 0);
        $quotient = $berlainanTanda ? $qAbs->neg() : $qAbs;
        $remainder = $this->sign < 0 ? $rAbs->neg() : $rAbs;

        if ($berlainanTanda && !$rAbs->isZero()) {
            $quotient = $quotient->sub(self::one());
            $remainder = $remainder->add($divisor);
        }
        return [$quotient, $remainder];
    }

    public function floorDiv(self $divisor): self
    {
        return $this->divMod($divisor)[0];
    }

    public function mod(self $divisor): self
    {
        return $this->divMod($divisor)[1];
    }

    public function modSmall(int $divisor): int
    {
        if ($divisor <= 0) {
            throw new InvalidArgumentException('MOD_SMALL_DIVISOR');
        }
        // Elakkan limpahan integer apabila baki * BASE melebihi PHP_INT_MAX.
        if ($divisor >= self::BASE) {
            return $this->mod(self::fromInt($divisor))->toIntExact();
        }
        $r = 0;
        for ($i = count($this->limbs) - 1; $i >= 0; $i--) {
            $r = (int)(($r * self::BASE + $this->limbs[$i]) % $divisor);
        }
        if ($this->sign >= 0 || $r === 0) {
            return $r;
        }
        return $divisor - $r;
    }

    public function toIntExact(): int
    {
        $s = $this->toString();
        if (!preg_match('/^-?\d{1,19}$/', $s)) {
            throw new RuntimeException('BIGINT_NOT_NATIVE_INT');
        }
        $v = filter_var($s, FILTER_VALIDATE_INT);
        if ($v === false) {
            throw new RuntimeException('BIGINT_NOT_NATIVE_INT');
        }
        return $v;
    }

    /** Exact decimal width of the magnitude; zero has one digit. */
    public function decimalDigitCount(): int
    {
        $last = count($this->limbs) - 1;
        return $last * self::BASE_DIGITS + strlen((string)$this->limbs[$last]);
    }

    /** Scratch-only canonical unsigned base-10^9 limbs, little endian. */
    public function scratchUnsignedLimbs56(): string
    {
        if ($this->sign < 0) throw new InvalidArgumentException('STAGE56_SCRATCH_NEGATIVE');
        return pack('V*', ...$this->limbs);
    }

    public static function fromScratchUnsignedLimbs56(string $bytes): self
    {
        $n = strlen($bytes);
        if ($n < 4 || $n > 8192 || $n % 4 !== 0) {
            throw new InvalidArgumentException('STAGE56_SCRATCH_LIMB_SIZE');
        }
        $limbs = array_values(unpack('V*', $bytes));
        foreach ($limbs as $limb) {
            if ($limb >= self::BASE) throw new InvalidArgumentException('STAGE56_SCRATCH_LIMB_RANGE');
        }
        if (count($limbs) > 1 && $limbs[array_key_last($limbs)] === 0) {
            throw new InvalidArgumentException('STAGE56_SCRATCH_LIMB_CANONICAL');
        }
        return new self(1, $limbs);
    }

    public function toString(): string
    {
        if ($this->sign === 0) {
            return '0';
        }
        $parts = array_reverse($this->limbs);
        $s = (string)array_shift($parts);
        foreach ($parts as $part) {
            $s .= str_pad((string)$part, self::BASE_DIGITS, '0', STR_PAD_LEFT);
        }
        return $this->sign < 0 ? '-' . $s : $s;
    }

    public function __toString(): string
    {
        return $this->toString();
    }

    /** @return array{0:self,1:self} */
    private static function divModPositive(self $a, self $d): array
    {
        if ($a->compare($d) < 0) {
            return [self::zero(), $a];
        }
        if (count($d->limbs) === 1) {
            $divisor = $d->limbs[0];
            $out = array_fill(0, count($a->limbs), 0);
            $rem = 0;
            for ($i = count($a->limbs) - 1; $i >= 0; $i--) {
                $cur = $rem * self::BASE + $a->limbs[$i];
                $out[$i] = intdiv($cur, $divisor);
                $rem = $cur % $divisor;
            }
            return [new self(1, $out), self::fromInt($rem)];
        }

        $qBigEndian = [];
        $remainder = self::zero();
        for ($i = count($a->limbs) - 1; $i >= 0; $i--) {
            $remainder = $remainder->shiftBaseAndAdd($a->limbs[$i]);
            $low = 0;
            $high = self::BASE - 1;
            $best = 0;
            while ($low <= $high) {
                $mid = intdiv($low + $high, 2);
                $probe = $d->mulSmall($mid);
                $cmp = $probe->compare($remainder);
                if ($cmp <= 0) {
                    $best = $mid;
                    $low = $mid + 1;
                } else {
                    $high = $mid - 1;
                }
            }
            $qBigEndian[] = $best;
            if ($best !== 0) {
                $remainder = $remainder->sub($d->mulSmall($best));
            }
        }

        $first = 0;
        while ($first < count($qBigEndian) - 1 && $qBigEndian[$first] === 0) {
            $first++;
        }
        $qBigEndian = array_slice($qBigEndian, $first);
        return [new self(1, array_reverse($qBigEndian)), $remainder];
    }

    private function shiftBaseAndAdd(int $limb): self
    {
        if ($this->isZero()) {
            return new self($limb === 0 ? 0 : 1, [$limb]);
        }
        $limbs = $this->limbs;
        array_unshift($limbs, $limb);
        return new self(1, $limbs);
    }

    /** @param list<int> $a @param list<int> $b */
    private static function compareAbsLimbs(array $a, array $b): int
    {
        if (count($a) !== count($b)) {
            return count($a) <=> count($b);
        }
        for ($i = count($a) - 1; $i >= 0; $i--) {
            if ($a[$i] !== $b[$i]) {
                return $a[$i] <=> $b[$i];
            }
        }
        return 0;
    }

    /** @param list<int> $a @param list<int> $b @return list<int> */
    private static function addAbsLimbs(array $a, array $b): array
    {
        $n = max(count($a), count($b));
        $out = [];
        $carry = 0;
        for ($i = 0; $i < $n; $i++) {
            $cur = ($a[$i] ?? 0) + ($b[$i] ?? 0) + $carry;
            if ($cur >= self::BASE) {
                $cur -= self::BASE;
                $carry = 1;
            } else {
                $carry = 0;
            }
            $out[] = $cur;
        }
        if ($carry !== 0) {
            $out[] = $carry;
        }
        return $out;
    }

    /** @param list<int> $a @param list<int> $b @return list<int> */
    private static function subAbsLimbs(array $a, array $b): array
    {
        $out = [];
        $borrow = 0;
        $n = count($a);
        for ($i = 0; $i < $n; $i++) {
            $cur = $a[$i] - ($b[$i] ?? 0) - $borrow;
            if ($cur < 0) {
                $cur += self::BASE;
                $borrow = 1;
            } else {
                $borrow = 0;
            }
            $out[] = $cur;
        }
        return $out;
    }
}
