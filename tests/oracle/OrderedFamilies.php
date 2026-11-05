<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Oracle;

use Pastafari\Stage01\BigInt;

use RuntimeException;

final class DistinctNameFamily
{
    /** @return list<int> */
    public static function unrankIndices(int $n, int $k, BigInt $rank1): array
    {
        $count = NormativeMath::fallingFactorial($n, $k);
        if ($rank1->compare(BigInt::one()) < 0 || $rank1->compare($count) > 0) {
            throw new RuntimeException('DISTINCT_NAME_RANK');
        }
        $remaining = range(1, $n);
        $out = [];
        $r = $rank1;
        for ($position = 1; $position <= $k; $position++) {
            $suffixLength = $k - $position;
            $block = NormativeMath::fallingFactorial(count($remaining) - 1, $suffixLength);
            foreach ($remaining as $idx => $masterIndex) {
                if ($r->compare($block) > 0) {
                    $r = $r->sub($block);
                    continue;
                }
                $out[] = $masterIndex;
                array_splice($remaining, $idx, 1);
                break;
            }
        }
        return $out;
    }
}

final class BoundedCompositionCounter
{
    private int $total;
    private int $slots;
    private int $lo;
    private int $hi;
    /** @var array<string,BigInt> */
    private array $memo = [];

    public function __construct(int $total, int $slots, int $lo, int $hi)
    {
        $this->total = $total;
        $this->slots = $slots;
        $this->lo = $lo;
        $this->hi = $hi;
    }

    public function countAll(): BigInt
    {
        return $this->count($this->total, $this->slots);
    }

    private function count(int $rem, int $slots): BigInt
    {
        if ($slots === 0) {
            return $rem === 0 ? BigInt::one() : BigInt::zero();
        }
        if ($rem < $slots * $this->lo || $rem > $slots * $this->hi) {
            return BigInt::zero();
        }
        $key = $rem . ':' . $slots;
        if (isset($this->memo[$key])) {
            return $this->memo[$key];
        }
        $sum = BigInt::zero();
        for ($x = $this->lo; $x <= $this->hi; $x++) {
            $sum = $sum->add($this->count($rem - $x, $slots - 1));
        }
        return $this->memo[$key] = $sum;
    }

    /** @return list<int> */
    public function unrank1(BigInt $rank1): array
    {
        $all = $this->countAll();
        if ($rank1->compare(BigInt::one()) < 0 || $rank1->compare($all) > 0) {
            throw new RuntimeException('BOUNDED_COMPOSITION_RANK');
        }
        $r = $rank1;
        $rem = $this->total;
        $out = [];
        for ($position = 1; $position <= $this->slots; $position++) {
            for ($x = $this->lo; $x <= $this->hi; $x++) {
                $block = $this->count($rem - $x, $this->slots - $position);
                if ($r->compare($block) > 0) {
                    $r = $r->sub($block);
                    continue;
                }
                $out[] = $x;
                $rem -= $x;
                break;
            }
        }
        return $out;
    }
}

final class CutletPartitionCounter
{
    private int $gaps;
    private int $parts;
    private ?int $required;
    /** @var array<string,BigInt> */
    private array $memo = [];

    public function __construct(int $gaps, int $parts, ?int $required)
    {
        $this->gaps = $gaps;
        $this->parts = $parts;
        $this->required = $required;
    }

    public function countAll(): BigInt
    {
        return $this->count($this->gaps, $this->parts, 0, false);
    }

    private function count(int $rem, int $slots, int $cumulative, bool $hit): BigInt
    {
        if ($slots === 0) {
            if ($rem !== 0) {
                return BigInt::zero();
            }
            return $this->required === null || $hit ? BigInt::one() : BigInt::zero();
        }
        if ($rem < $slots) {
            return BigInt::zero();
        }
        $key = $rem . ':' . $slots . ':' . $cumulative . ':' . ($hit ? '1' : '0');
        if (isset($this->memo[$key])) {
            return $this->memo[$key];
        }
        $total = BigInt::zero();
        $maxX = $rem - ($slots - 1);
        for ($x = 1; $x <= $maxX; $x++) {
            $nextCumulative = $cumulative + $x;
            $nextHit = $hit;
            if ($this->required !== null && !$hit) {
                if ($nextCumulative === $this->required) {
                    $nextHit = true;
                } elseif ($nextCumulative > $this->required) {
                    continue;
                }
            }
            $total = $total->add($this->count($rem - $x, $slots - 1, $nextCumulative, $nextHit));
        }
        return $this->memo[$key] = $total;
    }

