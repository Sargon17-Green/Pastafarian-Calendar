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
    /** @var array<string,BigInt> */
    private array $memo = [];

    /** @param list<int> $lengths */
    public function __construct(array $lengths)
    {
        if ($lengths === [] || min($lengths) < 1) {
            throw new RuntimeException('WEAVING_LENGTHS');
        }
        $this->lengths = array_values($lengths);
    }

    public function countAll(): BigInt
    {
        return $this->count($this->lengths, 0, 0);
    }

    /** @param list<int> $remaining */
    private function count(array $remaining, int $openedUpTo, int $closedUpTo): BigInt
    {
        $done = true;
        foreach ($remaining as $v) {
            if ($v !== 0) {
                $done = false;
                break;
            }
        }
        if ($done) {
            return BigInt::one();
        }
        $key = implode(',', $remaining) . '|' . $openedUpTo . '|' . $closedUpTo;
        if (isset($this->memo[$key])) {
            return $this->memo[$key];
        }
        $total = BigInt::zero();
        $m = count($remaining);
        for ($j = 1; $j <= $m; $j++) {
            if (!$this->legal($remaining, $openedUpTo, $closedUpTo, $j)) {
                continue;
            }
            [$nextRemaining, $nextOpened, $nextClosed] = $this->apply($remaining, $openedUpTo, $closedUpTo, $j);
            $total = $total->add($this->count($nextRemaining, $nextOpened, $nextClosed));
        }
        return $this->memo[$key] = $total;
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
        while (count($out) < $targetLength) {
            for ($j = 1; $j <= count($remaining); $j++) {
                if (!$this->legal($remaining, $opened, $closed, $j)) {
                    continue;
                }
                [$nextRemaining, $nextOpened, $nextClosed] = $this->apply($remaining, $opened, $closed, $j);
                $block = $this->count($nextRemaining, $nextOpened, $nextClosed);
                if ($r->compare($block) > 0) {
                    $r = $r->sub($block);
                    continue;
                }
                $out[] = $j;
                $remaining = $nextRemaining;
                $opened = $nextOpened;
                $closed = $nextClosed;
                break;
            }
        }
        return $out;
    }
}
