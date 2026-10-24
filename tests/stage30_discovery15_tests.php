<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyMissingThirdDigit15;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;

$m = NormativeMath::m();
$max = $m->square()->mul($m);
$oracle = new NormativeSauce();
$legacy = new LegacyMissingThirdDigit15(new SavePatch01(new LegacyRemainder()));
$kernel = new BootstrapKernel();
$unexpected = 0;
$scars = 0;
$matrix = 0;
$matrixWrong = 0;
$real = 0;
$invalid = 0;

// Keempat-empat saksi mempunyai n=M^3: tiada rejection,
 // maka setiap parut pasti disebabkan digit ketiga yang hilang.
$witnesses = [
    ['tag'=>'naik_1','first'=>BigInt::one(),'step'=>1],
    ['tag'=>'naik_2','first'=>BigInt::fromInt(2),'step'=>1],
    ['tag'=>'turun_4','first'=>BigInt::fromInt(4),'step'=>-1],
    ['tag'=>'lilit_M','first'=>$m,'step'=>1],
];
foreach ($witnesses as $w) {
    $stream=['first'=>$w['first'],'step'=>$w['step']];
    $digit2=NormativeMath::save(
        $w['first']->add(BigInt::fromInt(2*$w['step']))
    );
    $wanted=$oracle->chooseRank($stream,$max);
    $got=$legacy->chooseWrong($stream,$max);
    $difference=$digit2->sub(BigInt::one())->mul($m->square());
    if ($wanted->sub($got)->equals($difference) && !$wanted->equals($got)) {
        echo "GAGAL_DIJANGKA saksi={$w['tag']} digit3={$digit2}\n";
        $scars++;
    } else {
        echo "RALAT_SAKSI {$w['tag']} normatif={$wanted} legacy={$got}\n";
        $unexpected++;
    }
}

// M^2+1, M^2+2, M^3-1, M^3. Setiap titik diuji bagi dua arah.
// Titik mula dipilih untuk mengelakkan jalan rejection yang terlalu panjang.
$spaces = [
    $m->square()->add(BigInt::one()),
    $m->square()->add(BigInt::fromInt(2)),
    $max->sub(BigInt::one()),
    $max,
];
$starts=[BigInt::one(),BigInt::fromInt(2),BigInt::fromInt(4),
    $m->sub(BigInt::one()),$m];
foreach ($spaces as $n) {
    foreach ($starts as $first) {
        foreach ([-1,1] as $step) {
            $stream=['first'=>$first,'step'=>$step];
            $expected=$oracle->chooseRank($stream,$n);
            $actual=$legacy->chooseWrong($stream,$n);
            if ($actual->compare(BigInt::one())<0 || $actual->compare($n)>0) {
                echo "RALAT_DOMAIN_MATRIX\n";
                $unexpected++;
            }
            if (!$actual->equals($expected)) $matrixWrong++;
            $matrix++;
        }
    }
}
if ($matrixWrong !== 36 || $matrix !== 40) {
    echo "RALAT_MATRIX bil={$matrix} beza={$matrixWrong}\n";
    $unexpected++;
}

// Strim Native datang dari PATCH12. Tidak mendakwa tarikh nyata sentiasa
// mendedahkan parut: empat saksi di atas ialah bukti RED yang pasti.
foreach ([
    [NormativeMath::FOUNDATION_DAY,NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY,NormativeMath::TABLETS_DAY+17],
    [10000000,-10000000],
] as [$c,$t]) {
    $stream=$kernel->askBowl($c,$t,1,23);
    $direct=$legacy->chooseWrong($stream,$max);
    $routed=$kernel->legacyChooseTripleRank($c,$t,1,23,$max);
    $reference=$oracle->chooseRank($stream,$max);
    if ($direct->equals($routed) && $direct->compare(BigInt::one())>=0
        && $reference->compare(BigInt::one())>=0
        && $reference->compare($max)<=0) $real++;
    else {
        echo "RALAT_NATIVE\n";
        $unexpected++;
    }
}

// Lima input salah: sempadan first, step, dan ruang M²..M³.
foreach ([
    [['first'=>BigInt::zero(),'step'=>1],$max],
    [['first'=>$m->add(BigInt::one()),'step'=>1],$max],
    [['first'=>BigInt::one(),'step'=>0],$max],
    [['first'=>BigInt::one(),'step'=>1],$m->square()],
    [['first'=>BigInt::one(),'step'=>1],$max->add(BigInt::one())],
] as [$stream,$n]) {
    try {
        $legacy->chooseWrong($stream,$n);
        echo "RALAT_INVALID_DITERIMA\n";
        $unexpected++;
    } catch (InvalidArgumentException $e) {
        $invalid++;
    }
}

$src=dirname(__DIR__).'/src';
$legacyText=(string)file_get_contents($src.'/Legacy/LegacyMissingThirdDigit15.php');
$kernelText=(string)file_get_contents($src.'/BootstrapKernel.php');
if (!str_contains($legacyText,'for ($j = 0; $j < 2; $j++)')
    || !str_contains($kernelText,
        "dispatch('MISSING_THIRD_DIGIT_LEGACY', " . '$context)')
    || (is_file($src.'/Patches/ThirdDigitPatch15.php')
        && !(str_contains($kernelText,
                "dispatch('THIRD_DIGIT_PATCH_15', " . '$context)')
            && str_contains((string)file_get_contents(
                    $src.'/Patches/ThirdDigitPatch15.php'),
                '$this->legacy->chooseWrong($stream, $n)')))) {
    echo "RALAT_KONTRAK15\n";
    $unexpected++;
}
if ($scars!==4 || $matrix!==40 || $matrixWrong!==36
    || $real!==3 || $invalid!==5 || $unexpected!==0) {
    echo "KEPUTUSAN TIDAK_SAH parut={$scars} matriks={$matrix}"
        . " beza={$matrixWrong} real={$real} ralat={$invalid} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA parut=4 matriks=40 beza=36 real=3 ralat=5 lain=0\n";
exit(1);
