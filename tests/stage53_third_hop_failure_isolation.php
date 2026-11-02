<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks53 = 0;
$cases53 = 0;
$faults53 = 0;
$recovered53 = 0;
$baselines53 = 0;

function semak53(bool $ok, string $label): void {
    global $checks53;
    ++$checks53;
    if (!$ok) {
        throw new RuntimeException('STAGE53_CHECK_FAILED_' . $label);
    }
}

$day = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$years = [5000 => $oracle->year5000($day)];
for ($n = 4999; $n >= 4996; --$n) {
    $years[$n] = $oracle->previousYear($day, $years[$n + 1]);
}
for ($n = 5001; $n <= 5004; ++$n) {
    $years[$n] = $oracle->nextYear($day, $years[$n - 1]);
}
$original53 = serialize($years);
$anchor = $years[5000];
$kernel = new BootstrapKernel();

foreach (['forward' => 1, 'backward' => -1] as $direction => $sign) {
    $failFrom = 5000 + 2 * $sign; // The third traversal edge begins here.
    $failDestination = $years[5000 + 3 * $sign];
    $mode = 'ok';
    $trace = [];
    $gateCalls = 0;
    $sharedGateFromSecondHop = $sign === 1
        ? $years[5000 + 2 * $sign]['closeGateIndex']
        : $years[5000 + 2 * $sign]['openGateIndex'];
    $sharedGateAtThirdHop = $sign === 1
        ? $failDestination['openGateIndex']
        : $failDestination['closeGateIndex'];
    semak53($sharedGateFromSecondHop === $sharedGateAtThirdHop,
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
        // Inject only at the third-hop invocation, never at earlier shared seams.
        if ($mode === 'open_throw' && $gateCalls === 7 &&
            $index === $failDestination['openGateIndex']) {
            throw new RuntimeException('S53_GATE_OPEN_THROW');
        }
        $value = $oracle->ensureGateIndex($index);
        if ($mode === 'close_mismatch' && $gateCalls === 8 &&
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
            throw new RuntimeException('S53_PROPOSED_THROW');
        }
        return $oracle->nextYear($day, $from);
    };
    $canonicalNext = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'canonical_forward:' . $from['number'];
        if ($mode === 'canonical_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S53_CANONICAL_THROW');
        }
        return $oracle->nextYear($day, $from);
    };
    $proposedPrevious = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'proposed_backward:' . $from['number'];
        if ($mode === 'proposed_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S53_PROPOSED_THROW');
        }
        return $oracle->previousYear($day, $from);
    };
    $canonicalPrevious = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'canonical_backward:' . $from['number'];
        if ($mode === 'canonical_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S53_CANONICAL_THROW');
        }
        return $oracle->previousYear($day, $from);
    };

    foreach ([3, 4] as $depth) {
        ++$cases53;
        $wantedYear = $years[5000 + $depth * $sign];
        $target = $wantedYear['openGateDay'] +
            intdiv($wantedYear['closeGateDay'] -
                $wantedYear['openGateDay'], 2);
        semak53($target > $wantedYear['openGateDay'] &&
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
        ++$baselines53;
        semak53($baseline['targetYearCandidate'] === $wantedYear &&
            $baseline['steps'] === $depth &&
            $baseline['direction'] === $direction &&
            $baseline['usedLegacyOutput'] === false,
            'BASELINE_' . $direction . $depth);
        semak53($trace === $expected, 'TRACE_' . $direction . $depth);

        // The injected fault occurs in edge three. For depth four this also
        // proves the fourth edge was not invoked after an earlier failure.
        $beforeEdgeThree = 3 + 8;
        $faultCases = [
            ['proposed_throw', 'S53_PROPOSED_THROW', 1],
            ['canonical_throw', 'S53_CANONICAL_THROW', 2],
            ['open_throw', 'S53_GATE_OPEN_THROW', 3],
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
            ++$faults53;
            semak53($caught === $error,
                'ERROR_' . $direction . $depth . '_' . $kind . '_' . (string)$caught);
            $prefix = array_slice($expected, 0,
                $beforeEdgeThree + $callsInFailedEdge);
            semak53($trace === $prefix,
                'SHORT_CIRCUIT_' . $direction . $depth . '_' . $kind);
            $mode = 'ok';
            $clean = $run();
            ++$recovered53;
            semak53($clean === $baseline,
                'RECOVER_VALUE_' . $direction . $depth . '_' . $kind);
            semak53($trace === $expected,
                'RECOVER_TRACE_' . $direction . $depth . '_' . $kind);
        }
    }
}
semak53($cases53 === 4 && $faults53 === 16 &&
    $recovered53 === 16 && $baselines53 === 4, 'CARDINALITY');
semak53(serialize($years) === $original53, 'ORACLE_INPUT_UNCHANGED');
$productionSource = (string)file_get_contents(dirname(__DIR__) .
    '/src/Patches/CanonicalAdjacentPatch22.php');
semak53(!str_contains($productionSource, 'NormativeOracle') &&
    !str_contains($productionSource, 'NormativeMath'), 'NO_TEST_ORACLE_IN_PRODUCTION');
echo 'STAGE53_THIRD_HOP_ISOLATION checks=' . $checks53 .
    ' cases=' . $cases53 . ' faults=' . $faults53 .
    ' recovered=' . $recovered53 . ' baselines=' . $baselines53 . "\n";
