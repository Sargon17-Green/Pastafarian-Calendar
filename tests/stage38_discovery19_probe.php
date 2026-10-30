<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks = 0;
function periksa38(bool $ok, string $label): void {
    global $checks;
    ++$checks;
    if (!$ok) {
        throw new RuntimeException('STAGE38_CONTROL_FAILED_' . $label);
    }
}

$c = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$anchor = $oracle->year5000($c);
$next = $oracle->nextYear($c, $anchor);
$previous = $oracle->previousYear($c, $anchor);
periksa38($anchor['number'] === 5000, 'ANCHOR');
periksa38($next['number'] === 5001 && $previous['number'] === 4999, 'NUMBERS');
periksa38($next['openGateIndex'] === $anchor['closeGateIndex'], 'ORACLE_NEXT_INDEX');
periksa38($previous['closeGateIndex'] === $anchor['openGateIndex'], 'ORACLE_PREVIOUS_INDEX');
periksa38($next['openGateDay'] === $anchor['closeGateDay'], 'NEXT_DAY');
periksa38($previous['closeGateDay'] === $anchor['openGateDay'], 'PREVIOUS_DAY');

$kernel = new BootstrapKernel();
$targetForward = $anchor['closeGateDay'] + 1;
$targetBackward = $anchor['openGateDay'];
$forward = $kernel->targetYearSequentialPatch18(
    $c, $targetForward, $anchor, static fn(array $y): array => $next,
    static fn(array $y): array => $previous, 4
);
$backward = $kernel->targetYearSequentialPatch18(
    $c, $targetBackward, $anchor, static fn(array $y): array => $next,
    static fn(array $y): array => $previous, 4
);
periksa38($forward['targetYearCandidate'] === $next, 'TRUE_NEXT');
periksa38($backward['targetYearCandidate'] === $previous, 'TRUE_PREVIOUS');
periksa38($forward['steps'] === 1 && $backward['steps'] === 1, 'CONTROL_STEPS');
periksa38($forward['usedLegacyOutput'] === false, 'NO_LEGACY_DECISION');

$badNext = $next;
$badNext['openGateIndex'] = $next['openGateIndex'] + 1;
$badPrevious = $previous;
$badPrevious['closeGateIndex'] = $previous['closeGateIndex'] - 1;
periksa38($badNext['openGateIndex'] !== $anchor['closeGateIndex'], 'NEXT_CORRUPTED');
periksa38($badPrevious['closeGateIndex'] !== $anchor['openGateIndex'], 'PREVIOUS_CORRUPTED');
periksa38($badNext['openGateDay'] === $anchor['closeGateDay'], 'NEXT_DAYS_PRESERVED');
periksa38($badPrevious['closeGateDay'] === $anchor['openGateDay'], 'PREVIOUS_DAYS_PRESERVED');

$cases = [
    ['forward_index', $targetForward, $badNext, $next, 'openGateIndex',
        static fn(array $y): array => $badNext, static fn(array $y): array => $previous],
    ['backward_index', $targetBackward, $badPrevious, $previous, 'closeGateIndex',
        static fn(array $y): array => $next, static fn(array $y): array => $badPrevious],
];
$reproduced = 0;
$rejected = 0;
foreach ($cases as [$name, $target, $corrupt, $correct, $field, $nextProvider, $previousProvider]) {
    try {
        $result = $kernel->targetYearSequentialPatch18(
            $c, $target, $anchor, $nextProvider, $previousProvider, 4
        );
        periksa38(($result['legacyReport']['usedLegacyOutput'] ?? null) === true,
            'LEGACY_ARCHIVED_' . $name);
        periksa38(($result['usedLegacyOutput'] ?? null) === false, 'PATCH_ROUTE_' . $name);
        if ($result['targetYearCandidate'] === $corrupt &&
            $result['targetYearCandidate'] !== $correct) {
            ++$reproduced;
            echo 'CANDIDATE_REPRODUCED witness=' . $name
                . ' oracle_index=' . $correct[$field]
                . ' returned_index=' . $corrupt[$field]
                . ' target=' . $target . "\n";
        } else {
            echo 'CANDIDATE_NOT_REPRODUCED witness=' . $name . "\n";
        }
    } catch (InvalidArgumentException|RuntimeException $ex) {
        ++$rejected;
        echo 'CANDIDATE_REJECTED witness=' . $name
            . ' exception=' . get_class($ex) . "\n";
    }
}
echo 'STAGE38_DISCOVERY19_PROBE controls=' . $checks
    . ' candidates=2 reproduced=' . $reproduced
    . ' rejected=' . $rejected . "\n";
if ($reproduced !== 2 || $rejected !== 0) {
    fwrite(STDERR, "STAGE38_HYPOTHESIS_NOT_CONFIRMED\n");
    exit(1);
}
exit(0);
