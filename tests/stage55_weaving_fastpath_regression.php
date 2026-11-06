<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Oracle\WeavingCounter;

// Independent brute-force multiset enumeration. It neither reads the
// WeavingCounter transition rules nor reuses its counting recurrence.
$enumerate = null;
$enumerate = static function (array &$remaining, array &$word, array &$valid, int $months)
    use (&$enumerate): void {
    if (array_sum($remaining) === 0) {
        $first = [];
        $last = [];
        foreach ($word as $symbol) {
            if (!in_array($symbol, $first, true)) {
                $first[] = $symbol;
            }
        }
        for ($i = count($word) - 1; $i >= 0; --$i) {
            if (!in_array($word[$i], $last, true)) {
                $last[] = $word[$i];
            }
        }
        $ordered = range(1, $months);
        if ($first === $ordered && $last === array_reverse($ordered)) {
            $valid[] = $word;
        }
        return;
    }
    for ($j = 1; $j <= $months; ++$j) {
        if ($remaining[$j - 1] <= 0) {
            continue;
        }
        --$remaining[$j - 1];
        $word[] = $j;
        $enumerate($remaining, $word, $valid, $months);
        array_pop($word);
        ++$remaining[$j - 1];
    }
};

$cases = 0;
$ranks = 0;
$verify = static function (array $lengths) use ($enumerate, &$cases, &$ranks): void {
    $remaining = $lengths;
    $word = [];
    $valid = [];
    $enumerate($remaining, $word, $valid, count($lengths));
    $family = new WeavingCounter($lengths);
    if ($family->countAll()->compare(BigInt::fromInt(count($valid))) !== 0) {
        throw new RuntimeException('STAGE55_FASTPATH_COUNT_' . $cases);
    }
    foreach ($valid as $index => $expected) {
        if ($family->unrank1(BigInt::fromInt($index + 1)) !== $expected) {
            throw new RuntimeException('STAGE55_FASTPATH_UNRANK_' . $cases . '_' . $index);
        }
        ++$ranks;
    }
    ++$cases;
};
$walk = null;
$walk = static function (array $vector, int $months) use (&$walk, $verify): void {
    if (count($vector) === $months) {
        if (array_sum($vector) <= 9) {
            $verify($vector);
        }
        return;
    }
    for ($length = 1; $length <= 3; ++$length) {
        $next = $vector;
        $next[] = $length;
        $walk($next, $months);
    }
};
for ($m = 1; $m <= 4; ++$m) {
    $walk([], $m);
}
if ($cases !== 105 || $ranks !== 698) {
    throw new RuntimeException('STAGE55_FASTPATH_TOTAL_' . $cases . '_' . $ranks);
}
echo 'STAGE55_FASTPATH_EXACT cases=105 ranks=698' . "\n";
