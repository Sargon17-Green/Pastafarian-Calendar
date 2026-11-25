<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use LogicException;
use Pastafari\Stage01\BigInt;

/** Exact lexicographic interleaving rank/unrank using suffix DP. Internal IDs are zero-based. */
final class MonthWeavingInterleaving56
{
    private const SMALL_FACTOR_LIMIT = 999999999;
    /** @var array<int, list<BigInt>> */
    private array $suffixCache = [];
    /** @var array<int, list<BigInt>> Immutable reusable absolute-stride rows. */
    private array $suffixCheckpoints = [];
    /** @var list<int> */
    private array $lengths;
    private int $monthCount;

    /** @param list<int> $lengths */
    public function __construct(array $lengths)
    {
        if (!array_is_list($lengths) || $lengths === [] || count($lengths) > 47) {
            throw new InvalidArgumentException('STAGE56_INTERLEAVING_LENGTHS');
        }
        $total = 0;
        foreach ($lengths as $length) {
            if (!is_int($length) || $length < 1 || $length > 123) {
                throw new InvalidArgumentException('STAGE56_INTERLEAVING_LENGTHS');
            }
            $total += $length;
        }
        if ($total > 5778) throw new InvalidArgumentException('STAGE56_INTERLEAVING_TOTAL');
        $this->lengths = array_values($lengths);
        $this->monthCount = count($lengths);
    }

    public function count(): BigInt
    {
        if ($this->monthCount === 1) return BigInt::one();
        return $this->suffixCount(0, $this->lengths[0]);
    }

    /** @param list<int> $weave zero-based month IDs */
    public function rank(array $weave): BigInt
    {
        $totalLength = array_sum($this->lengths);
        if (!array_is_list($weave) || count($weave) !== $totalLength || ($weave[0] ?? null) !== 0) {
            throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD');
        }
        $remaining = $this->lengths;
        --$remaining[0];
        $low = 0;
        $high = 0;
        $activeTotal = $remaining[0];
        $baseCount = BigInt::one();
        $rank = BigInt::one();

        for ($position = 1; $position < $totalLength; ++$position) {
            $wanted = $weave[$position];
            if (!is_int($wanted) || $wanted < 0 || $wanted >= $this->monthCount) {
                throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD_ID');
            }
            $prefix = [];
            $running = 0;
            for ($index = $low; $index <= $high; ++$index) {
                $running += $remaining[$index];
                $prefix[] = $running;
            }
            $futureSame = $high < $this->monthCount - 1
                ? $this->suffixCount($high, $activeTotal)
                : BigInt::one();

            // All already-open sibling blocks share the same suffix factor.
            // Sum their bases before multiplying: exact distributivity preserves rank.
            $skippedBase = BigInt::zero();
            $selected = false;
            $previousMonth = null;
            $previousBaseCount = null;
            for ($month = $low; $month <= $high; ++$month) {
                $remainingForMonth = $remaining[$month];
                if ($remainingForMonth === 1 && $month !== $low) continue;
                $nextBaseCount = $previousMonth === null
                    ? self::firstBranchBaseCount($baseCount, $remainingForMonth, $prefix, $low, $month, $activeTotal)
                    : self::nextBranchBaseCount($previousBaseCount, $remaining, $prefix, $low, $previousMonth, $month);
                if ($month < $wanted) {
                    $skippedBase = $skippedBase->add($nextBaseCount);
                    $previousMonth = $month;
                    $previousBaseCount = $nextBaseCount;
                    continue;
                }
                if ($month > $wanted) throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD_INVALID');
                --$remaining[$month];
                --$activeTotal;
                $baseCount = $nextBaseCount;
                if ($remaining[$month] === 0) ++$low;
                $selected = true;
                break;
            }
            if (!$skippedBase->isZero()) $rank = $rank->add($skippedBase->mul($futureSame));
            if ($selected) continue;

            $month = $high + 1;
            if ($month >= $this->monthCount || $wanted !== $month) {
                throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD_INVALID');
            }
            $newRemaining = $this->lengths[$month] - 1;
            $nextBaseCount = self::multiplyByBinomial($baseCount, $activeTotal + $newRemaining - 1, $newRemaining - 1);
            $nextActiveTotal = $activeTotal + $newRemaining;
            $future = $month < $this->monthCount - 1
                ? $this->suffixCount($month, $nextActiveTotal + 1)
                : BigInt::one();
            if ($nextBaseCount->isZero() || $future->isZero()) {
                throw new LogicException('STAGE56_INTERLEAVING_EMPTY_NEW_MONTH');
            }
            $high = $month;
            --$remaining[$month];
            if ($low > $month - 1) $low = $month;
            $activeTotal = $nextActiveTotal;
            $baseCount = $nextBaseCount;
        }
        if (array_sum($remaining) !== 0) throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD_REMAINDER');
        return $rank;
    }

