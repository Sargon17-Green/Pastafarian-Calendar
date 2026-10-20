<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyBowlPermutation;
use Pastafari\Stage01\Legacy\LegacyPermutationUnrank0;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;

// Penemuan 08: pangkat satu dihantar ke penyahkedudukan pangkat sifar.
$zeroUnrank = new LegacyPermutationUnrank0();
$legacy = new LegacyBowlPermutation($zeroUnrank);
$kernel = new BootstrapKernel();
$oracle = new NormativeSauce();
$wrong = 0;
$outOfRange = 0;
$unexpected = 0;
$rawCorrect = 0;
$sampled = 0;

for ($rank1 = 1; $rank1 <= 720; $rank1++) {
    $drop = BigInt::fromInt($rank1);
    $normative = $oracle->permutationUnrank1($rank1);
    // Fungsi zero-based itu sendiri masih betul.
    if ($zeroUnrank->oldPermutationUnrank0($rank1 - 1) !== $normative) {
        echo "RALAT_ASAS_PANGKAT rank={$rank1}\n";
        $unexpected++;
    } else {
        $rawCorrect++;
    }
    try {
        $direct = $legacy->legacyBowlOrderFromDrop($drop);
        $actual = $kernel->legacyBowlOrder($drop);
        $another = (new BootstrapKernel())->legacyBowlOrder($drop);
        if ($rank1 === 720 || $direct !== $actual || $direct !== $another
            || $direct !== $zeroUnrank->oldPermutationUnrank0($rank1)) {
            echo "RALAT_LALUAN rank={$rank1}\n";
            $unexpected++;
        } elseif ($actual === $normative) {
            echo "RALAT_PADANAN rank={$rank1}\n";
            $unexpected++;
        } else {
            $wrong++;
        }
    } catch (InvalidArgumentException $error) {
        if ($rank1 !== 720 || $error->getMessage() !== 'PERMUTATION_RANK_ZERO_RANGE') {
            echo "RALAT_PENGECUALIAN rank={$rank1}\n";
            $unexpected++;
        } else {
            $outOfRange++;
        }
    }
}

if ($legacy->legacyBowlOrderFromDrop(BigInt::one()) !== [1,2,3,4,6,5]
    || $oracle->bowlOrderFromDrop(BigInt::one()) !== [1,2,3,4,5,6]) {
    echo "RALAT_VEKTOR_PERTAMA\n";
    $unexpected++;
}
foreach ([-1,720] as $bad) {
    try {
        $zeroUnrank->oldPermutationUnrank0($bad);
        echo "RALAT_RANK_DITERIMA rank={$bad}\n";
        $unexpected++;
    } catch (InvalidArgumentException $error) {
        if ($error->getMessage() !== 'PERMUTATION_RANK_ZERO_RANGE') $unexpected++;
    }
}
// Baki dan pembungkusan bagi integer amat besar serta negatif.
$large = BigInt::fromString(str_repeat('31415926535897932384626433832795', 9));
$probes = [
    BigInt::zero(), BigInt::fromInt(-1), BigInt::fromInt(-719),
    BigInt::fromInt(721), BigInt::fromInt(1440),
    $large, $large->neg(), $large->add(BigInt::fromInt(720)),
];
foreach ($probes as $value) {
    $oneBased = $value->sub(BigInt::one())->modSmall(720) + 1;
    if ($legacy->oneBasedRank($value) !== $oneBased) {
        echo "RALAT_RANK_BALUT\n";
        $unexpected++;
    }
    try {
        $got = $kernel->legacyBowlOrder($value);
        if ($oneBased === 720
            || $got !== $zeroUnrank->oldPermutationUnrank0($oneBased)
            || $got === $oracle->bowlOrderFromDrop($value)) {
            echo "RALAT_PETA_BALUT rank={$oneBased}\n";
            $unexpected++;
        }
    } catch (InvalidArgumentException $error) {
        if ($oneBased !== 720 || $error->getMessage() !== 'PERMUTATION_RANK_ZERO_RANGE') {
            echo "RALAT_BALUT_TIDAK_SEPADAN\n";
            $unexpected++;
        }
    }
}
// Bukti menggunakan 46 titisan terlihat yang dihasilkan oleh Stage 15.
$foundation = NormativeMath::FOUNDATION_DAY;
$visible = $kernel->visibleDrops($foundation, $foundation);
if (array_keys($visible) !== range(1, 46)) {
    echo "RALAT_BENTUK_VISIBLE\n";
    $unexpected++;
} else {
    foreach ($visible as $i => $drop) {
        $rank = $legacy->oneBasedRank($drop);
        try {
            $actual = $kernel->legacyBowlOrder($drop);
            if ($rank === 720 || $actual === $oracle->bowlOrderFromDrop($drop)) {
                echo "RALAT_VISIBLE i={$i}\n";
                $unexpected++;
            }
        } catch (InvalidArgumentException $error) {
            if ($rank !== 720 || $error->getMessage() !== 'PERMUTATION_RANK_ZERO_RANGE') {
                echo "RALAT_VISIBLE_720 i={$i}\n";
                $unexpected++;
            }
        }
        $sampled++;
    }
}
$source = (string)file_get_contents(dirname(__DIR__) . '/src/Legacy/LegacyBowlPermutation.php');
if (!str_contains($source, '$this->unrank->oldPermutationUnrank0($oneBased)')
    || str_contains($source, '$oneBased - 1')) {
    echo "RALAT_PARUT_DIPADAM\n";
    $unexpected++;
}
if ($wrong !== 719 || $outOfRange !== 1 || $rawCorrect !== 720
    || $sampled !== 46 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH salah={$wrong} luar={$outOfRange} fungsi_sifar={$rawCorrect} titisan={$sampled} lain={$unexpected}\n";
    exit(2);
}
echo "ORDINAL1_MISALIGNED rank=1\n";
echo "RANK720_REJECTED rank=720\n";
echo "CHECK_VISIBLE46 titisan=46\n";
echo "KEPUTUSAN MERAH_DIJANGKA salah=719 luar=1 jumlah=720 fungsi_sifar=720 titisan=46 lain=0\n";
exit(1);
