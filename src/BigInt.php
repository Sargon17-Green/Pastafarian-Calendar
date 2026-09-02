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
        if ($this->isZero() || $other->isZero()) {
            return self::zero();
        }
        $out = array_fill(0, count($this->limbs) + count($other->limbs) + 1, 0);
        foreach ($this->limbs as $i => $a) {
            $carry = 0;
            foreach ($other->limbs as $j => $b) {
                $idx = $i + $j;
                $cur = $out[$idx] + $a * $b + $carry;
                $out[$idx] = $cur % self::BASE;
                $carry = intdiv($cur, self::BASE);
            }
            $idx = $i + count($other->limbs);
            while ($carry > 0) {
                $cur = $out[$idx] + $carry;
                $out[$idx] = $cur % self::BASE;
                $carry = intdiv($cur, self::BASE);
                $idx++;
            }
        }
        return new self($this->sign * $other->sign, $out);
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

        if ($this->sign >= 0) {
            $q = $divisor->sign > 0 ? $qAbs : $qAbs->neg();
            return [$q, $rAbs];
        }

        if ($rAbs->isZero()) {
            $q = $divisor->sign > 0 ? $qAbs->neg() : $qAbs;
            return [$q, self::zero()];
        }

        $qFloorAbs = $qAbs->add(self::one());
        $q = $divisor->sign > 0 ? $qFloorAbs->neg() : $qFloorAbs;
        $r = $d->sub($rAbs);
        return [$q, $r];
    }

    public function floorDiv(self $divisor): self
    {
        return $this->divMod($divisor)[0];
    }

    public function mod(self $divisor): self
    {
        $r = $this->divMod($divisor)[1];
        if ($divisor->sign < 0 && !$r->isZero()) {
            return $r->neg();
        }
        return $r;
    }

    public function modSmall(int $divisor): int
    {
        if ($divisor <= 0) {
            throw new InvalidArgumentException('MOD_SMALL_DIVISOR');
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
