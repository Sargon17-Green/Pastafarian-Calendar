<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks52 = 0;
$cases52 = 0;
$faults52 = 0;
$recovered52 = 0;
$baselines52 = 0;

function semak52(bool $ok, string $label): void {
    global $checks52;
    ++$checks52;
    if (!$ok) {
        throw new RuntimeException('STAGE52_CHECK_FAILED_' . $label);
    }
}

$day = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$years = [5000 => $oracle->year5000($day)];
for ($n = 4999; $n >= 4997; --$n) {
    $years[$n] = $oracle->previousYear($day, $years[$n + 1]);
}
for ($n = 5001; $n <= 5003; ++$n) {
    $years[$n] = $oracle->nextYear($day, $years[$n - 1]);
}
$original52 = serialize($years);
$anchor = $years[5000];
$kernel = new BootstrapKernel();

foreach (['forward' => 1, 'backward' => -1] as $direction => $sign) {
    $failFrom = 5000 + $sign;      // The second traversal edge begins here.
    $failDestination = $years[5000 + 2 * $sign];
    $mode = 'ok';
    $trace = [];

    $trusted = static function () use ($anchor, &$trace): array {
        $trace[] = 'trusted:5000';
        return $anchor;
    };
    $gate = static function (int $index) use (
        $oracle, $failDestination, &$trace, &$mode
    ): int {
        $trace[] = 'gate:' . $index;
        if ($mode === 'open_throw' &&
            $index === $failDestination['openGateIndex']) {
            throw new RuntimeException('S52_GATE_OPEN_THROW');
        }
        $value = $oracle->ensureGateIndex($index);
        if ($mode === 'close_mismatch' &&
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
            throw new RuntimeException('S52_PROPOSED_THROW');
        }
        return $oracle->nextYear($day, $from);
    };
    $canonicalNext = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'canonical_forward:' . $from['number'];
        if ($mode === 'canonical_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S52_CANONICAL_THROW');
        }
        return $oracle->nextYear($day, $from);
    };
    $proposedPrevious = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'proposed_backward:' . $from['number'];
        if ($mode === 'proposed_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S52_PROPOSED_THROW');
        }
        return $oracle->previousYear($day, $from);
    };
    $canonicalPrevious = static function (array $from) use (
        $oracle, $day, $failFrom, &$trace, &$mode
    ): array {
        $trace[] = 'canonical_backward:' . $from['number'];
        if ($mode === 'canonical_throw' && $from['number'] === $failFrom) {
            throw new RuntimeException('S52_CANONICAL_THROW');
        }
        return $oracle->previousYear($day, $from);
    };

    foreach ([2, 3] as $depth) {
        ++$cases52;
        $wantedYear = $years[5000 + $depth * $sign];
        $target = $wantedYear['openGateDay'] +
            intdiv($wantedYear['closeGateDay'] -
                $wantedYear['openGateDay'], 2);
        semak52($target > $wantedYear['openGateDay'] &&
            $target < $wantedYear['closeGateDay'], 'MID_' . $direction . $depth);

        $run = static function () use (
            $kernel, $day, $target, $anchor, $depth,
            $proposedNext, $proposedPrevious,
            $gate, $trusted, $canonicalNext, $canonicalPrevious, &$trace
        ): array {
            $trace = [];
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
        ++$baselines52;
        semak52($baseline['targetYearCandidate'] === $wantedYear &&
            $baseline['steps'] === $depth &&
            $baseline['direction'] === $direction &&
            $baseline['usedLegacyOutput'] === false,
            'BASELINE_' . $direction . $depth);
        semak52($trace === $expected, 'TRACE_' . $direction . $depth);

        // The injected fault occurs in edge two. For depth three this also
        // proves the third edge was not invoked after an earlier failure.
        $beforeEdgeTwo = 3 + 4;
        $faultCases = [
            ['proposed_throw', 'S52_PROPOSED_THROW', 1],
            ['canonical_throw', 'S52_CANONICAL_THROW', 2],
            ['open_throw', 'S52_GATE_OPEN_THROW', 3],
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
            ++$faults52;
            semak52($caught === $error,
                'ERROR_' . $direction . $depth . '_' . $kind . '_' . (string)$caught);
            $prefix = array_slice($expected, 0,
                $beforeEdgeTwo + $callsInFailedEdge);
            semak52($trace === $prefix,
                'SHORT_CIRCUIT_' . $direction . $depth . '_' . $kind);
            $mode = 'ok';
            $clean = $run();
            ++$recovered52;
            semak52($clean === $baseline,
                'RECOVER_VALUE_' . $direction . $depth . '_' . $kind);
            semak52($trace === $expected,
                'RECOVER_TRACE_' . $direction . $depth . '_' . $kind);
        }
    }
}
semak52($cases52 === 4 && $faults52 === 16 &&
    $recovered52 === 16 && $baselines52 === 4, 'CARDINALITY');
semak52(serialize($years) === $original52, 'ORACLE_INPUT_UNCHANGED');
$productionSource = (string)file_get_contents(dirname(__DIR__) .
    '/src/Patches/CanonicalAdjacentPatch22.php');
semak52(!str_contains($productionSource, 'NormativeOracle') &&
    !str_contains($productionSource, 'NormativeMath'), 'NO_TEST_ORACLE_IN_PRODUCTION');
echo 'STAGE52_LATE_HOP_ISOLATION checks=' . $checks52 .
    ' cases=' . $cases52 . ' faults=' . $faults52 .
    ' recovered=' . $recovered52 . ' baselines=' . $baselines52 . "\n";
