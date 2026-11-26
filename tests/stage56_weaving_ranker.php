<?php
declare(strict_types=1);

require_once __DIR__ . '/stage56_weaving_frontier.php';
require_once dirname(__DIR__) . '/src/Patches/MonthWeavingAdjoint56.php';
require_once dirname(__DIR__) . '/src/Patches/MonthWeavingRanker56.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\MonthWeavingAdjoint56;
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

$fastVectors = 0;
$fastWords = 0;
$legacyChecks = 0;
$fastConfigurations = [[4, 4], [4, 4, 4], [4, 5, 4], [5, 5, 5]];
$legacyRanker = new MonthWeavingRanker56(new MonthWeavingAdjoint56());
foreach ($fastConfigurations as $counts) {
    $oracle = enumerate56($counts);
    usort($oracle, static function (array $a, array $b): int {
        foreach ($a as $i => $value) if ($value !== $b[$i]) return $value <=> $b[$i];
        return 0;
    });
    $total = $ranker->count($counts);
    if ($total->toString() !== (string) count($oracle)) {
        throw new RuntimeException('STAGE56_RANKER_FAST_COUNT_' . implode(',', $counts));
    }
    foreach ($oracle as $index => $word) {
        $expected = BigInt::fromInt($index + 1);
        if (!$ranker->rank($counts, $word)->equals($expected)) {
            throw new RuntimeException('STAGE56_RANKER_FAST_RANK_' . implode(',', $counts) . '_' . $index);
        }
        if ($ranker->unrank($counts, $expected) !== $word) {
            throw new RuntimeException('STAGE56_RANKER_FAST_UNRANK_' . implode(',', $counts) . '_' . $index);
        }
        ++$fastWords;
    }
    $legacyTotal = $legacyRanker->count($counts);
    if (!$legacyTotal->equals($total)) throw new RuntimeException('STAGE56_RANKER_FAST_LEGACY_COUNT_' . implode(',', $counts));
    $sampleIndexes = array_values(array_unique([0, intdiv(count($oracle), 2), count($oracle) - 1]));
    foreach ($sampleIndexes as $index) {
        $word = $oracle[$index];
        $expected = BigInt::fromInt($index + 1);
        if (!$legacyRanker->rank($counts, $word)->equals($expected) ||
            $legacyRanker->unrank($counts, $expected) !== $word) {
            throw new RuntimeException('STAGE56_RANKER_FAST_LEGACY_SAMPLE_' . implode(',', $counts) . '_' . $index);
        }
        ++$legacyChecks;
    }
    ++$fastVectors;
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

// Independent exact-integer recurrence constants (Python math.comb) and
// lexicographic endpoint words from the ordered-start/ordered-end definition.
// Exercise both sides of absolute checkpoint boundaries and repeated traversal.
foreach ([
    17 => '1336563913937742779015514226843205758749648930',
    25 => '1143433233166452213708275330375098141285116391578055346520242843926364172612',
    45 => '511450831603566635842431635061380097086835589165741668863877761837550078428239801390425493529408592938402092522571034259482326855962267094094250481647463405640',
    46 => '13581196218029437381585355263903987513757709166138434257280750049251153892567399950057832595323090920585018650185353788041788395544439984231314915779329821186650400',
] as $checkpointMonths => $expectedCount) {
    $counts = array_fill(0, $checkpointMonths, 4);
    $checkpointRanker = new MonthWeavingRanker56();
    $total = $checkpointRanker->count($counts);
    if ($total->toString() !== $expectedCount) {
        throw new RuntimeException('STAGE56_CHECKPOINT_COUNT_' . $checkpointMonths);
    }
    $first = [];
    $last = range(1, $checkpointMonths);
    for ($i = 1; $i <= $checkpointMonths; ++$i) {
        array_push($first, $i, $i, $i, $i);
    }
    for ($i = $checkpointMonths; $i >= 1; --$i) array_push($last, $i, $i);
    $last = array_merge($last, range(1, $checkpointMonths));
    foreach ([[BigInt::one(), $first], [$total, $last], [BigInt::one(), $first]] as [$r, $expectedWord]) {
        if ($checkpointRanker->unrank($counts, $r) !== $expectedWord ||
            !$checkpointRanker->rank($counts, $expectedWord)->equals($r) ||
            !$checkpointRanker->count($counts)->equals($total)) {
            throw new RuntimeException('STAGE56_CHECKPOINT_ENDPOINT_' . $checkpointMonths);
        }
    }
    [$mid, $remainder] = $total->divMod(BigInt::fromInt(2));
    $word = $checkpointRanker->unrank($counts, $mid);
    if (!$checkpointRanker->rank($counts, $word)->equals($mid)) {
        throw new RuntimeException('STAGE56_CHECKPOINT_MID_' . $checkpointMonths);
    }
}
echo "STAGE56_SUFFIX_CHECKPOINT_REGRESSION vectors=2 endpoints=6 midpoints=2 status=PASS\n";
echo "STAGE56_SUFFIX_STRIDE9_REGRESSION vectors=2 endpoints=6 midpoints=2 status=PASS\n";

if ($vectors !== 120 || $words !== 3940 || $rankChecks !== 3940 ||
    $unrankChecks !== 3940 || $positions !== 83776 || $outOfRange !== 360 ||
    $invalid !== 5 || $fastVectors !== 4 || $fastWords !== 31419 || $legacyChecks !== 12) {
    throw new RuntimeException('STAGE56_RANKER_EXPECTED_TOTALS');
}

echo "STAGE56_WEAVING_RANKER_B4 vectors=$vectors words=$words rank_checks=$rankChecks " .
    "unrank_checks=$unrankChecks positions=$positions out_of_range=$outOfRange " .
    "invalid=$invalid fast_vectors=$fastVectors fast_words=$fastWords legacy_checks=$legacyChecks huge=2 status=PASS\n";
