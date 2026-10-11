<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Patches\SavePatch01;
use Pastafari\Stage01\Oracle\NormativeMath;

function sah(bool $condition, string $code): void
{
    if (!$condition) {
        throw new RuntimeException($code);
    }
}

$m = NormativeMath::m();
$legacy = new LegacyRemainder();
$patch = new SavePatch01($legacy);
$kernel = new BootstrapKernel();
$jumlah = 0;
$bilanganNol = 0;

$uji = static function(BigInt $value, string $label) use ($m, $legacy, $patch, $kernel, &$jumlah, &$bilanganNol): void {
    $before = $value->toString();
    $expected = NormativeMath::save($value);
    $actual = $kernel->save($value);
    $old = $legacy->oldRemainder($value);
    $directPatch = $patch->savePatch($value);

    sah($actual->equals($expected), 'SAVE_NORMATIF_' . $label);
    sah($directPatch->equals($actual), 'LAPISAN_PRODUKSI_' . $label);
    sah($old->equals($legacy->calculateWithoutPatch($value)), 'LEGACY_KEKAL_' . $label);
    sah($actual->compare(BigInt::one()) >= 0, 'JULAT_RENDAH_' . $label);
    sah($actual->compare($m) <= 0, 'JULAT_TINGGI_' . $label);
    sah($value->toString() === $before, 'INPUT_TIDAK_BERUBAH_' . $label);

    if ($old->isZero()) {
        $bilanganNol++;
        sah($actual->equals($m), 'TAMPAL_SIFAR_' . $label);
    } else {
        sah($actual->equals($old), 'JANGAN_UBAH_BAKI_' . $label);
    }

    sah($kernel->save($actual)->equals($actual), 'IDEMPOTEN_' . $label);
    sah($kernel->save($value->add($m))->equals($actual), 'PERIODIK_POS_' . $label);
    sah($kernel->save($value->sub($m))->equals($actual), 'PERIODIK_NEG_' . $label);
    sah($kernel->save($value)->equals($actual), 'DETERMINISTIK_' . $label);
    $jumlah++;
};

// 17 kelas gandaan, masing-masing dengan lima jiran pada kedua-dua sisi.
for ($k = -8; $k <= 8; $k++) {
    for ($delta = -2; $delta <= 2; $delta++) {
        $value = $m->mulSmall($k)->add(BigInt::fromInt($delta));
        $uji($value, "k{$k}_d{$delta}");
    }
}

// Nilai yang melebihi 256 bit diuji pada kedua-dua arah.
$huge = BigInt::fromString(str_repeat('314159265358979323846264338327950288419716939937510', 6));
$uji($huge, 'besar_positif');
$uji($huge->neg(), 'besar_negatif');
$uji($huge->mul($m), 'besar_gandaan');
$uji($huge->mul($m)->neg(), 'besar_gandaan_negatif');

// Nilai integer mesin minimum/maksimum, dan panggilan berselang seli.
$uji(BigInt::fromInt(PHP_INT_MIN), 'int_min');
$uji(BigInt::fromInt(PHP_INT_MAX), 'int_max');
$uji($m->mulSmall(3), 'semakan_3M');
$uji(BigInt::one(), 'semakan_1');
$uji($m->mulSmall(3), 'semakan_3M_ulangan');

sah($legacy->oldRemainder($m)->isZero(), 'PARUT_LAMA_M');
sah($legacy->oldRemainder($m->mulSmall(2))->isZero(), 'PARUT_LAMA_2M');
sah($legacy->oldRemainder($m->mulSmall(3))->isZero(), 'PARUT_LAMA_3M');
sah($bilanganNol >= 17, 'CAKUPAN_GANDAAN_TIDAK_CUKUP');

// Pastikan tiada pembaikan masa hadapan atau panggilan oracle dalam pengeluaran.
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator(dirname(__DIR__) . '/src', FilesystemIterator::SKIP_DOTS)
);
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') {
        continue;
    }
    $contents = (string)file_get_contents($file->getPathname());
    sah(!str_contains($contents, 'NormativeMath'), 'ORACLE_DALAM_PRODUKSI');
    // Parut dan tampalan kedua dibenarkan; penemuan ketiga belum dibenarkan.
    sah(!str_contains($contents, 'oldDistance'), 'PENEMUAN_03_TERLALU_AWAL');
}

echo "LULUS Stage 3 PATCH 01 kes={$jumlah} baki_sifar={$bilanganNol} warisan=3\n";
