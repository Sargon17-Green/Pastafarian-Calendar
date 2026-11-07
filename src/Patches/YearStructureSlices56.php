<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use LogicException;
use Pastafari\Stage01\BigInt;

/**
 * Stage56 phase A: independent, exact, opt-in production combinatorics.
 * It does not build year records, generate a weaving, or supply PATCH23.
 * All ranks are one-based BigInt values; output vectors use lexical order.
 */
final class YearStructureSlices56
{
    /** @var array<string, BigInt> */
    private array $binomials = [];
    /** @var array<string, BigInt> */
    private array $monthCounts = [];

    private function choose(int $n, int $k): BigInt
    {
        if ($n < 0 || $k < 0 || $k > $n) {
            return BigInt::zero();
        }
        $k = min($k, $n - $k);
        $key = $n . ':' . $k;
        if (isset($this->binomials[$key])) {
            return $this->binomials[$key];
        }
        $value = BigInt::one();
        for ($i = 1; $i <= $k; ++$i) {
            [$quotient, $remainder] = $value->mulSmall($n - $k + $i)
                ->divMod(BigInt::fromInt($i));
            if (!$remainder->isZero()) {
                throw new LogicException('STAGE56_NONEXACT_BINOMIAL');
            }
            $value = $quotient;
        }
        return $this->binomials[$key] = $value;
    }

    private function checkCutletArgs(int $gaps, int $parts, ?int $required): void
    {
        if ($gaps < 1 || $gaps > 5778 || $parts < 1 || $parts > 17 || $parts > $gaps ||
            ($required !== null && ($required < 1 || $required >= $gaps))) {
            throw new InvalidArgumentException('STAGE56_CUTLET_ARGS');
        }
    }

    private function unrestricted(int $gaps, int $parts): BigInt
    {
        if ($parts === 0) {
            return $gaps === 0 ? BigInt::one() : BigInt::zero();
        }
        return $gaps >= $parts ? $this->choose($gaps - 1, $parts - 1) : BigInt::zero();
    }

    private function forced(int $gaps, int $parts, int $cut): BigInt
    {
        if ($cut <= 0 || $cut >= $gaps || $parts < 2 || $gaps < $parts) {
            return BigInt::zero();
        }
        $sum = BigInt::zero();
        for ($leftParts = 1; $leftParts < $parts; ++$leftParts) {
            $sum = $sum->add($this->choose($cut - 1, $leftParts - 1)
                ->mul($this->choose($gaps - $cut - 1, $parts - $leftParts - 1)));
        }
        return $sum;
    }

    public function countCutletPartitions(int $gaps, int $parts, ?int $requiredCut = null): BigInt
    {
        $this->checkCutletArgs($gaps, $parts, $requiredCut);
        return $requiredCut === null ? $this->unrestricted($gaps, $parts)
            : $this->forced($gaps, $parts, $requiredCut);
    }

    private function cutletSuffixCount(int $gaps, int $parts, ?int $required,
        int $before, int $candidate, int $afterSlots): BigInt
    {
        $after = $before + $candidate;
        $remaining = $gaps - $after;
        if ($required !== null && $before < $required && $after > $required) {
            return BigInt::zero();
        }
        if ($required !== null && $after < $required) {
            return $this->forced($remaining, $afterSlots, $required - $after);
        }
        return $this->unrestricted($remaining, $afterSlots);
    }

    private function checkRank(BigInt $rank, BigInt $total): void
    {
        if ($rank->compare(BigInt::one()) < 0 || $rank->compare($total) > 0) {
            throw new InvalidArgumentException('STAGE56_RANK_RANGE');
        }
    }

