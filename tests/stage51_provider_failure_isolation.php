<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks51 = 0;
$faults51 = 0;
$recovered51 = 0;
$baseline51 = 0;
function semak51(bool $condition, string $label): void {
    global $checks51;
    ++$checks51;
    if (!$condition) {
        throw new RuntimeException('STAGE51_CHECK_FAILED_' . $label);
    }
}

$calculationDay = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$anchor = $oracle->year5000($calculationDay);
$neighbours = [
    'forward' => $oracle->nextYear($calculationDay, $anchor),
    'backward' => $oracle->previousYear($calculationDay, $anchor),
];
$original = serialize([$anchor, $neighbours]);
$kernel = new BootstrapKernel();

foreach ($neighbours as $direction => $year) {
    $target = $year['openGateDay'] + intdiv(
        $year['closeGateDay'] - $year['openGateDay'], 2
    );
    semak51($year['number'] === ($direction === 'forward' ? 5001 : 4999)
        && $target > $year['openGateDay'] && $target < $year['closeGateDay'],
        'TARGET_' . $direction);
    $mode = 'ok';
    $trace = [];
    $gateCalls = 0;

    $trusted = static function () use ($anchor, &$trace, &$mode): array {
        $trace[] = 'trusted:5000';
        if ($mode === 'trusted_throw') {
            throw new RuntimeException('S51_TRUSTED_THROW');
        }
        $returned = $anchor;
        if ($mode === 'trusted_mismatch') {
            $returned['number'] = 5001;
        }
        return $returned;
    };
    $gate = static function (int $index) use ($oracle, &$trace, &$mode, &$gateCalls): int {
        $trace[] = 'gate:' . $index;
        ++$gateCalls;
        if ($mode === 'gate_open_throw' && $gateCalls === 3) {
            throw new RuntimeException('S51_GATE_OPEN_THROW');
        }
        $day = $oracle->ensureGateIndex($index);
        if ($mode === 'gate_close_mismatch' && $gateCalls === 4) {
            return $day + 1;
        }
        return $day;
    };
    $proposedNext = static function (array $from) use ($oracle, $calculationDay, &$mode, &$trace) {
        $trace[] = 'proposed_forward:' . $from['number'];
        if ($mode === 'proposed_throw') {
            throw new RuntimeException('S51_PROPOSED_THROW');
        }
        if ($mode === 'proposed_type') {
            return 'bad-provider-result';
        }
        return $oracle->nextYear($calculationDay, $from);
    };
    $proposedPrevious = static function (array $from) use ($oracle, $calculationDay, &$mode, &$trace) {
        $trace[] = 'proposed_backward:' . $from['number'];
        if ($mode === 'proposed_throw') {
            throw new RuntimeException('S51_PROPOSED_THROW');
        }
        if ($mode === 'proposed_type') {
            return 'bad-provider-result';
        }
        return $oracle->previousYear($calculationDay, $from);
    };
    $canonicalNext = static function (array $from) use ($oracle, $calculationDay, &$mode, &$trace) {
        $trace[] = 'canonical_forward:' . $from['number'];
        if ($mode === 'canonical_throw') {
            throw new RuntimeException('S51_CANONICAL_THROW');
        }
        if ($mode === 'canonical_type') {
            return 'bad-canonical-result';
        }
        $returned = $oracle->nextYear($calculationDay, $from);
        if ($mode === 'canonical_mismatch') {
            $returned['number'] += 1;
        }
        return $returned;
    };
    $canonicalPrevious = static function (array $from) use ($oracle, $calculationDay, &$mode, &$trace) {
        $trace[] = 'canonical_backward:' . $from['number'];
        if ($mode === 'canonical_throw') {
            throw new RuntimeException('S51_CANONICAL_THROW');
        }
        if ($mode === 'canonical_type') {
            return 'bad-canonical-result';
        }
        $returned = $oracle->previousYear($calculationDay, $from);
        if ($mode === 'canonical_mismatch') {
            $returned['number'] -= 1;
        }
        return $returned;
    };
    $run = static function (int $budget) use (
        $kernel, $calculationDay, $target, $anchor,
        $proposedNext, $proposedPrevious, $gate, $trusted,
        $canonicalNext, $canonicalPrevious, &$trace, &$gateCalls
    ): array {
        $trace = [];
        $gateCalls = 0;
        return $kernel->targetYearSequentialPatch22(
            $calculationDay, $target, $anchor,
            $proposedNext, $proposedPrevious, $gate, $trusted,
            $canonicalNext, $canonicalPrevious, $budget
        );
    };

    $prefix = [
        'trusted:5000',
        'gate:' . $anchor['openGateIndex'],
        'gate:' . $anchor['closeGateIndex'],
    ];
    $proposed = 'proposed_' . $direction . ':5000';
    $canonical = 'canonical_' . $direction . ':5000';
    $destinationOpen = 'gate:' . $year['openGateIndex'];
    $destinationClose = 'gate:' . $year['closeGateIndex'];
    $expectedSuccess = [
        ...$prefix, $proposed, $canonical, $destinationOpen, $destinationClose
    ];
    $baseline = $run(1);
    ++$baseline51;
    semak51($baseline['targetYearCandidate'] === $year &&
        $baseline['steps'] === 1 &&
        $baseline['direction'] === $direction &&
        $baseline['usedLegacyOutput'] === false, 'BASELINE_' . $direction);
    semak51($trace === $expectedSuccess, 'BASELINE_TRACE_' . $direction);

    $cases = [
        ['trusted_throw', 'S51_TRUSTED_THROW', ['trusted:5000'], 1],
        ['trusted_mismatch', 'PATCH21_CANONICAL_YEAR_NUMBER', ['trusted:5000'], 1],
        ['budget_zero', 'PATCH18_STEP_BUDGET_EXHAUSTED', $prefix, 0],
        ['proposed_throw', 'S51_PROPOSED_THROW', [...$prefix, $proposed], 1],
        ['proposed_type', 'PATCH22_PROPOSED_TYPE_' . $direction, [...$prefix, $proposed], 1],
        ['canonical_throw', 'S51_CANONICAL_THROW', [...$prefix, $proposed, $canonical], 1],
        ['canonical_type', 'PATCH22_CANONICAL_TYPE_' . $direction, [...$prefix, $proposed, $canonical], 1],
        ['canonical_mismatch', 'PATCH22_CANONICAL_MISMATCH_' . $direction . '_number',
            [...$prefix, $proposed, $canonical], 1],
        ['gate_open_throw', 'S51_GATE_OPEN_THROW',
            [...$prefix, $proposed, $canonical, $destinationOpen], 1],
        ['gate_close_mismatch', 'PATCH20_GATE_DAY_MISMATCH_close',
            [...$prefix, $proposed, $canonical, $destinationOpen, $destinationClose], 1],
    ];
    foreach ($cases as [$case, $expectedError, $expectedPrefix, $budget]) {
        $mode = $case;
        $actualError = null;
        try {
            $run($budget);
        } catch (RuntimeException $e) {
            $actualError = $e->getMessage();
        }
        ++$faults51;
        semak51($actualError === $expectedError,
            'ERROR_' . $direction . '_' . $case . '_' . (string)$actualError);
        semak51($trace === $expectedPrefix,
            'PREFIX_' . $direction . '_' . $case);
        $mode = 'ok';
        $clean = $run(1);
        ++$recovered51;
        semak51($clean === $baseline,
            'RECOVERY_' . $direction . '_' . $case);
        semak51($trace === $expectedSuccess,
            'RECOVERY_TRACE_' . $direction . '_' . $case);
    }
}
semak51($faults51 === 20 && $recovered51 === 20 && $baseline51 === 2,
    'CARDINALITY');
semak51(serialize([$anchor, $neighbours]) === $original, 'INPUT_IMMUTABILITY');
$source = (string)file_get_contents(dirname(__DIR__) .
    '/src/Patches/CanonicalAdjacentPatch22.php');
semak51(!str_contains($source, 'NormativeOracle') &&
    !str_contains($source, 'NormativeMath'), 'ORACLE_ISOLATION');
echo 'STAGE51_FAILURE_ISOLATION checks=' . $checks51 .
    ' directions=2 faults=' . $faults51 .
    ' recovered=' . $recovered51 .
    ' baseline=' . $baseline51 . "\n";
