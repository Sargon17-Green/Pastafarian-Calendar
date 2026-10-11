<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyDayTag;
use Pastafari\Stage01\Oracle\NormativeMath;

/**
 * Kegagalan ditetapkan pada hari Asas dan selepasnya sahaja.
 * Keluaran merah kod 1 ialah bukti penemuan, bukan ralat CI yang tidak dijangka.
 */
$foundation = NormativeMath::FOUNDATION_DAY;
$kernel = new BootstrapKernel();
$legacy = new LegacyDayTag();
$divergences = 0;
$matching = 0;
$unexpected = 0;

for ($offset = -64; $offset <= 64; $offset++) {
    $day = $foundation + $offset;
    $expected = NormativeMath::dayCount($day);
    $actual = $kernel->dayCount($day);
    $old = $legacy->oldDayTag($day);
    $historical = $legacy->calculateWithoutPatch($day);

    if (!$old->equals($historical) || !$old->equals($actual)) {
        echo "RALAT_LALUAN offset={$offset}: kaedah legacy tidak digunakan\n";
        $unexpected++;
        continue;
    }

    $distance = BigInt::fromInt($offset)->abs()->mulSmall(2);
    if (!$old->equals($distance)) {
        echo "RALAT_ARITMETIK offset={$offset}: jangkaan lama tidak tepat\n";
        $unexpected++;
        continue;
    }

    if ($offset >= 0) {
        if ($expected->equals($old->add(BigInt::one())) && !$expected->equals($actual)) {
            echo "GAGAL_DIJANGKA offset={$offset}: dijangka={$expected} diperoleh={$actual}\n";
            $divergences++;
        } else {
            echo "RALAT_SELAIN_JANGKAAN offset={$offset}: dijangka={$expected} diperoleh={$actual}\n";
            $unexpected++;
        }
    } elseif ($expected->equals($actual)) {
        echo "LULUS_TEPAT offset={$offset}: diperoleh={$actual}\n";
        $matching++;
    } else {
        echo "RALAT_SELAIN_JANGKAAN offset={$offset}: dijangka={$expected} diperoleh={$actual}\n";
        $unexpected++;
    }
}

// Pengiraan jarak bagi hujung julat int mesti dilakukan sebagai BigInt tulen.
$boundaryCount = 0;
foreach ([PHP_INT_MIN, PHP_INT_MAX] as $day) {
    $distance = BigInt::fromInt($day)->sub(BigInt::fromInt($foundation))->abs();
    $expectedLegacy = $distance->mulSmall(2);
    $actual = $kernel->dayCount($day);
    if (!$actual->equals($expectedLegacy) || !$legacy->oldDayTag($day)->equals($actual)) {
        echo "RALAT_TEPI day={$day}\n";
        $unexpected++;
    } else {
        echo "LULUS_TEPI day={$day} nilai={$actual}\n";
        $boundaryCount++;
    }
}

$again = $kernel->dayCount($foundation);
if (!$again->isZero() || !$kernel->dayCount($foundation - 1)->equals(BigInt::fromInt(2))) {
    echo "RALAT_PENGULANGAN\n";
    $unexpected++;
}

if ($divergences !== 65 || $matching !== 64 || $boundaryCount !== 2 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH perbezaan={$divergences} sepadan={$matching} tepi={$boundaryCount} lain={$unexpected}\n";
    exit(2);
}

echo "KEPUTUSAN MERAH_DIJANGKA perbezaan=65 sepadan=64 tepi=2 lain=0\n";
exit(1);
