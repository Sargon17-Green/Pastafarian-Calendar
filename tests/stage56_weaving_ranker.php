<?php
declare(strict_types=1);

require_once __DIR__ . '/stage56_weaving_frontier.php';
require_once dirname(__DIR__) . '/src/Patches/MonthWeavingAdjoint56.php';
require_once dirname(__DIR__) . '/src/Patches/MonthWeavingRanker56.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\MonthWeavingRanker56;

function rejectRanker56(callable $operation, string $label): void
{
    try {
        $operation();
    } catch (\InvalidArgumentException) {
        return;
    }
    throw new RuntimeException('STAGE56_RANKER_EXPECTED_REJECTION_' . $label);
}

$ranker = new MonthWeavingRanker56();
$vectors = 0;
$words = 0;
$rankChecks = 0;
$unrankChecks = 0;
$positions = 0;
$outOfRange = 0;
$invalid = 0;

for ($m = 1; $m <= 4; ++$m) {
    $configurations = [[]];
    for ($slot = 0; $slot < $m; ++$slot) {
        $next = [];
        foreach ($configurations as $partial) {
            foreach ([1, 2, 3] as $count) {
                $next[] = [...$partial, $count];
            }
        }
        $configurations = $next;
    }

    foreach ($configurations as $counts) {
        $oracle = enumerate56($counts);
        usort($oracle, static function (array $a, array $b): int {
            foreach ($a as $i => $value) {
                if ($value !== $b[$i]) return $value <=> $b[$i];
            }
            return 0;
        });

        $original = $counts;
        $total = $ranker->count($counts);
        if ($total->toString() !== (string) count($oracle)) {
            throw new RuntimeException('STAGE56_RANKER_COUNT_' . implode(',', $counts));
        }

        foreach ($oracle as $index => $word) {
            $expected = BigInt::fromInt($index + 1);
            if (!$ranker->rank($counts, $word)->equals($expected)) {
                throw new RuntimeException('STAGE56_RANKER_RANK_' . implode(',', $counts) . '_' . $index);
            }
            if ($ranker->unrank($counts, $expected) !== $word) {
                throw new RuntimeException('STAGE56_RANKER_UNRANK_' . implode(',', $counts) . '_' . $index);
            }
            ++$rankChecks;
            ++$unrankChecks;
            $positions += 2 * count($word);
            ++$words;
        }

        if ($counts !== $original) {
            throw new RuntimeException('STAGE56_RANKER_INPUT_MUTATION');
        }

        foreach ([
            BigInt::zero(),
            BigInt::fromInt(-1),
            $total->add(BigInt::one()),
        ] as $badRank) {
            rejectRanker56(
                static fn() => $ranker->unrank($counts, $badRank),
                'RANGE_' . implode(',', $counts)
            );
            ++$outOfRange;
        }
        ++$vectors;
    }
}

$invalidWords = [
    [[2, 2], [1, 2, 2, 1]],
    [[2, 2], [2, 1, 1, 2]],
    [[2, 2], [1, 1, 2]],
    [[2, 2], [1, 2, 1, 3]],
    [[2, 2], [1, 2, 2, 2]],
];
foreach ($invalidWords as [$counts, $word]) {
    rejectRanker56(
        static fn() => $ranker->rank($counts, $word),
        'WORD_' . implode(',', $counts)
    );
    ++$invalid;
}

$largeCounts = array_fill(0, 8, 6);
$largeTotal = $ranker->count($largeCounts);
if (strlen($largeTotal->toString()) <= 19) {
    throw new RuntimeException('STAGE56_RANKER_EXPECTED_BIGINT');
}
foreach ([BigInt::one(), $largeTotal] as $largeRank) {
    $word = $ranker->unrank($largeCounts, $largeRank);
    if (!$ranker->rank($largeCounts, $word)->equals($largeRank)) {
        throw new RuntimeException('STAGE56_RANKER_LARGE_ROUNDTRIP');
    }
}

if ($vectors !== 120 || $words !== 3940 || $rankChecks !== 3940 ||
    $unrankChecks !== 3940 || $positions !== 83776 || $outOfRange !== 360 ||
    $invalid !== 5) {
    throw new RuntimeException('STAGE56_RANKER_EXPECTED_TOTALS');
}

echo "STAGE56_WEAVING_RANKER_B4 vectors=$vectors words=$words rank_checks=$rankChecks " .
    "unrank_checks=$unrankChecks positions=$positions out_of_range=$outOfRange " .
    "invalid=$invalid huge=2 status=PASS\n";
