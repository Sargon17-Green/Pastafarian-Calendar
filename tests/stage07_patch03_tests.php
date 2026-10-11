<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyDistance;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Patches\DistanceCountPatch03;

function sahJarak(bool $condition, string $reason): void
{
    if (!$condition) {
        throw new RuntimeException($reason);
    }
}

$kernel = new BootstrapKernel();
$legacy = new LegacyDistance();
$patch = new DistanceCountPatch03($legacy);
$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$cases = 0;
$oracleCases = 0;
$largeCases = 0;
$diagonal = 0;
$forward = 0;
$backward = 0;
$symmetric = 0;
$shifted = 0;
$detours = 0;
$historicalMatches = 0;

$run = static function(int $c, int $t, string $label, bool $extreme = false) use (
    $kernel, $legacy, $patch,
    &$cases, &$oracleCases, &$largeCases, &$diagonal,
    &$forward, &$backward, &$symmetric, &$detours, &$historicalMatches
): void {
    $old = $legacy->oldDistance($c, $t);
    $fromLegacyWrapper = $legacy->calculateWithoutPatch($c, $t);
    $direct = $patch->distanceCountPatch03($c, $t);
    $actual = $kernel->distance($c, $t);
    $inverse = $kernel->distance($t, $c);
    $chronological = BigInt::fromInt($t)->sub(BigInt::fromInt($c))->abs();
    $correct = $chronological->add(BigInt::one());
    $expected = $extreme ? $correct : NormativeMath::workCounts($c, $t)['distance'];
    $fromTags = $kernel->dayCount($c)->sub($kernel->dayCount($t))->abs();
    $needsDetour = !$old->equals($chronological);

    sahJarak($expected->equals($correct), 'RUJUKAN_' . $label);
    sahJarak($old->equals($fromLegacyWrapper) && $old->equals($fromTags), 'PARUT_TAG_' . $label);
    sahJarak($actual->equals($expected) && $actual->equals($direct), 'NORMATIF_' . $label);
    sahJarak($actual->equals($chronological->add(BigInt::one())), 'LENCONGAN_' . $label);
    sahJarak($actual->compare(BigInt::one()) >= 0, 'BATAS_' . $label);
    sahJarak($inverse->equals($actual), 'SIMETRI_' . $label);
    sahJarak($kernel->distance($c, $t)->equals($actual), 'ULANGAN_' . $label);
    sahJarak((new BootstrapKernel())->distance($c, $t)->equals($actual), 'PEMILIKAN_STATE_' . $label);

    if ($needsDetour) {
        $detours++;
        sahJarak(!$old->equals($chronological), 'CABANG_LENCUNG_' . $label);
    } else {
        $historicalMatches++;
        sahJarak($old->equals($chronological), 'CABANG_SEPADAN_' . $label);
    }
    if ($c === $t) {
        sahJarak($old->isZero() && $actual->equals(BigInt::one()), 'HARI_SAMA_' . $label);
        $diagonal++;
    } elseif ($c < $t) {
        $forward++;
    } else {
        $backward++;
    }
    $symmetric++;
    $cases++;
    if ($extreme) {
        $largeCases++;
    } else {
        $oracleCases++;
    }
};

for ($a = -63; $a <= 63; $a++) {
    for ($b = -63; $b <= 63; $b++) {
        $run($foundation + $a, $foundation + $b, "matriks_{$a}_{$b}");
    }
}
$special = [
    ['sifar_sama', 0, 0], ['sifar_depan', 0, 1], ['sifar_belakang', 1, 0],
    ['asas_ke_loh', $foundation, $tablets], ['loh_ke_asas', $tablets, $foundation],
    ['loh_sama', $tablets, $tablets], ['rentas_positif', -1000000000, 1000000000],
    ['rentas_negatif', 1000000000, -1000000000],
    ['sama_negatif', -123456789, -123456789], ['sama_positif', 123456789, 123456789],
    ['positif_panjang', -2000000000, 2000000000],
    ['negatif_panjang', 2000000000, -2000000000],
    ['jiran_sebelum', $foundation - 1, $foundation],
    ['jiran_selepas', $foundation, $foundation + 1],
    ['ruang_terakhir', 1000000000, 1000000001],
];
foreach ($special as [$name, $c, $t]) {
    $run($c, $t, $name);
}
for ($i = 0; $i < 256; $i++) {
    $c = $foundation + ($i * 17293) - 2200000;
    $t = $foundation - ($i * 7919) + 500000;
    $run($c, $t, "serakan_depan_{$i}");
    $run($t, $c, "serakan_belakang_{$i}");
}
$extremes = [
    ['min_max', PHP_INT_MIN, PHP_INT_MAX], ['max_min', PHP_INT_MAX, PHP_INT_MIN],
    ['min_sama', PHP_INT_MIN, PHP_INT_MIN], ['max_sama', PHP_INT_MAX, PHP_INT_MAX],
    ['min_jiran', PHP_INT_MIN, PHP_INT_MIN + 1],
    ['min_jiran_balik', PHP_INT_MIN + 1, PHP_INT_MIN],
    ['max_jiran', PHP_INT_MAX - 1, PHP_INT_MAX],
    ['max_jiran_balik', PHP_INT_MAX, PHP_INT_MAX - 1],
    ['min_ke_asas', PHP_INT_MIN, $foundation], ['asas_ke_min', $foundation, PHP_INT_MIN],
    ['max_ke_asas', PHP_INT_MAX, $foundation], ['asas_ke_max', $foundation, PHP_INT_MAX],
];
foreach ($extremes as [$name, $c, $t]) {
    $run($c, $t, $name, true);
}

