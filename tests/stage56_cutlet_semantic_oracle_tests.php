<?php
declare(strict_types=1);

require_once __DIR__ . '/stage56_cutlet_semantic_oracle.php';
require_once __DIR__ . '/bootstrap.php';
require_once dirname(__DIR__) . '/src/Patches/YearStructureSlices56.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\YearStructureSlices56;

$assertions = 0;
$vectors = 0;
$partitionsChecked = 0;
$rankChecks = 0;
$unrankChecks = 0;
$mutations = 0;

function cutletOracleAssert(bool $condition, string $label): void
{
    global $assertions;
    ++$assertions;
    if (!$condition) {
        throw new RuntimeException('STAGE56_CUTLET_ORACLE_TEST_' . $label);
    }
}

function cutletOracleReject(callable $operation, string $label): void
{
    global $assertions;
    ++$assertions;
    try {
        $operation();
    } catch (RuntimeException $error) {
        if (str_starts_with($error->getMessage(), 'STAGE56_CUTLET_ORACLE_')) {
            return;
        }
        throw $error;
    }
    throw new RuntimeException('STAGE56_CUTLET_ORACLE_TEST_EXPECTED_REJECTION_' . $label);
}

/** @param list<int> $partition @param list<int> $names */
function makeSyntheticCutletStructure(array $partition, array $names, array $year, array $gateDays): array
{
    $cutlets = [];
    $prefix = 0;
    foreach ($partition as $slot => $part) {
        $startIndex = $year['openGateIndex'] + $prefix;
        $prefix += $part;
        $endIndex = $year['openGateIndex'] + $prefix;
        $cutlets[] = [
            'canonicalIndex' => $names[$slot],
            'openGateIndex' => $startIndex,
            'closeGateIndex' => $endIndex,
            'firstDay' => $gateDays[$startIndex] + 1,
            'lastDay' => $gateDays[$endIndex],
        ];
    }
    return [
        'cutletCount' => count($partition),
        'cutletPartition' => $partition,
        'cutletNameIndices' => $names,
        'cutlets' => $cutlets,
    ];
}

$oracle = Stage56CutletSemanticOracle::class;
$slices = new YearStructureSlices56();

$unrestrictedExample = $oracle::enumeratePartitions(8, 3);
$forcedExample = $oracle::enumeratePartitions(8, 3, 3);
cutletOracleAssert(count($unrestrictedExample) === 21, 'EXAMPLE_UNRESTRICTED_COUNT');
cutletOracleAssert(count($forcedExample) === 6, 'EXAMPLE_FORCED_COUNT');
cutletOracleAssert($forcedExample === [
    [1, 2, 5], [2, 1, 5], [3, 1, 4], [3, 2, 3], [3, 3, 2], [3, 4, 1],
], 'EXAMPLE_FORCED_LEXICOGRAPHIC_ORDER');

// Independent bounded DFS is the oracle; production count/rank/unrank are only
// the subjects being compared. No production recurrence is used to enumerate.
for ($gaps = 2; $gaps <= 12; ++$gaps) {
    for ($parts = 1; $parts <= min(5, $gaps); ++$parts) {
        $requirements = [null];
        for ($cut = 1; $cut < $gaps; ++$cut) {
            $requirements[] = $cut;
        }
        foreach ($requirements as $requiredCut) {
            $enumerated = $oracle::enumeratePartitions($gaps, $parts, $requiredCut, 250000);
            $productionCount = $slices->countCutletPartitions($gaps, $parts, $requiredCut);
            cutletOracleAssert(
                $productionCount->toIntExact() === count($enumerated),
                'COUNT_' . $gaps . '_' . $parts . '_' . ($requiredCut ?? 'none')
            );
            ++$vectors;
            foreach ($enumerated as $index => $partition) {
                $rank = BigInt::fromInt($index + 1);
                cutletOracleAssert(
                    $slices->unrankCutletPartitions($gaps, $parts, $requiredCut, $rank) === $partition,
                    'UNRANK_' . $gaps . '_' . $parts . '_' . ($requiredCut ?? 'none') . '_' . $index
                );
                cutletOracleAssert(
                    $slices->rankCutletPartitions($gaps, $parts, $requiredCut, $partition)->equals($rank),
                    'RANK_' . $gaps . '_' . $parts . '_' . ($requiredCut ?? 'none') . '_' . $index
                );
                ++$rankChecks;
                ++$unrankChecks;
                ++$partitionsChecked;
            }
        }
    }
}

