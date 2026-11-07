<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/src/BigInt.php';
require_once dirname(__DIR__) . '/src/Patches/YearStructureSlices56.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\YearStructureSlices56;

$subject = new YearStructureSlices56();
$assertions = 0;
$partitions = 0;
$monthVectors = 0;
$nameVectors = 0;
$invalid = 0;
$large = 0;

function assert56(bool $predicate, string $context): void {
    global $assertions;
    ++$assertions;
    if (!$predicate) {
        throw new RuntimeException('STAGE56_SLICE_FAILURE_' . $context);
    }
}
function reject56(callable $callback, string $context): void {
    global $invalid;
    try {
        $callback();
    } catch (InvalidArgumentException $exception) {
        assert56(str_starts_with($exception->getMessage(), 'STAGE56_'),
            $context . '_MESSAGE');
        ++$invalid;
        return;
    }
    throw new RuntimeException('STAGE56_EXPECTED_REJECTION_' . $context);
}
/** Exhaustive DFS oracle, test-only; no combinatorial formulas or production helpers. */
function bruteCutlets(int $total, int $slots, ?int $required): array {
    $all = [];
    $walk = static function(int $left, int $count, array $partial) use (&$walk, &$all, $required): void {
        if ($count === 0) {
            if ($left !== 0) return;
            $sum = 0;
            $gateSeen = false;
            foreach ($partial as $index => $gap) {
                $sum += $gap;
                if ($index < count($partial) - 1 && $sum === $required) $gateSeen = true;
            }
            if ($required === null || $gateSeen) $all[] = $partial;
            return;
        }
        for ($gap = 1; $gap <= $left - $count + 1; ++$gap) {
            $next = $partial;
            $next[] = $gap;
            $walk($left - $gap, $count - 1, $next);
        }
    };
    $walk($total, $slots, []);
    return $all;
}
function bruteMonths(int $total, int $slots): array {
    $all = [];
    $walk = static function(int $left, int $count, array $partial) use (&$walk, &$all): void {
        if ($count === 0) {
            if ($left === 0) $all[] = $partial;
            return;
        }
        for ($length = 4; $length <= min(123, $left); ++$length) {
            $next = $partial;
            $next[] = $length;
            $walk($left - $length, $count - 1, $next);
        }
    };
    $walk($total, $slots, []);
    return $all;
}
function bruteNames(int $pool, int $selected): array {
    $all = [];
    $walk = static function(array $available, int $count, array $partial) use (&$walk, &$all): void {
        if ($count === 0) {
            $all[] = $partial;
            return;
        }
        foreach ($available as $index => $name) {
            $next = $partial;
            $next[] = $name;
            $rest = $available;
            array_splice($rest, $index, 1);
            $walk($rest, $count - 1, $next);
        }
    };
    $walk(range(1, $pool), $selected, []);
    return $all;
}

