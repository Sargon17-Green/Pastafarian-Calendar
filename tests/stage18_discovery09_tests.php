<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyBowlFactory;
use Pastafari\Stage01\Legacy\LegacyFixedPositionPours;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;

// Legacy membaca ID mangkuk 1,2,3 walaupun order[0..2] bukan 1,2,3.
$save = new SavePatch01(new LegacyRemainder());
$factory = new LegacyBowlFactory($save);
$legacy = new LegacyFixedPositionPours($save);
$kernel = new BootstrapKernel();
$oracle = new NormativeSauce();
$wrong = 0;
$matches = 0;
$unexpected = 0;
$orders = [];
$fixed = [
    1=>BigInt::fromInt(101), 2=>BigInt::fromInt(211),
    3=>BigInt::fromInt(307), 4=>BigInt::fromInt(401),
    5=>BigInt::fromInt(503), 6=>BigInt::fromInt(601),
];
$stone = [
    'w'=>BigInt::fromInt(2), 'b'=>BigInt::fromInt(3),
    's'=>BigInt::fromInt(5), 'm'=>BigInt::fromInt(7),
    'r'=>BigInt::fromInt(11),
];
foreach (range(1,720) as $rank) {
    $drop = BigInt::fromInt($rank);
    $order = $kernel->bowlOrder($drop);
    $pours = $legacy->legacyPours(1, $drop, $stone, $fixed, $order);
    $normativeOrder = $oracle->permutationUnrank1($rank);
    if ($order !== $normativeOrder || array_keys($pours) !== range(1,6)) {
        echo "RALAT_ORDINAL rank={$rank}\n";
        $unexpected++;
        continue;
    }
    $orders[implode(',', $order)] = true;
    foreach ([1,2,3] as $position) {
        $kind = [1=>'w',2=>'b',3=>'s'][$position];
        $scale = [1=>3,2=>5,3=>7][$position];
        $correct = NormativeMath::save(
            $drop->square()
                ->add($stone[$kind]->mul($fixed[$order[$position-1]]))
                ->add(BigInt::fromInt($scale))
        );
        $fromFixed = NormativeMath::save(
            $drop->square()
                ->add($stone[$kind]->mul($fixed[$position]))
                ->add(BigInt::fromInt($scale))
        );
        if (!$pours[$position]->equals($fromFixed)) {
            echo "RALAT_LEGACY_DIHITUNG rank={$rank} posisi={$position}\n";
            $unexpected++;
        } elseif ($pours[$position]->equals($correct)) {
            if ($order[$position-1] !== $position) {
                echo "RALAT_SEPADAN_TIDAK_DIJANGKA rank={$rank} posisi={$position}\n";
                $unexpected++;
            } else {
                $matches++;
            }
        } elseif ($order[$position-1] === $position) {
            echo "RALAT_TAK_PADAN_KEDUDUKAN rank={$rank} posisi={$position}\n";
            $unexpected++;
        } else {
            $wrong++;
        }
    }
    foreach ([4,5,6] as $position) {
        if (!$pours[$position]->isZero()) {
            echo "RALAT_POSISI_KOSONG rank={$rank} posisi={$position}\n";
            $unexpected++;
        }
    }
}
if (count($orders)!==720 || $wrong!==1800 || $matches!==360) {
    echo "RALAT_KIRAAN_720 salah={$wrong} sepadan={$matches} unik=" . count($orders) . "\n";
    $unexpected++;
}

