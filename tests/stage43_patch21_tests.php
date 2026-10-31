<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks43 = 0;
$rejects43 = 0;
$archive43 = 0;
function semak43(bool $ok, string $label): void {
    global $checks43;
    ++$checks43;
    if (!$ok) throw new RuntimeException('STAGE43_CONTROL_FAILED_' . $label);
}
function tolak43(callable $test, string $label): void {
    global $rejects43;
    try {
        $test();
    } catch (InvalidArgumentException|RuntimeException $error) {
        ++$rejects43;
        semak43(true, 'REJECTED_' . $label);
        return;
    }
    semak43(false, 'NOT_REJECTED_' . $label);
}

$c = NormativeMath::FOUNDATION_DAY;
$o = new NormativeOracle();
$anchor = $o->year5000($c);
$next = $o->nextYear($c, $anchor);
$previous = $o->previousYear($c, $anchor);
$before = serialize([$anchor, $next, $previous]);
$trusted = static fn():array => $o->year5000($c);
$gateDay = static fn(int $index):int => $o->ensureGateIndex($index);
$nextProvider = static fn(array $y):array => $o->nextYear($c, $y);
$previousProvider = static fn(array $y):array => $o->previousYear($c, $y);
$kernel = new BootstrapKernel();
$run20 = static fn(int $day, array $a):array =>
    $kernel->targetYearSequentialPatch20($c, $day, $a, $nextProvider, $previousProvider, $gateDay, 4);
$run21 = static fn(int $day, array $a, callable $trustedProvider, callable $gateProvider, int $limit=4):array =>
    $kernel->targetYearSequentialPatch21(
        $c, $day, $a, $nextProvider, $previousProvider, $gateProvider, $trustedProvider, $limit
    );

semak43($anchor['number'] === 5000 && $next['number'] === 5001 &&
    $previous['number'] === 4999, 'TRUE_YEAR_NUMBERS');
semak43($trusted() === $anchor, 'CANONICAL_INDEPENDENT_REBUILD');
foreach ([$anchor,$next,$previous] as $y) {
    semak43($gateDay($y['openGateIndex']) === $y['openGateDay'] &&
        $gateDay($y['closeGateIndex']) === $y['closeGateDay'], 'TRUE_GATE_MAPPING');
}
$cases = [
    ['anchor_first', $anchor['openGateDay']+1, $anchor, 0],
    ['anchor_mid', $anchor['openGateDay']+365, $anchor, 0],
    ['anchor_last', $anchor['closeGateDay'], $anchor, 0],
    ['next_first', $anchor['closeGateDay']+1, $next, 1],
    ['next_last', $next['closeGateDay'], $next, 1],
    ['previous_last', $anchor['openGateDay'], $previous, 1],
    ['previous_first', $previous['openGateDay']+1, $previous, 1],
];
foreach ($cases as [$label,$day,$expected,$steps]) {
    $r20 = $run20($day, $anchor);
    $r21 = $run21($day, $anchor, $trusted, $gateDay);
    semak43($r21['targetYearCandidate'] === $expected, 'REAL_YEAR_'.$label);
    semak43($r21['steps'] === $steps && !$r21['usedLegacyOutput'], 'REAL_STEPS_'.$label);
    semak43($r21 === $r20, 'PATCH20_PRESERVED_'.$label);
}

// Historical Stage42 evidence: PATCH20 trusted the caller's false year label.
$forgedForward = $next; $forgedForward['number'] = 5000;
$forgedBackward = $previous; $forgedBackward['number'] = 5000;
$forwardDay = $next['openGateDay']+1;
$backwardDay = $previous['closeGateDay'];
foreach ([['forward', $forwardDay, $forgedForward, 5001],
          ['backward', $backwardDay, $forgedBackward, 4999]] as [$label,$day,$fake,$real]) {
    $old = $run20($day, $fake);
    semak43($old['targetYearCandidate'] === $fake &&
        $old['targetYearCandidate']['number'] !== $real &&
        $old['steps'] === 0 && !$old['usedLegacyOutput'], 'ARCHIVE_STAGE42_'.$label);
    ++$archive43;
}
tolak43(static fn()=> $run21($forwardDay,$forgedForward,$trusted,$gateDay),'FORGED_YEAR5001_AS_5000');
tolak43(static fn()=> $run21($backwardDay,$forgedBackward,$trusted,$gateDay),'FORGED_YEAR4999_AS_5000');
$badOpen = $anchor; $badOpen['openGateIndex']++;
tolak43(static fn()=> $run21($anchor['openGateDay']+1,$badOpen,$trusted,$gateDay),'ANCHOR_OPEN_INDEX');
$badClose = $anchor; $badClose['closeGateDay']++;
tolak43(static fn()=> $run21($anchor['openGateDay']+1,$badClose,$trusted,$gateDay),'ANCHOR_CLOSE_DAY');
$badNumber = $anchor; $badNumber['number'] = 5001;
tolak43(static fn()=> $run21($anchor['openGateDay']+1,$badNumber,$trusted,$gateDay),'ANCHOR_NUMBER');
$missing = $anchor; unset($missing['closeGateIndex']);
tolak43(static fn()=> $run21($anchor['openGateDay']+1,$missing,$trusted,$gateDay),'ANCHOR_MISSING_FIELD');
$badCanonical = $anchor; $badCanonical['number'] = 4999;
tolak43(static fn()=> $run21($anchor['openGateDay']+1,$anchor,static fn():array=>$badCanonical,$gateDay),'CANONICAL_WRONG_NUMBER');
$missingCanonical = $anchor; unset($missingCanonical['openGateIndex']);
tolak43(static fn()=> $run21($anchor['openGateDay']+1,$anchor,static fn():array=>$missingCanonical,$gateDay),'CANONICAL_MISSING_FIELD');
$wrongCanonicalType = static fn():string => 'invalid';
tolak43(static fn()=> $run21($anchor['openGateDay']+1,$anchor,$wrongCanonicalType,$gateDay),'CANONICAL_TYPE');
$wrongGate = static fn(int $index):int => $o->ensureGateIndex($index)+1;
tolak43(static fn()=> $run21($anchor['openGateDay']+1,$anchor,$trusted,$wrongGate),'PATCH20_STILL_ENFORCED');

semak43($archive43 === 2, 'ARCHIVE_COUNT');
semak43(serialize([$anchor,$next,$previous]) === $before,'IMMUTABLE_YEAR_RECORDS');
$patchSrc = (string)file_get_contents(dirname(__DIR__).'/src/Patches/AnchorIdentityPatch21.php');
$kernelSrc = (string)file_get_contents(dirname(__DIR__).'/src/BootstrapKernel.php');
semak43(!str_contains($patchSrc,'NormativeOracle') &&
    !str_contains($patchSrc,'NormativeMath') &&
    str_contains($patchSrc,'new GateDayCoherencePatch20()'),'PRODUCTION_INDEPENDENCE_AND_DELEGATION');
semak43(str_contains($kernelSrc,"register('TARGET_YEAR_PATCH_21'") &&
    str_contains($kernelSrc,"dispatch('TARGET_YEAR_PATCH_21', ".'$context)'),'ROUTE_REGISTERED');
echo 'LULUS Stage43 PATCH21 checks='.$checks43.
    ' genuine_years=3 real_targets=7 stage42_red='.$archive43.
    ' invalid='.$rejects43." stderr=0\n";
if ($rejects43 !== 10) exit(1);