for ($g = 2; $g <= 10; ++$g) {
    for ($k = 1; $k <= min(4, $g); ++$k) {
        foreach (array_merge([null], range(1, $g - 1)) as $gate) {
            $vectors = bruteCutlets($g, $k, $gate);
            $count = $subject->countCutletPartitions($g, $k, $gate);
            assert56($count->toString() === (string)count($vectors), "CUT_COUNT_$g:$k:$gate");
            foreach ($vectors as $index => $v) {
                $rank = BigInt::fromInt($index + 1);
                assert56($subject->unrankCutletPartitions($g, $k, $gate, $rank) === $v,
                    "CUT_UNRANK_$g:$k:$gate:$index");
                assert56($subject->rankCutletPartitions($g, $k, $gate, $v)->equals($rank),
                    "CUT_RANK_$g:$k:$gate:$index");
                ++$partitions;
            }
            reject56(static fn() => $subject->unrankCutletPartitions($g, $k, $gate,
                BigInt::zero()), 'CUT_ZERO');
            reject56(static fn() => $subject->unrankCutletPartitions($g, $k, $gate,
                $count->add(BigInt::one())), 'CUT_ABOVE');
        }
    }
}
for ($slots = 1; $slots <= 4; ++$slots) {
    for ($total = 4 * $slots - 1; $total <= 4 * $slots + 12; ++$total) {
        $vectors = bruteMonths($total, $slots);
        $count = $subject->countMonthLengths($total, $slots);
        assert56($count->toString() === (string)count($vectors), "MONTH_COUNT_$slots:$total");
        foreach ($vectors as $index => $vector) {
            $rank = BigInt::fromInt($index + 1);
            assert56($subject->unrankMonthLengths($total, $slots, $rank) === $vector,
                "MONTH_UNRANK_$slots:$total:$index");
            assert56($subject->rankMonthLengths($total, $slots, $vector)->equals($rank),
                "MONTH_RANK_$slots:$total:$index");
            ++$monthVectors;
        }
        reject56(static fn() => $subject->unrankMonthLengths($total, $slots,
            BigInt::zero()), 'MONTH_ZERO');
        reject56(static fn() => $subject->unrankMonthLengths($total, $slots,
            $count->add(BigInt::one())), 'MONTH_ABOVE');
    }
}
for ($pool = 2; $pool <= 7; ++$pool) {
    for ($selected = 1; $selected <= min(4, $pool); ++$selected) {
        $vectors = bruteNames($pool, $selected);
        $count = $subject->countOrderedNames($pool, $selected);
        assert56($count->toString() === (string)count($vectors), "NAME_COUNT_$pool:$selected");
        foreach ($vectors as $index => $vector) {
            $rank = BigInt::fromInt($index + 1);
            assert56($subject->unrankOrderedNames($pool, $selected, $rank) === $vector,
                "NAME_UNRANK_$pool:$selected:$index");
            assert56($subject->rankOrderedNames($pool, $selected, $vector)->equals($rank),
                "NAME_RANK_$pool:$selected:$index");
            ++$nameVectors;
        }
        reject56(static fn() => $subject->unrankOrderedNames($pool, $selected,
            BigInt::zero()), 'NAME_ZERO');
        reject56(static fn() => $subject->unrankOrderedNames($pool, $selected,
            $count->add(BigInt::one())), 'NAME_ABOVE');
    }
}
foreach ([
    [static fn() => $subject->countCutletPartitions(0, 2), 'CUT_GAP_ZERO'],
    [static fn() => $subject->countCutletPartitions(5, 6), 'CUT_TOO_MANY'],
    [static fn() => $subject->countCutletPartitions(5, 2, 5), 'CUT_BAD_GATE'],
    [static fn() => $subject->countCutletPartitions(5779, 2), 'CUT_TOO_LONG'],
    [static fn() => $subject->rankCutletPartitions(8, 3, 3, [3, 5, 0]), 'CUT_BAD_PART'],
    [static fn() => $subject->rankCutletPartitions(8, 3, 3, [2, 2, 4]), 'CUT_MISSING_GATE'],
    [static fn() => $subject->countMonthLengths(-1, 4), 'MONTH_NEGATIVE'],
    [static fn() => $subject->countMonthLengths(5779, 4), 'MONTH_TOO_LONG'],
    [static fn() => $subject->rankMonthLengths(15, 3, [4, 4, 8]), 'MONTH_BAD_SUM'],
    [static fn() => $subject->rankMonthLengths(15, 3, [3, 5, 7]), 'MONTH_BAD_LENGTH'],
    [static fn() => $subject->countOrderedNames(48, 3), 'NAME_POOL'],
    [static fn() => $subject->rankOrderedNames(4, 3, [1, 1, 2]), 'NAME_DUP'],
    [static fn() => $subject->rankOrderedNames(4, 3, [1, 2, 5]), 'NAME_RANGE'],
] as [$operation, $label]) reject56($operation, $label);

assert56($subject->countCutletPartitions(8, 3)->toString() === '21', 'EXAMPLE_CUT_TOTAL');
assert56($subject->countCutletPartitions(8, 3, 3)->toString() === '6', 'EXAMPLE_CUT_GATE');
assert56($subject->countMonthLengths(15, 3)->toString() === '10', 'EXAMPLE_MONTH');
assert56($subject->countMonthLengths(369, 3)->toString() === '1', 'EXAMPLE_MAX');
assert56($subject->countMonthLengths(370, 3)->isZero(), 'EXAMPLE_OVERFLOW');

// Very large exact ranks use the actual production BigInt, never native int or float.
foreach ([
    ['cutlets', $subject->countCutletPartitions(5778, 17),
        static fn(BigInt $r) => $subject->unrankCutletPartitions(5778, 17, null, $r),
        static fn(array $v) => $subject->rankCutletPartitions(5778, 17, null, $v)],
    ['months', $subject->countMonthLengths(400, 12),
        static fn(BigInt $r) => $subject->unrankMonthLengths(400, 12, $r),
        static fn(array $v) => $subject->rankMonthLengths(400, 12, $v)],
    ['names', $subject->countOrderedNames(47, 20),
        static fn(BigInt $r) => $subject->unrankOrderedNames(47, 20, $r),
        static fn(array $v) => $subject->rankOrderedNames(47, 20, $v)],
] as [$label, $total, $unrank, $rank]) {
    assert56(strlen($total->toString()) > 19, 'LARGE_BIGINT_' . $label);
    foreach ([BigInt::one(), $total] as $candidate) {
        $vector = $unrank($candidate);
        assert56($rank($vector)->equals($candidate), 'LARGE_ROUNDTRIP_' . $label);
        ++$large;
    }
}

assert56($partitions > 0 && $monthVectors > 0 && $nameVectors > 0,
    'NONEMPTY_EXHAUSTIVE_DOMAINS');
echo 'STAGE56_PRODUCTION_SLICES assertions=' . $assertions .
    ' cutlet_vectors=' . $partitions . ' month_vectors=' . $monthVectors .
    ' name_vectors=' . $nameVectors . ' rejected=' . $invalid .
    ' big_rank_roundtrips=' . $large . " status=PASS\n";
