<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyBowlFactory;
use Pastafari\Stage01\Legacy\LegacyFixedPositionPours;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\PoursAliasPatch09;
use Pastafari\Stage01\Patches\SavePatch01;

function sahAlias(bool $condition, string $id): void
{
    if (!$condition) throw new RuntimeException($id);
}

$save = new SavePatch01(new LegacyRemainder());
$legacy = new LegacyFixedPositionPours($save);
$patch = new PoursAliasPatch09($legacy);
$kernel = new BootstrapKernel();
$oracle = new NormativeSauce();
$bowls = [
    1 => BigInt::fromInt(101), 2 => BigInt::fromInt(211),
    3 => BigInt::fromInt(307), 4 => BigInt::fromInt(401),
    5 => BigInt::fromInt(503), 6 => BigInt::fromInt(601),
];
$stones = [
    'w' => BigInt::fromInt(2), 'b' => BigInt::fromInt(3),
    's' => BigInt::fromInt(5), 'm' => BigInt::fromInt(7),
    'r' => BigInt::fromInt(11),
];
$originalBowls = $bowls;
$ordersChecked = 0;
$comparisons = 0;
$historyWrong = 0;
$historyMatch = 0;
$aliasesChecked = 0;

for ($rank = 1; $rank <= 720; $rank++) {
    $drop = BigInt::fromInt($rank);
    $index = ($rank - 1) % 46 + 1;
    $order = $kernel->bowlOrder($drop);
    sahAlias($order === $oracle->permutationUnrank1($rank), 'ORDER_' . $rank);
    $aliases = $patch->installOrderAliases($order);
    sahAlias(array_keys($aliases) === range(1, 6), 'ALIAS_KEYS_' . $rank);
    for ($position = 1; $position <= 6; $position++) {
        sahAlias($aliases[$position] === $order[$position - 1], 'MAP_' . $rank . '_' . $position);
        sahAlias($patch->bowlByLegacyPosition($bowls, $aliases, $position)
            ->equals($bowls[$order[$position - 1]]), 'LOOKUP_' . $rank . '_' . $position);
        $aliasesChecked++;
    }
    $correct = $patch->patchedPours($index, $drop, $stones, $bowls, $order);
    $repeat = $patch->patchedPours($index, $drop, $stones, $bowls, $order);
    $wrong = $legacy->legacyPours($index, $drop, $stones, $bowls, $order);
    sahAlias(array_keys($correct) === range(1, 6), 'SIX_POURS_' . $rank);
    foreach ([1,2,3] as $position) {
        $kind = [1=>'w',2=>'b',3=>'s'][$position];
        $factor = [1=>3,2=>5,3=>7][$position];
        $norm = NormativeMath::save(
            $drop->square()->add($stones[$kind]->mul($bowls[$order[$position-1]]))
                ->add(BigInt::fromInt($factor * $index))
        );
        sahAlias($correct[$position]->equals($norm), 'NORM_' . $rank . '_' . $position);
        sahAlias($correct[$position]->equals($repeat[$position]), 'REPEAT_' . $rank . '_' . $position);
        $misidentified = $order[$position - 1] !== $position;
        if ($misidentified) {
            sahAlias(!$wrong[$position]->equals($norm), 'LEGACY_MISIDENTITY_' . $rank . '_' . $position);
            $historyWrong++;
        } else {
            sahAlias($wrong[$position]->equals($norm), 'LEGACY_MATCH_' . $rank . '_' . $position);
            $historyMatch++;
        }
        $comparisons++;
    }
    foreach ([4,5,6] as $position) {
        sahAlias($correct[$position]->isZero(), 'EMPTY_POSITION_' . $rank . '_' . $position);
    }
    $ordersChecked++;
}
sahAlias($ordersChecked === 720 && $comparisons === 2160, 'FULL_PERMUTATION_COVERAGE');
sahAlias($historyWrong === 1800 && $historyMatch === 360, 'LEGACY_SCAR_COVERAGE');
sahAlias($aliasesChecked === 4320, 'FULL_ALIAS_COVERAGE');
sahAlias($bowls === $originalBowls, 'INPUT_BOWLS_UNMODIFIED');

