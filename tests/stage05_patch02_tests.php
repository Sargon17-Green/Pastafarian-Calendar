<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyDayTag;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Patches\FoundationScarPatch02;

function sahHari(bool $condition, string $code): void
{
    if (!$condition) {
        throw new RuntimeException($code);
    }
}

$foundation = NormativeMath::FOUNDATION_DAY;
$kernel = new BootstrapKernel();
$legacy = new LegacyDayTag();
$patch = new FoundationScarPatch02($legacy);
$cases = 0;
$before = 0;
$onOrAfter = 0;
$scarTriggered = 0;

// Pengesahan terhadap oracle pada julat yang selamat untuk aritmetik int.
$uji = static function(int $day, string $label) use (
    $foundation, $kernel, $legacy, $patch, &$cases, &$before, &$onOrAfter, &$scarTriggered
): void {
    $expected = NormativeMath::dayCount($day);
    $actual = $kernel->dayCount($day);
    $direct = $patch->dayTagWithFoundationScar($day);
    $old = $legacy->oldDayTag($day);
    $former = $legacy->calculateWithoutPatch($day);
    $diff = BigInt::fromInt($day)->sub(BigInt::fromInt($foundation))->abs()->mulSmall(2);
    sahHari($old->equals($former) && $old->equals($diff), 'WARISAN_TETAP_' . $label);
    sahHari($actual->equals($expected), 'HARI_NORMATIF_' . $label);
    sahHari($actual->equals($direct), 'LALUAN_PATCH_' . $label);
    sahHari($actual->compare(BigInt::one()) >= 0, 'JULAT_HARI_' . $label);
    sahHari($actual->equals($kernel->dayCount($day)), 'DETERMINISTIK_' . $label);
    sahHari($actual->equals($patch->dayTagWithFoundationScar($day)), 'TAMPALAN_DETERMINISTIK_' . $label);

    $required = $day >= $foundation ? $old->add(BigInt::one()) : $old;
    sahHari($actual->equals($required), 'TAMBAHAN_TEPAT_' . $label);
    if ($day >= $foundation) {
        sahHari($old->modSmall(2) === 0 && $actual->modSmall(2) === 1, 'KEGANJILAN_' . $label);
        $onOrAfter++;
        if ($day === $foundation) {
            sahHari($old->isZero() && $actual->equals(BigInt::one()), 'PARUT_ASAS');
            $scarTriggered++;
        }
    } else {
        sahHari($actual->equals($old) && $actual->modSmall(2) === 0, 'SEBELUM_ASAS_' . $label);
        $before++;
    }
    $cases++;
};

// Pengujian berterusan merentasi sempadan, termasuk 129 kes penemuan terdahulu.
for ($offset = -2048; $offset <= 2048; $offset++) {
    $uji($foundation + $offset, "sempadan_{$offset}");
}

// Sampel deterministik tersebar pada paksi hari, tanpa nombor rawak mesin.
for ($i = 1; $i <= 256; $i++) {
    $jump = ($i * 104729) + (($i * $i) % 997);
    $uji($foundation + $jump, "depan_{$i}");
    $uji($foundation - $jump, "belakang_{$i}");
}

foreach ([0, 1, -1, 1000000, -1000000, 2000000000, -2000000000] as $day) {
    $uji($day, "luar_{$day}");
}

// BigInt diperlukan pada had PHP_INT_MIN/MAX. Oracle sedia ada menggunakan
// tolak int asli di hujung maksimum, maka kes ini disahkan daripada formula
// normatif dengan integer tepat, bukan dengan overflow atau penganggaran.
foreach ([PHP_INT_MIN, PHP_INT_MAX] as $day) {
    $old = $legacy->oldDayTag($day);
    $distance = BigInt::fromInt($day)->sub(BigInt::fromInt($foundation))->abs();
    sahHari($old->equals($distance->mulSmall(2)), 'WARISAN_TEPI_' . $day);
    $expected = $day >= $foundation ? $old->add(BigInt::one()) : $old;
    sahHari($kernel->dayCount($day)->equals($expected), 'JULAT_TEPI_' . $day);
    sahHari($patch->dayTagWithFoundationScar($day)->equals($expected), 'PATCH_TEPI_' . $day);
    sahHari($kernel->dayCount($day)->equals($expected), 'DETERMINISTIK_TEPI_' . $day);
    $cases++;
}

sahHari($legacy->oldDayTag($foundation)->isZero(), 'PARUT_ASAS_WUJUD');
sahHari($legacy->oldDayTag($foundation + 1)->equals(BigInt::fromInt(2)), 'PARUT_SELEPAS_WUJUD');
sahHari($scarTriggered === 1, 'JALUR_ASAS_TIDAK_TERPANGGIL');
sahHari($before > 2000 && $onOrAfter > 2000, 'LIPUTAN_KEDUA_SISI');

// Keadaan terdahulu, termasuk fungsi penyelamat SAVE, tidak terjejas oleh patch hari.
$m = NormativeMath::m();
foreach ([$m, $m->mulSmall(2), $m->add(BigInt::one()), BigInt::fromInt(-1)] as $x) {
    sahHari($kernel->save($x)->equals(NormativeMath::save($x)), 'SAVE_KEKAL');
}
sahHari($kernel->probe($foundation, $foundation)['status'] === 'READY', 'PROBE_KEKAL');

// Oracle tidak boleh masuk ke pengeluaran, dan kecacatan seterusnya belum boleh wujud.
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator(dirname(__DIR__) . '/src', FilesystemIterator::SKIP_DOTS)
);
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') {
        continue;
    }
    $content = (string)file_get_contents($file->getPathname());
    sahHari(!str_contains($content, 'NormativeMath'), 'ORACLE_DALAM_PRODUKSI');
    sahHari(!str_contains($content, 'oldDistance'), 'PENEMUAN_KETIGA_TERLALU_AWAL');
}

// Pastikan pemilik keadaan laluan produksi benar-benar menghala ke tampalan 02.
$kernelCode = (string)file_get_contents(dirname(__DIR__) . '/src/BootstrapKernel.php');
sahHari(str_contains($kernelCode, "dispatch('DAY_TAG_PATCH_02', " . '$context)'), 'DISPATCH_HARI_SALAH');

echo "LULUS Stage 5 PATCH 02 kes={$cases} sebelum={$before} pada_atau_selepas={$onOrAfter} asas={$scarTriggered} tepi=2\n";
