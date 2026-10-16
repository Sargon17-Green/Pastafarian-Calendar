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
use Pastafari\Stage01\Patches\HiddenNearnessPatch05;
use Pastafari\Stage01\Patches\PriorAccessPatch06;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Penemuan merah: pembaca g=1..11 menggunakan jadual lama 0..10.
 * Formula titisan dan prior kekal betul; hanya pemilihan baris salah.
 */
$kernel = new BootstrapKernel();
$oracle = new NormativeSauce();
$stones = $oracle->buildStones();
$save = new SavePatch01(new LegacyRemainder());
$hiddenLegacy = new LegacyHiddenBackward($save);
$prior = new PriorAccessPatch06(
    new LegacyVisiblePrior(), new HiddenNearnessPatch05($hiddenLegacy)
);
$legacy = new LegacyVisibleGrind($save, $prior);
$rows = LegacyVisibleGrind::legacyGrindRows();
$unexpected = 0;
$divergences = 0;
$casesChecked = 0;
$positive = 0;

if (array_keys($rows) !== range(0, 10)
    || $legacy->legacyRowAt(1) !== [5, 7, 11, 13, 'b']
    || $legacy->legacyRowAt(10) !== [37, 41, 43, 47, 'w']
    || $legacy->legacyRowAt(11) !== [3, 5, 7, 11, 'w']) {
    echo "RALAT_JADUAL_LAMA\n";
    $unexpected++;
}
foreach ([0, 12] as $bad) {
    try {
        $legacy->legacyRowAt($bad);
        echo "RALAT_JULAT_DITERIMA g={$bad}\n";
        $unexpected++;
    } catch (InvalidArgumentException $e) {
        if ($e->getMessage() !== 'VISIBLE_GRIND_RANGE') {
            echo "RALAT_JULAT g={$bad}\n";
            $unexpected++;
        }
    }
}
$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$cases = [
    ['asas_sama', $foundation, $foundation],
    ['loh_depan', $tablets, $tablets + 17],
    ['jauh_balik', 10000000, -10000000],
];
foreach ($cases as [$name, $c, $t]) {
    $counts = NormativeMath::workCounts($c, $t);
    $hidden = $oracle->buildHiddenDrops($counts, $stones);
    $expected = $oracle->buildVisibleDrops($counts, $stones, $hidden);
    $actual = $kernel->visibleDropsLegacy($c, $t);
    if (array_keys($actual) !== range(1, 46)
        || array_keys($expected) !== range(1, 46)) {
        echo "RALAT_BENTUK kes={$name}\n";
        $unexpected++;
        continue;
    }
    // Pembina lama menghasilkan kerosakan sendiri tanpa bantuan oracle.
    if ($name === 'asas_sama') {
        $backward = $hiddenLegacy->buildStoredBackward($counts, $kernel->stones());
        $direct = $legacy->buildVisibleWrong($counts, $kernel->stones(), $backward);
    }
    foreach (range(1, 46) as $i) {
        if (!$actual[$i] instanceof BigInt
            || !$expected[$i] instanceof BigInt) {
            echo "RALAT_JENIS kes={$name} i={$i}\n";
            $unexpected++;
            continue;
        }
        if ($name === 'asas_sama' && !$actual[$i]->equals($direct[$i])) {
            echo "RALAT_PENGHALA kes={$name} i={$i}\n";
            $unexpected++;
            continue;
        }
        if ($actual[$i]->equals($expected[$i])) {
            echo "RALAT_SEPADAN_TANPA_SEBAB kes={$name} i={$i}\n";
            $unexpected++;
        } else {
            echo "GAGAL_DIJANGKA kes={$name} i={$i}\n";
            $divergences++;
        }
        if ($actual[$i]->compare(BigInt::one()) >= 0
            && $actual[$i]->compare(NormativeMath::m()) <= 0) {
            $positive++;
        } else {
            echo "RALAT_SIMPAN kes={$name} i={$i}\n";
            $unexpected++;
        }
    }
    $casesChecked++;
}
if (!$kernel->dayCount($foundation)->equals(BigInt::one())
    || !$kernel->distance($foundation, $foundation)->equals(BigInt::one())
    || !$kernel->stones()[2]['b']->equals($stones[2]['b'])
    || !$kernel->hiddenDrops($foundation, $foundation)[1]
        ->equals($oracle->buildHiddenDrops(
            NormativeMath::workCounts($foundation, $foundation), $stones
        )[1])) {
    echo "RALAT_REGRESI_LAMA\n";
    $unexpected++;
}
$root = dirname(__DIR__) . '/src';
$legacyText = (string)file_get_contents($root . '/Legacy/LegacyVisibleGrind.php');
$kernelText = (string)file_get_contents($root . '/BootstrapKernel.php');
if (!str_contains($legacyText, '$this->rows[$grind] ?? $this->rows[0]')
    || !str_contains($legacyText, 'function legacyRowAt(')
    || !str_contains($kernelText, "dispatch('VISIBLE_GRIND_LEGACY', " . '$context)')
    || str_contains($legacyText, 'function grindPatch(')) {
    echo "RALAT_SUMBER_SEJARAH\n";
    $unexpected++;
}
if ($divergences !== 138 || $casesChecked !== 3
    || $positive !== 138 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH divergence={$divergences} kes={$casesChecked} julat={$positive} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA divergence=138 kes=3 julat=138 lain=0\n";
exit(1);
