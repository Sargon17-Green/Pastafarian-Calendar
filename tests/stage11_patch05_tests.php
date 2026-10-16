<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyHiddenBackward;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\HiddenNearnessPatch05;
use Pastafari\Stage01\Patches\SavePatch01;

function sahTitis(bool $condition, string $code): void
{
    if (!$condition) {
        throw new RuntimeException($code);
    }
}

$legacy = new LegacyHiddenBackward(new SavePatch01(new LegacyRemainder()));
$patch = new HiddenNearnessPatch05($legacy);
$normative = new NormativeSauce();
$stones = $normative->buildStones();
$kernel = new BootstrapKernel();
$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$keys = range(1, 7);
$cases = [
    ['asas_sama', $foundation, $foundation],
    ['asas_depan', $foundation, $foundation + 1],
    ['asas_belakang', $foundation + 1, $foundation],
    ['asas_lintas', $foundation - 20, $foundation + 40],
    ['loh_sama', $tablets, $tablets],
    ['loh_depan', $tablets, $tablets + 3],
    ['loh_belakang', $tablets + 3, $tablets],
    ['sifar_sama', 0, 0],
    ['sifar_depan', 0, 1],
    ['sifar_belakang', 1, 0],
    ['jauh_depan', -100000000, 100000000],
    ['jauh_belakang', 100000000, -100000000],
];
for ($j = -12; $j <= 12; $j++) {
    $c = $foundation + ($j * 2027);
    $t = $foundation + ($j * 3451) + 791;
    $cases[] = ["sebaran_{$j}", $c, $t];
}
$rows = 0;
$components = 0;
$legacyDifferent = 0;
$legacySame = 0;
$negativeCases = 0;
$allSame = 0;
$eachCaseDiff = 0;

foreach ($cases as [$name, $c, $t]) {
    $counts = NormativeMath::workCounts($c, $t);
    $correct = $normative->buildHiddenDrops($counts, $stones);
    $stored = $legacy->buildStoredBackward($counts, $kernel->stones());
    $legacyOutput = $legacy->revealWrong($stored);
    $direct = $patch->revealByNearness($stored);
    $actual = $kernel->hiddenDrops($c, $t);
    $repeat = $kernel->hiddenDrops($c, $t);
    $other = (new BootstrapKernel())->hiddenDrops($c, $t);
    sahTitis(array_keys($stored) === $keys, 'STORE_KEYS_' . $name);
    sahTitis(array_keys($actual) === $keys, 'OUTPUT_KEYS_' . $name);
    $differentInRow = 0;
    foreach ($keys as $k) {
        $value = $correct[$k];
        $got = $actual[$k];
        sahTitis($value instanceof BigInt && $got instanceof BigInt, 'TYPE_' . $name . '_' . $k);
        sahTitis($got->equals($value), 'NORMATIF_' . $name . '_' . $k);
        sahTitis($got->equals($direct[$k]), 'TAMPALAN_' . $name . '_' . $k);
        sahTitis($got->equals($repeat[$k]) && $got->equals($other[$k]), 'MILIK_STATE_' . $name . '_' . $k);
        sahTitis($got->equals($patch->hiddenByNearness($stored, $k)), 'AKSES_' . $name . '_' . $k);
        sahTitis($got->equals($stored[8 - $k]), 'INDEKS_' . $name . '_' . $k);
        sahTitis($got->compare(BigInt::one()) >= 0 && $got->compare(NormativeMath::m()) <= 0, 'SIMPAN_' . $name . '_' . $k);
        if (!$legacyOutput[$k]->equals($got)) {
            $legacyDifferent++;
            $differentInRow++;
        } else {
            $legacySame++;
            sahTitis($k === 4, 'LEGACY_DIAM_' . $name . '_' . $k);
        }
        $components++;
    }
    sahTitis($differentInRow === 6, 'PARUT_KEKAL_' . $name);
    $eachCaseDiff++;
    $rows++;
}
sahTitis($rows === 37 && $components === 259, 'LIPUTAN_UTAMA');
sahTitis($legacyDifferent === 222 && $legacySame === 37, 'PARUT_LENGKAP');

