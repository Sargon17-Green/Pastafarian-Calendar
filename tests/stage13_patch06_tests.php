<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyHiddenBackward;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Legacy\LegacyVisiblePrior;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\HiddenNearnessPatch05;
use Pastafari\Stage01\Patches\PriorAccessPatch06;
use Pastafari\Stage01\Patches\SavePatch01;

function sahPrior(bool $ok, string $label): void {
    if (!$ok) throw new RuntimeException($label);
}

$kernel = new BootstrapKernel();
$legacyPrior = new LegacyVisiblePrior();
$legacyHidden = new LegacyHiddenBackward(new SavePatch01(new LegacyRemainder()));
$patch05 = new HiddenNearnessPatch05($legacyHidden);
$patch06 = new PriorAccessPatch06($legacyPrior, $patch05);
$oracle = new NormativeSauce();
$stones = $oracle->buildStones();
$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$dates = [
    ['asas_sama', $foundation, $foundation],
    ['asas_depan', $foundation, $foundation + 3],
    ['asas_belakang', $foundation + 3, $foundation],
    ['loh_sama', $tablets, $tablets],
    ['sifar_lintas', -10, 30],
    ['jauh_balik', 100000000, -100000000],
];
$positive = 0;
$negative = 0;
$hiddenOracle = 0;
$oldNull = 0;
$identical = 0;
foreach ($dates as $n => [$label, $c, $t]) {
    $counts = NormativeMath::workCounts($c, $t);
    $expectedHidden = $oracle->buildHiddenDrops($counts, $stones);
    $stored = $legacyHidden->buildStoredBackward($counts, $kernel->stones());
    $beforeHidden = $stored;
    $near = $kernel->hiddenDrops($c, $t);
    for ($k = 1; $k <= 7; $k++) {
        sahPrior($patch05->hiddenByNearness($stored, $k)->equals($expectedHidden[$k]), 'HIDDEN_KEKAL_' . $label);
        sahPrior($near[$k]->equals($expectedHidden[$k]), 'HIDDEN_PRODUKSI_' . $label);
        $hiddenOracle++;
    }
    $visible = [];
    for ($i = 1; $i <= 46; $i++) {
        $visible[$i] = BigInt::fromInt(($n + 1) * 901003 + $i * 137);
    }
    $beforeVisible = $visible;
    $otherKernel = new BootstrapKernel();
    for ($i = 1; $i <= 46; $i++) {
        foreach ([1, 3, 7] as $back) {
            $slot = $i - $back;
            $actual = $kernel->prior($visible, $stored, $i, $back);
            $direct = $patch06->priorPatch($visible, $stored, $i, $back);
            $again = $kernel->prior($visible, $stored, $i, $back);
            $another = $otherKernel->prior($visible, $stored, $i, $back);
            sahPrior($actual instanceof BigInt && $actual->equals($direct), 'LALUAN_' . $label . $i . '_' . $back);
            sahPrior($actual->equals($again) && $actual->equals($another), 'PEMILIKAN_' . $label . $i . '_' . $back);
            if ($slot >= 1) {
                $old = $legacyPrior->legacyPrior($visible, $i, $back);
                sahPrior($old instanceof BigInt && $actual->equals($old), 'SEJARAH_POSITIF_' . $label);
                sahPrior($actual->equals($visible[$slot]), 'POSITIF_' . $label);
                $positive++;
                $identical++;
            } else {
                $k = 1 - $slot;
                sahPrior($legacyPrior->legacyPrior($visible, $i, $back) === null, 'PARUT_SALAH_KEKAL_' . $label);
                sahPrior($actual->equals($expectedHidden[$k]), 'ORACLE_NEGATIF_' . $label . $i . '_' . $back);
                sahPrior($actual->equals($patch05->hiddenByNearness($stored, $k)), 'TAMPALAN_05_' . $label);
                $negative++;
                $oldNull++;
            }
        }
    }
    sahPrior($visible === $beforeVisible && $stored === $beforeHidden, 'INPUT_TIDAK_BERUBAH_' . $label);
}
sahPrior($positive === 762 && $negative === 66 && $hiddenOracle === 42 && $oldNull === 66, 'BILANGAN_ASAS');

