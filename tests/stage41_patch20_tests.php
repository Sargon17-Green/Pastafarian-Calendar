<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks41 = 0;
$rejects41 = 0;
function semak41(bool $ok, string $tag): void {
    global $checks41;
    ++$checks41;
    if (!$ok) throw new RuntimeException('STAGE41_CONTROL_FAILED_' . $tag);
}
function tolak41(callable $action, string $tag): void {
    global $rejects41;
    try {
        $action();
    } catch (InvalidArgumentException|RuntimeException $e) {
        $rejects41++;
        semak41(true, 'REJECTED_' . $tag);
        return;
    }
    semak41(false, 'NOT_REJECTED_' . $tag);
}

$c = NormativeMath::FOUNDATION_DAY;
$o = new NormativeOracle();
$anchor = $o->year5000($c);
$nextYear = $o->nextYear($c, $anchor);
$prevYear = $o->previousYear($c, $anchor);
$providerNext = static fn(array $y): array => $o->nextYear($c, $y);
$providerPrevious = static fn(array $y): array => $o->previousYear($c, $y);
// Independent test oracle: gate day is computed by gate index, not read
// back from the potentially corrupted year record.
$gateDay = static fn(int $index): int => $o->ensureGateIndex($index);
$kernel = new BootstrapKernel();
$before = serialize([$anchor, $nextYear, $prevYear]);
semak41($anchor['number']===5000 && $nextYear['number']===5001 &&
    $prevYear['number']===4999, 'REAL_YEAR_IDENTITIES');
semak41($gateDay($anchor['openGateIndex'])===$anchor['openGateDay'] &&
    $gateDay($anchor['closeGateIndex'])===$anchor['closeGateDay'], 'ANCHOR_MAPPED');

$cases = [
    ['anchor_first', $anchor['openGateDay']+1, $anchor, 0],
    ['anchor_mid', $anchor['openGateDay']+365, $anchor, 0],
    ['anchor_last', $anchor['closeGateDay'], $anchor, 0],
    ['next_first', $anchor['closeGateDay']+1, $nextYear, 1],
    ['next_last', $nextYear['closeGateDay'], $nextYear, 1],
    ['previous_last', $anchor['openGateDay'], $prevYear, 1],
    ['previous_first', $prevYear['openGateDay']+1, $prevYear, 1],
];
foreach ($cases as [$label,$day,$expected,$steps]) {
    $r19=$kernel->targetYearSequentialPatch19($c,$day,$anchor,$providerNext,$providerPrevious,4);
    $r20=$kernel->targetYearSequentialPatch20($c,$day,$anchor,$providerNext,$providerPrevious,$gateDay,4);
    semak41($r20['targetYearCandidate']===$expected, 'YEAR_'.$label);
    semak41($r20['steps']===$steps && !$r20['usedLegacyOutput'], 'STEPS_'.$label);
    semak41($r20===$r19, 'PRESERVE_'.$label);
}

$nextFar=$nextYear; $nextFar['closeGateIndex']++;
$prevFar=$prevYear; $prevFar['openGateIndex']--;
$badNext=static fn(array $y): array => $nextFar;
$badPrevious=static fn(array $y): array => $prevFar;
$forwardDay=$anchor['closeGateDay']+1;
$backwardDay=$anchor['openGateDay'];
$rOldN=$kernel->targetYearSequentialPatch19($c,$forwardDay,$anchor,$badNext,$providerPrevious,4);
$rOldP=$kernel->targetYearSequentialPatch19($c,$backwardDay,$anchor,$providerNext,$badPrevious,4);
semak41($rOldN['targetYearCandidate']===$nextFar &&
    $rOldP['targetYearCandidate']===$prevFar, 'STAGE40_ARCHIVE_EXPECTED_RED');
semak41($nextFar['openGateIndex']===$anchor['closeGateIndex'] &&
    $prevFar['closeGateIndex']===$anchor['openGateIndex'], 'SEAM_UNTOUCHED');
