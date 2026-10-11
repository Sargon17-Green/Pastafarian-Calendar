<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyDistance;
use Pastafari\Stage01\Oracle\NormativeMath;

/** Bukti merah sebenar bagi hipotesis salah: jarak tag tidak sama jarak hari. */
$kernel = new BootstrapKernel();
$legacy = new LegacyDistance();
$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$failures = 0;
$matches = 0;
$detours = 0;
$unexpected = 0;
$extremeCount = 0;
$same = 0;
$forward = 0;
$backward = 0;
$seen = [];

$check = static function(int $c, int $t, string $name, bool $extreme = false) use (
    $kernel, $legacy, &$failures, &$matches, &$detours,
    &$unexpected, &$extremeCount, &$same, &$forward, &$backward, &$seen
): void {
    $old = $legacy->oldDistance($c, $t);
    $former = $legacy->calculateWithoutPatch($c, $t);
    $chronological = BigInt::fromInt($t)->sub(BigInt::fromInt($c))->abs();
    $expected = $extreme ? $chronological->add(BigInt::one()) : NormativeMath::workCounts($c, $t)['distance'];
    $fromTags = $kernel->dayCount($c)->sub($kernel->dayCount($t))->abs();

    if (!$former->equals($old) || !$old->equals($fromTags)
        || !$expected->equals($chronological->add(BigInt::one()))
        || !$legacy->calculateWithoutPatch($t, $c)->equals($old)
        || !$legacy->calculateWithoutPatch($c, $t)->equals($old)) {
        echo "RALAT_KONTRAK kes={$name}\n";
        $unexpected++;
        return;
    }
    if ($c === $t) {
        if (!$old->isZero()) {
            echo "RALAT_HARI_SAMA kes={$name}\n";
            $unexpected++;
            return;
        }
        $same++;
    } elseif ($c < $t) {
        $forward++;
    } else {
        $backward++;
    }
    if (!$old->equals($chronological)) {
        $detours++;
    }
    if ($extreme) {
        $extremeCount++;
    }
    if ($old->equals($expected)) {
        echo "LULUS_TEPAT kes={$name}: nilai={$old}\n";
        $matches++;
    } else {
        echo "GAGAL_DIJANGKA kes={$name}: normatif={$expected} legacy={$old}\n";
        $failures++;
    }
    $seen[$name] = true;
};

$offsets = [-255, -127, -40, -9, -2, -1, 0, 1, 2, 9, 40];
foreach ($offsets as $i => $a) {
    foreach ($offsets as $j => $b) {
        $check($foundation + $a, $foundation + $b, "grid_{$i}_{$j}");
    }
}
$more = [
    ['sifar_sama', 0, 0], ['sifar_depan', 0, 1], ['sifar_belakang', 1, 0],
    ['satu_belakang', -1, 1], ['satu_depan', 1, -1],
    ['jauh_depan', -1000000000, 1000000000], ['jauh_belakang', 1000000000, -1000000000],
    ['tablet_sama', $tablets, $tablets], ['tablet_jiran', $tablets - 1, $tablets + 1],
    ['asas_ke_tablet', $foundation, $tablets], ['tablet_ke_asas', $tablets, $foundation],
    ['besar_belakang', 2000000000, -2000000000], ['besar_depan', -2000000000, 2000000000],
    ['positif_sama', 123456789, 123456789], ['negatif_jiran', -123456789, -123456780],
];
foreach ($more as [$name, $c, $t]) {
    $check($c, $t, $name);
}
$bounds = [
    ['min_max', PHP_INT_MIN, PHP_INT_MAX], ['max_min', PHP_INT_MAX, PHP_INT_MIN],
    ['min_sama', PHP_INT_MIN, PHP_INT_MIN], ['max_sama', PHP_INT_MAX, PHP_INT_MAX],
    ['min_depan', PHP_INT_MIN, PHP_INT_MIN + 1], ['min_belakang', PHP_INT_MIN + 1, PHP_INT_MIN],
    ['max_depan', PHP_INT_MAX - 1, PHP_INT_MAX], ['max_belakang', PHP_INT_MAX, PHP_INT_MAX - 1],
];
foreach ($bounds as [$name, $c, $t]) {
    $check($c, $t, $name, true);
}
if (!$kernel->dayCount($foundation)->equals(BigInt::one())
    || !$kernel->save(NormativeMath::m())->equals(NormativeMath::m())
    || $kernel->probe($foundation, $foundation)['status'] !== 'READY') {
    echo "RALAT_REGRESI_LAMA\n";
    $unexpected++;
}

$total = count($offsets) ** 2 + count($more) + count($bounds);
if ($total !== 144 || count($seen) !== 144 || $failures !== 130 || $matches !== 14
    || $detours !== 124 || $extremeCount !== 8 || $same < 10
    || $forward < 10 || $backward < 10 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH perbezaan={$failures} sepadan={$matches} lencongan={$detours} tepi={$extremeCount} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA perbezaan=130 sepadan=14 lencongan=124 tepi=8 lain=0\n";
exit(1);