for ($i = -128; $i <= 128; $i++) {
    $c = $foundation + $i;
    $t = $foundation + 3 * $i + 11;
    $expected = $kernel->distance($c, $t);
    foreach ([-1000, -17, 0, 17, 1000] as $shift) {
        sahJarak($kernel->distance($c + $shift, $t + $shift)->equals($expected), 'ANJAKAN_' . $i . '_' . $shift);
        $shifted++;
    }
}
for ($i = 0; $i < 200; $i++) {
    $a = $foundation - 1000 + $i;
    $b = $a + 1 + ($i % 31);
    $c = $b + 1 + ($i % 29);
    $ac = $kernel->distance($a, $c);
    $ab = $kernel->distance($a, $b);
    $bc = $kernel->distance($b, $c);
    sahJarak($ac->equals($ab->add($bc)->sub(BigInt::one())), 'RANTAI_' . $i);
}

sahJarak($kernel->dayCount($foundation)->equals(BigInt::one()), 'PATCH_02_KEKAL');
sahJarak($kernel->dayCount($foundation + 1)->equals(BigInt::fromInt(3)), 'PATCH_02_SELEPAS');
foreach ([NormativeMath::m(), NormativeMath::m()->mulSmall(2), BigInt::one()] as $value) {
    sahJarak($kernel->save($value)->equals(NormativeMath::save($value)), 'PATCH_01_KEKAL');
}
sahJarak($kernel->probe($foundation, $foundation)['status'] === 'READY', 'BOOTSTRAP_KEKAL');
$root = dirname(__DIR__) . '/src';
$legacySource = (string)file_get_contents($root . '/Legacy/LegacyDistance.php');
$patchSource = (string)file_get_contents($root . '/Patches/DistanceCountPatch03.php');
$kernelSource = (string)file_get_contents($root . '/BootstrapKernel.php');
sahJarak(str_contains($legacySource, '$actionTag->sub($targetTag)->abs()'), 'PARUT_ASAL_KEKAL');
sahJarak(str_contains($patchSource, 'if (!$distanceByTags->equals($chronological))'), 'CABANG_TAMPALAN_WUJUD');
sahJarak(str_contains($kernelSource, "dispatch('DISTANCE_PATCH_03', " . '$context)'), 'DISPATCH_PRODUKSI');
sahJarak(str_contains($kernelSource, "register('DISTANCE_LEGACY'"), 'DISPATCH_WARISAN');
$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS));
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $source = (string)file_get_contents($file->getPathname());
    sahJarak(!str_contains($source, 'NormativeMath'), 'ORACLE_DI_PRODUKSI');
    sahJarak(!str_contains($source, 'mutateStonesWrong'), 'PENEMUAN_04_TIDAK_DIBENARKAN');
}

sahJarak($cases === 16668 && $oracleCases === 16656 && $largeCases === 12, 'BILANGAN_KES');
sahJarak($symmetric === $cases && $shifted === 1285, 'LIPUTAN_INVARIAN');
sahJarak($detours === 16450 && $historicalMatches === 218, 'LIPUTAN_CABANG');
sahJarak($diagonal >= 127 && $forward >= 100 && $backward >= 100, 'LIPUTAN_ARAH');
echo "LULUS Stage 7 PATCH 03 kes={$cases} oracle={$oracleCases} tepi={$largeCases} simetri={$symmetric} anjakan={$shifted} lencongan={$detours} sepadan_legacy={$historicalMatches}\n";
