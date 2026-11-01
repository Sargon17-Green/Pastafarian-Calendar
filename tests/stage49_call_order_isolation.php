<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks49 = 0;
$positive49 = 0;
$rejected49 = 0;
function semak49(bool $ok, string $name): void {
    global $checks49;
    ++$checks49;
    if (!$ok) {
        throw new RuntimeException('STAGE49_CHECK_FAILED_' . $name);
    }
}
$c = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$years = [5000 => $oracle->year5000($c)];
for ($n = 4999; $n >= 4997; --$n) {
    $years[$n] = $oracle->previousYear($c, $years[$n + 1]);
}
for ($n = 5001; $n <= 5003; ++$n) {
    $years[$n] = $oracle->nextYear($c, $years[$n - 1]);
}
$original = serialize($years);
$anchor = $years[5000];
$gate = static fn(int $i): int => $oracle->ensureGateIndex($i);
$trusted = static fn(): array => $oracle->year5000($c);
$next = static fn(array $y): array => $oracle->nextYear($c, $y);
$prev = static fn(array $y): array => $oracle->previousYear($c, $y);
$kernel = new BootstrapKernel();
$run = static fn(int $day, int $budget): array =>
    $kernel->targetYearSequentialPatch22(
        $c, $day, $anchor, $next, $prev, $gate,
        $trusted, $next, $prev, $budget
    );
$specs = [];
foreach (range(4997, 5003) as $yearNumber) {
    $year = $years[$yearNumber];
    $span = $year['closeGateDay'] - $year['openGateDay'];
    semak49($year['number'] === $yearNumber && $span >= 252 && $span <= 5778,
        'YEAR_' . $yearNumber);
    semak49($gate($year['openGateIndex']) === $year['openGateDay'] &&
        $gate($year['closeGateIndex']) === $year['closeGateDay'],
        'GATES_' . $yearNumber);
    foreach ([1, 2, 3] as $p) {
        $day = $year['openGateDay'] + intdiv($p * $span, 4);
        semak49($year['openGateDay'] < $day && $day < $year['closeGateDay'],
            'INTERIOR_' . $yearNumber . '_' . $p);
        $specs[$yearNumber . ':' . $p] = [
            'day' => $day,
            'year' => $year,
            'hops' => abs($yearNumber - 5000),
            'direction' => $yearNumber > 5000 ? 'forward' :
                ($yearNumber < 5000 ? 'backward' : 'stay')
        ];
    }
}
$ordered = array_keys($specs);
$reversed = array_reverse($ordered);
$woven = [];
foreach ([5000, 4999, 5001, 4998, 5002, 4997, 5003] as $yearNumber) {
    foreach ([3, 1, 2] as $p) {
        $woven[] = $yearNumber . ':' . $p;
    }
}
semak49(count($ordered) === 21 && count(array_unique($woven)) === 21 &&
    count(array_unique(array_column($specs, 'day'))) === 21,
    'UNIQUE_TARGETS');
$baseline = [];
foreach ([$ordered, $reversed, $woven] as $orderIndex => $order) {
    foreach ($order as $key) {
        $spec = $specs[$key];
        if ($orderIndex === 2 && str_ends_with($key, ':3') && $spec['hops'] > 0) {
            $caught = false;
            try {
                $run($spec['day'], $spec['hops'] - 1);
            } catch (RuntimeException $e) {
                $caught = $e->getMessage() === 'PATCH18_STEP_BUDGET_EXHAUSTED';
                if (!$caught) {
                    throw $e;
                }
            }
            semak49($caught, 'SHORT_BUDGET_' . $key);
            ++$rejected49;
        }
        $result = $run($spec['day'], $spec['hops'] + 2);
        ++$positive49;
        semak49($result['targetYearCandidate'] === $spec['year'] &&
            $result['steps'] === $spec['hops'] &&
            $result['direction'] === $spec['direction'] &&
            $result['usedLegacyOutput'] === false,
            'ORACLE_' . $orderIndex . '_' . $key);
        if ($orderIndex === 0) {
            $baseline[$key] = $result;
        } else {
            semak49($result === $baseline[$key],
                'ORDER_INVARIANT_' . $orderIndex . '_' . $key);
        }
    }
}
semak49($positive49 === 63 && $rejected49 === 6 &&
    count($baseline) === 21, 'COUNTS');
semak49(serialize($years) === $original, 'ORACLE_IMMUTABILITY');
$src = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/CanonicalAdjacentPatch22.php');
semak49(!str_contains($src, 'NormativeOracle') &&
    !str_contains($src, 'NormativeMath'), 'PRODUCTION_ORACLE_ABSENT');
echo 'STAGE49_ORDER_ISOLATION checks=' . $checks49 .
    ' years=7 targets=21 orders=3 successful=' . $positive49 .
    ' short_rejections=' . $rejected49 . "\n";
