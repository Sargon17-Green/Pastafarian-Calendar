<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use LogicException;
use Pastafari\Stage01\BigInt;

/**
 * Stage56 Phase B4: exact lexicographic rank/unrank using one shared B3
 * sibling-block computation per prefix. This is opt-in and not wired to PATCH23.
 */
final class MonthWeavingRanker56
{
    private MonthWeavingAdjoint56 $adjoint;

    public function __construct(?MonthWeavingAdjoint56 $adjoint = null)
    {
        $this->adjoint = $adjoint ?? new MonthWeavingAdjoint56();
    }

    /** @param list<int> $counts */
    public function count(array $counts): BigInt
    {
        [$blocks] = $this->initialState($counts);
        return self::sumBlocks($blocks);
    }

    /**
     * One-based lexicographic rank of a valid word.
     * @param list<int> $counts
     * @param list<int> $word
     */
    public function rank(array $counts, array $word): BigInt
    {
        [$blocks, $length] = $this->initialState($counts);
        if (!array_is_list($word) || count($word) !== $length) {
            throw new InvalidArgumentException('STAGE56_RANKER_WORD_LENGTH');
        }

        $remaining = $counts;
        $opened = 0;
        $rank = BigInt::one();

        foreach ($word as $position => $wanted) {
            if (!is_int($wanted)) {
                throw new InvalidArgumentException('STAGE56_RANKER_WORD_ID');
            }

            $found = false;
            foreach ($blocks as $id => $size) {
                if ($id < $wanted) {
                    $rank = $rank->add($size);
                    continue;
                }
                if ($id === $wanted) {
                    --$remaining[$id - 1];
                    $opened = max($opened, $id);
                    $found = true;
                }
                break;
            }
            if (!$found) {
                throw new InvalidArgumentException('STAGE56_RANKER_WORD_INVALID');
            }

            if ($position + 1 < $length) {
                $blocks = $this->adjoint->candidateBlocks($remaining, $opened);
            }
        }

        if (array_sum($remaining) !== 0) {
            throw new LogicException('STAGE56_RANKER_RANK_REMAINDER');
        }
        return $rank;
    }

    /**
     * Return the one-based lexicographic word at $rank.
     * @param list<int> $counts
     * @return list<int>
     */
    public function unrank(array $counts, BigInt $rank): array
    {
        [$blocks, $length, $total] = $this->initialState($counts);
        if ($rank->compare(BigInt::one()) < 0 || $rank->compare($total) > 0) {
            throw new InvalidArgumentException('STAGE56_RANKER_RANK_RANGE');
        }

        $remaining = $counts;
        $opened = 0;
        $word = [];

        for ($position = 0; $position < $length; ++$position) {
            $found = false;
            foreach ($blocks as $id => $size) {
                if ($rank->compare($size) > 0) {
                    $rank = $rank->sub($size);
                    continue;
                }
                $word[] = $id;
                --$remaining[$id - 1];
                $opened = max($opened, $id);
                $found = true;
                break;
            }
            if (!$found) {
                throw new LogicException('STAGE56_RANKER_UNRANK_INVARIANT');
            }

            if ($position + 1 < $length) {
                $blocks = $this->adjoint->candidateBlocks($remaining, $opened);
            }
        }

        if (array_sum($remaining) !== 0 || !$rank->equals(BigInt::one())) {
            throw new LogicException('STAGE56_RANKER_UNRANK_REMAINDER');
        }
        return $word;
    }

    /**
     * Validate an original positive count vector and return its first sibling map.
     * @param list<int> $counts
     * @return array{0:array<int,BigInt>,1:int,2:BigInt}
     */
    private function initialState(array $counts): array
    {
        if (!array_is_list($counts) || $counts === [] || count($counts) > 47) {
            throw new InvalidArgumentException('STAGE56_RANKER_COUNTS');
        }
        $length = 0;
        foreach ($counts as $count) {
            if (!is_int($count) || $count < 1 || $count > 123) {
                throw new InvalidArgumentException('STAGE56_RANKER_COUNTS');
            }
            $length += $count;
        }
        if ($length > 5778) {
            throw new InvalidArgumentException('STAGE56_RANKER_LENGTH');
        }

        $blocks = $this->adjoint->candidateBlocks($counts, 0);
        if ($blocks === []) {
            throw new LogicException('STAGE56_RANKER_EMPTY_INITIAL_BLOCKS');
        }
        return [$blocks, $length, self::sumBlocks($blocks)];
    }

    /** @param array<int,BigInt> $blocks */
    private static function sumBlocks(array $blocks): BigInt
    {
        $total = BigInt::zero();
        foreach ($blocks as $block) {
            $total = $total->add($block);
        }
        return $total;
    }
}
