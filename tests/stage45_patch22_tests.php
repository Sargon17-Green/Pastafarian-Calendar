<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks45 = 0;
$rejected45 = 0;
$archive45 = 0;
function semak45(bool $ok, string $name): void {
    global $checks45;
    ++$checks45;
    if (!$ok) throw new RuntimeException('STAGE45_FAILED_' . $name);
}
function tolak45(callable $work, string $name, string $required = ''): void {
    global $rejected45;
    try {
        $work();
    } catch (InvalidArgumentException|RuntimeException $e) {
        semak45($required === '' || str_starts_with($e->getMessage(), $required),
            'EXCEPTION_CODE_' . $name);
        ++$rejected45;
        return;
    }
    semak45(false, 'NOT_REJECTED_' . $name);
}
function alternatif45(array $truth, string $edge, callable $gate): array {
    $field = $edge . 'GateIndex';
    $day = $edge . 'GateDay';
    foreach ([1,-1,2,-2,3,-3,4,-4,5,-5] as $delta) {
        $result = $truth;
        $result[$field] = $truth[$field] + $delta;
        $result[$day] = $gate($result[$field]);
        $span = $result['closeGateDay'] - $result['openGateDay'];
        if ($result['closeGateIndex'] - $result['openGateIndex'] >= 6 &&
            $span >= 252 && $span <= 5778) return $result;
    }
    throw new RuntimeException('STAGE45_NO_ALTERNATE');
}

$c = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$anchor = $oracle->year5000($c);
$next = $oracle->nextYear($c, $anchor);
$previous = $oracle->previousYear($c, $anchor);
$original = serialize([$anchor, $next, $previous]);
$gate = static fn(int $index):int => $oracle->ensureGateIndex($index);
$trustedAnchor = static fn():array => $oracle->year5000($c);
$canonicalNext = static fn(array $y):array => $oracle->nextYear($c, $y);
$canonicalPrevious = static fn(array $y):array => $oracle->previousYear($c, $y);
$kernel = new BootstrapKernel();
$run21 = static fn(int $day, callable $n, callable $p):array =>
    $kernel->targetYearSequentialPatch21(
        $c,$day,$anchor,$n,$p,$gate,$trustedAnchor,4
    );
$run22 = static fn(int $day, callable $n, callable $p, callable $cn, callable $cp,
                     callable $a, callable $g, int $limit=4):array =>
    $kernel->targetYearSequentialPatch22(
        $c,$day,$anchor,$n,$p,$g,$a,$cn,$cp,$limit
    );
$good = static fn(int $day):array =>
    $run22($day,$canonicalNext,$canonicalPrevious,$canonicalNext,
        $canonicalPrevious,$trustedAnchor,$gate);
semak45($anchor['number'] === 5000 && $next['number'] === 5001 &&
    $previous['number'] === 4999, 'YEAR_LABELS');
semak45($trustedAnchor() === $anchor, 'TRUSTED_ANCHOR');
foreach ([$anchor,$next,$previous] as $year) {
    semak45($gate($year['openGateIndex']) === $year['openGateDay'] &&
        $gate($year['closeGateIndex']) === $year['closeGateDay'], 'TRUE_GATE_DAYS');
}
$real = [
    ['anchor_first', $anchor['openGateDay']+1, $anchor, 0],
    ['anchor_mid', $anchor['openGateDay']+365, $anchor, 0],
    ['anchor_last', $anchor['closeGateDay'], $anchor, 0],
    ['next_first', $anchor['closeGateDay']+1, $next, 1],
    ['next_last', $next['closeGateDay'], $next, 1],
    ['previous_last', $anchor['openGateDay'], $previous, 1],
    ['previous_first', $previous['openGateDay']+1, $previous, 1]
];
foreach ($real as [$name,$day,$truth,$steps]) {
    $old = $run21($day,$canonicalNext,$canonicalPrevious);
    $new = $good($day);
    semak45($new['targetYearCandidate'] === $truth,'REAL_' . $name);
    semak45($new['steps'] === $steps && !$new['usedLegacyOutput'], 'STEPS_' . $name);
    semak45($new === $old,'PATCH21_REGRESSION_' . $name);
}

// Archived Stage44 Native red witnesses, now rejected via the independent source.
$forwardAlt = alternatif45($next,'close',$gate);
$backwardAlt = alternatif45($previous,'open',$gate);
$forwardTarget = $next['openGateDay']+1;
$backwardTarget = $previous['closeGateDay'];
$badNext = static fn(array $old):array => $forwardAlt;
$badPrevious = static fn(array $old):array => $backwardAlt;
foreach ([
    ['forward',$forwardTarget,$badNext,$canonicalPrevious,$forwardAlt],
    ['backward',$backwardTarget,$canonicalNext,$badPrevious,$backwardAlt]
] as [$name,$day,$n,$p,$wrong]) {
    $old = $run21($day,$n,$p);
    semak45($old['targetYearCandidate'] === $wrong && $old['steps'] === 1 &&
        !$old['usedLegacyOutput'], 'ARCHIVED_STAGE44_' . $name);
    ++$archive45;
    tolak45(static fn()=> $run22($day,$n,$p,$canonicalNext,$canonicalPrevious,
        $trustedAnchor,$gate), 'BAD_BOUNDARY_' . $name, 'PATCH22_CANONICAL_MISMATCH_');
}
$wrongCanonicalForward = $next;
$wrongCanonicalForward['closeGateIndex'] += 1;
$wrongCanonicalBackward = $previous;
$wrongCanonicalBackward['openGateIndex'] -= 1;
tolak45(static fn()=> $run22($forwardTarget,$canonicalNext,$canonicalPrevious,
    static fn(array $y):array=>$wrongCanonicalForward,$canonicalPrevious,$trustedAnchor,$gate),
    'INCONSISTENT_TRUSTED_FORWARD','PATCH22_CANONICAL_MISMATCH_');
