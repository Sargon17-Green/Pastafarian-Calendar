<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyHiddenBackward;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Penemuan merah: stor hidden7..hidden1 dibaca seolah-olah hidden1..hidden7.
 * Formula setiap titisan diperiksa secara berasingan melalui oracle PHP tempatan.
 */
$kernel = new BootstrapKernel();
$legacy = new LegacyHiddenBackward(new SavePatch01(new LegacyRemainder()));
$normative = new NormativeSauce();
$normativeStones = $normative->buildStones();
$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
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
$failures = 0;
$matches = 0;
$unexpected = 0;
$rows = 0;
$keys = range(1, 7);

foreach ($cases as [$name, $c, $t]) {
    $expectedCounts = NormativeMath::workCounts($c, $t);
    $expected = $normative->buildHiddenDrops($expectedCounts, $normativeStones);
    $actual = $legacy->revealWrong($storedPlaceholder = $legacy->buildStoredBackward($expectedCounts, $kernel->stones()));
    $stored = $storedPlaceholder;
    $direct = $legacy->revealWrong($stored);
    $repeat = $legacy->revealWrong($stored);
    $newKernel = (new LegacyHiddenBackward(new SavePatch01(new LegacyRemainder())))->revealWrong($stored);

    if (array_keys($actual) !== $keys || array_keys($stored) !== $keys
        || count($expected) !== 7) {
        echo "RALAT_BENTUK kes={$name}\n";
        $unexpected++;
        continue;
    }
    for ($k = 1; $k <= 7; $k++) {
        $history = $actual[$k];
        $near = $expected[$k];
        $reverse = $expected[8 - $k];
        if (!$history instanceof BigInt
            || !$history->equals($stored[$k])
            || !$history->equals($direct[$k])
            || !$history->equals($repeat[$k])
            || !$history->equals($newKernel[$k])
            || !$history->equals($reverse)
            || !$legacy->wrongNearness($stored, $k)->equals($history)) {
            echo "RALAT_PEMILIKAN kes={$name} slot={$k}\n";
            $unexpected++;
            continue;
        }
        if ($k === 4 && $history->equals($near)) {
            echo "SEPADAN_DIJANGKA kes={$name} slot=4\n";
            $matches++;
        } elseif ($k !== 4 && !$history->equals($near)) {
            echo "GAGAL_DIJANGKA kes={$name} slot={$k}: normatif={$near} legacy={$history}\n";
            $failures++;
        } else {
            echo "RALAT_SELAIN_JANGKAAN kes={$name} slot={$k}\n";
            $unexpected++;
        }
    }
    $rows++;
}

// Jaminan struktur dan keselamatan: tiada indeks luar had, tiada nilai
// hilang diterima, dan susunan stor tetap terbalik.
$validStorage = [
    1 => BigInt::fromInt(71), 2 => BigInt::fromInt(61),
    3 => BigInt::fromInt(51), 4 => BigInt::fromInt(41),
    5 => BigInt::fromInt(31), 6 => BigInt::fromInt(21),
    7 => BigInt::fromInt(11),
];
foreach ($keys as $k) {
    if (!$legacy->wrongNearness($validStorage, $k)->equals(BigInt::fromInt(81 - 10 * $k))) {
        echo "RALAT_STOR_SLOT slot={$k}\n";
        $unexpected++;
    }
}
foreach ([0, 8] as $bad) {
    try {
        $legacy->wrongNearness($validStorage, $bad);
        echo "RALAT_JULAT_DITERIMA slot={$bad}\n";
        $unexpected++;
    } catch (InvalidArgumentException $e) {
        if ($e->getMessage() !== 'HIDDEN_SLOT_RANGE') {
            $unexpected++;
        }
    }
}
$missing = $validStorage;
unset($missing[6]);
try {
    $legacy->wrongNearness($missing, 6);
    echo "RALAT_SLOT_HILANG_DITERIMA\n";
    $unexpected++;
} catch (InvalidArgumentException $e) {
    if ($e->getMessage() !== 'HIDDEN_SLOT_MISSING') {
        $unexpected++;
    }
}

if (!$kernel->distance($foundation, $foundation)->equals(BigInt::one())
    || !$kernel->dayCount($foundation)->equals(BigInt::one())
    || !$kernel->save(NormativeMath::m())->equals(NormativeMath::m())
    || !$kernel->stones()[2]['b']->equals($normativeStones[2]['b'])) {
    echo "RALAT_REGRESI_LAMA\n";
    $unexpected++;
}
if ($rows !== 12 || $failures !== 72 || $matches !== 12 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH perbezaan={$failures} sepadan={$matches} pasangan={$rows} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA perbezaan=72 sepadan=12 pasangan=12 lain=0\n";
exit(1);