semak41($nextFar['openGateDay']===$nextYear['openGateDay'] &&
    $nextFar['closeGateDay']===$nextYear['closeGateDay'] &&
    $prevFar['openGateDay']===$prevYear['openGateDay'] &&
    $prevFar['closeGateDay']===$prevYear['closeGateDay'], 'DAYS_UNTOUCHED');

$run=static fn(int $day,array $a,callable $n,callable $p,callable $g,int $budget=4): array =>
    $kernel->targetYearSequentialPatch20($c,$day,$a,$n,$p,$g,$budget);
tolak41(static fn()=> $run($forwardDay,$anchor,$badNext,$providerPrevious,$gateDay), 'NEXT_FAR_INDEX');
tolak41(static fn()=> $run($backwardDay,$anchor,$providerNext,$badPrevious,$gateDay), 'PREV_FAR_INDEX');
$badNextSeam=$nextYear; $badNextSeam['openGateIndex']++;
$badPrevSeam=$prevYear; $badPrevSeam['closeGateIndex']--;
tolak41(static fn()=> $run($forwardDay,$anchor,static fn(array $y):array=>$badNextSeam,$providerPrevious,$gateDay),'NEXT_SEAM');
tolak41(static fn()=> $run($backwardDay,$anchor,$providerNext,static fn(array $y):array=>$badPrevSeam,$gateDay),'PREV_SEAM');
$badAnchorClose=$anchor; $badAnchorClose['closeGateIndex']++;
tolak41(static fn()=> $run($forwardDay,$badAnchorClose,$providerNext,$providerPrevious,$gateDay),'ANCHOR_CLOSE');
$badAnchorOpen=$anchor; $badAnchorOpen['openGateIndex']--;
tolak41(static fn()=> $run($backwardDay,$badAnchorOpen,$providerNext,$providerPrevious,$gateDay),'ANCHOR_OPEN');
$wrongDay=static fn(int $index):int => $o->ensureGateIndex($index)+1;
tolak41(static fn()=> $run($forwardDay,$anchor,$providerNext,$providerPrevious,$wrongDay),'UNTRUSTED_MAPPING');
$wrongType=static fn(int $index):string => 'not a day';
tolak41(static fn()=> $run($forwardDay,$anchor,$providerNext,$providerPrevious,$wrongType),'MAPPING_TYPE');
$noAnchorOpen=$anchor; unset($noAnchorOpen['openGateIndex']);
tolak41(static fn()=> $run($forwardDay,$noAnchorOpen,$providerNext,$providerPrevious,$gateDay),'MISSING_ANCHOR_OPEN');
$noNextClose=$nextYear; unset($noNextClose['closeGateIndex']);
tolak41(static fn()=> $run($forwardDay,$anchor,static fn(array $y):array=>$noNextClose,$providerPrevious,$gateDay),'MISSING_NEXT_CLOSE');
$noPrevOpen=$prevYear; unset($noPrevOpen['openGateIndex']);
tolak41(static fn()=> $run($backwardDay,$anchor,$providerNext,static fn(array $y):array=>$noPrevOpen,$gateDay),'MISSING_PREV_OPEN');
semak41(serialize([$anchor,$nextYear,$prevYear])===$before,'INPUTS_IMMUTABLE');

$src=(string)file_get_contents(dirname(__DIR__).'/src/Patches/GateDayCoherencePatch20.php');
$kernelSrc=(string)file_get_contents(dirname(__DIR__).'/src/BootstrapKernel.php');
semak41(!str_contains($src,'NormativeOracle') &&
    !str_contains($src,'NormativeMath'),'PRODUCTION_NO_ORACLE');
semak41(str_contains($src,'new GateIndexContinuityPatch19()') &&
    str_contains($kernelSrc,"register('TARGET_YEAR_PATCH_20'") &&
    str_contains($kernelSrc,"dispatch('TARGET_YEAR_PATCH_20', ".'$context)'),'PRODUCTION_ROUTE');
echo 'LULUS Stage41 PATCH20 checks='.$checks41.
    ' genuine_years=3 real_targets=7 stage40_red=2 invalid='.$rejects41." stderr=0\n";
if($rejects41!==11) exit(1);