tolak45(static fn()=> $run22($backwardTarget,$canonicalNext,$canonicalPrevious,
    $canonicalNext,static fn(array $y):array=>$wrongCanonicalBackward,$trustedAnchor,$gate),
    'INCONSISTENT_TRUSTED_BACKWARD','PATCH22_CANONICAL_MISMATCH_');
$incomplete=$next;
unset($incomplete['closeGateDay']);
tolak45(static fn()=> $run22($forwardTarget,$canonicalNext,$canonicalPrevious,
    static fn(array $y):array=>$incomplete,$canonicalPrevious,$trustedAnchor,$gate),
    'MISSING_CANONICAL_FIELD','PATCH22_CANONICAL_FIELD_');
$invalidType=static fn(array $y):string => 'wrong';
tolak45(static fn()=> $run22($forwardTarget,$canonicalNext,$canonicalPrevious,
    $invalidType,$canonicalPrevious,$trustedAnchor,$gate),
    'BAD_CANONICAL_RESULT','PATCH22_CANONICAL_TYPE_');
$invalidNext = $next; $invalidNext['openGateDay']++;
tolak45(static fn()=> $run22($forwardTarget,static fn(array $y):array=>$invalidNext,
    $canonicalPrevious,$canonicalNext,$canonicalPrevious,$trustedAnchor,$gate),
    'BAD_PROPOSED_FIELD','PATCH22_CANONICAL_MISMATCH_');
$invalidNextType=static fn(array $y):string => 'wrong';
tolak45(static fn()=> $run22($forwardTarget,$invalidNextType,
    $canonicalPrevious,$canonicalNext,$canonicalPrevious,$trustedAnchor,$gate),
    'BAD_PROPOSED_RESULT','PATCH22_PROPOSED_TYPE_');
$forgedAnchor=$anchor;
$forgedAnchor['number']=4999;
tolak45(static fn()=> $kernel->targetYearSequentialPatch22($c,$forwardTarget,$forgedAnchor,
    $canonicalNext,$canonicalPrevious,$gate,$trustedAnchor,
    $canonicalNext,$canonicalPrevious,4),
    'FORGED_ANCHOR','PATCH21_ANCHOR_IDENTITY_MISMATCH_');
$wrongGate=static fn(int $index):int=>$oracle->ensureGateIndex($index)+1;
tolak45(static fn()=> $run22($forwardTarget,$canonicalNext,$canonicalPrevious,
    $canonicalNext,$canonicalPrevious,$trustedAnchor,$wrongGate),
    'BAD_GATE_MAP','PATCH20_GATE_DAY_MISMATCH_');
tolak45(static fn()=> $run22($forwardTarget,$canonicalNext,$canonicalPrevious,
    $canonicalNext,$canonicalPrevious,$trustedAnchor,$gate,0),
    'STEP_BUDGET','PATCH18_STEP_BUDGET_EXHAUSTED');
tolak45(static fn()=> $run22($forwardTarget,$canonicalNext,$canonicalPrevious,
    $canonicalNext,$canonicalPrevious,$trustedAnchor,$gate,-1),
    'INVALID_BUDGET','PATCH18_STEP_BUDGET');
semak45($archive45===2,'ARCHIVE_COUNT');
semak45(serialize([$anchor,$next,$previous])===$original,'INPUTS_UNCHANGED');
$source=(string)file_get_contents(dirname(__DIR__).'/src/Patches/CanonicalAdjacentPatch22.php');
$kernelSource=(string)file_get_contents(dirname(__DIR__).'/src/BootstrapKernel.php');
semak45(!str_contains($source,'NormativeOracle') && !str_contains($source,'NormativeMath') &&
    str_contains($source,'new AnchorIdentityPatch21()'),'SOURCE_INDEPENDENCE');
semak45(str_contains($kernelSource,"register('TARGET_YEAR_PATCH_22'") &&
    str_contains($kernelSource,"dispatch('TARGET_YEAR_PATCH_22', ".'$context)'),'REGISTERED_ROUTE');
echo 'LULUS Stage45 PATCH22 checks='.$checks45.' genuine_years=3 real_targets=7'.
    ' stage44_red='.$archive45.' invalid='.$rejected45.' stderr=0'."\n";
if ($archive45!==2 || $rejected45!==12) exit(1);
