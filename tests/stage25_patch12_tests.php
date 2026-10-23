<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyNumericSuccessor12;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\NextBowlOrderPatch12;
use Pastafari\Stage01\Patches\SavePatch01;

function wajib25(bool $condition, string $label): void
{
    if (!$condition) {
        throw new RuntimeException('GAGAL_STAGE25_' . $label);
    }
}

$oracle = new NormativeSauce();
$save = new SavePatch01(new LegacyRemainder());
$legacy = new LegacyNumericSuccessor12($save);
$patch = new NextBowlOrderPatch12($legacy, $save);
$kernel = new BootstrapKernel();
$another = new BootstrapKernel();
$bowls = [];
foreach (range(1, 6) as $id) {
    $bowls[$id] = BigInt::fromInt(10000 + 133 * $id);
}
$correctNeighbors = 0;
$wrongLegacyNeighbors = 0;
$permutations = 0;
$checked = 0;

// Buktikan keseluruhan enam ID bagi semua 720 susunan.
for ($rank = 1; $rank <= 720; $rank++) {
    $order = $oracle->permutationUnrank1($rank);
    $sauce = ['bowls' => $bowls, 'orderAtDrop46' => $order];
    foreach (range(1, 6) as $id) {
        $expected = $oracle->askBowl($sauce, $id, 23);
        $actual = $patch->askPatched($sauce, $id, 23);
        $old = $legacy->askWrong($sauce, $id, 23);
        $position = array_search($id, $order, true);
        $next = $order[($position + 1) % 6];
        wajib25($actual['nextBowlId'] === $next, 'JIRAN_' . $rank . '_' . $id);
        wajib25(
            $actual['first']->equals($expected['first'])
            && $actual['step'] === $expected['step'],
            'ORACLE_' . $rank . '_' . $id
        );
        if ($old['nextBowlId'] === $next) {
            $correctNeighbors++;
            wajib25(
                $old['first']->equals($actual['first'])
                && $old['step'] === $actual['step'],
                'WARISAN_TEPAT_' . $rank . '_' . $id
            );
        } else {
            $wrongLegacyNeighbors++;
            wajib25(!$old['first']->equals($actual['first']),
                'PARUT_' . $rank . '_' . $id);
        }
        $checked++;
    }
    wajib25($sauce['orderAtDrop46'] === $order && $sauce['bowls'] === $bowls,
        'MILIK_INPUT_' . $rank);
    $permutations++;
}
wajib25($permutations === 720 && $checked === 4320
    && $wrongLegacyNeighbors === 3456 && $correctNeighbors === 864,
    'LIPUTAN_PENUH');

// Meterai tambahan menguji first/step tanpa kebergantungan pada meterai tetap.
$extra = 0;
foreach ([-73, 0, 181] as $seal) {
    foreach ([1, 37, 354, 720] as $rank) {
        $order = $oracle->permutationUnrank1($rank);
        $sauce = ['bowls' => $bowls, 'orderAtDrop46' => $order];
        foreach (range(1, 6) as $id) {
            $expected = $oracle->askBowl($sauce, $id, $seal);
            $got = $patch->askPatched($sauce, $id, $seal);
            wajib25($got['first']->equals($expected['first'])
                && $got['step'] === $expected['step'], 'METERAI_' . $seal);
            $extra++;
        }
    }
}

$dates = [
    ['asas', NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY],
    ['loh', NormativeMath::TABLETS_DAY, NormativeMath::TABLETS_DAY + 17],
    ['jauh', 10000000, -10000000],
];
$real = 0;
foreach ($dates as [$label, $c, $t]) {
    $reference = $oracle->sauce($c, $t);
    $sauce = $kernel->sauceOrder($c, $t);
    wajib25($sauce['orderAtDrop46'] === $reference['orderAtDrop46'],
        'ORDER_PRODUKSI_' . $label);
    foreach (range(1, 6) as $id) {
        wajib25($sauce['bowls'][$id]->equals($reference['bowls'][$id]),
            'MANGKUK_' . $label . '_' . $id);
        $expected = $oracle->askBowl($reference, $id, 23);
        $actual = $kernel->askBowl($c, $t, $id, 23);
        $repeated = $another->askBowl($c, $t, $id, 23);
        $direct = $patch->askPatched($sauce, $id, 23);
        $at = array_search($id, $reference['orderAtDrop46'], true);
        $next = $reference['orderAtDrop46'][($at + 1) % 6];
        wajib25(
            $actual['nextBowlId'] === $next
            && $actual['first']->equals($expected['first'])
            && $actual['step'] === $expected['step'],
            'PENGELUARAN_' . $label . '_' . $id
        );
        wajib25($actual['first']->equals($repeated['first'])
            && $actual['step'] === $repeated['step']
            && $actual['first']->equals($direct['first'])
            && $actual['step'] === $direct['step'],
            'PANGGILAN_' . $label . '_' . $id);
        $real++;
    }
}

$invalid = 0;
foreach ([0, 7] as $id) {
    try {
        $patch->askPatched(['bowls'=>$bowls,
            'orderAtDrop46'=>[1,2,3,4,5,6]], $id, 23);
        throw new RuntimeException('KELULUSAN_ID_' . $id);
    } catch (InvalidArgumentException $e) {
        $invalid++;
    }
}
try {
    $patch->askPatched(['bowls'=>$bowls,
        'orderAtDrop46'=>[1,2,3,4,4,6]], 1, 23);
    throw new RuntimeException('KELULUSAN_SUSUNAN');
} catch (InvalidArgumentException $e) {
    $invalid++;
}
$missingBowl = $bowls;
unset($missingBowl[6]);
try {
    $patch->askPatched(['bowls'=>$missingBowl,
        'orderAtDrop46'=>[1,2,3,4,5,6]], 1, 23);
    throw new RuntimeException('KELULUSAN_MANGKUK');
} catch (InvalidArgumentException $e) {
    $invalid++;
}
wajib25($invalid === 4, 'PENOLAKAN_INPUT');

$root = dirname(__DIR__) . '/src';
$fixedCode = (string)file_get_contents($root . '/Patches/NextBowlOrderPatch12.php');
$legacyCode = (string)file_get_contents($root . '/Legacy/LegacyNumericSuccessor12.php');
$kernelCode = (string)file_get_contents($root . '/BootstrapKernel.php');
wajib25(
    str_contains($fixedCode, '$this->legacy->askWrong($sauce, $queriedBowlId, $seal)')
    && str_contains($fixedCode, '$nextId = $order[($position + 1) % 6];')
    && str_contains($legacyCode, '$nextId = ($queriedBowlId % 6) + 1;')
    && str_contains($kernelCode, "dispatch('NUMERIC_NEXT_BOWL_LEGACY', " . '$context)')
    && str_contains($kernelCode, "dispatch('ORDER_NEIGHBOR_PATCH_12', " . '$context)'),
    'PARUT_DAN_PENGHALA'
);
echo "LULUS Stage 25 PATCH 12 pangkat={$permutations} semakan={$checked}"
    . " jiran_lama_salah={$wrongLegacyNeighbors} jiran_lama_tepat={$correctNeighbors}"
    . " tambahan={$extra} real={$real} ralat={$invalid}\n";
