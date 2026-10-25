<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyMissingFourthDigit16;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;

$m = NormativeMath::m();
$m3 = $m->square()->mul($m);
$m4 = $m->square()->square();
$legacy = new LegacyMissingFourthDigit16(new SavePatch01(new LegacyRemainder()));
$oracle = new NormativeSauce();
$kernel = new BootstrapKernel();
$scars = 0; $other = 0; $matrix = 0; $different = 0; $real = 0; $invalid = 0;

// Tiada rejection pada n=M^4: beza mesti tepat (digit4-1)*M^3.
$witnesses = [
    ['name'=>'asas', 'first'=>BigInt::one(), 'step'=>1],
    ['name'=>'menaik', 'first'=>BigInt::fromInt(2), 'step'=>1],
    ['name'=>'menurun', 'first'=>BigInt::fromInt(5), 'step'=>-1],
    ['name'=>'lilitan', 'first'=>$m, 'step'=>1],
];
foreach ($witnesses as $item) {
    $stream = ['first'=>$item['first'],'step'=>$item['step']];
    $digit4 = NormativeMath::save(
        $item['first']->add(BigInt::fromInt(3 * $item['step']))
    );
    $expected = $oracle->chooseRank($stream, $m4);
    $wrong = $legacy->chooseWrong($stream, $m4);
    $gap = $digit4->sub(BigInt::one())->mul($m3);
    if (!$expected->equals($wrong) && $expected->sub($wrong)->equals($gap)) {
        echo "GAGAL_DIJANGKA saksi={$item['name']} digit4={$digit4}\n";
        $scars++;
    } else {
        echo "RALAT_SAKSI_{$item['name']}\n";
        $other++;
    }
}

// Empat saiz, tujuh nilai permulaan, dua arah: 56 kes deterministik.
// Pemilihan saiz sengaja mengelak penolakan astronomi.
$spaces = [$m3->add(BigInt::one()), $m3->add(BigInt::fromInt(2)),
    $m4->sub(BigInt::one()), $m4];
$starts = [BigInt::one(), BigInt::fromInt(2), BigInt::fromInt(3),
    BigInt::fromInt(5), $m->sub(BigInt::fromInt(2)),
    $m->sub(BigInt::one()), $m];
foreach ($spaces as $space) {
    foreach ($starts as $first) {
        foreach ([-1,1] as $step) {
            $stream = ['first'=>$first, 'step'=>$step];
            $expected = $oracle->chooseRank($stream,$space);
            $actual = $legacy->chooseWrong($stream,$space);
            if ($actual->compare(BigInt::one()) < 0 || $actual->compare($space)>0) {
                echo "RALAT_DOMAIN\n";
                $other++;
            }
            if (!$expected->equals($actual)) $different++;
            $matrix++;
        }
    }
}
if ($matrix !== 56 || $different !== 52) {
    echo "RALAT_MATRIX total={$matrix} beza={$different}\n";
    $other++;
}

// Laluan kernel Stage32 mesti mengguna askBowl PATCH12 dan kelas legacy sebenar.
foreach ([
    [NormativeMath::FOUNDATION_DAY,NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY,NormativeMath::TABLETS_DAY+17],
    [10000000,-10000000],
] as [$c,$t]) {
    $stream = $kernel->askBowl($c,$t,1,23);
    $actual = $kernel->legacyChooseQuadRank($c,$t,1,23,$m4);
    $direct = $legacy->chooseWrong($stream,$m4);
    $expected = $oracle->chooseRank($stream,$m4);
    if ($actual->equals($direct) && $expected->compare(BigInt::one())>=0
        && $expected->compare($m4)<=0) {
        $real++;
    } else {
        echo "RALAT_NATIVE\n";
        $other++;
    }
}
foreach ([
    [['first'=>BigInt::zero(),'step'=>1],$m4],
    [['first'=>$m->add(BigInt::one()),'step'=>1],$m4],
    [['first'=>BigInt::one(),'step'=>0],$m4],
    [['first'=>BigInt::one(),'step'=>1],$m3],
    [['first'=>BigInt::one(),'step'=>1],$m4->add(BigInt::one())],
] as [$stream,$space]) {
    try {
        $legacy->chooseWrong($stream,$space);
        echo "RALAT_INVALID_DITERIMA\n";
        $other++;
    } catch (InvalidArgumentException $e) {
        $invalid++;
    }
}
$root=dirname(__DIR__);
$legacyCode=(string)file_get_contents($root.'/src/Legacy/LegacyMissingFourthDigit16.php');
$kernelCode=(string)file_get_contents($root.'/src/BootstrapKernel.php');
if (!str_contains($legacyCode,'for ($j = 0; $j < 3; $j++)')
    || !str_contains($kernelCode, "dispatch('MISSING_FOURTH_DIGIT_LEGACY', " . '$context)')
    || (is_file($root.'/src/Patches/FourthDigitPatch16.php')
        && !(str_contains($kernelCode,
                "dispatch('FOUR_DIGIT_PATCH_16', " . '$context)')
            && str_contains((string)file_get_contents(
                    $root.'/src/Patches/FourthDigitPatch16.php'),
                '$this->legacy->chooseWrong($stream, $n)')))) {
    echo "RALAT_KONTRAK16\n";
    $other++;
}
if ($scars!==4 || $matrix!==56 || $different!==52 || $real!==3
    || $invalid!==5 || $other!==0) {
    echo "KEPUTUSAN TIDAK_SAH parut={$scars} matriks={$matrix} beza={$different} real={$real} ralat={$invalid} lain={$other}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA parut=4 matriks=56 beza=52 real=3 ralat=5 lain=0\n";
exit(1);