    /** @return list<int> */
    public function unrankCutletPartitions(int $gaps, int $parts, ?int $requiredCut,
        BigInt $rank): array
    {
        $total = $this->countCutletPartitions($gaps, $parts, $requiredCut);
        $this->checkRank($rank, $total);
        $prefix = 0;
        $result = [];
        for ($slot = 0; $slot < $parts; ++$slot) {
            $remainingSlots = $parts - $slot - 1;
            $maximum = $gaps - $prefix - $remainingSlots;
            $picked = false;
            for ($candidate = 1; $candidate <= $maximum; ++$candidate) {
                $block = $this->cutletSuffixCount($gaps, $parts, $requiredCut,
                    $prefix, $candidate, $remainingSlots);
                if ($rank->compare($block) > 0) {
                    $rank = $rank->sub($block);
                    continue;
                }
                $result[] = $candidate;
                $prefix += $candidate;
                $picked = true;
                break;
            }
            if (!$picked) {
                throw new LogicException('STAGE56_CUTLET_UNRANK_INVARIANT');
            }
        }
        return $result;
    }

    /** @param list<int> $partition */
    public function rankCutletPartitions(int $gaps, int $parts, ?int $requiredCut,
        array $partition): BigInt
    {
        $this->checkCutletArgs($gaps, $parts, $requiredCut);
        if (!array_is_list($partition) || count($partition) !== $parts) {
            throw new InvalidArgumentException('STAGE56_CUTLET_VECTOR');
        }
        $prefix = 0;
        $hit = false;
        foreach ($partition as $part) {
            if (!is_int($part) || $part <= 0) {
                throw new InvalidArgumentException('STAGE56_CUTLET_VECTOR');
            }
            $prefix += $part;
            if ($requiredCut !== null && $prefix === $requiredCut) {
                $hit = true;
            }
        }
        if ($prefix !== $gaps || ($requiredCut !== null && !$hit)) {
            throw new InvalidArgumentException('STAGE56_CUTLET_VECTOR');
        }
        $rank = BigInt::one();
        $prefix = 0;
        foreach ($partition as $slot => $chosen) {
            $remainingSlots = $parts - $slot - 1;
            for ($candidate = 1; $candidate < $chosen; ++$candidate) {
                $rank = $rank->add($this->cutletSuffixCount($gaps, $parts,
                    $requiredCut, $prefix, $candidate, $remainingSlots));
            }
            $prefix += $chosen;
        }
        $this->checkRank($rank, $this->countCutletPartitions($gaps, $parts, $requiredCut));
        return $rank;
    }

    private function checkMonthArgs(int $total, int $slots): void
    {
        if ($total < 0 || $total > 5778 || $slots < 1 || $slots > 47) {
            throw new InvalidArgumentException('STAGE56_MONTH_ARGS');
        }
    }

    public function countMonthLengths(int $total, int $slots): BigInt
    {
        $this->checkMonthArgs($total, $slots);
        if ($total < 4 * $slots || $total > 123 * $slots) {
            return BigInt::zero();
        }
        $key = $slots . ':' . $total;
        if (isset($this->monthCounts[$key])) {
            return $this->monthCounts[$key];
        }
        $extra = $total - 4 * $slots;
        $answer = BigInt::zero();
        for ($j = 0; $j <= min($slots, intdiv($extra, 120)); ++$j) {
            $term = $this->choose($slots, $j)
                ->mul($this->choose($extra - 120 * $j + $slots - 1, $slots - 1));
            $answer = ($j % 2 === 0) ? $answer->add($term) : $answer->sub($term);
        }
        if ($answer->sign() < 0) {
            throw new LogicException('STAGE56_NEGATIVE_MONTH_COUNT');
        }
        return $this->monthCounts[$key] = $answer;
    }

    private function remainingMonthCount(int $total, int $slots): BigInt
    {
        if ($slots === 0) {
            return $total === 0 ? BigInt::one() : BigInt::zero();
        }
        if ($total < 0 || $total > 5778) {
            return BigInt::zero();
        }
        return $this->countMonthLengths($total, $slots);
    }