$year = [
    'number' => 5000,
    'openGateIndex' => -2,
    'closeGateIndex' => 6,
    'openGateDay' => 1000,
    'closeGateDay' => 1560,
];
$gateDays = [];
for ($index = -2; $index <= 6; ++$index) {
    $gateDays[$index] = 1000 + 70 * ($index + 2);
}
$partition = [1, 1, 1, 1, 1, 3];
$names = [4, 1, 9, 17, 6, 2];
$valid = makeSyntheticCutletStructure($partition, $names, $year, $gateDays);
$report = $oracle::validateStructure($valid, $year, $gateDays, 1140);
cutletOracleAssert($report['required_cut'] === 2, 'ACTUAL_GATE_FORCES_CUT');
cutletOracleAssert($report['gap_count'] === 8 && $report['year_days'] === 560, 'STRUCTURE_SUMMARY');

// No exact calculation-day gate means no forced partition prefix.
$withoutForcedCut = makeSyntheticCutletStructure([1, 2, 1, 1, 1, 2], $names, $year, $gateDays);
$report = $oracle::validateStructure($withoutForcedCut, $year, $gateDays, 1100);
cutletOracleAssert($report['required_cut'] === null, 'BETWEEN_GATES_NO_FORCED_CUT');
$report = $oracle::validateStructure($withoutForcedCut, $year, $gateDays, 1000);
cutletOracleAssert($report['required_cut'] === null, 'OPEN_ENDPOINT_NO_FORCED_CUT');
$report = $oracle::validateStructure($withoutForcedCut, $year, $gateDays, 1560);
cutletOracleAssert($report['required_cut'] === null, 'CLOSE_ENDPOINT_NO_FORCED_CUT');

// Fail-closed negative mutations: each changes one semantic invariant.
$bad = $valid;
$bad['cutletPartition'] = [1, 2, 1, 1, 1, 2];
cutletOracleReject(static fn() => $oracle::validateStructure($bad, $year, $gateDays, 1140), 'MISSING_FORCED_CUT');
++$mutations;

$bad = $valid;
$bad['cutletPartition'][2] = 0;
cutletOracleReject(static fn() => $oracle::validateStructure($bad, $year, $gateDays, 1140), 'NONPOSITIVE_PART');
++$mutations;

$bad = $valid;
$bad['cutletPartition'][5] = 2;
cutletOracleReject(static fn() => $oracle::validateStructure($bad, $year, $gateDays, 1140), 'WRONG_PARTITION_SUM');
++$mutations;

$bad = makeSyntheticCutletStructure($partition, [4, 4, 9, 17, 6, 2], $year, $gateDays);
cutletOracleReject(static fn() => $oracle::validateStructure($bad, $year, $gateDays, 1140), 'DUPLICATE_NAME');
++$mutations;

$bad = makeSyntheticCutletStructure($partition, [4, 1, 9, 18, 6, 2], $year, $gateDays);
cutletOracleReject(static fn() => $oracle::validateStructure($bad, $year, $gateDays, 1140), 'OUT_OF_RANGE_NAME');
++$mutations;

$bad = $valid;
$bad['cutlets'][2]['openGateIndex']++;
cutletOracleReject(static fn() => $oracle::validateStructure($bad, $year, $gateDays, 1140), 'WRONG_GATE_BOUNDARY');
++$mutations;

$bad = $valid;
$bad['cutlets'][1]['firstDay']++;
cutletOracleReject(static fn() => $oracle::validateStructure($bad, $year, $gateDays, 1140), 'DAY_GAP');
++$mutations;

$bad = $valid;
$bad['cutlets'][5]['lastDay']--;
cutletOracleReject(static fn() => $oracle::validateStructure($bad, $year, $gateDays, 1140), 'WRONG_FINAL_DAY');
++$mutations;

$bad = $valid;
array_pop($bad['cutlets']);
cutletOracleReject(static fn() => $oracle::validateStructure($bad, $year, $gateDays, 1140), 'MISSING_CUTLET');
++$mutations;

$badGates = $gateDays;
$badGates[0] = $badGates[-1] + 1000;
cutletOracleReject(static fn() => $oracle::validateStructure($valid, $year, $badGates, 1140), 'INVALID_GATE_DISTANCE');
++$mutations;

$badYear = $year;
$badYear['closeGateDay']++;
cutletOracleReject(static fn() => $oracle::validateStructure($valid, $badYear, $gateDays, 1140), 'WRONG_YEAR_ENDPOINT');
++$mutations;

if ($vectors < 300 || $partitionsChecked < 1000 || $mutations !== 11 ||
    $rankChecks !== $partitionsChecked || $unrankChecks !== $partitionsChecked) {
    throw new RuntimeException('STAGE56_CUTLET_ORACLE_TEST_EXPECTED_TOTALS');
}

echo "STAGE56_CUTLET_SEMANTIC_ORACLE vectors={$vectors} partitions={$partitionsChecked} " .
    "rank_checks={$rankChecks} unrank_checks={$unrankChecks} mutations={$mutations} " .
    "actual_structure=PASS status=PASS\n";
