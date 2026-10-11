<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyDistance;
use Pastafari\Stage01\Oracle\NormativeMath;

/**
 * Pengesahan merah Stage 6. Perbandingan normatif digunakan hanya dalam ujian.
 * Dalam pengeluaran, nilai jarak lama mesti kekal tidak ditampal.
 */
$kernel = new BootstrapKernel();
$legacy = new LegacyDistance();
$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$seen = [];
$failures = 0;
$unexpected = 0;
$sameDay = 0;
$forward = 0;
$backward = 0;
$edge = 0;

$check = static function(int $c, int $t, string $name, bool $extreme = false) use (
    $kernel, $legacy, &$seen, &$failures, &$unexpected, &$sameDay, &$forward, &$backward, &$edge
): void {
    $historical = $legacy->oldDistance($c, $t);
    $legacyWrapper = $legacy->calculateWithoutPatch($c, $t);
    $production = $kernel->distance($c, $t);

    $difference = BigInt::fromInt($t)->sub(BigInt::fromInt($c))->abs();
    $exactCount = $difference->add(BigInt::one());

    if ($extreme) {
        // Oracle Stage 1 menggunakan tolak int asli pada workCounts;
        // hujung PHP_INT_MIN/MAX mesti dibandingkan dengan bentuk BigInt tepat.
        $expected = $exactCount;
        $edge++;
    } else {
        $expected = NormativeMath::workCounts($c, $t)['distance'];
    }

    if (!$expected->equals($exactCount)
        || !$historical->equals($difference)
        || !$legacyWrapper->equals($historical)
        || !$production->equals($historical)
        || !$kernel->distance($t, $c)->equals($historical)
        || !$kernel->distance($c, $t)->equals($production)) {
        echo "RALAT_LAIN kes={$name} c={$c} t={$t} normatif={$expected} legacy={$production}\n";
        $unexpected++;
        return;
    }

    if ($c === $t) {
        if (!$historical->isZero() || !$expected->equals(BigInt::one())) {
            echo "RALAT_HARI_SAMA kes={$name}\n";
            $unexpected++;
            return;
        }
        $sameDay++;
    } elseif ($c < $t) {
        $forward++;
    } else {
        $backward++;
    }

    if (!$production->equals($expected) && $expected->equals($production->add(BigInt::one()))) {
        echo "GAGAL_DIJANGKA kes={$name}: normatif={$expected} legacy={$production}\n";
        $failures++;
        $seen[$name] = true;
    } else {
        echo "RALAT_SELAIN_JANGKAAN kes={$name}\n";
        $unexpected++;
    }
};

// Kes grid menangkap hari sama, arah bertentangan dan melintasi Hari Asas.
$offsets = [-255, -127, -40, -9, -2, -1, 0, 1, 2, 9, 40];
foreach ($offsets as $i => $a) {
    foreach ($offsets as $j => $b) {
        $check($foundation + $a, $foundation + $b, "grid_{$i}_{$j}");
    }
}
$more = [
    ['sifar_sama', 0, 0],
    ['sifar_depan', 0, 1],
    ['sifar_belakang', 1, 0],
    ['satu_belakang', -1, 1],
    ['satu_depan', 1, -1],
    ['jauh_depan', -1000000000, 1000000000],
    ['jauh_belakang', 1000000000, -1000000000],
    ['tablet_sama', $tablets, $tablets],
    ['tablet_jiran', $tablets - 1, $tablets + 1],
    ['asas_ke_tablet', $foundation, $tablets],
    ['tablet_ke_asas', $tablets, $foundation],
    ['besar_belakang', 2000000000, -2000000000],
    ['besar_depan', -2000000000, 2000000000],
    ['positif_sama', 123456789, 123456789],
    ['negatif_jiran', -123456789, -123456780],
];
foreach ($more as [$name, $c, $t]) {
    $check($c, $t, $name);
}
$bounds = [
    ['min_max', PHP_INT_MIN, PHP_INT_MAX],
    ['max_min', PHP_INT_MAX, PHP_INT_MIN],
    ['min_sama', PHP_INT_MIN, PHP_INT_MIN],
    ['max_sama', PHP_INT_MAX, PHP_INT_MAX],
    ['min_depan', PHP_INT_MIN, PHP_INT_MIN + 1],
    ['min_belakang', PHP_INT_MIN + 1, PHP_INT_MIN],
    ['max_depan', PHP_INT_MAX - 1, PHP_INT_MAX],
    ['max_belakang', PHP_INT_MAX, PHP_INT_MAX - 1],
];
foreach ($bounds as [$name, $c, $t]) {
    $check($c, $t, $name, true);
}

// Pemerhatian silang mesti mengekalkan kedua-dua tampalan terdahulu.
if (!$kernel->dayCount($foundation)->equals(BigInt::one())
    || !$kernel->dayCount($foundation + 1)->equals(BigInt::fromInt(3))
    || !$kernel->save(NormativeMath::m())->equals(NormativeMath::m())
    || $kernel->probe($foundation, $foundation)['status'] !== 'READY') {
    echo "RALAT_REGRESI_LAMA\n";
    $unexpected++;
}

$total = count($offsets) ** 2 + count($more) + count($bounds);
if ($total !== 144 || $failures !== $total || count($seen) !== $total
    || $unexpected !== 0 || $edge !== 8 || $sameDay < 10
    || $forward < 10 || $backward < 10) {
    echo "KEPUTUSAN TIDAK_SAH perbezaan={$failures} jumlah={$total} tepi={$edge} sama={$sameDay} depan={$forward} belakang={$backward} lain={$unexpected}\n";
    exit(2);
}

echo "KEPUTUSAN MERAH_DIJANGKA perbezaan=144 jumlah=144 tepi=8 lain=0\n";
exit(1);