    /** @return list<int> */
    public function unrankMonthLengths(int $total, int $slots, BigInt $rank): array
    {
        $count = $this->countMonthLengths($total, $slots);
        $this->checkRank($rank, $count);
        $result = [];
        $left = $total;
        for ($i = 0; $i < $slots; ++$i) {
            $afterSlots = $slots - $i - 1;
            $chosen = false;
            for ($length = 4; $length <= 123; ++$length) {
                $block = $this->remainingMonthCount($left - $length, $afterSlots);
                if ($rank->compare($block) > 0) {
                    $rank = $rank->sub($block);
                    continue;
                }
                $result[] = $length;
                $left -= $length;
                $chosen = true;
                break;
            }
            if (!$chosen) {
                throw new LogicException('STAGE56_MONTH_UNRANK_INVARIANT');
            }
        }
        return $result;
    }

    /** @param list<int> $lengths */
    public function rankMonthLengths(int $total, int $slots, array $lengths): BigInt
    {
        $this->checkMonthArgs($total, $slots);
        if (!array_is_list($lengths) || count($lengths) !== $slots) {
            throw new InvalidArgumentException('STAGE56_MONTH_VECTOR');
        }
        $sum = 0;
        foreach ($lengths as $length) {
            if (!is_int($length) || $length < 4 || $length > 123) {
                throw new InvalidArgumentException('STAGE56_MONTH_VECTOR');
            }
            $sum += $length;
        }
        if ($sum !== $total) {
            throw new InvalidArgumentException('STAGE56_MONTH_VECTOR');
        }
        $rank = BigInt::one();
        $left = $total;
        foreach ($lengths as $i => $chosen) {
            $afterSlots = $slots - $i - 1;
            for ($length = 4; $length < $chosen; ++$length) {
                $rank = $rank->add($this->remainingMonthCount($left - $length, $afterSlots));
            }
            $left -= $chosen;
        }
        $this->checkRank($rank, $this->countMonthLengths($total, $slots));
        return $rank;
    }

    private function checkNameArgs(int $pool, int $selected): void
    {
        if ($pool < 1 || $pool > 47 || $selected < 1 || $selected > $pool) {
            throw new InvalidArgumentException('STAGE56_NAME_ARGS');
        }
    }

    private function falling(int $pool, int $slots): BigInt
    {
        $answer = BigInt::one();
        for ($i = 0; $i < $slots; ++$i) {
            $answer = $answer->mulSmall($pool - $i);
        }
        return $answer;
    }

    public function countOrderedNames(int $pool, int $selected): BigInt
    {
        $this->checkNameArgs($pool, $selected);
        return $this->falling($pool, $selected);
    }

    /** @return list<int> */
    public function unrankOrderedNames(int $pool, int $selected, BigInt $rank): array
    {
        $this->checkRank($rank, $this->countOrderedNames($pool, $selected));
        $offset = $rank->sub(BigInt::one());
        $remaining = range(1, $pool);
        $result = [];
        for ($i = 0; $i < $selected; ++$i) {
            $block = $this->falling($pool - $i - 1, $selected - $i - 1);
            [$quotient, $offset] = $offset->divMod($block);
            $position = $quotient->toIntExact();
            if ($position < 0 || $position >= count($remaining)) {
                throw new LogicException('STAGE56_NAME_UNRANK_INVARIANT');
            }
            $result[] = $remaining[$position];
            array_splice($remaining, $position, 1);
        }
        return $result;
    }

    /** @param list<int> $names */
    public function rankOrderedNames(int $pool, int $selected, array $names): BigInt
    {
        $this->checkNameArgs($pool, $selected);
        if (!array_is_list($names) || count($names) !== $selected) {
            throw new InvalidArgumentException('STAGE56_NAME_VECTOR');
        }
        $remaining = range(1, $pool);
        $offset = BigInt::zero();
        foreach ($names as $i => $name) {
            if (!is_int($name)) {
                throw new InvalidArgumentException('STAGE56_NAME_VECTOR');
            }
            $position = array_search($name, $remaining, true);
            if ($position === false) {
                throw new InvalidArgumentException('STAGE56_NAME_VECTOR');
            }
            $offset = $offset->add($this->falling($pool - $i - 1,
                $selected - $i - 1)->mulSmall($position));
            array_splice($remaining, $position, 1);
        }
        return $offset->add(BigInt::one());
    }
}
