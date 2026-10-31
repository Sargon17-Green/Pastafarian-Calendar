<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

// Stage42 research ONLY. Do not treat an untrusted anchor as production input.
// The normative oracle is test-only; it is not an implementation dependency.
$controls42 = 0;
$reproduced42 = 0;
$rejected42 = 0;
function semak42(bool $ok, string $label): void {
    global $controls42;
    ++$controls42;
    if (!$ok) throw new RuntimeException('STAGE42_CONTROL_FAILED_' . $label);
}
$calculation = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$anchor = $oracle->year5000($calculation);
$next = $oracle->nextYear($calculation, $anchor);
$previous = $oracle->previousYear($calculation, $anchor);
$immutable = serialize([$anchor, $next, $previous]);
$gateDay = static fn(int $index): int => $oracle->ensureGateIndex($index);
$nextProvider = static fn(array $year): array => $oracle->nextYear($calculation, $year);
$previousProvider = static fn(array $year): array => $oracle->previousYear($calculation, $year);
$kernel = new BootstrapKernel();
semak42($anchor['number'] === 5000 && $next['number'] === 5001 &&
    $previous['number'] === 4999, 'REAL_YEAR_NUMBERS');
foreach ([$anchor, $next, $previous] as $record) {
    semak42($gateDay($record['openGateIndex']) === $record['openGateDay'] &&
        $gateDay($record['closeGateIndex']) === $record['closeGateDay'], 'REAL_GATE_MAPPING');
}
$forwardTarget = $next['openGateDay'] + 1;
$backwardTarget = $previous['closeGateDay'];
$run = static fn(int $targetDay, array $year5000): array =>
    $kernel->targetYearSequentialPatch20(
        $calculation, $targetDay, $year5000,
        $nextProvider, $previousProvider, $gateDay, 4
    );
$positiveNext = $run($forwardTarget, $anchor);
$positivePrevious = $run($backwardTarget, $anchor);
semak42($positiveNext['targetYearCandidate'] === $next &&
    $positiveNext['steps'] === 1, 'TRUE_FORWARD');
semak42($positivePrevious['targetYearCandidate'] === $previous &&
    $positivePrevious['steps'] === 1, 'TRUE_BACKWARD');

// Mutate ONLY the claimed year number of a physically real adjacent year.
// All physical gate indexes and days are still independently correct.
// These violate the explicit caller obligation to supply verified Year5000.
$forgedForward = $next;
$forgedForward['number'] = 5000;
$forgedBackward = $previous;
$forgedBackward['number'] = 5000;
$cases = [
    ['forward_anchor_5001_as_5000', $forwardTarget, $forgedForward, $next],
    ['backward_anchor_4999_as_5000', $backwardTarget, $forgedBackward, $previous],
];
foreach ($cases as [$label, $targetDay, $fake, $truth]) {
    semak42($fake['number'] === 5000 && $truth['number'] !== 5000, 'LABEL_' . $label);
    semak42($fake['openGateDay'] === $truth['openGateDay'] &&
        $fake['closeGateDay'] === $truth['closeGateDay'] &&
        $fake['openGateIndex'] === $truth['openGateIndex'] &&
        $fake['closeGateIndex'] === $truth['closeGateIndex'], 'GATES_' . $label);
    try {
        $result = $run($targetDay, $fake);
        if ($result['targetYearCandidate'] === $fake &&
            $result['targetYearCandidate']['number'] !== $truth['number'] &&
            $result['steps'] === 0 && !$result['usedLegacyOutput']) {
            ++$reproduced42;
            echo 'CANDIDATE_REPRODUCED witness=' . $label .
                ' canonical_year=' . $truth['number'] .
                ' returned_year=' . $result['targetYearCandidate']['number'] .
                ' target=' . $targetDay . "\n";
        } else {
            echo 'CANDIDATE_NOT_REPRODUCED witness=' . $label . "\n";
        }
    } catch (InvalidArgumentException|RuntimeException $error) {
        ++$rejected42;
        echo 'CANDIDATE_REJECTED witness=' . $label .
            ' error=' . get_class($error) . "\n";
    }
}
semak42(serialize([$anchor, $next, $previous]) === $immutable, 'SOURCE_IMMUTABLE');
$patchSource = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/GateDayCoherencePatch20.php');
semak42(!str_contains($patchSource, 'NormativeOracle') &&
    !str_contains($patchSource, 'NormativeMath'), 'PRODUCTION_NO_TEST_ORACLE');
echo 'STAGE42_DISCOVERY21_PROBE controls=' . $controls42 .
    ' candidates=2 reproduced=' . $reproduced42 .
    ' rejected=' . $rejected42 . "\n";
if ($reproduced42 !== 2 || $rejected42 !== 0) {
    fwrite(STDERR, "STAGE42_HYPOTHESIS_NOT_CONFIRMED\n");
    exit(1);
}
