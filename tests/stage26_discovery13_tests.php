<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyNoRejection13;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;

$oracle = new NormativeSauce();
$legacy = new LegacyNoRejection13();
$kernel = new BootstrapKernel();
$m = NormativeMath::m();
$wrong = 0;
$controls = 0;
$unexpected = 0;

// Empat bukti matematik yang bebas daripada kebetulan tarikh:
// x=L+1, step=-1: oracle menolak x dan menerima L (rank n).
// Legacy terus memetakan x kepada rank 1, walaupun 1<=n<=M.
foreach ([3, 10, 97, 720] as $size) {
    $n = BigInt::fromInt($size);
    $limit = $m->floorDiv($n)->mul($n);
    if ($limit->compare($m) >= 0) {
        echo "RALAT_BATAS_RUANG ruang={$size}\n";
        $unexpected++;
        continue;
    }
    $stream = ['first'=>$limit->add(BigInt::one()), 'step'=>-1];
    $expected = $oracle->chooseRank($stream, $n);
    $actual = $legacy->chooseWrong($stream, $n);
    if (!$expected->equals($n) || !$actual->equals(BigInt::one())) {
        echo "RALAT_BUKTI_BIAS ruang={$size} oracle={$expected} legacy={$actual}\n";
        $unexpected++;
    } else {
        echo "GAGAL_DIJANGKA ruang={$size} legacy=1 normatif={$size}\n";
        $wrong++;
    }

    // Di bawah cutoff, pengiraan modulo lama memang sepadan dengan oracle.
    foreach ([
        ['first'=>$limit, 'step'=>-1],
        ['first'=>$limit, 'step'=>1],
        ['first'=>BigInt::one(), 'step'=>1],
    ] as $correctStream) {
        $wanted = $oracle->chooseRank($correctStream, $n);
        $found = $legacy->chooseWrong($correctStream, $n);
        if (!$wanted->equals($found)) {
            echo "RALAT_KAWALAN ruang={$size}\n";
            $unexpected++;
        } else {
            $controls++;
        }
    }
}
$one = BigInt::one();
if ($legacy->chooseWrong(['first'=>$m,'step'=>-1], $one)->equals($one)
    && $oracle->chooseRank(['first'=>$m,'step'=>-1], $one)->equals($one)) {
    $controls++;
} else {
    echo "RALAT_SATU\n";
    $unexpected++;
}

// Penghala Native mengakses strim PATCH12 yang sudah betul.
// Tiga pasangan hari berbeza tidak diada-adakan sebagai parut RED.
$dates = [
    [NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY, NormativeMath::TABLETS_DAY + 17],
    [10000000, -10000000],
];
$real = 0;
foreach ($dates as [$c, $t]) {
    $stream = $kernel->askBowl($c, $t, 1, 23);
    $direct = $legacy->chooseWrong($stream, BigInt::fromInt(97));
    $routed = $kernel->legacyChooseRank($c, $t, 1, 23, BigInt::fromInt(97));
    if (!$direct->equals($routed)
        || !$stream['first'] instanceof BigInt
        || !in_array($stream['step'], [-1, 1], true)) {
        echo "RALAT_LALUAN_NATIVE\n";
        $unexpected++;
    } else {
        $real++;
    }
}
$invalid = 0;
foreach ([
    [['first'=>BigInt::zero(),'step'=>1], BigInt::fromInt(10)],
    [['first'=>BigInt::one(),'step'=>0], BigInt::fromInt(10)],
    [['first'=>BigInt::one(),'step'=>1], BigInt::zero()],
    [['first'=>BigInt::one(),'step'=>1], $m->add(BigInt::one())],
] as [$stream, $n]) {
    try {
        $legacy->chooseWrong($stream, $n);
        echo "RALAT_TERIMA_INPUT\n";
        $unexpected++;
    } catch (InvalidArgumentException $e) {
        $invalid++;
    }
}

$src = dirname(__DIR__) . '/src';
$legacyText = (string)file_get_contents($src . '/Legacy/LegacyNoRejection13.php');
$kernelText = (string)file_get_contents($src . '/BootstrapKernel.php');
if (!str_contains($legacyText,
        'return $first->sub(BigInt::one())->mod($n)->add(BigInt::one());')
    || !str_contains($kernelText,
        "dispatch('NO_REJECTION_CHOICE_LEGACY', " . '$context)')
    || (is_file($src . '/Patches/RejectionSamplingPatch13.php')
        && !(str_contains($kernelText,
                "dispatch('REJECTION_SAMPLING_PATCH_13', " . '$context)')
            && str_contains((string)file_get_contents(
                    $src . '/Patches/RejectionSamplingPatch13.php'),
                '$this->legacy->chooseWrong($stream, $n)')))) {
    echo "RALAT_KONTRAK_DISCOVERY13\n";
    $unexpected++;
}
if ($wrong !== 4 || $controls !== 13 || $real !== 3
    || $invalid !== 4 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH merah={$wrong} kawalan={$controls}"
        . " real={$real} ralat={$invalid} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA merah=4 kawalan=13 real=3 ralat=4 lain=0\n";
exit(1);
