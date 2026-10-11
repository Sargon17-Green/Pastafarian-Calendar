<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;

// Arkib ujian kegagalan asal: baki legacy kekal salah walaupun laluan pengeluaran telah ditampal.
$m = NormativeMath::m();
$cases = [
    'M' => $m,
    '2M' => $m->mulSmall(2),
    '3M' => $m->mulSmall(3),
    'M+1' => $m->add(BigInt::one()),
];

$rawLegacy = new LegacyRemainder();
$divergences = 0;
$matching = 0;
$unexpected = 0;

foreach ($cases as $name => $operand) {
    $expected = NormativeMath::save($operand);
    $actual = $rawLegacy->calculateWithoutPatch($operand);
    $raw = $rawLegacy->oldRemainder($operand);
    $mustDiffer = $name !== 'M+1';
    $same = $actual->equals($expected);

    if (!$raw->equals($actual)) {
        echo "RALAT_LALUAN {$name}: pengeluaran tidak menggunakan baki lama\n";
        $unexpected++;
        continue;
    }
    if ($mustDiffer && !$same && $actual->isZero() && $expected->equals($m)) {
        echo "GAGAL_DIJANGKA {$name}: dijangka={$expected} diperoleh={$actual}\n";
        $divergences++;
    } elseif (!$mustDiffer && $same && $actual->equals(BigInt::one())) {
        echo "LULUS {$name}: dijangka={$expected} diperoleh={$actual}\n";
        $matching++;
    } else {
        echo "RALAT_SELAIN_JANGKAAN {$name}: dijangka={$expected} diperoleh={$actual}\n";
        $unexpected++;
    }
}

if ($divergences !== 3 || $matching !== 1 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH perbezaan={$divergences} sepadan={$matching} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA perbezaan=3 sepadan=1 lain=0\n";
exit(1);
