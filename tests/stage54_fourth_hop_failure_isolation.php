<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks54 = 0;
$cases54 = 0;
$faults54 = 0;
$recovered54 = 0;
$baselines54 = 0;

function semak54(bool $ok, string $label): void {
    global $checks54;
    ++$checks54;
    if (!$ok) {
        throw new RuntimeException('STAGE54_CHECK_FAILED_' . $label);
    }
}

$day = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$years = [5000 => $oracle->year5000($day)];
for ($n = 4999; $n >= 4995; --$n) {
    $years[$n] = $oracle->previousYear($day, $years[$n + 1]);
}
for ($n = 5001; $n <= 5005; ++$n) {
    $years[$n] = $oracle->nextYear($day, $years[$n - 1]);
}
$original54 = serialize($years);
$anchor = $years[5000];
$kernel = new BootstrapKernel();

foreach (['forward' => 1, 'backward' => -1] as $direction => $sign) {
    $failFrom = 5000 + 3 * $sign; // The fourth traversal edge begins here.
    $failDestination = $years[5000 + 4 * $sign];
    $mode = 'ok';
    $trace = [];
    $gateCalls = 0;
    $sharedGateFromThirdHop = $sign === 1
        ? $years[5000 + 3 * $sign]['closeGateIndex']
        : $years[5000 + 3 * $sign]['openGateIndex'];
    $sharedGateAtFourthHop = $sign === 1
        ? $failDestination['openGateIndex']
        : $failDestination['closeGateIndex'];
    semak54($sharedGateFromThirdHop === $sharedGateAtFourthHop,
        'SHARED_SEAM_' . $direction);

    $trusted = static function () use ($anchor, &$trace): array {
        $trace[] = 'trusted:5000';
        return $anchor;
    };
    $gate = static function (int $index) use (
        $oracle, $failDestination, &$trace, &$mode, &$gateCalls
    ): int {
        $trace[] = 'gate:' . $index;
        ++$gateCalls;
        // Shared seam indices appear in two adjacent year validations.
        // Inject only at the fourth-hop invocation, never at earlier shared seams.
        if ($mode === 'open_throw' && $gateCalls === 9 &&
            $index === $failDestination['openGateIndex']) {
            throw new RuntimeException('S54_GATE_OPEN_THROW');
        }
        $value = $oracle->ensureGateIndex($index);
        if ($mode === 'close_mismatch' && $gateCalls === 10 &&
            $index === $failDestination['closeGateIndex']) {
            return $value + 1;
        }
        return $value;
    };
    $proposedNext = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'proposed_forward:' . $from['number'];
        if ($mode === 'proposed_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S54_PROPOSED_THROW');
        }
        return $oracle->nextYear($day, $from);
    };
    $canonicalNext = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'canonical_forward:' . $from['number'];
        if ($mode === 'canonical_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S54_CANONICAL_THROW');
        }
        return $oracle->nextYear($day, $from);
    };
    $proposedPrevious = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'proposed_backward:' . $from['number'];
        if ($mode === 'proposed_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S54_PROPOSED_THROW');
        }
        return $oracle->previousYear($day, $from);
    };
    $canonicalPrevious = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'canonical_backward:' . $from['number'];
        if ($mode === 'canonical_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S54_CANONICAL_THROW');
        }
        return $oracle->previousYear($day, $from);
    };

    foreach ([4, 5] as $depth) {
        ++$cases54;
        $wantedYear = $years[5000 + $depth * $sign];
        $target = $wantedYear['openGateDay'] +
            intdiv($wantedYear['closeGateDay'] -
                $wantedYear['openGateDay'], 2);
        semak54($target > $wantedYear['openGateDay'] &&
            $target < $wantedYear['closeGateDay'], 'MID_' . $direction . $depth);

        $run = static function () use (
            $kernel, $day, $target, $anchor, $depth,
            $proposedNext, $proposedPrevious,
            $gate, $trusted, $canonicalNext, $canonicalPrevious,
            &$trace, &$gateCalls
        ): array {
            $trace = [];
            $gateCalls = 0;
            return $kernel->targetYearSequentialPatch22(
                $day, $target, $anchor, $proposedNext, $proposedPrevious,
                $gate, $trusted, $canonicalNext, $canonicalPrevious, $depth
            );
        };

        // Expected sequence is constructed solely from immutable oracle years,
        // independently of the implementation's callback trace.
        $expected = [
            'trusted:5000',
            'gate:' . $anchor['openGateIndex'],
            'gate:' . $anchor['closeGateIndex']
        ];
        for ($step = 1; $step <= $depth; ++$step) {
            $fromNumber = 5000 + ($step - 1) * $sign;
            $to = $years[5000 + $step * $sign];
            $expected[] = 'proposed_' . $direction . ':' . $fromNumber;
            $expected[] = 'canonical_' . $direction . ':' . $fromNumber;
            $expected[] = 'gate:' . $to['openGateIndex'];
            $expected[] = 'gate:' . $to['closeGateIndex'];
        }
        $baseline = $run();
        ++$baselines54;
        semak54($baseline['targetYearCandidate'] === $wantedYear &&
            $baseline['steps'] === $depth &&
            $baseline['direction'] === $direction &&
            $baseline['usedLegacyOutput'] === false,
            'BASELINE_' . $direction . $depth);
        semak54($trace === $expected, 'TRACE_' . $direction . $depth);

        // The injected fault occurs in edge four. For depth five this also
        // proves the fifth edge was not invoked after an earlier failure.
        $beforeEdgeFour = 3 + 12;
        $faultCases = [
            ['proposed_throw', 'S54_PROPOSED_THROW', 1],
            ['canonical_throw', 'S54_CANONICAL_THROW', 2],
            ['open_throw', 'S54_GATE_OPEN_THROW', 3],
            ['close_mismatch', 'PATCH20_GATE_DAY_MISMATCH_close', 4],
        ];
        foreach ($faultCases as [$kind, $error, $callsInFailedEdge]) {
            $mode = $kind;
            $caught = null;
            try {
                $run();
            } catch (\Throwable $e) {
                $caught = $e->getMessage();
            }
            ++$faults54;
            semak54($caught === $error,
                'ERROR_' . $direction . $depth . '_' . $kind . '_' . (string)$caught);
            $prefix = array_slice($expected, 0,
                $beforeEdgeFour + $callsInFailedEdge);
            semak54($trace === $prefix,
                'SHORT_CIRCUIT_' . $direction . $depth . '_' . $kind);
            $mode = 'ok';
            $clean = $run();
            ++$recovered54;
            semak54($clean === $baseline,
                'RECOVER_VALUE_' . $direction . $depth . '_' . $kind);
            semak54($trace === $expected,
                'RECOVER_TRACE_' . $direction . $depth . '_' . $kind);
        }
    }
}
semak54($cases54 === 4 && $faults54 === 16 &&
    $recovered54 === 16 && $baselines54 === 4, 'CARDINALITY');
semak54(serialize($years) === $original54, 'ORACLE_INPUT_UNCHANGED');
$productionSource = (string)file_get_contents(dirname(__DIR__) .
    '/src/Patches/CanonicalAdjacentPatch22.php');
semak54(!str_contains($productionSource, 'NormativeOracle') &&
    !str_contains($productionSource, 'NormativeMath'), 'NO_TEST_ORACLE_IN_PRODUCTION');
echo 'STAGE54_FOURTH_HOP_ISOLATION checks=' . $checks54 .
    ' cases=' . $cases54 . ' faults=' . $faults54 .
    ' recovered=' . $recovered54 . ' baselines=' . $baselines54 . "\n";