    /** @return list<int> zero-based month IDs */
    public function unrank(BigInt $rank): array
    {
        $totalLength = array_sum($this->lengths);
        $total = $this->count();
        if ($rank->compare(BigInt::one()) < 0 || $rank->compare($total) > 0) {
            throw new InvalidArgumentException('STAGE56_INTERLEAVING_RANK_RANGE');
        }
        $weave = array_fill(0, $totalLength, 0);
        $remaining = $this->lengths;
        --$remaining[0];
        $low = 0;
        $high = 0;
        $activeTotal = $remaining[0];
        $baseCount = BigInt::one();

        for ($position = 1; $position < $totalLength; ++$position) {
            $prefix = [];
            $running = 0;
            for ($index = $low; $index <= $high; ++$index) {
                $running += $remaining[$index];
                $prefix[] = $running;
            }
            $futureSame = $high < $this->monthCount - 1
                ? $this->suffixCount($high, $activeTotal)
                : BigInt::one();
            // Prefix sums of sibling bases are monotone. Compare scaled
            // prefix sums rather than multiplying each individual sibling.
            // At most 47 candidates, and the first candidate retains a fast path.
            $ids = [];
            $bases = [];
            $cumulative = [];
            $sum = BigInt::zero();
            $previousMonth = null;
            $previousBaseCount = null;
            $chosen = null;
            for ($month = $low; $month <= $high; ++$month) {
                $remainingForMonth = $remaining[$month];
                if ($remainingForMonth === 1 && $month !== $low) continue;
                $nextBaseCount = $previousMonth === null
                    ? self::firstBranchBaseCount($baseCount, $remainingForMonth, $prefix, $low, $month, $activeTotal)
                    : self::nextBranchBaseCount($previousBaseCount, $remaining, $prefix, $low, $previousMonth, $month);
                $sum = $sum->add($nextBaseCount);
                $ids[] = $month;
                $bases[] = $nextBaseCount;
                $cumulative[] = $sum;
                if (count($ids) === 1 && $rank->compare($sum->mul($futureSame)) <= 0) {
                    $chosen = 0;
                    break;
                }
                $previousMonth = $month;
                $previousBaseCount = $nextBaseCount;
            }
            if ($chosen === null && $ids !== []) {
                $scaledTotal = $sum->mul($futureSame);
                if ($rank->compare($scaledTotal) > 0) {
                    $rank = $rank->sub($scaledTotal);
                } else {
                    // The first candidate was already ruled out.
                    $left = 1;
                    $right = count($ids) - 1;
                    while ($left < $right) {
                        $mid = intdiv($left + $right, 2);
                        if ($rank->compare($cumulative[$mid]->mul($futureSame)) <= 0) {
                            $right = $mid;
                        } else {
                            $left = $mid + 1;
                        }
                    }
                    $chosen = $left;
                    $rank = $rank->sub($cumulative[$chosen - 1]->mul($futureSame));
                }
            }
            if ($chosen !== null) {
                $month = $ids[$chosen];
                $weave[$position] = $month;
                --$remaining[$month];
                --$activeTotal;
                $baseCount = $bases[$chosen];
                if ($remaining[$month] === 0) ++$low;
                continue;
            }

            $month = $high + 1;
            if ($month >= $this->monthCount) throw new LogicException('STAGE56_INTERLEAVING_EXHAUSTED');
            $newRemaining = $this->lengths[$month] - 1;
            $nextBaseCount = self::multiplyByBinomial($baseCount, $activeTotal + $newRemaining - 1, $newRemaining - 1);
            $nextActiveTotal = $activeTotal + $newRemaining;
            $future = $month < $this->monthCount - 1
                ? $this->suffixCount($month, $nextActiveTotal + 1)
                : BigInt::one();
            $block = $nextBaseCount->mul($future);
            if ($rank->compare($block) > 0) throw new LogicException('STAGE56_INTERLEAVING_FINAL_BRANCH');
            $weave[$position] = $month;
            $high = $month;
            --$remaining[$month];
            if ($low > $month - 1) $low = $month;
            $activeTotal = $nextActiveTotal;
            $baseCount = $nextBaseCount;
        }
        if (array_sum($remaining) !== 0 || !$rank->equals(BigInt::one())) {
            throw new LogicException('STAGE56_INTERLEAVING_REMAINDER');
        }
        return $weave;
    }

