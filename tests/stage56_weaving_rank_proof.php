<?php
declare(strict_types=1);

// Test-only exact lexicographic rank/unrank baseline. Intentionally not a
// production provider: countSuffix is recomputed for each lexicographic block.
require_once __DIR__ . '/stage56_weaving_frontier.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\MonthWeavingFrontier56;

function choices56(array $remaining, int $opened): array
{
    $choices = [];
    $limit = min(count($remaining), $opened + 1);
    for ($id = 1; $id <= $limit; ++$id) {
        if ($remaining[$id - 1] === 0) continue;
        if ($remaining[$id - 1] === 1) {
            $earlierOpen = false;
            for ($j = 0; $j < $id - 1; ++$j) {
                if ($remaining[$j] !== 0) { $earlierOpen = true; break; }
            }
            if ($earlierOpen) continue;
        }
        $choices[] = $id;
    }
    return $choices;
}

function proofRank56(MonthWeavingFrontier56 $counter, array $counts, array $word): BigInt
{
    $counter->count($counts);
    if (!array_is_list($word) || count($word) !== array_sum($counts)) {
        throw new InvalidArgumentException('STAGE56_B2_WORD_LENGTH');
    }
    $remaining = $counts;
    $opened = 0;
    $rank = BigInt::one();
    foreach ($word as $wanted) {
        $found = false;
        foreach (choices56($remaining, $opened) as $id) {
            $after = $remaining;
            --$after[$id - 1];
            $size = $counter->countSuffix($after, max($opened, $id));
            if ($id === $wanted) {
                $remaining = $after;
                $opened = max($opened, $id);
                $found = true;
                break;
            }
            if (is_int($wanted) && $id < $wanted) {
                $rank = $rank->add($size);
            }
        }
        if (!$found) throw new InvalidArgumentException('STAGE56_B2_WORD_INVALID');
    }
    return $rank;
}

function proofUnrank56(MonthWeavingFrontier56 $counter, array $counts, BigInt $rank): array
{
    $total = $counter->count($counts);
    if ($rank->compare(BigInt::one()) < 0 || $rank->compare($total) > 0) {
        throw new InvalidArgumentException('STAGE56_B2_RANK_RANGE');
    }
    $remaining = $counts;
    $opened = 0;
    $word = [];
    for ($position = 0, $length = array_sum($counts); $position < $length; ++$position) {
        $found = false;
        foreach (choices56($remaining, $opened) as $id) {
            $after = $remaining;
            --$after[$id - 1];
            $size = $counter->countSuffix($after, max($opened, $id));
            if ($rank->compare($size) <= 0) {
                $word[] = $id;
                $remaining = $after;
                $opened = max($opened, $id);
                $found = true;
                break;
            }
            $rank = $rank->sub($size);
        }
        if (!$found) throw new RuntimeException('STAGE56_B2_UNRANK_INVARIANT');
    }
    return $word;
}

function expectReject56(callable $candidate): void
{
    try { $candidate(); } catch (InvalidArgumentException) { return; }
    throw new RuntimeException('STAGE56_B2_EXPECTED_REJECTION');
}

$counter = new MonthWeavingFrontier56();
$vectors = 0;
$words = 0;
$outOfRange = 0;
for ($m = 1; $m <= 4; ++$m) {
    $combinations = [[]];
    for ($j = 0; $j < $m; ++$j) {
        $next = [];
        foreach ($combinations as $partial) {
            foreach ([1, 2, 3] as $n) $next[] = [...$partial, $n];
        }
        $combinations = $next;
    }
    foreach ($combinations as $counts) {
        $oracle = enumerate56($counts); // Separate DFS, not the frontier recurrence.
        usort($oracle, static function (array $a, array $b): int {
            foreach ($a as $i => $value) {
                if ($value !== $b[$i]) return $value <=> $b[$i];
            }
            return 0;
        });
        $total = $counter->count($counts);
        if ($total->toString() !== (string)count($oracle)) {
            throw new RuntimeException('STAGE56_B2_COUNT_MISMATCH');
        }
        foreach ($oracle as $index => $word) {
            $rank = BigInt::fromInt($index + 1);
            if (!proofRank56($counter, $counts, $word)->equals($rank) ||
                proofUnrank56($counter, $counts, $rank) !== $word) {
                throw new RuntimeException('STAGE56_B2_DIFFERENTIAL_' . implode(',', $counts) . '_' . $index);
            }
            ++$words;
        }
        foreach ([BigInt::zero(), BigInt::fromInt(-1), $total->add(BigInt::one())] as $bad) {
            expectReject56(static fn() => proofUnrank56($counter, $counts, $bad));
            ++$outOfRange;
        }
        ++$vectors;
    }
}
foreach ([
    static fn() => proofRank56($counter, [2, 2], [1, 2, 2, 1]),
    static fn() => proofRank56($counter, [2, 2], [1, 1, 2]),
    static fn() => proofRank56($counter, [1, 1], [2, 1]),
    static fn() => proofRank56($counter, [2, 2], [1, 3, 1, 2]),
    static fn() => proofUnrank56($counter, [0, 2], BigInt::one()),
] as $bad) expectReject56($bad);

$hugeCounts = array_fill(0, 8, 6);
$hugeTotal = $counter->count($hugeCounts);
if (strlen($hugeTotal->toString()) <= 19) {
    throw new RuntimeException('STAGE56_B2_EXPECTED_LARGE_BIGINT');
}
foreach ([BigInt::one(), $hugeTotal] as $rank) {
    $word = proofUnrank56($counter, $hugeCounts, $rank);
    if (!proofRank56($counter, $hugeCounts, $word)->equals($rank)) {
        throw new RuntimeException('STAGE56_B2_LARGE_ROUNDTRIP');
    }
}
if ($vectors !== 120 || $words !== 3940 || $outOfRange !== 360) {
    throw new RuntimeException('STAGE56_B2_EXPECTED_COUNTS');
}
echo "STAGE56_WEAVING_RANK_PROOF vectors=$vectors words=$words out_of_range=$outOfRange invalid=5 huge=2 status=PASS\n";