    /** @return list<int> */
    public function unrank1(BigInt $rank1): array
    {
        $all = $this->countAll();
        if ($rank1->compare(BigInt::one()) < 0 || $rank1->compare($all) > 0) {
            throw new RuntimeException('CUTLET_PARTITION_RANK');
        }
        $r = $rank1;
        $rem = $this->gaps;
        $slots = $this->parts;
        $cumulative = 0;
        $hit = false;
        $out = [];
        while ($slots > 0) {
            $maxX = $rem - ($slots - 1);
            for ($x = 1; $x <= $maxX; $x++) {
                $nextCumulative = $cumulative + $x;
                $nextHit = $hit;
                if ($this->required !== null && !$hit) {
                    if ($nextCumulative === $this->required) {
                        $nextHit = true;
                    } elseif ($nextCumulative > $this->required) {
                        continue;
                    }
                }
                $block = $this->count($rem - $x, $slots - 1, $nextCumulative, $nextHit);
                if ($r->compare($block) > 0) {
                    $r = $r->sub($block);
                    continue;
                }
                $out[] = $x;
                $rem -= $x;
                $slots--;
                $cumulative = $nextCumulative;
                $hit = $nextHit;
                break;
            }
        }
        return $out;
    }
}

final class WeavingCounter
{
    /** @var list<int> */
    private array $lengths;
    private ?BigInt $allCount = null;
    /** @var array<int,string> Zlib-compressed, newline-separated exact decimal rows. */
    private array $suffixCounts = [];
    private ?int $loadedRowIndex = null;
    /** @var list<string> */
    private array $loadedRow = [];

    /** @param list<int> $lengths */
    public function __construct(array $lengths)
    {
        if ($lengths === [] || min($lengths) < 1) {
            throw new RuntimeException('WEAVING_LENGTHS');
        }
        $this->lengths = array_values($lengths);
    }

    /** Progress samples are emitted only when Stage55 CI supplies a file path. */
    private static function traceStage55(string $phase, int $index, int $size): void
    {
        $path = getenv('STAGE55_PROFILE_PATH');
        if ($path === false || $path === '') {
            return;
        }
        $line = implode("\t", [
            (string)hrtime(true), $phase, (string)$index, (string)$size,
            (string)memory_get_usage(true), (string)memory_get_peak_usage(true),
        ]) . "\n";
        if (file_put_contents($path, $line, FILE_APPEND | LOCK_EX) === false) {
            throw new RuntimeException('STAGE55_PROFILE_WRITE_FAILED');
        }
    }

    public function countAll(): BigInt
    {
        return $this->allCount ??= $this->countSuffix($this->lengths, 0, 0);
    }

    /** Exact binomial via integer operations; no floating-point approximation. */
    private static function choose(int $n, int $k): BigInt
    {
        if ($k < 0 || $k > $n) {
            throw new RuntimeException('WEAVING_BINOMIAL_ARGUMENT');
        }
        $k = min($k, $n - $k);
        $out = BigInt::one();
        for ($i = 1; $i <= $k; ++$i) {
            $numerator = $out->mulSmall($n - $k + $i);
            [$quotient, $remainder] = $numerator->divMod(BigInt::fromInt($i));
            if (!$remainder->isZero()) {
                throw new RuntimeException('WEAVING_BINOMIAL_NONINTEGER');
            }
            $out = $quotient;
        }
        return $out;
    }

    /** Advance C(a+d-2,d) to C(a+d-1,d+1), with exact division. */
    private static function nextCoefficient(BigInt $current, int $a, int $d): BigInt
    {
        $numerator = $current->mulSmall($a + $d - 1);
        [$quotient, $remainder] = $numerator->divMod(BigInt::fromInt($d + 1));
        if (!$remainder->isZero()) {
            throw new RuntimeException('WEAVING_COEFFICIENT_NONINTEGER');
        }
        return $quotient;
    }

    /**
     * Exact insertion recurrence: for a new month of length a and t slots
     * after the preceding new month's first occurrence, choose d old symbols
     * after the new first occurrence (0 <= d <= t). The multiplicity is
     * C(a+d-2,d), and the new tail length is a-1+d.
     *
     * H[k][t] = sum_{d=0..t} C(a_k+d-2,d) H[k+1][a_k-1+d].
     * Since H[k][t]-H[k][t-1] is one term, each row needs only O(t)
     * arithmetic instead of enumerating all interleavings.
     */
    private function buildSuffixCounts(): void
    {
        if ($this->suffixCounts !== []) {
            return;
        }
        $m = count($this->lengths);
        $prefixLength = array_sum($this->lengths);
        self::traceStage55('weave_table_begin', $m, $prefixLength);
        $nextRow = [];
        for ($k = $m; $k >= 1; --$k) {
            $a = $this->lengths[$k - 1];
            $prefixLength -= $a;
            $row = [];
            $sum = BigInt::zero();
            $coefficient = BigInt::one();
            for ($t = 0; $t <= $prefixLength; ++$t) {
                $following = $k === $m
                    ? BigInt::one()
                    : $nextRow[$a - 1 + $t];
                $sum = $sum->add($coefficient->mul($following));
                $row[] = $sum;
                if ($t < $prefixLength) {
                    $coefficient = self::nextCoefficient($coefficient, $a, $t);
                }
            }
            $decimal = [];
            foreach ($row as $ways) {
                $decimal[] = $ways->toString();
            }
            $packed = gzcompress(implode("\n", $decimal), 1);
            if ($packed === false) {
                throw new RuntimeException('WEAVING_SUFFIX_COMPRESSION');
            }
            $this->suffixCounts[$k] = $packed;
            $nextRow = $row;
            if ($k === $m || $k === 1 || ($k % 4) === 0) {
                self::traceStage55('weave_table_row', $k, count($row));
            }
        }
    }