    private function suffixCount(int $lastSeen, int $q): BigInt
    {
        if ($lastSeen >= $this->monthCount - 1) return BigInt::one();
        $cached = $this->suffixCache[$lastSeen] ?? null;
        if ($cached !== null && count($cached) > $q) return $cached[$q];
        $checkpoint = $this->suffixCheckpoints[$lastSeen] ?? null;
        if ($checkpoint !== null && count($checkpoint) > $q) return $checkpoint[$q];
        $this->rebuildSuffix($lastSeen, $q);
        return $this->suffixCache[$lastSeen][$q]
            ?? throw new LogicException('STAGE56_INTERLEAVING_CACHE_MISS');
    }

    private function rebuildSuffix(int $start, int $qStart): void
    {
        $needed = array_fill(0, $this->monthCount, 0);
        $needed[$start] = $qStart;
        for ($index = $start; $index < $this->monthCount - 1; ++$index) {
            $needed[$index + 1] = $needed[$index] + $this->lengths[$index + 1] - 1;
        }
        // A covering checkpoint is the exact same DP row, possibly with extra
        // entries. Never reuse a shorter row; recompute from the terminal row.
        $following = null;
        $stop = $this->monthCount - 1;
        for ($index = $start + 1; $index < $this->monthCount - 1; ++$index) {
            $checkpoint = $this->suffixCheckpoints[$index] ?? null;
            if ($checkpoint !== null && count($checkpoint) > $needed[$index]) {
                $following = $checkpoint;
                $stop = $index - 1;
                break;
            }
        }
        // At most five absolute checkpoints (8,16,24,32,40); reserve
        // the remaining slots of the original eight-row cache for active rows.
        $activeRows = 8 - intdiv($this->monthCount - 2, 8);
        $this->suffixCache = [];
        for ($index = $stop; $index >= $start; --$index) {
            $qMax = $needed[$index];
            if ($index === $this->monthCount - 1) {
                $current = array_fill(0, $qMax + 1, BigInt::one());
            } else {
                if (!is_array($following)) throw new LogicException('STAGE56_INTERLEAVING_DP_SUFFIX');
                $current = array_fill(0, $qMax + 1, BigInt::zero());
                $monthLength = $this->lengths[$index + 1];
                $cumulative = BigInt::zero();
                $weight = BigInt::one();
                for ($q = 1; $q <= $qMax; ++$q) {
                    $r = $q - 1;
                    $target = $monthLength + $r;
                    if (!isset($following[$target])) throw new LogicException('STAGE56_INTERLEAVING_DP_INDEX');
                    $cumulative = $cumulative->add($weight->mul($following[$target]));
                    $current[$q] = $cumulative;
                    [$weight, $remainder] = $weight->mulSmall($monthLength + $r - 1)
                        ->divMod(BigInt::fromInt($r + 1));
                    if (!$remainder->isZero()) throw new LogicException('STAGE56_INTERLEAVING_WEIGHT_NONEXACT');
                }
            }
            $following = $current;
            if ($index < $start + $activeRows) $this->suffixCache[$index] = $current;
            if ($index > 0 && $index % 8 === 0 && $index < $this->monthCount - 1 &&
                count($this->suffixCheckpoints[$index] ?? []) < count($current)) {
                $this->suffixCheckpoints[$index] = $current;
            }
        }
    }

