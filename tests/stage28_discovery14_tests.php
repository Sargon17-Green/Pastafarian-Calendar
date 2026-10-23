<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyBigEndianDigits14;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;

$m = NormativeMath::m();
$oracle = new NormativeSauce();
$legacy = new LegacyBigEndianDigits14(new SavePatch01(new LegacyRemainder()));
$kernel = new BootstrapKernel();
$n = $m->add(BigInt::one());
$expectedWrong = 0;
$unexpected = 0;

// Empat saksi berbeza, termasuk lintasan M -> 1.
$witnesses = [
    ['label'=>'asas', 'first'=>BigInt::one(), 'step'=>1,
        'expected'=>$n, 'wrong'=>BigInt::fromInt(2)],
    ['label'=>'menaik', 'first'=>BigInt::fromInt(2), 'step'=>1,
        'expected'=>$n, 'wrong'=>BigInt::fromInt(2)],
    ['label'=>'menurun', 'first'=>BigInt::fromInt(2), 'step'=>-1,
        'expected'=>BigInt::fromInt(2), 'wrong'=>$n],
    ['label'=>'lilitan', 'first'=>$m, 'step'=>1,
        'expected'=>$m, 'wrong'=>BigInt::fromInt(3)],
];
foreach ($witnesses as $w) {
    $stream=['first'=>$w['first'],'step'=>$w['step']];
    $expected=$oracle->chooseRank($stream,$n);
    $actual=$legacy->chooseWrong($stream,$n);
    if (!$expected->equals($w['expected'])
        || !$actual->equals($w['wrong'])
        || $expected->equals($actual)) {
        echo "RALAT_SAKSI_{$w['label']} normatif={$expected} legacy={$actual}\n";
        $unexpected++;
        continue;
    }
    $expectedWrong++;
    echo "GAGAL_DIJANGKA kes={$w['label']}\n";
}

// Matriks tambahan: M+1, 2M+1, M^2-1, M^2; kedua-dua arah.
$matrix=0;
$matrixDifferent=0;
$sizes=[$m->add(BigInt::one()),$m->add(BigInt::fromInt(2)),
    $m->square()->sub(BigInt::one()),$m->square()];
foreach ($sizes as $space) {
    foreach ([BigInt::one(), BigInt::fromInt(2), BigInt::fromInt(3),
        $m->sub(BigInt::fromInt(2)), $m->sub(BigInt::one()), $m] as $first) {
        foreach ([-1,1] as $step) {
            $stream=['first'=>$first,'step'=>$step];
            $expected=$oracle->chooseRank($stream,$space);
            $actual=$legacy->chooseWrong($stream,$space);
            if ($actual->compare(BigInt::one()) < 0 || $actual->compare($space) > 0) {
                echo "RALAT_DOMAIN_MATRIX\n";
                $unexpected++;
            }
            if (!$expected->equals($actual)) {
                $matrixDifferent++;
            }
            $matrix++;
        }
    }
}
if ($matrixDifferent < 40) {
    echo "RALAT_MATRIX_DIFFERENCES got={$matrixDifferent}\n";
    $unexpected++;
}

// Ujian penghala melalui aliran PATCH12; jangan jadikan ketidakpadanan
// bagi tarikh rawak sebagai kriteria, kerana empat saksi matematik sudah tetap.
$real=0;
foreach ([
    [NormativeMath::FOUNDATION_DAY,NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY,NormativeMath::TABLETS_DAY+17],
    [10000000,-10000000],
] as [$c,$t]) {
    $stream=$kernel->askBowl($c,$t,1,23);
    $direct=$legacy->chooseWrong($stream,$n);
    $routed=$kernel->legacyChooseWideRank($c,$t,1,23,$n);
    $expected=$oracle->chooseRank($stream,$n);
    if (!$direct->equals($routed)
        || $routed->compare(BigInt::one())<0 || $routed->compare($n)>0
        || $expected->compare(BigInt::one())<0 || $expected->compare($n)>0) {
        echo "RALAT_NATIVE_ROUTE\n";
        $unexpected++;
    } else {
        $real++;
    }
}

$bad=0;
foreach ([
    [['first'=>BigInt::zero(),'step'=>1],$n],
    [['first'=>$m->add(BigInt::one()),'step'=>1],$n],
    [['first'=>BigInt::one(),'step'=>0],$n],
    [['first'=>BigInt::one(),'step'=>1],$m],
    [['first'=>BigInt::one(),'step'=>1],$m->square()->add(BigInt::one())],
] as [$stream,$space]) {
    try {
        $legacy->chooseWrong($stream,$space);
        echo "RALAT_INPUT_DITERIMA\n";
        $unexpected++;
    } catch (InvalidArgumentException $e) {
        $bad++;
    }
}

$src=dirname(__DIR__).'/src';
$legacyCode=(string)file_get_contents($src.'/Legacy/LegacyBigEndianDigits14.php');
$kernelCode=(string)file_get_contents($src.'/BootstrapKernel.php');
if (!str_contains($legacyCode,'$digitWeights = [$this->modulus, BigInt::one()];')
    || !str_contains($kernelCode,
        "dispatch('BIG_ENDIAN_DIGITS_LEGACY', " . '$context)')
    || (is_file($src.'/Patches/BigEndianDigitsPatch14.php')
        && !(str_contains($kernelCode,
                "dispatch('TWO_DIGIT_WEIGHTS_PATCH_14', " . '$context)')
            && str_contains((string)file_get_contents(
                    $src.'/Patches/BigEndianDigitsPatch14.php'),
                '$this->legacy->chooseWrong($stream, $n)')))) {
    echo "RALAT_KONTRAK14\n";
    $unexpected++;
}
if ($expectedWrong !== 4 || $matrix !== 48 || $real !== 3
    || $bad !== 5 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH merah={$expectedWrong} matriks={$matrix}"
        . " salah_matriks={$matrixDifferent} real={$real} ralat={$bad} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA merah=4 matriks=48"
    . " salah_matriks={$matrixDifferent} real=3 ralat=5 lain=0\n";
exit(1);
