<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks39 = 0;
$rejects39 = 0;
function periksa39(bool $ok, string $name): void {
    global $checks39;
    ++$checks39;
    if (!$ok) throw new RuntimeException('STAGE39_FAILED_' . $name);
}
function tolak39(callable $fn, string $name): void {
    global $rejects39;
    try {
        $fn();
    } catch (InvalidArgumentException|RuntimeException $ex) {
        ++$rejects39;
        periksa39(true, 'REJECT_' . $name);
        return;
    }
    periksa39(false, 'ACCEPTED_' . $name);
}
$c = NormativeMath::FOUNDATION_DAY;
$o = new NormativeOracle();
$a = $o->year5000($c);
$n = $o->nextYear($c, $a);
$p = $o->previousYear($c, $a);
$next = static fn(array $year): array => $o->nextYear($c, $year);
$prev = static fn(array $year): array => $o->previousYear($c, $year);
$k = new BootstrapKernel();
$original = serialize([$a, $n, $p]);
periksa39($a['number'] === 5000 && $n['number'] === 5001 && $p['number'] === 4999, 'YEAR_IDENTITIES');
periksa39($n['openGateIndex'] === $a['closeGateIndex'], 'NEXT_ORACLE_INDEX');
periksa39($p['closeGateIndex'] === $a['openGateIndex'], 'PREVIOUS_ORACLE_INDEX');

$cases = [
    ['anchor_first', $a['openGateDay'] + 1, $a, 0],
    ['anchor_last', $a['closeGateDay'], $a, 0],
    ['anchor_mid', $a['openGateDay'] + 365, $a, 0],
    ['next_first', $a['closeGateDay'] + 1, $n, 1],
    ['next_last', $n['closeGateDay'], $n, 1],
    ['previous_last', $a['openGateDay'], $p, 1],
    ['previous_first', $p['openGateDay'] + 1, $p, 1],
];
foreach ($cases as [$name, $target, $expected, $steps]) {
    $v18 = $k->targetYearSequentialPatch18($c, $target, $a, $next, $prev, 4);
    $v19 = $k->targetYearSequentialPatch19($c, $target, $a, $next, $prev, 4);
    periksa39($v19['targetYearCandidate'] === $expected, 'YEAR_' . $name);
    periksa39($v19['steps'] === $steps && $v19['direction'] === $v18['direction'], 'TRAVERSAL_' . $name);
    periksa39($v19['legacyReport'] === $v18['legacyReport'] && !$v19['usedLegacyOutput'], 'LEGACY_' . $name);
    periksa39($v19 === $v18, 'NO_UNRELATED_OUTPUT_CHANGE_' . $name);
}
periksa39(serialize([$a, $n, $p]) === $original, 'INPUTS_IMMUTABLE');

$badNext = $n;
$badNext['openGateIndex']++;
$badPrev = $p;
$badPrev['closeGateIndex']--;
periksa39($badNext['openGateDay'] === $a['closeGateDay'] &&
    $badPrev['closeGateDay'] === $a['openGateDay'], 'DAY_BOUNDARIES_UNCHANGED');
$targetNext = $a['closeGateDay'] + 1;
$targetPrev = $a['openGateDay'];
$badN = static fn(array $year): array => $badNext;
$badP = static fn(array $year): array => $badPrev;
$oldN = $k->targetYearSequentialPatch18($c, $targetNext, $a, $badN, $prev, 4);
$oldP = $k->targetYearSequentialPatch18($c, $targetPrev, $a, $next, $badP, 4);
periksa39($oldN['targetYearCandidate'] === $badNext &&
    $oldP['targetYearCandidate'] === $badPrev, 'ARCHIVED_STAGE38_WITNESSES');
tolak39(static fn() => $k->targetYearSequentialPatch19($c, $targetNext, $a, $badN, $prev, 4),
    'NEXT_INDEX_CORRUPTION');
tolak39(static fn() => $k->targetYearSequentialPatch19($c, $targetPrev, $a, $next, $badP, 4),
    'PREVIOUS_INDEX_CORRUPTION');

$missingAnchor = $a;
unset($missingAnchor['openGateIndex']);
tolak39(static fn() => $k->targetYearSequentialPatch19($c, $targetNext, $missingAnchor, $next, $prev, 4),
    'MISSING_ANCHOR_INDEX');
$wrongAnchor = $a;
$wrongAnchor['closeGateIndex'] = '4';
tolak39(static fn() => $k->targetYearSequentialPatch19($c, $targetNext, $wrongAnchor, $next, $prev, 4),
    'STRING_ANCHOR_INDEX');
$missingNext = $n;
unset($missingNext['openGateIndex']);
tolak39(static fn() => $k->targetYearSequentialPatch19($c, $targetNext, $a, static fn(array $y): array => $missingNext, $prev, 4),
    'MISSING_NEXT_INDEX');
$missingPrev = $p;
unset($missingPrev['closeGateIndex']);
tolak39(static fn() => $k->targetYearSequentialPatch19($c, $targetPrev, $a, $next, static fn(array $y): array => $missingPrev, 4),
    'MISSING_PREVIOUS_INDEX');
tolak39(static fn() => $k->targetYearSequentialPatch19($c, $targetNext, $a, $next, $prev, 0),
    'ZERO_STEP_BUDGET');
tolak39(static fn() => $k->targetYearSequentialPatch19($c, $targetPrev, $a, $next, $prev, -1),
    'NEGATIVE_STEP_BUDGET');
$gap = $n;
$gap['openGateDay']++;
tolak39(static fn() => $k->targetYearSequentialPatch19($c, $targetNext, $a, static fn(array $y): array => $gap, $prev, 4),
    'DAY_GAP_PREDECESSOR');

$sourceRoot = dirname(__DIR__) . '/src';
$patch19 = (string)file_get_contents($sourceRoot . '/Patches/GateIndexContinuityPatch19.php');
$patch18 = (string)file_get_contents($sourceRoot . '/Patches/SequentialYearWalkPatch18.php');
$kernel = (string)file_get_contents($sourceRoot . '/BootstrapKernel.php');
periksa39(str_contains($patch19, "new SequentialYearWalkPatch18()") &&
    str_contains($kernel, "register('TARGET_YEAR_PATCH_19'") &&
    str_contains($kernel, "dispatch('TARGET_YEAR_PATCH_19', " . '$context)'), 'PRODUCTION_ROUTE');
periksa39(!str_contains($patch19, 'NormativeOracle') &&
    !str_contains($patch19, 'NormativeMath'), 'NO_PRODUCTION_ORACLE');
periksa39(str_contains($patch18, "PATCH18_NEXT_NOT_ADJACENT") &&
    str_contains($patch18, "PATCH18_PREVIOUS_NOT_ADJACENT"), 'PATCH18_PRESERVED');
echo 'LULUS Stage39 PATCH19 checks=' . $checks39
    . ' genuine_years=3 real_targets=7 stage38_red=2 invalid=' . $rejects39
    . " stderr=0\n";
if ($rejects39 !== 9) exit(1);
