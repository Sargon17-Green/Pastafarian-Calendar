<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks50 = 0;
$positive50 = 0;
$rejected50 = 0;
$maxHops50 = 0;
function semak50(bool $ok, string $label): void {
    global $checks50;
    ++$checks50;
    if (!$ok) {
        throw new RuntimeException('STAGE50_CHECK_FAILED_' . $label);
    }
}
function expectedTrace50(array $years, int $yearNumber, int $steps): array {
    $anchor = $years[5000];
    $out = [
        'trusted:5000',
        'gate:' . $anchor['openGateIndex'],
        'gate:' . $anchor['closeGateIndex'],
    ];
    $sign = $yearNumber > 5000 ? 1 : -1;
    $direction = $sign === 1 ? 'forward' : 'backward';
    for ($i = 0; $i < $steps; ++$i) {
        $from = 5000 + $i * $sign;
        $to = $years[$from + $sign];
        $out[] = 'proposed_' . $direction . ':' . $from;
        $out[] = 'canonical_' . $direction . ':' . $from;
        $out[] = 'gate:' . $to['openGateIndex'];
        $out[] = 'gate:' . $to['closeGateIndex'];
    }
    return $out;
}
$c = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$years = [5000 => $oracle->year5000($c)];
for ($n = 4999; $n >= 4996; --$n) {
    $years[$n] = $oracle->previousYear($c, $years[$n + 1]);
}
for ($n = 5001; $n <= 5004; ++$n) {
    $years[$n] = $oracle->nextYear($c, $years[$n - 1]);
}
$original = serialize($years);
$anchor = $years[5000];
$trace = [];
$trusted = static function () use ($oracle, $c, &$trace): array {
    $trace[] = 'trusted:5000';
    return $oracle->year5000($c);
};
$gate = static function (int $i) use ($oracle, &$trace): int {
    $trace[] = 'gate:' . $i;
    return $oracle->ensureGateIndex($i);
};
$proposedNext = static function (array $from) use ($oracle, $c, &$trace): array {
    $trace[] = 'proposed_forward:' . $from['number'];
    return $oracle->nextYear($c, $from);
};
$proposedPrevious = static function (array $from) use ($oracle, $c, &$trace): array {
    $trace[] = 'proposed_backward:' . $from['number'];
    return $oracle->previousYear($c, $from);
};
$canonicalNext = static function (array $from) use ($oracle, $c, &$trace): array {
    $trace[] = 'canonical_forward:' . $from['number'];
    return $oracle->nextYear($c, $from);
};
$canonicalPrevious = static function (array $from) use ($oracle, $c, &$trace): array {
    $trace[] = 'canonical_backward:' . $from['number'];
    return $oracle->previousYear($c, $from);
};
$kernel = new BootstrapKernel();
$run = static function (int $target, int $budget) use (
    $kernel, $c, $anchor, $proposedNext, $proposedPrevious,
    $gate, $trusted, $canonicalNext, $canonicalPrevious, &$trace
): array {
    $trace = [];
    return $kernel->targetYearSequentialPatch22(
        $c, $target, $anchor, $proposedNext, $proposedPrevious,
        $gate, $trusted, $canonicalNext, $canonicalPrevious, $budget
    );
};

$days = [];
foreach (range(4996, 5004) as $n) {
    $year = $years[$n];
    $span = $year['closeGateDay'] - $year['openGateDay'];
    $day = $year['openGateDay'] + intdiv($span, 2);
    $hops = abs($n - 5000);
    $maxHops50 = max($maxHops50, $hops);
    semak50($year['number'] === $n && $span >= 252 && $span <= 5778,
        'YEAR_' . $n);
    semak50($day > $year['openGateDay'] && $day < $year['closeGateDay'],
        'STRICT_INTERIOR_' . $n);
    semak50($gate($year['openGateIndex']) === $year['openGateDay'] &&
        $gate($year['closeGateIndex']) === $year['closeGateDay'],
        'ORACLE_GATES_' . $n);
    $days[] = $day;
    $result = $run($day, $hops);
    ++$positive50;
    $wantedDirection = $n > 5000 ? 'forward' :
        ($n < 5000 ? 'backward' : 'stay');
    semak50($result['targetYearCandidate'] === $year &&
        $result['steps'] === $hops &&
        $result['direction'] === $wantedDirection &&
        $result['usedLegacyOutput'] === false,
        'ORACLE_' . $n);
    $expected = expectedTrace50($years, $n, $hops);
    semak50($trace === $expected, 'SUCCESS_TRACE_' . $n);
    if ($hops === 0) {
        continue;
    }
    $caught = false;
    try {
        $run($day, $hops - 1);
    } catch (RuntimeException $e) {
        if ($e->getMessage() !== 'PATCH18_STEP_BUDGET_EXHAUSTED') {
            throw $e;
        }
        $caught = true;
    }
    ++$rejected50;
    semak50($caught, 'EXHAUSTED_' . $n);
    semak50($trace === expectedTrace50($years, $n, $hops - 1),
        'REJECTED_TRACE_' . $n);
    $recovered = $run($day, $hops);
    ++$positive50;
    semak50($recovered === $result && $trace === $expected,
        'RECOVERY_' . $n);
}
semak50(count(array_unique($days)) === 9, 'UNIQUE_TARGETS');
semak50($positive50 === 17 && $rejected50 === 8 &&
    $maxHops50 === 4, 'COUNTS');
semak50(serialize($years) === $original, 'ORACLE_IMMUTABLE');
$source = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/CanonicalAdjacentPatch22.php');
semak50(!str_contains($source, 'NormativeOracle') &&
    !str_contains($source, 'NormativeMath'), 'PRODUCTION_ORACLE_ABSENT');
echo 'STAGE50_CALLBACK_TRACE checks=' . $checks50 .
    ' years=9 targets=9 successful=' . $positive50 .
    ' rejected=' . $rejected50 . ' max_hops=' . $maxHops50 . "\n";
