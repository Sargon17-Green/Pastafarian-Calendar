<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyBowlFactory;
use Pastafari\Stage01\Legacy\LegacyBowlPermutation;
use Pastafari\Stage01\Legacy\LegacyFixedPositionPours;
use Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir;
use Pastafari\Stage01\Legacy\LegacyOverwrittenOrder11;
use Pastafari\Stage01\Legacy\LegacyPermutationUnrank0;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\BowlShadowPatch10;
use Pastafari\Stage01\Patches\PermutationPatch08;
use Pastafari\Stage01\Patches\PoursAliasPatch09;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Bukti penemuan 11: enam nilai mangkuk akhir tetap betul;
 * hanya susunan 46 ditimpa oleh dua belas pesanan post-stir.
 */

/** @param array<int,BigInt> $bowls @return array{0:array<int,BigInt>,1:list<int>} */
function rujukanSelepasKacau(array $bowls, NormativeSauce $oracle): array
{
    $last = [];
    for ($stir = 1; $stir <= 12; $stir++) {
        $old = $bowls;
        $raw = BigInt::zero();
        foreach (range(1, 6) as $id) {
            $raw = $raw->add($old[$id]);
        }
        $saved = NormativeMath::save($raw->add(BigInt::fromInt(149 * $stir)));
        $last = $oracle->permutationUnrank1(
            $saved->sub(BigInt::one())->modSmall(720) + 1
        );
        $new = [];
        for ($pos = 1; $pos <= 6; $pos++) {
            $id = $last[$pos - 1];
            $prev = $last[($pos + 4) % 6];
            $next = $last[$pos % 6];
            $z = $old[$id]
                ->add($old[$prev]->mulSmall(3))
                ->add($old[$next]->mulSmall(5))
                ->add($saved)
                ->add(BigInt::fromInt($stir + $pos * $pos));
            $new[$id] = NormativeMath::save(
                $z->square()->add($old[$prev]->mul($old[$next])->mulSmall(7))
            );
        }
        $bowls = $new;
    }
    return [$bowls, $last];
}

$oracle = new NormativeSauce();
$kernel = new BootstrapKernel();
$stones = $oracle->buildStones();
$save = new SavePatch01(new LegacyRemainder());
$unrank = new LegacyPermutationUnrank0();
$runner = new LegacyOverwrittenOrder11(
    $save,
    new LegacyBowlFactory($save),
    new PermutationPatch08(new LegacyBowlPermutation($unrank), $unrank),
    new PoursAliasPatch09(new LegacyFixedPositionPours($save)),
    new BowlShadowPatch10(new LegacyInPlaceBowlStir($save), $save)
);

$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$dates = [
    ['asas', $foundation, $foundation],
    ['loh', $tablets, $tablets + 17],
    ['jauh', 10000000, -10000000],
];

$wrongOrders = 0;
$correctBowls = 0;
$postStirs = 0;
$unexpected = 0;
$cases = 0;
foreach ($dates as [$label, $c, $t]) {
    $counts = NormativeMath::workCounts($c, $t);
    $normative = $oracle->sauce($c, $t);
    $legacy = $kernel->legacySauceOrder($c, $t);
    if ($label === 'asas') {
        $direct = $runner->sauceWrong($counts, $stones, $normative['visible']);
        if ($legacy['orderAtDrop46'] !== $direct['orderAtDrop46']) {
            echo "RALAT_LALUAN_LANGSUNG kes={$label}\n";
            $unexpected++;
        }
        foreach (range(1,6) as $id) {
            if (!$legacy['bowls'][$id]->equals($direct['bowls'][$id])) {
                echo "RALAT_MANGKUK_LANGSUNG id={$id}\n";
                $unexpected++;
            }
        }
    }
    [$afterDrops] = $oracle->applyVisibleDropsToBowls(
        $oracle->initialBowls($counts), $normative['visible'], $stones
    );
    [$postBowls, $lastPostOrder] = rujukanSelepasKacau($afterDrops, $oracle);
    if ($legacy['postStirs'] !== 12 || $legacy['dropCount'] !== 46
        || $legacy['orderAtDrop46'] !== $lastPostOrder) {
        echo "RALAT_KONTEKS_POST kes={$label}\n";
        $unexpected++;
    } else {
        $postStirs += $legacy['postStirs'];
    }
    if ($normative['orderAtDrop46']
        !== $oracle->bowlOrderFromDrop($normative['visible'][46])) {
        echo "RALAT_ORACLE_TITISAN_46 kes={$label}\n";
        $unexpected++;
    }
    foreach (range(1,6) as $id) {
        if (!$legacy['bowls'][$id] instanceof BigInt
            || !$legacy['bowls'][$id]->equals($normative['bowls'][$id])
            || !$legacy['bowls'][$id]->equals($postBowls[$id])) {
            echo "RALAT_MANGKUK_AKHIR kes={$label} id={$id}\n";
            $unexpected++;
        } else {
            $correctBowls++;
        }
    }
    if ($legacy['orderAtDrop46'] === $normative['orderAtDrop46']) {
        echo "RALAT_SUSUNAN_TERSAMPAI kes={$label}\n";
        $unexpected++;
    } else {
        echo "GAGAL_DIJANGKA kes={$label} susunan_46_ditindih_oleh_post_12\n";
        $wrongOrders++;
    }
    $cases++;
}

$legacyFile = (string)file_get_contents(
    dirname(__DIR__) . '/src/Legacy/LegacyOverwrittenOrder11.php'
);
$kernelFile = (string)file_get_contents(dirname(__DIR__) . '/src/BootstrapKernel.php');
if (!str_contains($legacyFile, '$order = $this->permutation->permutationPatch($saved);')
    || !str_contains($legacyFile, "'orderAtDrop46' => $order")
    || !str_contains($kernelFile, "dispatch('OVERWRITTEN_ORDER_46_LEGACY', " . '$context)')
    || str_contains($legacyFile, 'orderAt46Latch')) {
    echo "RALAT_KONTRAK_LEGACY\n";
    $unexpected++;
}
if ($cases !== 3 || $correctBowls !== 18 || $postStirs !== 36
    || $wrongOrders !== 3 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH kes={$cases} salah={$wrongOrders}"
        . " mangkuk={$correctBowls} kacau={$postStirs} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA kes=3 susunan_salah=3 mangkuk_betul=18"
    . " kacau=36 lain=0\n";
exit(1);
