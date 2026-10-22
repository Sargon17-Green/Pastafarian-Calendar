<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyBowlFactory;
use Pastafari\Stage01\Legacy\LegacyBowlPermutation;
use Pastafari\Stage01\Legacy\LegacyFixedPositionPours;
use Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir;
use Pastafari\Stage01\Legacy\LegacyOverwrittenOrder11;
use Pastafari\Stage01\Legacy\LegacyPermutationUnrank0;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\BowlShadowPatch10;
use Pastafari\Stage01\Patches\OrderLatchPatch11;
use Pastafari\Stage01\Patches\PermutationPatch08;
use Pastafari\Stage01\Patches\PoursAliasPatch09;
use Pastafari\Stage01\Patches\SavePatch01;

function pastikanLatch(bool $yes, string $label): void
{
    if (!$yes) throw new RuntimeException($label);
}

$save = new SavePatch01(new LegacyRemainder());
$unrank = new LegacyPermutationUnrank0();
$permutation = new PermutationPatch08(new LegacyBowlPermutation($unrank), $unrank);
$legacy = new LegacyOverwrittenOrder11(
    $save, new LegacyBowlFactory($save), $permutation,
    new PoursAliasPatch09(new LegacyFixedPositionPours($save)),
    new BowlShadowPatch10(new LegacyInPlaceBowlStir($save), $save)
);
$patch = new OrderLatchPatch11($legacy, $permutation);
$kernel = new BootstrapKernel();
$another = new BootstrapKernel();
$oracle = new NormativeSauce();
$stones = $oracle->buildStones();
$dates = [
    ['asas', NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY],
    ['loh', NormativeMath::TABLETS_DAY, NormativeMath::TABLETS_DAY + 17],
    ['jauh', 10000000, -10000000],
    ['dekat', NormativeMath::TABLETS_DAY + 1, NormativeMath::TABLETS_DAY],
    ['undur', 20261022, 20261021],
    ['sama', 0, 0],
];
$cases = 0;
$bowls = 0;
$stirs = 0;
$scars = 0;
foreach ($dates as [$label, $c, $t]) {
    $reference = $oracle->sauce($c, $t);
    $actual = $kernel->sauceOrder($c, $t);
    $again = $another->sauceOrder($c, $t);
    $historical = $kernel->legacySauceOrder($c, $t);
    pastikanLatch($actual['orderAtDrop46'] === $reference['orderAtDrop46']
        && $actual['orderAtDrop46'] === $again['orderAtDrop46'],
        'SUSUNAN_' . $label);
    pastikanLatch(
        $actual['orderAtDrop46'] === $oracle->bowlOrderFromDrop($reference['visible'][46]),
        'TITISAN_46_' . $label
    );
    pastikanLatch($actual['postStirs'] === 12 && $actual['dropCount'] === 46
        && $historical['postStirs'] === 12, 'KITARAN_' . $label);
    for ($id = 1; $id <= 6; $id++) {
        pastikanLatch($actual['bowls'][$id] instanceof BigInt
            && $actual['bowls'][$id]->equals($reference['bowls'][$id])
            && $actual['bowls'][$id]->equals($again['bowls'][$id])
            && $actual['bowls'][$id]->equals($historical['bowls'][$id]),
            'MANGKUK_' . $label . '_' . $id);
        $bowls++;
    }
    if ($historical['orderAtDrop46'] !== $actual['orderAtDrop46']) $scars++;
    if ($cases === 0) {
        $counts = NormativeMath::workCounts($c, $t);
        $direct = $patch->sauceWithOrderLatch($counts, $stones, $reference['visible']);
        pastikanLatch($direct['orderAtDrop46'] === $actual['orderAtDrop46'],
            'LALUAN_LANGSUNG');
        for ($id = 1; $id <= 6; $id++) {
            pastikanLatch($direct['bowls'][$id]->equals($actual['bowls'][$id]),
                'MANGKUK_LANGSUNG_' . $id);
        }
    }
    $cases++;
    $stirs += $actual['postStirs'];
}
pastikanLatch($cases === 6 && $bowls === 36 && $stirs === 72
    && $scars >= 3, 'JUMLAH_LIPUTAN');

$visible = $oracle->sauce(0, 0)['visible'];
$counts = NormativeMath::workCounts(0, 0);
$invalid = 0;
$bad = $visible;
unset($bad[46]);
try {
    $patch->sauceWithOrderLatch($counts, $stones, $bad);
    throw new RuntimeException('VISIBLE_TAK_LENGKAP_DITERIMA');
} catch (\InvalidArgumentException $e) {
    $invalid++;
}
$badStones = $stones;
unset($badStones[46]);
try {
    $patch->sauceWithOrderLatch($counts, $badStones, $visible);
    throw new RuntimeException('STONE_TAK_LENGKAP_DITERIMA');
} catch (\InvalidArgumentException $e) {
    $invalid++;
}
$root = dirname(__DIR__) . '/src';
$patchText = (string)file_get_contents($root . '/Patches/OrderLatchPatch11.php');
$legacyText = (string)file_get_contents($root . '/Legacy/LegacyOverwrittenOrder11.php');
$kernelText = (string)file_get_contents($root . '/BootstrapKernel.php');
pastikanLatch(
    str_contains($patchText, '$orderAt46Latch = $this->permutation->permutationPatch($visible[46]);')
    && str_contains($patchText, '$this->legacy->sauceWrong($counts, $stones, $visible);')
    && str_contains($patchText, "\$historical['orderAtDrop46'] = \$orderAt46Latch;")
    && !str_contains($legacyText, 'orderAt46Latch')
    && str_contains($kernelText, "dispatch('OVERWRITTEN_ORDER_46_LEGACY', " . '$context)')
    && str_contains($kernelText, "dispatch('ORDER_LATCH_PATCH_11', " . '$context)'),
    'KONTRAK_PARUT_DAN_LATCH'
);
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)
) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $code = (string)file_get_contents($file->getPathname());
    pastikanLatch(!str_contains($code, 'NormativeMath')
        && !str_contains($code, 'NormativeSauce'), 'ORACLE_PRODUKSI');
}
echo "LULUS Stage 23 PATCH 11 kes={$cases} mangkuk={$bowls}"
    . " kacau={$stirs} parut={$scars} ralat={$invalid}\n";
