<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

// DISCOVERY22: test-only investigation. These callbacks deliberately violate
// the caller's canonical-adjacent-provider obligation. No production change.
$checks44 = 0;
$candidates44 = 0;
$reproduced44 = 0;
$rejected44 = 0;
$other44 = 0;
function semak44(bool $ok, string $label): void {
    global $checks44;
    ++$checks44;
    if (!$ok) throw new RuntimeException('STAGE44_CONTROL_FAILED_' . $label);
}

/**
 * Construct a different physically valid adjacent-year endpoint from the same
 * independent test-only gate map. This is NOT a canonical year generator.
 */
function alternate44(array $truth, string $edge, callable $dayAtIndex): ?array {
    $idxField = $edge . 'GateIndex';
    $dayField = $edge . 'GateDay';
    foreach ([1, -1, 2, -2, 3, -3, 4, -4, 5, -5] as $offset) {
        $candidate = $truth;
        $candidate[$idxField] = $truth[$idxField] + $offset;
        $candidate[$dayField] = $dayAtIndex($candidate[$idxField]);
        $gapCount = $candidate['closeGateIndex'] - $candidate['openGateIndex'];
        $spanDays = $candidate['closeGateDay'] - $candidate['openGateDay'];
        if ($gapCount >= 6 && $spanDays >= 252 && $spanDays <= 5778) {
            return $candidate;
        }
    }
    return null;
}
$calculation = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$anchor = $oracle->year5000($calculation);
$next = $oracle->nextYear($calculation, $anchor);
$previous = $oracle->previousYear($calculation, $anchor);
$before = serialize([$anchor, $next, $previous]);
$trustedAnchor = static fn():array => $oracle->year5000($calculation);
$gateDay = static fn(int $index):int => $oracle->ensureGateIndex($index);
$trueNext = static fn(array $y):array => $oracle->nextYear($calculation, $y);
$truePrevious = static fn(array $y):array => $oracle->previousYear($calculation, $y);
$kernel = new BootstrapKernel();
$run = static fn(int $target, callable $n, callable $p):array =>
    $kernel->targetYearSequentialPatch21(
        $calculation, $target, $anchor, $n, $p, $gateDay, $trustedAnchor, 4
    );
semak44($anchor['number'] === 5000 && $next['number'] === 5001 &&
    $previous['number'] === 4999, 'YEAR_LABELS');
semak44($trustedAnchor() === $anchor, 'TRUSTED_ANCHOR_INDEPENDENT');
foreach ([$anchor, $next, $previous] as $year) {
    semak44($gateDay($year['openGateIndex']) === $year['openGateDay'] &&
        $gateDay($year['closeGateIndex']) === $year['closeGateDay'],
        'INDEPENDENT_GATE_MAP');
}
$forwardTarget = $next['openGateDay'] + 1;
$backwardTarget = $previous['closeGateDay'];
semak44($run($forwardTarget, $trueNext, $truePrevious)['targetYearCandidate'] === $next,
    'BASELINE_FORWARD');
semak44($run($backwardTarget, $trueNext, $truePrevious)['targetYearCandidate'] === $previous,
    'BASELINE_BACKWARD');

$cases = [
    ['forward', 'close', $forwardTarget, $next],
    ['backward', 'open', $backwardTarget, $previous],
];
foreach ($cases as [$name, $edge, $target, $truth]) {
    $alternative = alternate44($truth, $edge, $gateDay);
    semak44($alternative !== null, 'CANDIDATE_EXISTS_' . $name);
    semak44($alternative['number'] === $truth['number'] &&
        $alternative !== $truth, 'ALTERED_CANONICAL_ENDPOINT_' . $name);
    semak44($alternative['openGateIndex'] < $alternative['closeGateIndex'] &&
        $alternative['openGateDay'] < $target &&
        $target <= $alternative['closeGateDay'], 'PHYSICAL_TARGET_IN_BOTH_' . $name);
    semak44($gateDay($alternative['openGateIndex']) === $alternative['openGateDay'] &&
        $gateDay($alternative['closeGateIndex']) === $alternative['closeGateDay'],
        'ALTERNATIVE_GATE_MAP_' . $name);
    ++$candidates44;
    $nextProvider = $name === 'forward'
        ? static fn(array $old):array => $alternative : $trueNext;
    $previousProvider = $name === 'backward'
        ? static fn(array $old):array => $alternative : $truePrevious;
    try {
        $answer = $run($target, $nextProvider, $previousProvider);
        if ($answer['targetYearCandidate'] === $alternative &&
            $answer['targetYearCandidate'] !== $truth &&
            $answer['steps'] === 1 && !$answer['usedLegacyOutput']) {
            ++$reproduced44;
            echo 'CANDIDATE_REPRODUCED direction=' . $name .
                 ' canonical_gate=' . $truth[$edge.'GateIndex'] .
                 ' returned_gate=' . $alternative[$edge.'GateIndex'] .
                 ' target=' . $target . "\n";
        } else {
            ++$other44;
            echo 'CANDIDATE_NOT_REPRODUCED direction=' . $name . "\n";
        }
    } catch (InvalidArgumentException|RuntimeException $e) {
        ++$rejected44;
        echo 'CANDIDATE_REJECTED direction=' . $name .
             ' exception=' . get_class($e) . "\n";
    }
}
semak44(serialize([$anchor, $next, $previous]) === $before, 'INPUT_IMMUTABLE');
$source = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/AnchorIdentityPatch21.php');
semak44(!str_contains($source, 'NormativeOracle') &&
    !str_contains($source, 'NormativeMath'), 'PRODUCTION_NO_TEST_ORACLE');
semak44($candidates44 === 2 &&
    $reproduced44 + $rejected44 + $other44 === $candidates44,
    'COMPLETE_CLASSIFICATION');
echo 'STAGE44_DISCOVERY22_PROBE controls=' . $checks44 .
    ' candidates=' . $candidates44 .
    ' reproduced=' . $reproduced44 .
    ' rejected=' . $rejected44 .
    ' other=' . $other44 . "\n";
