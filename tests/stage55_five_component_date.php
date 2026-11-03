<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;
use Pastafari\Stage01\Patches\DateTuplePatch23;

$checks55 = 0;
$targets55 = 0;
$components55 = 0;
$invalid55 = 0;
$budgets55 = 0;
$recoveries55 = 0;

function semak55(bool $ok, string $name): void {
    global $checks55;
    ++$checks55;
    if (!$ok) {
        throw new RuntimeException('STAGE55_FAILED_' . $name);
    }
}
function tolak55(callable $operation, string $label, string $prefix): void {
    global $invalid55;
    $error = '';
    try {
        $operation();
    } catch (\InvalidArgumentException $e) {
        $error = $e->getMessage();
    }
    semak55(str_starts_with($error, $prefix), 'REJECT_' . $label . '_' . $error);
    ++$invalid55;
}

$day = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$anchor = $oracle->year5000($day);
$years = [
    4999 => $oracle->previousYear($day, $anchor),
    5000 => $anchor,
    5001 => $oracle->nextYear($day, $anchor),
];
$structures = [];
foreach ($years as $n => $year) {
    $structures[$n] = $oracle->buildYearStructure($day, $year);
}
$before = serialize([$years, $structures]);
$next = static fn(array $y): array => $oracle->nextYear($day, $y);
$previous = static fn(array $y): array => $oracle->previousYear($day, $y);
$gate = static fn(int $i): int => $oracle->ensureGateIndex($i);
$trusted = static fn(): array => $anchor;
$providers = 0;
$structureProvider = static function (array $year) use ($structures, &$providers): array {
    ++$providers;
    $number = $year['number'] ?? null;
    if (!is_int($number) || !isset($structures[$number])) {
        throw new RuntimeException('STAGE55_UNKNOWN_YEAR');
    }
    return $structures[$number];
};
$kernel = new BootstrapKernel();
$assembler = new DateTuplePatch23();
$run = static function(int $target, int $budget, callable $provider) use (
    $assembler, $kernel, $day, $anchor, $next, $previous,
    $gate, $trusted
): array {
    return $assembler->calendarDate(
        $kernel, $day, $target, $anchor, $next, $previous,
        $gate, $trusted, $next, $previous, $provider, $budget
    );
};

$baseline = [];
foreach ($years as $n => $year) {
    $open = $year['openGateDay'];
    $close = $year['closeGateDay'];
    $points = [$open + 1, $open + intdiv($close - $open, 2), $close];
    semak55(count(array_unique($points)) === 3, 'THREE_POINTS_' . $n);
    foreach ($points as $i => $target) {
        $expected = $oracle->calendarDate($day, $target);
        $hops = abs($n - 5000);
        $beforeCalls = $providers;
        $actual = $run($target, $hops, $structureProvider);
        ++$targets55;
        semak55($providers === $beforeCalls + 1, 'PROVIDER_CALL_' . $n . '_' . $i);
        semak55(array_is_list($actual) && count($actual) === 5,
            'TUPLE_SHAPE_' . $n . '_' . $i);
        foreach ($expected as $position => $component) {
            semak55($actual[$position] === $component,
                'COMPONENT_' . $n . '_' . $i . '_' . $position);
            ++$components55;
        }
        $baseline[$n . ':' . $i] = [$target, $actual];
    }
}

$bad = $structures[5000];
$bad['cutlets'][0]['firstDay'] += 1;
tolak55(static fn() => $run($anchor['openGateDay'] + 1, 0,
    static fn(array $y): array => $bad), 'CUTLET', 'PATCH23_CUTLET_PARTITION');
$bad = $structures[5000];
array_pop($bad['monthWeaving']);
tolak55(static fn() => $run($anchor['openGateDay'] + 1, 0,
    static fn(array $y): array => $bad), 'WEAVE_LENGTH', 'PATCH23_STRUCTURE_SHAPE');
$bad = $structures[5000];
$bad['monthWeaving'][0] = 0;
tolak55(static fn() => $run($anchor['openGateDay'] + 1, 0,
    static fn(array $y): array => $bad), 'WEAVE_ID', 'PATCH23_MONTH_WEAVING');
$bad = $structures[5000];
$bad['monthNameIndices'][0] = 48;
tolak55(static fn() => $run($anchor['openGateDay'] + 1, 0,
    static fn(array $y): array => $bad), 'MONTH_NAME', 'PATCH23_MONTH_METADATA');
$bad = $structures[5000];
$bad['monthLengths'][0] += 1;
tolak55(static fn() => $run($anchor['openGateDay'] + 1, 0,
    static fn(array $y): array => $bad), 'MONTH_LENGTH', 'PATCH23_MONTH_COUNTS');
tolak55(static fn() => $run($anchor['openGateDay'] + 1, 0,
    static fn(array $y): string => 'invalid'), 'TYPE', 'PATCH23_STRUCTURE_TYPE');

foreach ([4999, 5001] as $n) {
    $target = $years[$n]['closeGateDay'];
    $beforeCalls = $providers;
    $error = '';
    try {
        $run($target, 0, $structureProvider);
    } catch (\RuntimeException $e) {
        $error = $e->getMessage();
    }
    semak55($error === 'PATCH18_STEP_BUDGET_EXHAUSTED' &&
        $providers === $beforeCalls, 'BUDGET_' . $n);
    ++$budgets55;
}

[$target, $wanted] = $baseline['5001:1'];
$thrown = '';
try {
    $run($target, 1, static function (array $year): array {
        throw new RuntimeException('S55_PROVIDER_FAILURE');
    });
} catch (\RuntimeException $e) {
    $thrown = $e->getMessage();
}
semak55($thrown === 'S55_PROVIDER_FAILURE', 'PROVIDER_FAULT');
semak55($run($target, 1, $structureProvider) === $wanted, 'RECOVERY');
++$recoveries55;
semak55(serialize([$years, $structures]) === $before, 'INPUTS_IMMUTABLE');
$production = (string)file_get_contents(dirname(__DIR__) .
    '/src/Patches/DateTuplePatch23.php');
semak55(!str_contains($production, 'NormativeOracle') &&
    !str_contains($production, 'NormativeMath') &&
    !str_contains($production, 'tests/oracle'), 'ORACLE_NOT_IN_PRODUCTION');
semak55($targets55 === 9 && $components55 === 45 &&
    $invalid55 === 6 && $budgets55 === 2 && $recoveries55 === 1, 'COUNTS');
echo 'STAGE55_FIVE_COMPONENTS checks=' . $checks55 .
    ' targets=' . $targets55 . ' components=' . $components55 .
    ' invalid=' . $invalid55 . ' budgets=' . $budgets55 .
    ' recoveries=' . $recoveries55 . "\n";