// Mencari setiap bentuk urutan stor secara bebas dengan nilai sintetik.
// Semakan ini memastikan pemetaan, bukannya pembalikan stor dalaman.
for ($sample = 0; $sample < 128; $sample++) {
    $stored = [];
    for ($k = 1; $k <= 7; $k++) {
        $stored[$k] = BigInt::fromString((string)(($sample + 3) * 100000 + $k * 1231));
    }
    $before = $stored;
    $revealed = $patch->revealByNearness($stored);
    sahTitis(array_keys($stored) === $keys && array_keys($revealed) === $keys, 'BENTUK_SINTETIK_' . $sample);
    for ($k = 1; $k <= 7; $k++) {
        sahTitis($revealed[$k]->equals($before[8 - $k]), 'SLOT_SINTETIK_' . $sample . '_' . $k);
        sahTitis($stored[$k]->equals($before[$k]), 'TANPA_SUSUN_SEMULA_' . $sample . '_' . $k);
        sahTitis($legacy->wrongNearness($stored, $k)->equals($before[$k]), 'WARISAN_SINTETIK_' . $sample . '_' . $k);
        $allSame++;
    }
}
sahTitis($allSame === 896 && $eachCaseDiff === 37, 'BILANGAN_SINTETIK');

// Pastikan had indeks tidak membenarkan kebocoran atau pembetulan tersembunyi.
$example = [1=>BigInt::fromInt(7),2=>BigInt::fromInt(6),3=>BigInt::fromInt(5),4=>BigInt::fromInt(4),5=>BigInt::fromInt(3),6=>BigInt::fromInt(2),7=>BigInt::one()];
foreach ([-4, 0, 8, 100] as $invalid) {
    try {
        $patch->hiddenByNearness($example, $invalid);
        throw new RuntimeException('INDEKS_DITERIMA_' . $invalid);
    } catch (InvalidArgumentException $e) {
        sahTitis($e->getMessage() === 'HIDDEN_NEARNESS_RANGE', 'HAD_INDeks_' . $invalid);
        $negativeCases++;
    }
}
$broken = $example;
unset($broken[2]);
try {
    $patch->hiddenByNearness($broken, 6);
    throw new RuntimeException('SLOT_HILANG_DITERIMA');
} catch (InvalidArgumentException $e) {
    sahTitis($e->getMessage() === 'HIDDEN_SLOT_MISSING', 'PENOLAKAN_SLOT');
    $negativeCases++;
}
sahTitis($negativeCases === 5, 'UJI_NEGATIF');

// Kod sejarah mesti kekal dan benar-benar dibaca dari dalam pembalut.
$root = dirname(__DIR__) . '/src';
$patchSource = (string)file_get_contents($root . '/Patches/HiddenNearnessPatch05.php');
$legacySource = (string)file_get_contents($root . '/Legacy/LegacyHiddenBackward.php');
$kernelSource = (string)file_get_contents($root . '/BootstrapKernel.php');
sahTitis(str_contains($patchSource, '$this->legacy->wrongNearness($backward, 8 - $k)'), 'WARISAN_DIPANGGIL');
sahTitis(str_contains($legacySource, '$backward[8 - $k] = $x;'), 'SUSUNAN_TERBALIK_KEKAL');
sahTitis(str_contains($legacySource, 'function wrongNearness('), 'AKSES_SALAH_KEKAL');
sahTitis(str_contains($kernelSource, "register('HIDDEN_BACKWARD_LEGACY'"), 'PENGHALA_LAMA_KEKAL');
sahTitis(str_contains($kernelSource, "dispatch('HIDDEN_PATCH_05', " . '$context)'), 'PENGHALA_BAHARU');
foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $source = (string)file_get_contents($file->getPathname());
    sahTitis(!str_contains($source, 'NormativeMath') && !str_contains($source, 'NormativeSauce'), 'ORACLE_DALAM_PRODUKSI');
}

sahTitis($kernel->dayCount($foundation)->equals(BigInt::one()), 'REGRESI_HARI');
sahTitis($kernel->distance($foundation, $foundation)->equals(BigInt::one()), 'REGRESI_JARAK');
sahTitis($kernel->save(NormativeMath::m())->equals(NormativeMath::m()), 'REGRESI_SAVE');
sahTitis($kernel->stones()[2]['b']->equals($stones[2]['b']), 'REGRESI_BATU');
echo "LULUS Stage 11 PATCH 05 pasangan={$rows} komponen={$components} parut={$legacyDifferent} sepadan_legacy={$legacySame} slot_sintetik={$allSame} ralat={$negativeCases}\n";
