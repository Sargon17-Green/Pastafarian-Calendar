<?php
declare(strict_types=1);

require_once __DIR__ . '/stage56_weaving_frontier.php'; // Independent DFS oracle.
require_once dirname(__DIR__) . '/src/Patches/MonthWeavingAdjoint56.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\MonthWeavingAdjoint56;
use Pastafari\Stage01\Patches\MonthWeavingFrontier56;

$subject = new MonthWeavingAdjoint56();
$baseline = new MonthWeavingFrontier56();
$vectors = 0;
$prefixChecks = 0;
$branchChecks = 0;
$wordChecks = 0;
for ($m = 1; $m <= 4; ++$m) {
    $vectorsHere = [[]];
    for ($j = 0; $j < $m; ++$j) {
        $next = [];
        foreach ($vectorsHere as $partial) {
            foreach ([1, 2, 3] as $n) $next[] = [...$partial, $n];
        }
        $vectorsHere = $next;
    }
    foreach ($vectorsHere as $counts) {
        $original = $counts;
        $words = enumerate56($counts); // Independent brute-force paths.
        $wordChecks += count($words);
        $states = [];
        foreach ($words as $word) {
            $prefix = [];
            $rest = $counts;
            $opened = 0;
            for ($at = 0, $length = count($word); $at <= $length; ++$at) {
                $key = implode(',', $prefix);
                if (!isset($states[$key])) {
                    $states[$key] = ['remaining' => $rest, 'opened' => $opened, 'next' => []];
                }
                if ($at === $length) break;
                $id = $word[$at];
                $states[$key]['next'][$id] = ($states[$key]['next'][$id] ?? 0) + 1;
                --$rest[$id - 1];
                $opened = max($opened, $id);
                $prefix[] = $id;
            }
        }
        foreach ($states as $record) {
            $remaining = $record['remaining'];
            $opened = $record['opened'];
            $expected = $record['next'];
            $before = $remaining;
            $actual = $subject->candidateBlocks($remaining, $opened);
            if ($remaining !== $before || array_keys($actual) !== array_keys($expected)) {
                throw new RuntimeException('STAGE56_B3_KEYS_OR_MUTATION_' . implode(',', $counts));
            }
            $sum = BigInt::zero();
            foreach ($expected as $id => $size) {
                if (!$actual[$id]->equals(BigInt::fromInt($size))) {
                    throw new RuntimeException('STAGE56_B3_DIFFERENTIAL_' . implode(',', $counts) . '_' . $id);
                }
                $sum = $sum->add($actual[$id]);
                ++$branchChecks;
            }
            if ($expected !== [] && $sum->toString() !== $baseline->countSuffix($remaining, $opened)->toString()) {
                throw new RuntimeException('STAGE56_B3_PARTITION_' . implode(',', $counts));
            }
            ++$prefixChecks;
        }
        if ($counts !== $original) throw new RuntimeException('STAGE56_B3_SOURCE_MUTATION');
        ++$vectors;
    }
}

$invalid = [
    static fn() => $subject->candidateBlocks([], 0),
    static fn() => $subject->candidateBlocks([1, 0, 1], 1),
    static fn() => $subject->candidateBlocks([0, 1], 0),
    static fn() => $subject->candidateBlocks([1, 2], -1),
    static fn() => $subject->candidateBlocks([1, 2], 3),
    static fn() => $subject->candidateBlocks([124], 0),
    static fn() => $subject->candidateBlocks([1.5], 0),
    static fn() => $subject->candidateBlocks(array_fill(0, 47, 123), 0),
];
foreach ($invalid as $bad) {
    try { $bad(); } catch (InvalidArgumentException) { continue; }
    throw new RuntimeException('STAGE56_B3_EXPECTED_REJECTION');
}

$bigCounts = array_fill(0, 8, 6);
$big = $baseline->count($bigCounts);
if (strlen($big->toString()) <= 19) throw new RuntimeException('STAGE56_B3_LARGE_BIGINT');
$blocks = $subject->candidateBlocks($bigCounts, 0);
$sum = BigInt::zero();
foreach ($blocks as $block) $sum = $sum->add($block);
if (!$sum->equals($big)) throw new RuntimeException('STAGE56_B3_LARGE_PARTITION');
if ($vectors !== 120 || $prefixChecks !== 18302 || $wordChecks !== 3940) {
    throw new RuntimeException('STAGE56_B3_EXPECTED_TOTALS');
}
echo "STAGE56_WEAVING_ADJOINT_B3 vectors=$vectors prefixes=$prefixChecks branches=$branchChecks words=$wordChecks invalid=8 huge=1 status=PASS\n";
