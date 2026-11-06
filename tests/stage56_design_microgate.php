<?php
declare(strict_types=1);

// Stage56 DESIGN-ONLY gate. Independent small integer model, not the normative oracle
// and not a production year-structure implementation. Safe bounded ranges only.
function chooseSmall(int $n, int $k): int {
    if ($n < 0 || $k < 0 || $k > $n) return 0;
    $k = min($k, $n - $k);
    $v = 1;
    for ($i = 1; $i <= $k; ++$i) $v = intdiv($v * ($n - $i + 1), $i);
    return $v;
}
function positivePartitionsEnumerated(int $g, int $k, ?int $required): int {
    $visit = static function(int $left, int $slots, int $position, bool $hit) use (&$visit, $required): int {
        if ($slots === 0) return ($left === 0 && ($required === null || $hit)) ? 1 : 0;
        $count = 0;
        for ($part = 1; $part <= $left - $slots + 1; ++$part) {
            $next = $position + $part;
            $count += $visit($left - $part, $slots - 1, $next, $hit || $next === $required);
        }
        return $count;
    };
    return $visit($g, $k, 0, false);
}
function positivePartitionsFormula(int $g, int $k, ?int $required): int {
    if ($required === null) return chooseSmall($g - 1, $k - 1);
    $sum = 0;
    for ($i = 1; $i < $k; ++$i) {
        $sum += chooseSmall($required - 1, $i - 1)
            * chooseSmall($g - $required - 1, $k - $i - 1);
    }
    return $sum;
}
function boundedCompositionsEnumerated(int $total, int $slots, int $lo, int $hi): int {
    if ($slots === 0) return $total === 0 ? 1 : 0;
    $sum = 0;
    for ($v = $lo; $v <= $hi; ++$v) {
        $sum += boundedCompositionsEnumerated($total - $v, $slots - 1, $lo, $hi);
    }
    return $sum;
}
function boundedCompositionsFormula(int $total, int $slots, int $lo, int $hi): int {
    $extra = $total - $slots * $lo;
    $width = $hi - $lo + 1;
    $count = 0;
    for ($j = 0; $j <= $slots; ++$j) {
        $term = chooseSmall($slots, $j) * chooseSmall($extra - $j * $width + $slots - 1, $slots - 1);
        $count += ($j % 2 === 0) ? $term : -$term;
    }
    return $count;
}
function legalSmallWeavings(array $lengths): int {
    $m = count($lengths);
    $prefix = array_fill(0, $m, -1);
    $suffix = array_fill(0, $m, -1);
    $count = 0;
    $visit = static function(array $remaining, int $position) use (&$visit, &$prefix, &$suffix, &$count, $m): void {
        if (array_sum($remaining) === 0) {
            for ($j = 1; $j < $m; ++$j) {
                if (!($prefix[$j - 1] < $prefix[$j] && $suffix[$j - 1] < $suffix[$j])) return;
            }
            ++$count;
            return;
        }
        for ($j = 0; $j < $m; ++$j) {
            if ($remaining[$j] === 0) continue;
            $first = $prefix[$j]; $last = $suffix[$j];
            if ($first === -1) $prefix[$j] = $position;
            $suffix[$j] = $position;
            --$remaining[$j];
            $visit($remaining, $position + 1);
            $prefix[$j] = $first; $suffix[$j] = $last;
            ++$remaining[$j];
        }
    };
    $visit($lengths, 0);
    return $count;
}
$checks = 0;
function mustEqual(int $actual, int $expected, string $label): void {
    global $checks;
    ++$checks;
    if ($actual !== $expected) throw new RuntimeException("STAGE56_DESIGN_MISMATCH:$label:$actual:$expected");
}
for ($g = 2; $g <= 12; ++$g) {
    for ($k = 2; $k <= min(5, $g); ++$k) {
        foreach (array_merge([null], range(1, $g - 1)) as $r) {
            mustEqual(positivePartitionsFormula($g, $k, $r),
                positivePartitionsEnumerated($g, $k, $r), "cutlet-$g-$k-" . ($r ?? 'none'));
        }
    }
}
for ($slots = 1; $slots <= 4; ++$slots) {
    for ($total = 0; $total <= 26; ++$total) {
        mustEqual(boundedCompositionsFormula($total, $slots, 2, 5),
            boundedCompositionsEnumerated($total, $slots, 2, 5), "months-$slots-$total");
    }
}
foreach ([[[1, 1], 1], [[2, 1], 1], [[1, 2], 1], [[2, 2], 2]] as [$lengths, $expected]) {
    mustEqual(legalSmallWeavings($lengths), $expected, 'weaving-' . implode(',', $lengths));
}
mustEqual(positivePartitionsFormula(8, 3, 3), 6, 'example-required-gate');
mustEqual(positivePartitionsFormula(8, 3, null), 21, 'example-unrestricted');
mustEqual(boundedCompositionsFormula(15, 3, 4, 123), 10, 'example-length');
mustEqual(boundedCompositionsFormula(369, 3, 4, 123), 1, 'upper-bound');
mustEqual(boundedCompositionsFormula(370, 3, 4, 123), 0, 'above-upper-bound');
echo "STAGE56_DESIGN_MICROGATE checks=$checks partitions=bounded months=bounded weaving=4 status=PASS\n";
