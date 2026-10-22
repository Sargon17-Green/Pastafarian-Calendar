<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyNumericSuccessor12;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;

// 720 permutasi, enam pertanyaan setiap permutasi: padanan 864, salah 3456.
$oracle = new NormativeSauce();
$legacy = new LegacyNumericSuccessor12(new SavePatch01(new LegacyRemainder()));
$kernel = new BootstrapKernel();
$bowls = [];
foreach (range(1, 6) as $id) {
    $bowls[$id] = BigInt::fromInt(10000 + 133 * $id);
}
$wrong = 0;
$equal = 0;
$unexpected = 0;
for ($rank = 1; $rank <= 720; $rank++) {
    $order = $oracle->permutationUnrank1($rank);
    $sauce = ['bowls'=>$bowls, 'orderAtDrop46'=>$order];
    foreach (range(1, 6) as $id) {
        $expected = $oracle->askBowl($sauce, $id, 23);
        $actual = $legacy->askWrong($sauce, $id, 23);
        $at = array_search($id, $order, true);
        $correctNext = $order[($at + 1) % 6];
        $numericNext = ($id % 6) + 1;
        if ($actual['nextBowlId'] !== $numericNext) {
            echo "RALAT_ID_LEGACY pangkat={$rank} id={$id}\n";
            $unexpected++;
        }
        if ($correctNext === $numericNext) {
            $equal++;
            if (!$actual['first']->equals($expected['first'])
                || $actual['step'] !== $expected['step']) {
                echo "RALAT_PADANAN pangkat={$rank} id={$id}\n";
                $unexpected++;
            }
        } else {
            $wrong++;
            if ($actual['first']->equals($expected['first'])) {
                echo "RALAT_PERBEZAAN pangkat={$rank} id={$id}\n";
                $unexpected++;
            }
        }
    }
}
$dates = [
    [NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY, NormativeMath::TABLETS_DAY + 17],
    [10000000, -10000000],
];
$real = 0;
$realWrong = 0;
foreach ($dates as [$c, $t]) {
    $reference = $oracle->sauce($c, $t);
    $production = $kernel->sauceOrder($c, $t);
    if ($production['orderAtDrop46'] !== $reference['orderAtDrop46']) {
        echo "RALAT_TURUTAN_PRODUKSI\n";
        $unexpected++;
    }
    foreach (range(1, 6) as $bowlId) {
        if (!$production['bowls'][$bowlId]->equals($reference['bowls'][$bowlId])) {
            echo "RALAT_MANGKUK_PRODUKSI id={$bowlId}\n";
            $unexpected++;
        }
    }
    foreach (range(1, 6) as $id) {
        $real++;
        $expected = $oracle->askBowl($reference, $id, 23);
        $actual = $legacy->askWrong($production, $id, 23);
        $at = array_search($id, $reference['orderAtDrop46'], true);
        $correctNext = $reference['orderAtDrop46'][($at + 1) % 6];
        if ($correctNext !== $actual['nextBowlId']) {
            $realWrong++;
            if ($actual['first']->equals($expected['first'])) {
                echo "RALAT_BUKTI_REAL id={$id}\n";
                $unexpected++;
            }
        } elseif (!$actual['first']->equals($expected['first'])
            || $actual['step'] !== $expected['step']) {
            echo "RALAT_PADANAN_REAL id={$id}\n";
            $unexpected++;
        }
    }
    $routed = $kernel->legacyAskBowl($c, $t, 1, 23);
    $direct = $legacy->askWrong($production, 1, 23);
    if (!$routed['first']->equals($direct['first'])
        || $routed['step'] !== $direct['step']
        || $routed['nextBowlId'] !== $direct['nextBowlId']) {
        echo "RALAT_DISPATCH\n";
        $unexpected++;
    }
}
$invalid = 0;
foreach ([0, 7] as $id) {
    try {
        $legacy->askWrong(
            ['bowls'=>$bowls, 'orderAtDrop46'=>[1,2,3,4,5,6]], $id, 23
        );
        echo "RALAT_ID_TIDAK_SAH id={$id}\n";
        $unexpected++;
    } catch (\InvalidArgumentException $e) {
        $invalid++;
    }
}
try {
    $legacy->askWrong(
        ['bowls'=>$bowls, 'orderAtDrop46'=>[1,2,3,4,4,6]], 1, 23
    );
    echo "RALAT_SUSUNAN_TIDAK_SAH\n";
    $unexpected++;
} catch (\InvalidArgumentException $e) {
    $invalid++;
}
if ($wrong !== 3456 || $equal !== 864 || $real !== 18
    || $realWrong < 1 || $invalid !== 3 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH salah={$wrong} sepadan={$equal}"
        . " real={$real} real_salah={$realWrong} ralat={$invalid} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA salah=3456 sepadan=864 pangkat=720"
    . " real=18 real_salah={$realWrong} ralat=3 lain=0\n";
exit(1);
