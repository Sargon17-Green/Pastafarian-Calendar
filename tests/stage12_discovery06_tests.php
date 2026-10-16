<?php
declare(strict_types=1);
require_once __DIR__.'/bootstrap.php';
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyVisiblePrior;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
$kernel=new BootstrapKernel();
$legacy=new LegacyVisiblePrior();
$oracle=new NormativeSauce();
$stones=$oracle->buildStones();
$f=NormativeMath::FOUNDATION_DAY;
$dates=[['asas_sama',$f,$f],['asas_depan',$f,$f+3],['sifar_lintas',-10,30],['jauh_balik',100000000,-100000000]];
$missing=0;$found=0;$hiddenOK=0;$unexpected=0;
foreach($dates as $n=>[$label,$c,$day]){
  $oracleHidden=$oracle->buildHiddenDrops(NormativeMath::workCounts($c,$day),$stones);
  $hidden=$kernel->hiddenDrops($c,$day);
  for($k=1;$k<=7;$k++){
    if(!$hidden[$k]->equals($oracleHidden[$k])){$unexpected++;echo "RALAT_HIDDEN {$label} {$k}\n";}
    else $hiddenOK++;
  }
  $visible=[];
  for($i=1;$i<=46;$i++)$visible[$i]=BigInt::fromInt($i*1000+137*($n+1));
  $old=$visible;
  for($i=1;$i<=46;$i++)foreach([1,3,7] as $back){
    $slot=$i-$back;
    $got=$kernel->priorLegacy($visible,$i,$back);
    $again=$kernel->priorLegacy($visible,$i,$back);
    $direct=$legacy->legacyPrior($visible,$i,$back);
    if($slot>=1){
      if(!$got instanceof BigInt||!$got->equals($visible[$slot])||!$got->equals($direct)||!$got->equals($again)){
        echo "RALAT_VISIBLE {$label} {$i} {$back}\n";$unexpected++;
      }else $found++;
    }else{
      $k=1-$slot;
      if($got!==null||$again!==null||$direct!==null||!$hidden[$k] instanceof BigInt){
        echo "RALAT_MISSING {$label} {$i} {$back}\n";$unexpected++;
      }else{
        echo "GAGAL_DIJANGKA kes={$label} i={$i} back={$back} slot={$slot} hidden_k={$k}\n";
        $missing++;
      }
    }
  }
  if($old!==$visible){echo "RALAT_INPUT {$label}\n";$unexpected++;}
}
if($missing!==44||$found!==508||$hiddenOK!==28||$unexpected!==0){
  echo "RALAT_RINGKAS missing={$missing} found={$found} hidden={$hiddenOK} lain={$unexpected}\n";exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA missing=44 found=508 hidden=28 lain=0\n";exit(1);
