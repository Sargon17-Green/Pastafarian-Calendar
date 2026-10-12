<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Legacy\LegacyStoneMutation;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Bukti merah mutasi in-place dibandingkan dengan oracle tempatan ujian sahaja.
 */
$kernel = new BootstrapKernel();
$legacy = new LegacyStoneMutation(new SavePatch01(new LegacyRemainder()));
$correct = (new NormativeSauce())->buildStones();
$wrong = $kernel->stones();
$direct = $legacy->buildStonesWrong();
$repeated = $kernel->stones();
$another = (new BootstrapKernel())->stones();

$unexpected = 0;
$divergences = 0;
$matches = 0;
$componentFailures = 0;
$keys = ['w', 'b', 's', 'm', 'r'];

if (count($wrong) !== 46 || count($correct) !== 46 || array_keys($wrong) !== range(1, 46)) {
    echo "RALAT_JADUAL: panjang atau indeks tidak sah\n";
    $unexpected++;
}
foreach ($correct as $index => $expected) {
    $observed = $wrong[$index] ?? null;
    if (!is_array($observed) || array_keys($observed) !== $keys) {
        echo "RALAT_BENTUK batu={$index}\n";
        $unexpected++;
        continue;
    }
    $different = 0;
    foreach ($keys as $key) {
        if (!($observed[$key] instanceof BigInt)
            || !$observed[$key]->equals($direct[$index][$key])
            || !$observed[$key]->equals($repeated[$index][$key])
            || !$observed[$key]->equals($another[$index][$key])) {
            echo "RALAT_PEMILIKAN batu={$index} jenis={$key}\n";
            $unexpected++;
            continue;
        }
        if (!$observed[$key]->equals($expected[$key])) {
            $different++;
            $componentFailures++;
        }
    }
    if ($index === 1 && $different === 0) {
        echo "LULUS_ASAS batu=1 semua=5\n";
        $matches++;
    } elseif ($index >= 2 && $different >= 1) {
        echo "GAGAL_DIJANGKA batu={$index} komponen={$different}\n";
        $divergences++;
    } else {
        echo "RALAT_SELAIN_JANGKAAN batu={$index} komponen={$different}\n";
        $unexpected++;
    }
}

$firstWrong = ['w' => '378', 'b' => '1434', 's' => '3780', 'm' => '9932', 'r' => '25047'];
$firstExpected = ['w' => '378', 'b' => '1073', 's' => '2375', 'm' => '6195', 'r' => '10493'];
foreach ($keys as $key) {
    if (($wrong[2][$key] ?? null)?->toString() !== $firstWrong[$key]
        || ($correct[2][$key] ?? null)?->toString() !== $firstExpected[$key]) {
        echo "RALAT_VEKTOR batu=2 jenis={$key}\n";
        $unexpected++;
    }
}

$original = $direct[1];
$mutable = $original;
$alias = $legacy->mutateStonesWrong(2, $mutable);
foreach ($keys as $key) {
    if (!$alias[$key]->equals($direct[2][$key])
        || !$mutable[$key]->equals($direct[2][$key])
        || !$original[$key]->equals($direct[1][$key])) {
        echo "RALAT_MUTASI jenis={$key}\n";
        $unexpected++;
    }
}

foreach ([1, 47] as $badIndex) {
    $before = $original;
    try {
        $legacy->mutateStonesWrong($badIndex, $before);
        echo "RALAT_INDEKS_DITERIMA indeks={$badIndex}\n";
        $unexpected++;
    } catch (InvalidArgumentException $error) {
        if ($error->getMessage() !== 'STONE_INDEX_RANGE' || $before !== $original) {
            echo "RALAT_INDEKS_GUARD indeks={$badIndex}\n";
            $unexpected++;
        }
    }
}
$before = $original;
unset($before['s']);
try {
    $legacy->mutateStonesWrong(2, $before);
    echo "RALAT_STATE_DITERIMA\n";
    $unexpected++;
} catch (InvalidArgumentException $error) {
    if ($error->getMessage() !== 'STONE_STATE_SHAPE') {
        echo "RALAT_STATE_GUARD\n";
        $unexpected++;
    }
}

$foundation = NormativeMath::FOUNDATION_DAY;
if (!$kernel->dayCount($foundation)->equals(BigInt::one())
    || !$kernel->distance($foundation, $foundation)->equals(BigInt::one())
    || !$kernel->save(NormativeMath::m())->equals(NormativeMath::m())) {
    echo "RALAT_REGRESI_TERDAHULU\n";
    $unexpected++;
}

if ($divergences !== 45 || $matches !== 1 || $componentFailures < 45 || $unexpected !== 0) {
    echo "KEPUTUSAN TIDAK_SAH perbezaan={$divergences} sepadan={$matches} komponen={$componentFailures} lain={$unexpected}\n";
    exit(2);
}
echo "KEPUTUSAN MERAH_DIJANGKA perbezaan=45 sepadan=1 lain=0\n";
exit(1);
