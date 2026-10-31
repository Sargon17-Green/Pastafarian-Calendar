<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

// Stage47 is a boundary regression experiment, not a pre-declared bug.
$checks47 = 0;
$targets47 = 0;
$maxObservedHops47 = 0;
function semak47(bool $ok, string $label): void {
    global $checks47;
    ++$checks47;
    if (!$ok) throw new RuntimeException('STAGE47_CHECK_FAILED_' . $label);
}

$c = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$years = [5000 => $oracle->year5000($c)];
for ($number = 4999; $number >= 4997; --$number) {
    $years[$number] = $oracle->previousYear($c, $years[$number + 1]);
}
for ($number = 5001; $number <= 5003; ++$number) {
    $years[$number] = $oracle->nextYear($c, $years[$number - 1]);
}
$anchor = $years[5000];
$original = serialize($years);
$gate = static fn(int $index): int => $oracle->ensureGateIndex($index);
$trustedAnchor = static fn(): array => $oracle->year5000($c);
$next = static fn(array $year): array => $oracle->nextYear($c, $year);
$previous = static fn(array $year): array => $oracle->previousYear($c, $year);
$kernel = new BootstrapKernel();
$run = static fn(int $day, int $budget): array =>
    $kernel->targetYearSequentialPatch22(
        $c, $day, $anchor, $next, $previous, $gate,
        $trustedAnchor, $next, $previous, $budget
    );

foreach ($years as $number => $year) {
    semak47($year['number'] === $number, 'LABEL_' . $number);
    semak47($gate($year['openGateIndex']) === $year['openGateDay'] &&
        $gate($year['closeGateIndex']) === $year['closeGateDay'],
        'GATE_' . $number);
}
foreach (range(4998, 5002) as $number) {
    $year = $years[$number];
    semak47($years[$number - 1]['closeGateDay'] === $year['openGateDay'],
        'PREVIOUS_SEAM_' . $number);
    semak47($years[$number + 1]['openGateDay'] === $year['closeGateDay'],
        'NEXT_SEAM_' . $number);
    // (open, close] is the normative interval. Two endpoints are owned by
    // adjacent years, while the immediately interior days stay in this year.
    $cases = [
        ['at_open', $year['openGateDay'], $number - 1],
        ['first_inside', $year['openGateDay'] + 1, $number],
        ['at_close', $year['closeGateDay'], $number],
        ['after_close', $year['closeGateDay'] + 1, $number + 1],
    ];
    foreach ($cases as [$label, $day, $expectedNumber]) {
        $budget = abs($expectedNumber - 5000);
        $output = $run($day, $budget);
        ++$targets47;
        $maxObservedHops47 = max($maxObservedHops47, $output['steps']);
        $expectedDirection = $expectedNumber > 5000 ? 'forward' :
            ($expectedNumber < 5000 ? 'backward' : 'stay');
        semak47($output['targetYearCandidate'] === $years[$expectedNumber],
            'YEAR_' . $number . '_' . $label);
        semak47($output['steps'] === $budget &&
            $output['direction'] === $expectedDirection &&
            $output['usedLegacyOutput'] === false,
            'TRAVERSAL_' . $number . '_' . $label);
    }
}
$budgetRejected47 = 0;
try {
    $run($years[5002]['openGateDay'] + 1, 1);
} catch (RuntimeException $e) {
    if ($e->getMessage() === 'PATCH18_STEP_BUDGET_EXHAUSTED') {
        ++$budgetRejected47;
    } else {
        throw $e;
    }
}
semak47($budgetRejected47 === 1, 'EXACT_BUDGET_REJECTION');
semak47($targets47 === 20 && $maxObservedHops47 === 3,
    'MATRIX_COVERAGE');
semak47(serialize($years) === $original, 'INPUT_IMMUTABILITY');
$source = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/CanonicalAdjacentPatch22.php');
semak47(!str_contains($source, 'NormativeOracle') &&
    !str_contains($source, 'NormativeMath'), 'PRODUCTION_ORACLE_ABSENT');
echo 'STAGE47_SEAM_MATRIX checks=' . $checks47 .
    ' years=5 targets=' . $targets47 .
    ' max_hops=' . $maxObservedHops47 .
    ' budget_rejections=' . $budgetRejected47 . "\n";
