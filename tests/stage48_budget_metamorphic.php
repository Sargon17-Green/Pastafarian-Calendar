<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

// Stage48 verifies budget monotonicity on genuine interior year days.
// No defect is presumed; production PHP remains unchanged.
$checks48 = 0;
$targets48 = 0;
$positive48 = 0;
$shortRejected48 = 0;
$shortCases48 = 0;
$maxHops48 = 0;
function semak48(bool $ok, string $label): void {
    global $checks48;
    ++$checks48;
    if (!$ok) throw new RuntimeException('STAGE48_CHECK_FAILED_' . $label);
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
$anchor = $years[5000];
$unchanged = serialize($years);
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

foreach (range(4997, 5003) as $n) {
    $year = $years[$n];
    $span = $year['closeGateDay'] - $year['openGateDay'];
    semak48($year['number'] === $n && $span >= 252 && $span <= 5778,
        'YEAR_RECORD_' . $n);
    semak48($gate($year['openGateIndex']) === $year['openGateDay'] &&
        $gate($year['closeGateIndex']) === $year['closeGateDay'],
        'YEAR_GATE_' . $n);
    $days = [
        $year['openGateDay'] + intdiv($span, 4),
        $year['openGateDay'] + intdiv($span, 2),
        $year['openGateDay'] + intdiv(3 * $span, 4),
    ];
    $minimum = abs($n - 5000);
    $direction = $n > 5000 ? 'forward' : ($n < 5000 ? 'backward' : 'stay');
    foreach ($days as $position => $day) {
        ++$targets48;
        semak48($year['openGateDay'] < $day && $day < $year['closeGateDay'],
            'STRICT_INTERIOR_' . $n . '_' . $position);
        $exact = $run($day, $minimum);
        $relaxed = $run($day, $minimum + 3);
        $positive48 += 2;
        $maxHops48 = max($maxHops48, $exact['steps'], $relaxed['steps']);
        semak48($exact['targetYearCandidate'] === $year &&
            $exact['steps'] === $minimum &&
            $exact['direction'] === $direction &&
            $exact['usedLegacyOutput'] === false,
            'EXACT_' . $n . '_' . $position);
        semak48($relaxed['targetYearCandidate'] === $year &&
            $relaxed['steps'] === $minimum &&
            $relaxed['direction'] === $direction &&
            $relaxed['usedLegacyOutput'] === false,
            'RELAXED_' . $n . '_' . $position);
        semak48($exact === $relaxed,
            'MONOTONE_' . $n . '_' . $position);
    }
    if ($minimum > 0) {
        ++$shortCases48;
        try {
            $run($days[0], $minimum - 1);
        } catch (RuntimeException $e) {
            if ($e->getMessage() === 'PATCH18_STEP_BUDGET_EXHAUSTED') {
                ++$shortRejected48;
            } else {
                throw $e;
            }
        }
        semak48($shortRejected48 === $shortCases48,
            'SHORT_BUDGET_COUNT_' . $n);
    }
}
semak48($targets48 === 21 && $positive48 === 42 &&
    $shortRejected48 === 6 && $maxHops48 === 3, 'COVERAGE');
semak48(serialize($years) === $unchanged, 'INPUT_IMMUTABILITY');
$source = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/CanonicalAdjacentPatch22.php');
semak48(!str_contains($source, 'NormativeOracle') &&
    !str_contains($source, 'NormativeMath'), 'PRODUCTION_ORACLE_ABSENT');
echo 'STAGE48_BUDGET_METAMORPHIC checks=' . $checks48 .
    ' years=7 targets=' . $targets48 . ' positive=' . $positive48 .
    ' short_rejections=' . $shortRejected48 .
    ' max_hops=' . $maxHops48 . "\n";
