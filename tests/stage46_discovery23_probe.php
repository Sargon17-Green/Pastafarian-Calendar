<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

// DISCOVERY23 is observational: no expected-red result is assumed.
// The noncanonical callbacks are test-only and violate the caller trust contract.
$checks46 = 0;
$reproduced46 = 0;
$rejected46 = 0;
$other46 = 0;
function semak46(bool $ok, string $label): void {
    global $checks46;
    ++$checks46;
    if (!$ok) throw new RuntimeException('STAGE46_CONTROL_FAILED_' . $label);
}
function alteredBoundary46(array $year, string $edge, callable $gate): array {
    $idx = $edge . 'GateIndex';
    $day = $edge . 'GateDay';
    foreach ([1, -1, 2, -2, 3, -3, 4, -4, 5, -5] as $delta) {
        $candidate = $year;
        $candidate[$idx] += $delta;
        $candidate[$day] = $gate($candidate[$idx]);
        $span = $candidate['closeGateDay'] - $candidate['openGateDay'];
        $gates = $candidate['closeGateIndex'] - $candidate['openGateIndex'];
        if ($gates >= 6 && $span >= 252 && $span <= 5778) return $candidate;
    }
    throw new RuntimeException('STAGE46_NO_PHYSICAL_ALTERNATE_' . $edge);
}

$c = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$anchor = $oracle->year5000($c);
$f1 = $oracle->nextYear($c, $anchor);
$f2 = $oracle->nextYear($c, $f1);
$b1 = $oracle->previousYear($c, $anchor);
$b2 = $oracle->previousYear($c, $b1);
$original = serialize([$anchor, $f1, $f2, $b1, $b2]);
$gate = static fn(int $index):int => $oracle->ensureGateIndex($index);
$trustedAnchor = static fn():array => $oracle->year5000($c);
$trueNext = static fn(array $y):array => $oracle->nextYear($c, $y);
$truePrevious = static fn(array $y):array => $oracle->previousYear($c, $y);
$kernel = new BootstrapKernel();
$run = static fn(int $day, callable $n, callable $p,
                  callable $cn, callable $cp):array =>
    $kernel->targetYearSequentialPatch22(
        $c, $day, $anchor, $n, $p, $gate, $trustedAnchor, $cn, $cp, 4
    );
$forwardTarget = $f2['openGateDay'] + 1;
$backwardTarget = $b2['closeGateDay'];
semak46([$b2['number'],$b1['number'],$anchor['number'],$f1['number'],$f2['number']]
    === [4998,4999,5000,5001,5002], 'YEAR_LABELS');
foreach ([$b2,$b1,$anchor,$f1,$f2] as $year) {
    semak46($gate($year['openGateIndex']) === $year['openGateDay'] &&
        $gate($year['closeGateIndex']) === $year['closeGateDay'], 'GATE_DAYS');
}
$canonicalForward = $run($forwardTarget, $trueNext, $truePrevious, $trueNext, $truePrevious);
$canonicalBackward = $run($backwardTarget, $trueNext, $truePrevious, $trueNext, $truePrevious);
semak46($canonicalForward['targetYearCandidate'] === $f2 &&
    $canonicalForward['steps'] === 2 && $canonicalForward['direction'] === 'forward' &&
    $canonicalForward['usedLegacyOutput'] === false, 'TWO_HOPS_FORWARD');
semak46($canonicalBackward['targetYearCandidate'] === $b2 &&
    $canonicalBackward['steps'] === 2 && $canonicalBackward['direction'] === 'backward' &&
    $canonicalBackward['usedLegacyOutput'] === false, 'TWO_HOPS_BACKWARD');

$wrongForward = alteredBoundary46($f2, 'close', $gate);
$wrongBackward = alteredBoundary46($b2, 'open', $gate);
semak46($wrongForward !== $f2 && $wrongBackward !== $b2,
    'NONCANONICAL_SECOND_HOPS');
// Do not alter the first hop. The same corrupt second-hop record is injected
// either by the proposed or by the separately trusted provider.
$badNext = static fn(array $from):array =>
    $from['number'] === 5001 ? $wrongForward : $trueNext($from);
$badPrevious = static fn(array $from):array =>
    $from['number'] === 4999 ? $wrongBackward : $truePrevious($from);
$cases = [
    ['forward_proposed', $forwardTarget, $badNext, $truePrevious,
        $trueNext, $truePrevious, $wrongForward],
    ['forward_trusted', $forwardTarget, $trueNext, $truePrevious,
        $badNext, $truePrevious, $wrongForward],
    ['backward_proposed', $backwardTarget, $trueNext, $badPrevious,
        $trueNext, $truePrevious, $wrongBackward],
    ['backward_trusted', $backwardTarget, $trueNext, $truePrevious,
        $trueNext, $badPrevious, $wrongBackward],
];
foreach ($cases as [$name, $day, $proposedN, $proposedP, $trustedN, $trustedP, $bad]) {
    try {
        $out = $run($day, $proposedN, $proposedP, $trustedN, $trustedP);
        if ($out['targetYearCandidate'] === $bad && $out['steps'] === 2 &&
            $out['usedLegacyOutput'] === false) {
            ++$reproduced46;
            echo 'CANDIDATE_REPRODUCED witness=' . $name . "\n";
        } else {
            ++$other46;
            echo 'CANDIDATE_OTHER witness=' . $name . "\n";
        }
    } catch (InvalidArgumentException|RuntimeException $e) {
        ++$rejected46;
        echo 'CANDIDATE_REJECTED witness=' . $name .
            ' exception=' . get_class($e) . ' code=' . $e->getMessage() . "\n";
    }
}
semak46($reproduced46 + $rejected46 + $other46 === count($cases),
    'CLASSIFICATION_EXHAUSTIVE');
semak46(serialize([$anchor, $f1, $f2, $b1, $b2]) === $original,
    'INPUTS_IMMUTABLE');
$source = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/CanonicalAdjacentPatch22.php');
semak46(!str_contains($source, 'NormativeOracle') &&
    !str_contains($source, 'NormativeMath'), 'PRODUCTION_ORACLE_ABSENT');
echo 'STAGE46_DISCOVERY23_PROBE controls=' . $checks46 .
    ' candidates=' . count($cases) . ' reproduced=' . $reproduced46 .
    ' rejected=' . $rejected46 . ' other=' . $other46 . "\n";
