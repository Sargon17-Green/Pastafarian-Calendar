<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyMissingFifthDigit17;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;

$m = NormativeMath::m();
$m4 = $m->square()->square();
$m5 = $m4->mul($m);
$legacy = new LegacyMissingFifthDigit17(new SavePatch01(new LegacyRemainder()));
$oracle = new NormativeSauce();
$kernel = new BootstrapKernel();
$scars = 0; $unexpected = 0; $matrix = 0; $different = 0;
$real = 0; $invalid = 0;

// Empat saksi tanpa rejection: n=M^5. Beza tepat
// (digit kelima - 1)*M^4, tiada kesan daripada cutoff.
$witnesses = [
    ['name'=>'asas', 'first'=>BigInt::one(), 'step'=>1],
    ['name'=>'menaik', 'first'=>BigInt::fromInt(2), 'step'=>1],
    ['name'=>'menurun', 'first'=>BigInt::fromInt(6), 'step'=>-1],
    ['name'=>'lilitan', 'first'=>$m, 'step'=>1],
];
foreach ($witnesses as $item) {
    $stream=['first'=>$item['first'], 'step'=>$item['step']];
    $fifth = NormativeMath::save(
        $item['first']->add(BigInt::fromInt(4 * $item['step']))
    );
    $want = $oracle->chooseRank($stream,$m5);
    $wrong = $legacy->chooseWrong($stream,$m5);
    $difference = $fifth->sub(BigInt::one())->mul($m4);
    if (!$want->equals($wrong) && $want->sub($wrong)->equals($difference)) {
        echo "GAGAL_DIJANGKA saksi={$item['name']} digit5={$fifth}\n";
        $scars++;
    } else {
        echo "RALAT_SAKSI_{$item['name']}\n";
        $unexpected++;
    }
}

// Empat saiz x tujuh nilai x dua arah = 56 kes.
// Saiz dipilih supaya tidak wujud rejection yang tidak berkesudahan.
$spaces = [$m4->add(BigInt::one()), $m4->add(BigInt::fromInt(2)),
    $m5->sub(BigInt::one()), $m5];
$starts = [BigInt::one(),BigInt::fromInt(2),BigInt::fromInt(3),
    BigInt::fromInt(5),$m->sub(BigInt::fromInt(2)),
    $m->sub(BigInt::one()),$m];
foreach ($spaces as $n) {
    foreach ($starts as $first) {
        foreach ([-1,1] as $step) {
            $stream=['first'=>$first,'step'=>$step];
            $normative=$oracle->chooseRank($stream,$n);
            $historical=$legacy->chooseWrong($stream,$n);
            if ($historical->compare(BigInt::one()) < 0
                || $historical->compare($n) > 0) {
                echo "RALAT_MATRIX_DOMAIN\n";
                $unexpected++;
            }
            if (!$normative->equals($historical)) $different++;
            $matrix++;
        }
    }
}
if ($matrix !== 56 || $different !== 52) {
    echo "RALAT_MATRIX bil={$matrix} beza={$different}\n";
    $unexpected++;
}

// Jalur Native: strim daripada PATCH12, bukan oracle dalam produksi.
foreach ([
    [NormativeMath::FOUNDATION_DAY,NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY,NormativeMath::TABLETS_DAY+17],
    [10000000,-10000000],
] as [$c,$t]) {
    $stream=$kernel->askBowl($c,$t,1,23);
    $direct=$legacy->chooseWrong($stream,$m5);
    $routed=$kernel->legacyChooseQuintRank($c,$t,1,23,$m5);
    $normative=$oracle->chooseRank($stream,$m5);
    if ($direct->equals($routed) && $normative->compare(BigInt::one()) >= 0
        && $normative->compare($m5) <= 0) $real++;
    else {
        echo "RALAT_NATIVE\n";
        $unexpected++;
    }
}
foreach ([
    [['first'=>BigInt::zero(),'step'=>1],$m5],
    [['first'=>$m->add(BigInt::one()),'step'=>1],$m5],
    [['first'=>BigInt::one(),'step'=>0],$m5],
    [['first'=>BigInt::one(),'step'=>1],$m4],
    [['first'=>BigInt::one(),'step'=>1],$m5->add(BigInt::one())],
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
$legacyCode=(string)file_get_contents($src.'/Legacy/LegacyMissingFifthDigit17.php');
$kernelCode=(string)file_get_contents($src.'/BootstrapKernel.php');
if (!str_contains($legacyCode,'for ($j = 0; $j < 4; $j++)')
    || !str_contains($kernelCode,
        "dispatch('MISSING_FIFTH_DIGIT_LEGACY', " . '$context)')
    || (is_file($src.'/Patches/FifthDigitPatch17.php')
        && !(str_contains($kernelCode,
                "dispatch('FIFTH_DIGIT_PATCH_17', " . '$context)')
            && str_contains((string)file_get_contents(
                    $src.'/Patches/FifthDigitPatch17.php'),
                '$this->legacy->chooseWrong($stream, $n)')))) {
    echo "RALAT_KONTRAK17\n";
    $unexpected++;
}
if ($scars !== 4 || $matrix !== 56 || $different !== 52
    || $real !== 3 || $invalid !== 5 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH parut={$scars} matriks={$matrix}"
        . " beza={$different} real={$real} ralat={$invalid} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA parut=4 matriks=56 beza=52 real=3 ralat=5 lain=0\n";
exit(1);
