<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Oracle\WeavingCounter;

// Independent brute-force oracle: enumerate all multiset words, then filter
// by first- and last-appearance order, without calling WeavingCounter::legal().
function enumerateWords55(array &$remaining, array &$word, array &$valid, int $monthCount): void
{
    if (array_sum($remaining) === 0) {
        $first = [];
        $last = [];
        foreach ($word as $position => $month) {
            if (!isset($first[$month])) {
                $first[$month] = $position;
            }
            $last[$month] = $position;
        }
        asort($first, SORT_NUMERIC);
        asort($last, SORT_NUMERIC);
        $order = range(1, $monthCount);
        if (array_keys($first) === $order && array_keys($last) === $order) {
            $valid[] = $word;
        }
        return;
    }
    for ($month = 1; $month <= $monthCount; ++$month) {
        if ($remaining[$month - 1] === 0) {
            continue;
        }
        --$remaining[$month - 1];
        $word[] = $month;
        enumerateWords55($remaining, $word, $valid, $monthCount);
        array_pop($word);
        ++$remaining[$month - 1];
    }
}

$cases = [[2, 2], [2, 2, 2], [3, 2, 2], [2, 3, 2, 2]];
$ranks = 0;
foreach ($cases as $caseIndex => $lengths) {
    $remaining = $lengths;
    $word = [];
    $valid = [];
    enumerateWords55($remaining, $word, $valid, count($lengths));
    $family = new WeavingCounter($lengths);
    if ($family->countAll()->compare(BigInt::fromInt(count($valid))) !== 0) {
        throw new RuntimeException('STAGE55_MEMO_COUNT_' . $caseIndex);
    }
    foreach ($valid as $index => $expected) {
        $actual = $family->unrank1(BigInt::fromInt($index + 1));
        if ($actual !== $expected) {
            throw new RuntimeException('STAGE55_MEMO_UNRANK_' . $caseIndex . '_' . $index);
        }
        ++$ranks;
    }
}
if ($ranks !== 53) {
    throw new RuntimeException('STAGE55_MEMO_RANK_TOTAL');
}
echo 'STAGE55_MEMO_EXACT cases=4 ranks=53' . "\n";
