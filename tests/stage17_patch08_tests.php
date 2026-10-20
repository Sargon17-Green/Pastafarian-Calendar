<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyBowlPermutation;
use Pastafari\Stage01\Legacy\LegacyPermutationUnrank0;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\PermutationPatch08;

function sahSusunan(bool $ok, string $reason): void
{
    if (!$ok) {
        throw new RuntimeException($reason);
    }
}

$unrank = new LegacyPermutationUnrank0();
$legacy = new LegacyBowlPermutation($unrank);
$patch = new PermutationPatch08($legacy, $unrank);
$kernel = new BootstrapKernel();
$oracle = new NormativeSauce();

$ranks = 0;
$historicalWrong = 0;
$historicalOverflow = 0;
$unique = [];
$again = 0;
foreach (range(1, 720) as $rank) {
    $drop = BigInt::fromInt($rank);
    $expected = $oracle->permutationUnrank1($rank);
    $fixed = $kernel->bowlOrder($drop);
    $direct = $patch->permutationPatch($drop);
    $second = $kernel->bowlOrder($drop);
    $another = (new BootstrapKernel())->bowlOrder($drop);
    sahSusunan($fixed === $expected && $direct === $expected, 'ORACLE_' . $rank);
    sahSusunan($fixed === $second && $fixed === $another, 'DETERMINISME_' . $rank);
    sahSusunan(count($fixed) === 6 && array_keys($fixed) === range(0, 5), 'BENTUK_' . $rank);
    $sorted = $fixed;
    sort($sorted);
    sahSusunan($sorted === [1,2,3,4,5,6], 'ENAM_MANGKUK_' . $rank);
    $signature = implode(',', $fixed);
    sahSusunan(!isset($unique[$signature]), 'DUPLIKAT_' . $rank);
    $unique[$signature] = true;
    $again++;
    if ($rank < 720) {
        $wrong = $legacy->legacyBowlOrderFromDrop($drop);
        $wrongKernel = $kernel->legacyBowlOrder($drop);
        sahSusunan($wrong === $wrongKernel && $wrong !== $expected, 'PARUT_' . $rank);
        $historicalWrong++;
    } else {
        try {
            $legacy->legacyBowlOrderFromDrop($drop);
            throw new RuntimeException('WARISAN_TERIMA_720');
        } catch (InvalidArgumentException $error) {
            sahSusunan($error->getMessage() === 'PERMUTATION_RANK_ZERO_RANGE', 'RALAT_WARISAN_720');
            $historicalOverflow++;
        }
    }
    $ranks++;
}
sahSusunan($ranks === 720 && count($unique) === 720 && $again === 720, 'LIPUTAN_PENUH');
sahSusunan($historicalWrong === 719 && $historicalOverflow === 1, 'WARISAN_KONSISTEN');
sahSusunan($kernel->bowlOrder(BigInt::one()) === [1,2,3,4,5,6], 'PERMUTASI_PERTAMA');
sahSusunan($kernel->bowlOrder(BigInt::fromInt(720)) === [6,5,4,3,2,1], 'PERMUTASI_TERAKHIR');

$big = BigInt::fromString(str_repeat('31415926535897932384626433832795028841971693', 10));
$values = [
    BigInt::zero(), BigInt::fromInt(-1), BigInt::fromInt(-719),
    BigInt::fromInt(-720), BigInt::fromInt(-721),
    BigInt::one(), BigInt::fromInt(720), BigInt::fromInt(721),
    BigInt::fromInt(1440), BigInt::fromInt(1441),
    $big, $big->neg(), $big->add(BigInt::one()), $big->sub(BigInt::one()),
];
$wrapped = 0;
foreach ($values as $value) {
    $fixed = $kernel->bowlOrder($value);
    $expected = $oracle->bowlOrderFromDrop($value);
    sahSusunan($fixed === $expected && $patch->permutationPatch($value) === $expected, 'MODULO_INTEGER_BESAR_' . $wrapped);
    $rank1 = $legacy->oneBasedRank($value);
    sahSusunan($rank1 >= 1 && $rank1 <= 720, 'RANK_JULAT_' . $wrapped);
    $wrapped++;
}
sahSusunan($wrapped === 14, 'LIPUTAN_INTEGER_BESAR');

