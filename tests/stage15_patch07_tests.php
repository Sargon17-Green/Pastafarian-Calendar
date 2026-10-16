<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyHiddenBackward;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Legacy\LegacyVisibleGrind;
use Pastafari\Stage01\Legacy\LegacyVisiblePrior;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\GrindTablePatch07;
use Pastafari\Stage01\Patches\HiddenNearnessPatch05;
use Pastafari\Stage01\Patches\PriorAccessPatch06;
use Pastafari\Stage01\Patches\SavePatch01;

function sahKisar(bool $ok, string $code): void
{
    if (!$ok) throw new RuntimeException($code);
}

$save = new SavePatch01(new LegacyRemainder());
$hiddenLegacy = new LegacyHiddenBackward($save);
$prior = new PriorAccessPatch06(
    new LegacyVisiblePrior(), new HiddenNearnessPatch05($hiddenLegacy)
);
$patch = new GrindTablePatch07($save, $prior);
$legacy = new LegacyVisibleGrind($save, $prior);
$kernel = new BootstrapKernel();
$oracle = new NormativeSauce();
$stones = $oracle->buildStones();

$oldRows = LegacyVisibleGrind::legacyGrindRows();
$rows = GrindTablePatch07::rowsWithSentinel();
sahKisar(array_keys($oldRows) === range(0, 10), 'INDEKS_LEGACY');
sahKisar(array_keys($rows) === range(0, 11), 'INDEKS_SENTINEL');
sahKisar($rows[0] === [0,0,0,0,'none'], 'KANDUNGAN_SENTINEL');
sahKisar(count($oldRows) === 11 && count($rows) === 12, 'BILANGAN_BARIS');
for ($g = 1; $g <= 11; $g++) {
    sahKisar($rows[$g] === $oldRows[$g - 1], 'TURUTAN_' . $g);
    sahKisar($patch->grindPatch($g) === $oldRows[$g - 1], 'LEGACY_DIBALUT_' . $g);
}
sahKisar($legacy->legacyRowAt(1) === $oldRows[1], 'PARUT_BARIS_PERTAMA');
sahKisar($legacy->legacyRowAt(11) === $oldRows[0], 'PARUT_BARIS_TERAKHIR');
foreach ([0,12] as $bad) {
    try {
        $patch->grindPatch($bad);
        throw new RuntimeException('JULAT_DITERIMA_' . $bad);
    } catch (InvalidArgumentException $error) {
        sahKisar($error->getMessage() === 'VISIBLE_GRIND_RANGE', 'JULAT_GAGAL_' . $bad);
    }
}

$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$cases = [
    ['asas_sama', $foundation, $foundation],
    ['asas_depan', $foundation, $foundation + 1],
    ['asas_belakang', $foundation + 1, $foundation],
    ['loh_sama', $tablets, $tablets],
    ['loh_depan', $tablets, $tablets + 17],
    ['sifar_sama', 0, 0],
    ['sifar_lintas', -10, 30],
    ['jauh_balik', 10000000, -10000000],
];
$rowsChecked = 0;
$components = 0;
$historicalDifferent = 0;
$repeated = 0;
foreach ($cases as [$name,$c,$t]) {
    $counts = NormativeMath::workCounts($c, $t);
    $hidden = $oracle->buildHiddenDrops($counts, $stones);
    $expected = $oracle->buildVisibleDrops($counts, $stones, $hidden);
    $production = $kernel->visibleDrops($c, $t);
    sahKisar(array_keys($expected) === range(1,46)
        && array_keys($production) === range(1,46), 'BENTUK_' . $name);
    if (in_array($name, ['asas_sama','loh_depan','jauh_balik'], true)) {
        $wrong = $kernel->visibleDropsLegacy($c, $t);
        sahKisar(array_keys($wrong) === range(1,46), 'WARISAN_BENTUK_' . $name);
    }
    if ($name === 'asas_sama') {
        $stored = $hiddenLegacy->buildStoredBackward($counts, $kernel->stones());
        $direct = $patch->buildVisible($counts, $kernel->stones(), $stored);
        $again = $kernel->visibleDrops($c, $t);
        $other = (new BootstrapKernel())->visibleDrops($c, $t);
    }
    for ($i=1; $i<=46; $i++) {
        $got = $production[$i];
        sahKisar($got instanceof BigInt && $expected[$i] instanceof BigInt, 'JENIS_' . $name . '_' . $i);
        sahKisar($got->equals($expected[$i]), 'NORMATIF_' . $name . '_' . $i);
        sahKisar($got->compare(BigInt::one())>=0 && $got->compare(NormativeMath::m())<=0, 'SAVE_' . $name . '_' . $i);
        if ($name === 'asas_sama') {
            sahKisar($got->equals($direct[$i])
                && $got->equals($again[$i])
                && $got->equals($other[$i]), 'PEMILIKAN_' . $i);
            $repeated++;
        }
        if (isset($wrong)) {
            sahKisar(!$got->equals($wrong[$i]), 'PARUT_' . $name . '_' . $i);
            $historicalDifferent++;
        }
        $components++;
    }
    unset($wrong);
    $rowsChecked++;
}
sahKisar($rowsChecked === 8 && $components === 368
    && $historicalDifferent === 138 && $repeated === 46, 'LIPUTAN_UTAMA');

// Ujian sintetik memastikan sentinel tidak menggantikan mana-mana baris nyata.
$synthetic = 0;
for ($sample=1; $sample<=128; $sample++) {
    $independent = GrindTablePatch07::rowsWithSentinel();
    $independent[0] = [0,0,0,0,'none'];
    foreach (range(1,11) as $g) {
        sahKisar($patch->grindPatch($g) === $independent[$g], 'SINTETIK_' . $sample . '_' . $g);
        $synthetic++;
    }
}
sahKisar($synthetic === 1408, 'JUMLAH_SINTETIK');

$oldSource = (string)file_get_contents(dirname(__DIR__) . '/src/Legacy/LegacyVisibleGrind.php');
$patchSource = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/GrindTablePatch07.php');
$kernelSource = (string)file_get_contents(dirname(__DIR__) . '/src/BootstrapKernel.php');
sahKisar(str_contains($oldSource, '$this->rows[$grind] ?? $this->rows[0]'), 'SEJARAH_TIDAK_DIPADAM');
sahKisar(str_contains($patchSource, 'LegacyVisibleGrind::legacyGrindRows()'), 'ASAL_BARIS');
sahKisar(str_contains($patchSource, '$index + 1'), 'PERALIHAN_INDEKS');
sahKisar(str_contains($patchSource, '$this->legacyWithSentinel->legacyRowAt($grind)'), 'PEMBACA_SEBENAR');
sahKisar(str_contains($kernelSource, "dispatch('VISIBLE_GRIND_LEGACY', " . '$context)'), 'PENGHALA_SEJARAH');
sahKisar(str_contains($kernelSource, "dispatch('VISIBLE_GRIND_PATCH_07', " . '$context)'), 'PENGHALA_BARU');
sahKisar($kernel->distance($foundation,$foundation)->equals(BigInt::one()), 'JARAK_KEKAL');
sahKisar($kernel->stones()[2]['b']->equals($stones[2]['b']), 'BATU_KEKAL');
echo "LULUS Stage 15 PATCH 07 kes={$rowsChecked} komponen={$components} parut={$historicalDifferent} ulang={$repeated} baris_sintetik={$synthetic}\n";