// Pemilikan dan pemetaan semantik dengan 128 stor sintetik yang berbeza.
$synthetic = 0;
for ($sample = 1; $sample <= 128; $sample++) {
    $hidden = [];
    $visible = [];
    for ($slot = 1; $slot <= 7; $slot++) {
        $hidden[$slot] = BigInt::fromInt($sample * 10000 + $slot * 37);
    }
    for ($slot = 1; $slot <= 46; $slot++) {
        $visible[$slot] = BigInt::fromInt($sample * 100000 + $slot * 61);
    }
    $beforeHidden = $hidden;
    $beforeVisible = $visible;
    for ($i = 1; $i <= 7; $i++) {
        foreach ([1, 3, 7] as $back) {
            $slot = $i - $back;
            $got = $patch06->priorPatch($visible, $hidden, $i, $back);
            $expected = $slot >= 1 ? $visible[$slot] : $hidden[8 - (1 - $slot)];
            sahPrior($got->equals($expected), 'SINTETIK_' . $sample . '_' . $i . '_' . $back);
            $synthetic++;
        }
    }
    sahPrior($visible === $beforeVisible && $hidden === $beforeHidden, 'TANPA_MUTASI_' . $sample);
}
sahPrior($synthetic === 2688, 'LIPUTAN_SINTETIK');

// Input tidak sah ditolak tanpa mengubah stor atau menukar hasil kepada 0.
$hidden = [];
$visible = [];
for ($i = 1; $i <= 7; $i++) $hidden[$i] = BigInt::fromInt($i * 11);
for ($i = 1; $i <= 46; $i++) $visible[$i] = BigInt::fromInt($i * 13);
$errors = 0;
$reject = static function(array $v, array $h, int $i, int $back, string $reason) use ($patch06, &$errors): void {
    try {
        $patch06->priorPatch($v, $h, $i, $back);
        throw new RuntimeException('DITERIMA_TIDAK_SAH_' . $reason);
    } catch (InvalidArgumentException $e) {
        sahPrior($e->getMessage() === $reason, 'RALAT_SEBAB_' . $reason);
        $errors++;
    }
};
$reject($visible, $hidden, 0, 1, 'PRIOR_INDEX_RANGE');
$reject($visible, $hidden, 47, 1, 'PRIOR_INDEX_RANGE');
$reject($visible, $hidden, 1, 0, 'PRIOR_BACK_RANGE');
$reject($visible, $hidden, 1, -1, 'PRIOR_BACK_RANGE');
$reject($visible, $hidden, 1, 8, 'HIDDEN_NEARNESS_RANGE');
$missingVisible = $visible;
unset($missingVisible[3]);
$reject($missingVisible, $hidden, 4, 1, 'PRIOR_VISIBLE_MISSING');
$missingHidden = $hidden;
unset($missingHidden[7]);
$reject($visible, $missingHidden, 1, 1, 'HIDDEN_SLOT_MISSING');
sahPrior($errors === 7, 'NEGATIF_TUJUH');

// Kod sejarah kekal, pengeluaran melalui adapter, dan tiada oracle di src.
$root = dirname(__DIR__) . '/src';
$kernelText = (string)file_get_contents($root . '/BootstrapKernel.php');
$patchText = (string)file_get_contents($root . '/Patches/PriorAccessPatch06.php');
$historyText = (string)file_get_contents($root . '/Legacy/LegacyVisiblePrior.php');
sahPrior(str_contains($patchText, '$this->legacy->legacyPrior($dropStore, $i, $back)'), 'PANGGILAN_LEGACY');
sahPrior(str_contains($patchText, '$this->hidden->hiddenByNearness($legacyHidden, $k)'), 'PEMETAAN_HIDDEN');
sahPrior(str_contains($historyText, 'return $dropStore[$i - $back] ?? null;'), 'PARUT_DIKUNCI');
sahPrior(str_contains($kernelText, "dispatch('PRIOR_PATCH_06', " . '$context)'), 'PENGHALA_BAHARU');
sahPrior(str_contains($kernelText, "dispatch('VISIBLE_PRIOR_LEGACY', " . '$context)'), 'PENGHALA_LEGACY');
foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $text = (string)file_get_contents($file->getPathname());
    sahPrior(!str_contains($text, 'NormativeMath') && !str_contains($text, 'NormativeSauce'), 'ORACLE_DI_PRODUKSI');
}
sahPrior($kernel->dayCount($foundation)->equals(BigInt::one()), 'HARI_KEKAL');
sahPrior($kernel->distance($foundation, $foundation)->equals(BigInt::one()), 'JARAK_KEKAL');
sahPrior($kernel->stones()[2]['b']->equals($stones[2]['b']), 'BATU_KEKAL');

echo "LULUS Stage 13 PATCH 06 positif={$positive} hidden={$negative} oracle_hidden={$hiddenOracle} sintetik={$synthetic} ralat={$errors}\n";