// Pemeriksaan pada data keluaran sebenar, dua tarikh dan dua kedudukan titisan.
$cases = [
    [NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY, 1],
    [NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY, 46],
    [NormativeMath::TABLETS_DAY, NormativeMath::TABLETS_DAY + 17, 1],
    [NormativeMath::TABLETS_DAY, NormativeMath::TABLETS_DAY + 17, 46],
];
$real = 0;
$realPours = 0;
$factory = new LegacyBowlFactory($save);
foreach ($cases as [$c,$t,$i]) {
    $counts = NormativeMath::workCounts($c, $t);
    $expectedBowls = $oracle->initialBowls($counts);
    $actual = $kernel->poursAt($c, $t, $i);
    $again = $kernel->poursAt($c, $t, $i);
    $other = (new BootstrapKernel())->poursAt($c, $t, $i);
    $historical = $kernel->legacyPoursAt($c, $t, $i);
    $stone = $kernel->stones()[$i];
    $drop = $kernel->visibleDrops($c, $t)[$i];
    $order = $oracle->bowlOrderFromDrop($drop);
    sahAlias($actual['drop']->equals($drop), 'DROP_REAL_' . $real);
    sahAlias($actual['order'] === $order, 'ORDER_REAL_' . $real);
    sahAlias($actual['aliases'] === $patch->installOrderAliases($order), 'ALIAS_REAL_' . $real);
    sahAlias($actual['order'] === $historical['order'], 'HISTORY_ORDER_' . $real);
    foreach (range(1,6) as $id) {
        sahAlias($actual['oldBowls'][$id]->equals($expectedBowls[$id]), 'FACTORY_REAL_' . $real . '_' . $id);
        sahAlias($actual['oldBowls'][$id]->equals($factory->initialBowls($counts)[$id]), 'BOWLS_REAL_' . $real . '_' . $id);
    }
    for ($position=1; $position<=6; $position++) {
        $k = [1=>'w',2=>'b',3=>'s'];
        $factor = [1=>3,2=>5,3=>7];
        $expected = $position <= 3
            ? NormativeMath::save(
                $drop->square()->add($stone[$k[$position]]->mul($expectedBowls[$order[$position-1]]))
                    ->add(BigInt::fromInt($factor[$position] * $i))
            )
            : BigInt::zero();
        sahAlias($actual['pours'][$position]->equals($expected), 'REAL_ORACLE_' . $real . '_' . $position);
        sahAlias($actual['pours'][$position]->equals($again['pours'][$position]), 'REAL_REPEAT_' . $real . '_' . $position);
        sahAlias($actual['pours'][$position]->equals($other['pours'][$position]), 'REAL_INSTANCE_' . $real . '_' . $position);
        if ($position <= 3 && $order[$position-1] === $position) {
            sahAlias($historical['pours'][$position]->equals($expected), 'REAL_LEGACY_MATCH_' . $real . '_' . $position);
        }
        $realPours++;
    }
    $real++;
}
sahAlias($real === 4 && $realPours === 24, 'REAL_PRODUCTION_COVERAGE');

// Input tidak sah dikesan di sempadan alias; pembetul tidak mengubah legacy.
$reject = 0;
foreach ([[1,1,2,3,4,5], [1,2,3,4,5], [0,1,2,3,4,5], [1,2,3,4,5,7]] as $invalid) {
    try {
        $patch->installOrderAliases($invalid);
        throw new RuntimeException('INVALID_ORDER_ACCEPTED');
    } catch (InvalidArgumentException $error) {
        sahAlias($error->getMessage() === 'BOWL_ALIAS_ORDER', 'INVALID_ORDER_DIAGNOSTIC');
        $reject++;
    }
}
try {
    $patch->bowlByLegacyPosition($bowls, $patch->installOrderAliases([1,2,3,4,5,6]), 0);
    throw new RuntimeException('INVALID_POSITION_ACCEPTED');
} catch (InvalidArgumentException $error) {
    sahAlias($error->getMessage() === 'BOWL_ALIAS_POSITION', 'POSITION_DIAGNOSTIC');
    $reject++;
}
$incomplete = $bowls;
unset($incomplete[4]);
try {
    $patch->bowlByLegacyPosition($incomplete, $patch->installOrderAliases([4,1,2,3,5,6]), 1);
    throw new RuntimeException('MISSING_BOWL_ACCEPTED');
} catch (InvalidArgumentException $error) {
    sahAlias($error->getMessage() === 'BOWL_ALIAS_MISSING', 'BOWL_DIAGNOSTIC');
    $reject++;
}
sahAlias($reject === 6, 'REJECTION_COVERAGE');

$root = dirname(__DIR__) . '/src';
$patchSource = (string)file_get_contents($root . '/Patches/PoursAliasPatch09.php');
$legacySource = (string)file_get_contents($root . '/Legacy/LegacyFixedPositionPours.php');
$kernelSource = (string)file_get_contents($root . '/BootstrapKernel.php');
sahAlias(str_contains($patchSource, 'function installOrderAliases('), 'ALIAS_SOURCE');
sahAlias(str_contains($patchSource, 'function bowlByLegacyPosition('), 'ALIAS_READER');
sahAlias(str_contains($patchSource, '$this->legacy->legacyPours('), 'ACTUAL_LEGACY_INVOCATION');
sahAlias(str_contains($legacySource, '$oldBowls[1]') && str_contains($legacySource, '$oldBowls[3]'), 'LEGACY_SCAR_PRESERVED');
sahAlias(str_contains($kernelSource, "dispatch('FIXED_POSITION_POURS_LEGACY', " . '$context)'), 'LEGACY_DISPATCH_PRESERVED');
sahAlias(str_contains($kernelSource, "dispatch('POURS_ALIAS_PATCH_09', " . '$context)'), 'PATCH_DISPATCH');
foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)) as $file) {
    if (strtolower($file->getExtension())!=='php') continue;
    $s = (string)file_get_contents($file->getPathname());
    sahAlias(!str_contains($s,'NormativeMath') && !str_contains($s,'NormativeSauce'), 'ORACLE_NOT_IN_PRODUCTION');
}
echo "LULUS Stage 19 PATCH 09 pangkat={$ordersChecked} tuangan={$comparisons}"
    . " legacy_salah={$historyWrong} legacy_sepadan={$historyMatch}"
    . " alias={$aliasesChecked} real={$real} real_tuangan={$realPours} ralat={$reject}\n";