    private function suffixValue(int $k, int $tail): BigInt
    {
        if ($this->loadedRowIndex !== $k) {
            $plain = gzuncompress($this->suffixCounts[$k]);
            if ($plain === false) {
                throw new RuntimeException('WEAVING_SUFFIX_DECOMPRESSION');
            }
            $this->loadedRow = explode("\n", $plain);
            $this->loadedRowIndex = $k;
        }
        return BigInt::fromString($this->loadedRow[$tail]);
    }

    /**
     * Already-opened but not-yet-closed months have only last-occurrence
     * constraints. Their exact number of completions is a product of
     * binomials for ordered final occurrences. All unopened months are
     * handled by the suffix insertion table using the length of this group.
     *
     * @param list<int> $remaining
     */
    private function countSuffix(array $remaining, int $openedUpTo, int $closedUpTo): BigInt
    {
        if (array_sum($remaining) === 0) {
            return BigInt::one();
        }
        $this->buildSuffixCounts();
        $base = BigInt::one();
        $size = 0;
        for ($i = $closedUpTo; $i < $openedUpTo; ++$i) {
            $a = $remaining[$i];
            $base = $base->mul(self::choose($size + $a - 1, $size));
            $size += $a;
        }
        if ($openedUpTo === count($this->lengths)) {
            return $base;
        }
        return $base->mul($this->suffixValue($openedUpTo + 1, $size));
    }

    /** @param list<int> $remaining */
    private function legal(array $remaining, int $openedUpTo, int $closedUpTo, int $j): bool
    {
        $idx = $j - 1;
        if ($remaining[$idx] === 0) {
            return false;
        }
        $alreadyOpened = $remaining[$idx] < $this->lengths[$idx];
        if (!$alreadyOpened && $j !== $openedUpTo + 1) {
            return false;
        }
        $willClose = $remaining[$idx] === 1;
        if ($willClose && $j !== $closedUpTo + 1) {
            return false;
        }
        return true;
    }

    /** @param list<int> $remaining @return array{0:list<int>,1:int,2:int} */
    private function apply(array $remaining, int $openedUpTo, int $closedUpTo, int $j): array
    {
        $idx = $j - 1;
        $nextOpened = $openedUpTo;
        $nextClosed = $closedUpTo;
        if ($remaining[$idx] === $this->lengths[$idx]) {
            $nextOpened = $j;
        }
        $remaining[$idx]--;
        if ($remaining[$idx] === 0) {
            $nextClosed = $j;
        }
        return [$remaining, $nextOpened, $nextClosed];
    }

    /** @return list<int> */
    public function unrank1(BigInt $rank1): array
    {
        $all = $this->countAll();
        if ($rank1->compare(BigInt::one()) < 0 || $rank1->compare($all) > 0) {
            throw new RuntimeException('WEAVING_RANK');
        }
        $remaining = $this->lengths;
        $opened = 0;
        $closed = 0;
        $r = $rank1;
        $out = [];
        $targetLength = array_sum($this->lengths);
        self::traceStage55('weave_unrank_begin', count($this->lengths), $targetLength);
        while (count($out) < $targetLength) {
            for ($j = 1; $j <= count($remaining); $j++) {
                if (!$this->legal($remaining, $opened, $closed, $j)) {
                    continue;
                }
                [$nextRemaining, $nextOpened, $nextClosed] = $this->apply($remaining, $opened, $closed, $j);
                $block = $this->countSuffix($nextRemaining, $nextOpened, $nextClosed);
                if ($r->compare($block) > 0) {
                    $r = $r->sub($block);
                    continue;
                }
                $out[] = $j;
                if ((count($out) % 256) === 0) {
                    self::traceStage55('weave_unrank_step', count($out), $targetLength);
                }
                $remaining = $nextRemaining;
                $opened = $nextOpened;
                $closed = $nextClosed;
                break;
            }
        }
        self::traceStage55('weave_unrank_end', count($out), $targetLength);
        return $out;
    }
}