    private static function firstBranchBaseCount(BigInt $baseCount, int $remainingForMonth, array $prefix, int $low, int $month, int $activeTotal): BigInt
    {
        $offset = $month - $low;
        $firstFactor = $remainingForMonth > 1 ? $offset : $offset + 1;
        $numerators = $remainingForMonth > 1 ? [$remainingForMonth - 1] : [];
        $denominators = [$activeTotal];
        for ($i = $firstFactor, $n = count($prefix); $i < $n; ++$i) {
            $numerators[] = $prefix[$i];
            $denominators[] = $prefix[$i] - 1;
        }
        return self::scaleBySmallRatio($baseCount, $numerators, $denominators);
    }

    private static function nextBranchBaseCount(BigInt $previousBaseCount, array $remaining, array $prefix, int $low, int $previousMonth, int $month): BigInt
    {
        $previousOffset = $previousMonth - $low;
        $offset = $month - $low;
        $currentRemaining = $remaining[$month];
        $previousRemaining = $remaining[$previousMonth];
        if ($currentRemaining <= 1) throw new LogicException('STAGE56_INTERLEAVING_BRANCH_ORDER');
        $numerators = [$currentRemaining - 1];
        $denominators = [];
        $firstPrefix = $previousRemaining === 1 ? $previousOffset + 1 : $previousOffset;
        if ($previousRemaining > 1) $denominators[] = $previousRemaining - 1;
        for ($i = $firstPrefix; $i < $offset; ++$i) {
            $numerators[] = $prefix[$i] - 1;
            $denominators[] = $prefix[$i];
        }
        return self::scaleBySmallRatio($previousBaseCount, $numerators, $denominators);
    }

    /** @param list<int> $numerators @param list<int> $denominators */
    private static function scaleBySmallRatio(BigInt $value, array $numerators, array $denominators): BigInt
    {
        foreach ($numerators as $i => $numerator) {
            if ($numerator < 1) throw new LogicException('STAGE56_INTERLEAVING_RATIO_NUMERATOR');
            for ($j = 0, $n = count($denominators); $j < $n && $numerator > 1; ++$j) {
                $denominator = $denominators[$j];
                if ($denominator < 1) throw new LogicException('STAGE56_INTERLEAVING_RATIO_DENOMINATOR');
                $gcd = self::gcd($numerator, $denominator);
                if ($gcd > 1) {
                    $numerator = intdiv($numerator, $gcd);
                    $denominators[$j] = intdiv($denominator, $gcd);
                }
            }
            $numerators[$i] = $numerator;
        }
        foreach (self::packSmallFactors($numerators) as $factor) $value = $value->mulSmall($factor);
        foreach (self::packSmallFactors($denominators) as $factor) {
            [$value, $remainder] = $value->divMod(BigInt::fromInt($factor));
            if (!$remainder->isZero()) throw new LogicException('STAGE56_INTERLEAVING_RATIO_NONEXACT');
        }
        return $value;
    }

    /** @param list<int> $factors @return list<int> */
    private static function packSmallFactors(array $factors): array
    {
        $packed = [];
        $product = 1;
        foreach ($factors as $factor) {
            if ($factor < 1) throw new LogicException('STAGE56_INTERLEAVING_FACTOR');
            if ($factor === 1) continue;
            if ($product > intdiv(self::SMALL_FACTOR_LIMIT, $factor)) {
                $packed[] = $product;
                $product = 1;
            }
            $product *= $factor;
        }
        if ($product > 1) $packed[] = $product;
        return $packed;
    }

    private static function multiplyByBinomial(BigInt $value, int $n, int $k): BigInt
    {
        if ($k < 0 || $n < 0 || $k > $n) return BigInt::zero();
        $k = min($k, $n - $k);
        $numerators = [];
        $denominators = [];
        for ($i = 1; $i <= $k; ++$i) {
            $numerators[] = $n - $k + $i;
            $denominators[] = $i;
        }
        return self::scaleBySmallRatio($value, $numerators, $denominators);
    }

    private static function gcd(int $a, int $b): int
    {
        while ($b !== 0) [$a, $b] = [$b, $a % $b];
        return $a;
    }
}