// Jalur pengeluaran mengira titisan nyata, mangkuk asas dan susunan yang sah.
// Formula kegagalan ialah bacaan ID, bukan kesilapan pengiraan nilai atau stone.
$dates = [
    ['asas_sama', NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY],
    ['loh_depan', NormativeMath::TABLETS_DAY, NormativeMath::TABLETS_DAY+17],
];
$real = 0;
$realWrong = 0;
foreach ($dates as [$name,$c,$t]) {
    $counts = NormativeMath::workCounts($c,$t);
    $expectedBowls = $oracle->initialBowls($counts);
    $actualBowls = $factory->initialBowls($counts);
    for ($id=1;$id<=6;$id++) {
        if (!$actualBowls[$id]->equals($expectedBowls[$id])) {
            echo "RALAT_KILANG kes={$name} id={$id}\n";
            $unexpected++;
        }
    }
    $visible = $kernel->visibleDrops($c,$t);
    $stones = $kernel->stones();
    foreach ([1,46] as $i) {
        $got = $kernel->legacyPoursAt($c,$t,$i);
        $drop = $visible[$i];
        $order = $oracle->bowlOrderFromDrop($drop);
        if (!$got['drop']->equals($drop) || $got['order']!==$order) {
            echo "RALAT_HALUAN kes={$name} i={$i}\n";
            $unexpected++;
            continue;
        }
        for ($id=1;$id<=6;$id++) {
            if (!$got['oldBowls'][$id]->equals($expectedBowls[$id])) {
                echo "RALAT_PEMILIKAN kes={$name} i={$i} id={$id}\n";
                $unexpected++;
            }
        }
        $direct = $legacy->legacyPours($i,$drop,$stones[$i],$actualBowls,$order);
        foreach ([1,2,3] as $pos) {
            $kind = [1=>'w',2=>'b',3=>'s'][$pos];
            $factor = [1=>3,2=>5,3=>7][$pos];
            $norm = NormativeMath::save(
                $drop->square()
                    ->add($stones[$i][$kind]->mul($expectedBowls[$order[$pos-1]]))
                    ->add(BigInt::fromInt($factor*$i))
            );
            if (!$got['pours'][$pos]->equals($direct[$pos])) {
                echo "RALAT_PRODUKSI kes={$name} i={$i} posisi={$pos}\n";
                $unexpected++;
            }
            if ($order[$pos-1]!==$pos && !$got['pours'][$pos]->equals($norm)) {
                $realWrong++;
            }
        }
        $real++;
    }
}
if ($real!==4 || $realWrong<1) {
    echo "RALAT_BUKTI_NYATA pasangan={$real} perbezaan={$realWrong}\n";
    $unexpected++;
}

foreach ([0,47] as $bad) {
    try {
        $legacy->legacyPours($bad, BigInt::one(), $stone, $fixed, [1,2,3,4,5,6]);
        echo "RALAT_JULAT_DITERIMA {$bad}\n"; $unexpected++;
    } catch (InvalidArgumentException $e) {
        if ($e->getMessage()!=='LEGACY_POUR_ARGUMENTS') $unexpected++;
    }
}
try {
    $broken = $fixed;
    unset($broken[3]);
    $legacy->legacyPours(1,BigInt::one(),$stone,$broken,[1,2,3,4,5,6]);
    echo "RALAT_KERAMIK_HILANG\n"; $unexpected++;
} catch (InvalidArgumentException $e) {
    if ($e->getMessage()!=='LEGACY_BOWL_MISSING') $unexpected++;
}
$src = dirname(__DIR__) . '/src';
$legacySource = (string)file_get_contents($src.'/Legacy/LegacyFixedPositionPours.php');
$kernelSource = (string)file_get_contents($src.'/BootstrapKernel.php');
if (!str_contains($legacySource, '$oldBowls[1]')
    || !str_contains($legacySource, '$oldBowls[2]')
    || !str_contains($legacySource, '$oldBowls[3]')
    || !str_contains($kernelSource, "dispatch('FIXED_POSITION_POURS_LEGACY', " . '$context)')) {
    echo "RALAT_PARUT_SUMBER\n";$unexpected++;
}
if ($unexpected!==0) {
    echo "KEPUTUSAN TIDAK_SAH salah={$wrong} sepadan={$matches} real={$real} real_salah={$realWrong} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA salah=1800 sepadan=360 pangkat=720 real=4 lain=0\n";
exit(1);