// Kedua-dua jalan menggunakan 46 titisan visible yang telah diluluskan
// pada Stage 15; sebarang hasil sejarah yang salah tetap dapat diamati.
$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$dates = [
    [$foundation, $foundation],
    [$tablets, $tablets + 17],
    [10000000, -10000000],
];
$visibleCount = 0;
$legacyDifferences = 0;
$legacyExceptions = 0;
foreach ($dates as [$c, $t]) {
    $visible = $kernel->visibleDrops($c, $t);
    sahSusunan(array_keys($visible) === range(1, 46), 'BENTUK_VISIBLE');
    foreach ($visible as $i => $drop) {
        $expected = $oracle->bowlOrderFromDrop($drop);
        $fixed = $kernel->bowlOrder($drop);
        sahSusunan($fixed === $expected, 'VISIBLE_ORACLE_' . $c . '_' . $i);
        try {
            $wrong = $kernel->legacyBowlOrder($drop);
            sahSusunan($wrong !== $fixed, 'LEGACY_DIFFERENCE_' . $c . '_' . $i);
            $legacyDifferences++;
        } catch (InvalidArgumentException $error) {
            sahSusunan($legacy->oneBasedRank($drop) === 720, 'LEGACY_EXCEPTION_RANK_' . $i);
            sahSusunan($error->getMessage() === 'PERMUTATION_RANK_ZERO_RANGE', 'LEGACY_EXCEPTION_TYPE_' . $i);
            $legacyExceptions++;
        }
        $visibleCount++;
    }
}
sahSusunan($visibleCount === 138 && $legacyDifferences + $legacyExceptions === 138, 'LIPUTAN_VISIBLE');

// Nilai sah tidak bergantung pada rekod sejarah tersimpan atau cache.
$patchSource = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/PermutationPatch08.php');
$legacySource = (string)file_get_contents(dirname(__DIR__) . '/src/Legacy/LegacyBowlPermutation.php');
$rawSource = (string)file_get_contents(dirname(__DIR__) . '/src/Legacy/LegacyPermutationUnrank0.php');
$kernelSource = (string)file_get_contents(dirname(__DIR__) . '/src/BootstrapKernel.php');
sahSusunan(str_contains($patchSource, '$this->legacy->legacyBowlOrderFromDrop($drop)'), 'LEGACY_DIPANGGIL');
sahSusunan(str_contains($patchSource, '$rank0 = $rank1 - 1;'), 'PANGKAT_SIFAR');
sahSusunan(str_contains($patchSource, '$this->unrank->oldPermutationUnrank0($rank0)'), 'PEMBACA_DIPANGGIL');
sahSusunan(str_contains($legacySource, '$this->unrank->oldPermutationUnrank0($oneBased)'), 'PARUT_DIKUNCI');
sahSusunan(str_contains($rawSource, 'function oldPermutationUnrank0('), 'PEMBACA_DIKUNCI');
sahSusunan(str_contains($kernelSource, "dispatch('BOWL_PERMUTATION_LEGACY', " . '$context)'), 'DISPATCH_LEGACY');
sahSusunan(str_contains($kernelSource, "dispatch('BOWL_PERMUTATION_PATCH_08', " . '$context)'), 'DISPATCH_PRODUKSI');

$directory = dirname(__DIR__) . '/src';
foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($directory, FilesystemIterator::SKIP_DOTS)) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $content = (string)file_get_contents($file->getPathname());
    sahSusunan(!str_contains($content, 'NormativeMath') && !str_contains($content, 'NormativeSauce'), 'ORACLE_DI_PRODUKSI');
}
sahSusunan($kernel->dayCount($foundation)->equals(BigInt::one()), 'REGRESI_HARI');
sahSusunan($kernel->distance($foundation, $foundation)->equals(BigInt::one()), 'REGRESI_JARAK');
echo "LULUS Stage 17 PATCH 08 pangkat={$ranks} unik=" . count($unique)
    . " parut={$historicalWrong} pengecualian={$historicalOverflow}"
    . " integer_besar={$wrapped} visible={$visibleCount}"
    . " legacy_visible={$legacyDifferences} legacy_exception={$legacyExceptions}\n";
