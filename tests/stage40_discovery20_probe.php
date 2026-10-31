<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks40=0; $reproduced40=0; $rejected40=0;
function check40(bool $ok, string $tag): void {
    global $checks40;
    $checks40++;
    if (!$ok) throw new RuntimeException('STAGE40_CONTROL_FAILED_'.$tag);
}
$c=NormativeMath::FOUNDATION_DAY;
$oracle=new NormativeOracle();
$anchor=$oracle->year5000($c);
$next=$oracle->nextYear($c,$anchor);
$prev=$oracle->previousYear($c,$anchor);
$before=serialize([$anchor,$next,$prev]);
check40($anchor['number']===5000,'ANCHOR');
check40($next['number']===5001 && $prev['number']===4999,'YEARS');
check40($next['openGateIndex']===$anchor['closeGateIndex'],'NEXT_INDEX_SEAM');
check40($prev['closeGateIndex']===$anchor['openGateIndex'],'PREVIOUS_INDEX_SEAM');
check40($next['openGateDay']===$anchor['closeGateDay'],'NEXT_DAY_SEAM');
check40($prev['closeGateDay']===$anchor['openGateDay'],'PREVIOUS_DAY_SEAM');

$k=new BootstrapKernel();
$nt=$anchor['closeGateDay']+1;
$pt=$anchor['openGateDay'];
$goodN=static fn(array $year):array=>$next;
$goodP=static fn(array $year):array=>$prev;
$rN=$k->targetYearSequentialPatch19($c,$nt,$anchor,$goodN,$goodP,4);
$rP=$k->targetYearSequentialPatch19($c,$pt,$anchor,$goodN,$goodP,4);
check40($rN['targetYearCandidate']===$next,'TRUE_NEXT');
check40($rP['targetYearCandidate']===$prev,'TRUE_PREV');
check40($rN['steps']===1 && $rP['steps']===1,'ONE_STEP');
check40(!$rN['usedLegacyOutput'] && !$rP['usedLegacyOutput'],'NOT_LEGACY');

$badN=$next; $badN['closeGateIndex']++;
$badP=$prev; $badP['openGateIndex']--;
check40($badN['closeGateIndex']!==$next['closeGateIndex'],'NEXT_FAR_MUTATED');
check40($badP['openGateIndex']!==$prev['openGateIndex'],'PREV_FAR_MUTATED');
check40($badN['openGateIndex']===$anchor['closeGateIndex'] &&
    $badP['closeGateIndex']===$anchor['openGateIndex'],'SEAMS_UNCHANGED');
check40($badN['openGateDay']===$next['openGateDay'] &&
    $badN['closeGateDay']===$next['closeGateDay'] &&
    $badP['openGateDay']===$prev['openGateDay'] &&
    $badP['closeGateDay']===$prev['closeGateDay'],'DAYS_UNCHANGED');
check40($badN['number']===$next['number'] &&
    $badP['number']===$prev['number'],'NUMBERS_UNCHANGED');

$cases=[
 ['next_far',$nt,$badN,$next,'closeGateIndex',
    static fn(array $y):array=>$badN,$goodP],
 ['prev_far',$pt,$badP,$prev,'openGateIndex',
    $goodN,static fn(array $y):array=>$badP]
];
foreach($cases as [$label,$day,$corrupt,$true,$field,$np,$pp]) {
    try {
        $r=$k->targetYearSequentialPatch19($c,$day,$anchor,$np,$pp,4);
        check40($r['steps']===1 && !$r['usedLegacyOutput'],'ROUTE_'.$label);
        if($r['targetYearCandidate']===$corrupt &&
           $r['targetYearCandidate']!==$true && $corrupt[$field]!==$true[$field]) {
            $reproduced40++;
            echo 'CANDIDATE_REPRODUCED witness='.$label.' oracle_index='.
                $true[$field].' returned_index='.$corrupt[$field].' target='.$day."\n";
        } else {
            echo 'CANDIDATE_NOT_REPRODUCED witness='.$label."\n";
        }
    } catch(InvalidArgumentException|RuntimeException $e) {
        $rejected40++;
        echo 'CANDIDATE_REJECTED witness='.$label.' error='.get_class($e)."\n";
    }
}
check40(serialize([$anchor,$next,$prev])===$before,'INPUTS_UNCHANGED');
$src=(string)file_get_contents(dirname(__DIR__).'/src/Patches/GateIndexContinuityPatch19.php');
check40(!str_contains($src,'NormativeOracle'),'NO_PRODUCTION_ORACLE');
echo 'STAGE40_DISCOVERY20_PROBE controls='.$checks40.
    ' candidates=2 reproduced='.$reproduced40.' rejected='.$rejected40."\n";
if($reproduced40!==2 || $rejected40!==0) {
    fwrite(STDERR,"STAGE40_HYPOTHESIS_NOT_CONFIRMED\n"); exit(1);
}
exit(0);
