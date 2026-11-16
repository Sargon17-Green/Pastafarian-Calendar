<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/src/BigInt.php';
require_once dirname(__DIR__) . '/src/Patches/MonthWeavingFrontier56.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\MonthWeavingFrontier56;

/** Independent brute-force generator, not production's insertion recurrence. */
function enumerate56(array $counts): array
{
    $m = count($counts);
    $remaining = $counts;
    $all = [];
    $visit = static function (array $prefix, int $opened) use (&$visit, &$remaining, &$all, $m): void {
        if (array_sum($remaining) === 0) {
            $all[] = $prefix;
            return;
        }
        for ($id = 1; $id <= min($m, $opened + 1); ++$id) {
            if ($remaining[$id - 1] === 0) continue;
            if ($remaining[$id - 1] === 1) {
                $blocked = false;
                for ($earlier = 0; $earlier < $id - 1; ++$earlier) {
                    if ($remaining[$earlier] !== 0) { $blocked = true; break; }
                }
                if ($blocked) continue;
            }
            --$remaining[$id - 1];
            $next = $prefix;
            $next[] = $id;
            $visit($next, max($opened, $id));
            ++$remaining[$id - 1];
        }
    };
    $visit([], 0);
    return $all;
}

$subject = new MonthWeavingFrontier56();
$vectors = 0;
$prefixChecks = 0;
$wordsChecked = 0;
for ($m = 1; $m <= 4; ++$m) {
    $configurations = [[]];
    for ($id = 0; $id < $m; ++$id) {
        $next = [];
        foreach ($configurations as $c) {
            foreach ([1, 2, 3] as $n) {
                $next[] = [...$c, $n];
            }
        }
        $configurations = $next;
    }
    foreach ($configurations as $counts) {
        $oracle = enumerate56($counts);
        if ($subject->count($counts)->toString() !== (string)count($oracle)) {
            throw new RuntimeException('STAGE56_B1_COUNT_' . implode('_', $counts));
        }
        ++$vectors;
        $wordsChecked += count($oracle);
        $prefixes = ['' => []];
        foreach ($oracle as $word) {
            for ($at = 0; $at <= count($word); ++$at) {
                $p = array_slice($word, 0, $at);
                $prefixes[implode(',', $p)] = $p;
            }
        }
        foreach ($prefixes as $prefix) {
            $rest = $counts;
            $opened = 0;
            foreach ($prefix as $id) {
                --$rest[$id - 1];
                $opened = max($opened, $id);
            }
            $expected = 0;
            foreach ($oracle as $word) {
                if (array_slice($word, 0, count($prefix)) === $prefix) ++$expected;
            }
            if ($subject->countSuffix($rest, $opened)->toString() !== (string)$expected) {
                throw new RuntimeException('STAGE56_B1_PREFIX_' . implode('_', $counts) . '_' . implode('_', $prefix));
            }
            ++$prefixChecks;
        }
    }
}
foreach ([
    static fn() => $subject->count([]),
    static fn() => $subject->count([0, 1]),
    static fn() => $subject->count([124]),
    static fn() => $subject->countSuffix([1, 0, 2], 1),
    static fn() => $subject->countSuffix([0, 1], 0),
    static fn() => $subject->countSuffix([2], -1),
] as $bad) {
    try { $bad(); } catch (InvalidArgumentException) { continue; }
    throw new RuntimeException('STAGE56_B1_EXPECTED_REJECT');
}
if ($vectors !== 120 || $prefixChecks !== 18302 || $wordsChecked !== 3940) {
    throw new RuntimeException('STAGE56_B1_COUNTER_INVARIANT');
}
echo "STAGE56_WEAVING_FRONTIER_B1 vectors=$vectors prefixes=$prefixChecks words=$wordsChecked rejected=6 status=PASS\n";
