<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;

function sahKacau(bool $ok, string $id): void
{
    if (!$ok) {
        throw new RuntimeException($id);
    }
}

/**
 * Oracle terasing bagi SATU titisan. Keenam-enam posisi membaca input asal,
 * bukannya mangkuk yang diubah dalam gelung sebelumnya.
 *
 * @param array<int,BigInt> $old
 * @param array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt} $stone
 * @param list<int> $order
 * @param array<int,BigInt> $pours
 * @return array<int,BigInt>
 */
function stirOneDropNormative(
    array $old, int $i, BigInt $drop, array $stone,
    array $order, array $pours
): array {
    $stoneForPosition = [1=>'w',2=>'b',3=>'s',4=>'m',5=>'r',6=>'w'];
    $nextBowls = [];
    for ($position = 1; $position <= 6; $position++) {
        $id = $order[$position - 1];
        $prev = $order[($position + 4) % 6];
        $next = $order[$position % 6];
        $s = $old[$id]
            ->add($old[$prev]->mulSmall(2))
            ->add($old[$next]->mulSmall(3))
            ->add($pours[$position])
            ->add($drop)
            ->add($stone[$stoneForPosition[$position]]);
        $nextBowls[$id] = NormativeMath::save(
            $s->square()
                ->add($old[$prev]->mul($old[$next])->mulSmall(5))
                ->add(BigInt::fromInt($i * $position))
        );
    }
    return $nextBowls;
}

$kernel = new BootstrapKernel();
$oracle = new NormativeSauce();
$legacy = new LegacyInPlaceBowlStir(new SavePatch01(new LegacyRemainder()));
$old = [
    1=>BigInt::fromInt(101),2=>BigInt::fromInt(211),
    3=>BigInt::fromInt(307),4=>BigInt::fromInt(401),
    5=>BigInt::fromInt(503),6=>BigInt::fromInt(601),
];
$stone = [
    'w'=>BigInt::fromInt(2),'b'=>BigInt::fromInt(3),
    's'=>BigInt::fromInt(5),'m'=>BigInt::fromInt(7),
    'r'=>BigInt::fromInt(11),
];
$pours = [
    1=>BigInt::fromInt(17),2=>BigInt::fromInt(19),
    3=>BigInt::fromInt(23),4=>BigInt::zero(),
    5=>BigInt::zero(),6=>BigInt::zero(),
];
$drop = BigInt::fromInt(31);
$matches = 0;
$differences = 0;
$orders = 0;
$positionDifferences = array_fill(1, 6, 0);
$otherErrors = 0;

foreach (range(1, 720) as $rank) {
    $order = $oracle->permutationUnrank1($rank);
    sahKacau($kernel->bowlOrder(BigInt::fromInt($rank)) === $order, 'ORDER_' . $rank);
    $pristine = $old;
    $input = $old;
    $wrong = $legacy->stirOneDropWrong($input, 1, $drop, $stone, $order, $pours);
    $expected = stirOneDropNormative($pristine, 1, $drop, $stone, $order, $pours);
    sahKacau($input === $wrong, 'WRITE_IN_PLACE_' . $rank);
    sahKacau($old === $pristine, 'READ_ONLY_SOURCE_' . $rank);
    for ($position = 1; $position <= 6; $position++) {
        $id = $order[$position - 1];
        sahKacau($wrong[$id] instanceof BigInt, 'OUTPUT_TYPE_' . $rank . '_' . $position);
        sahKacau($wrong[$id]->compare(BigInt::one()) >= 0
            && $wrong[$id]->compare(NormativeMath::m()) <= 0, 'SAVE_RANGE_' . $rank . '_' . $position);
        if ($wrong[$id]->equals($expected[$id])) {
            $matches++;
            if ($position !== 1) {
                echo "RALAT_PADANAN_TIDAK_DIJANGKA pangkat={$rank} posisi={$position}\n";
                $otherErrors++;
            }
        } else {
            $differences++;
            $positionDifferences[$position]++;
            if ($position === 1) {
                echo "RALAT_POSISI_PERTAMA pangkat={$rank}\n";
                $otherErrors++;
            }
        }
    }
    $orders++;
}
sahKacau($orders === 720 && $matches === 720
    && $differences === 3600 && $otherErrors === 0, 'LIPUTAN_MERAH');
sahKacau($positionDifferences === [1=>0,2=>720,3=>720,4=>720,5=>720,6=>720], 'CORAK_MERAH');

$foundation = NormativeMath::FOUNDATION_DAY;
$tablets = NormativeMath::TABLETS_DAY;
$realCases = [
    [$foundation,$foundation,1],
    [$foundation,$foundation+7,7],
    [$tablets,$tablets,23],
    [10000000,-10000000,46],
];
$stones = $oracle->buildStones();
$real = 0;
$realDifferences = 0;
foreach ($realCases as [$c,$t,$index]) {
    $trace = $kernel->legacyStirAt($c,$t,$index);
    $fromPours = $kernel->poursAt($c,$t,$index);
    sahKacau($trace['drop']->equals($fromPours['drop']), 'TRACE_DROP');
    sahKacau($trace['order'] === $fromPours['order'], 'TRACE_ORDER');
    foreach (range(1, 6) as $id) {
        sahKacau($trace['oldBowls'][$id]->equals($fromPours['oldBowls'][$id]), 'TRACE_OLD_BOWLS_' . $id);
        sahKacau($trace['pours'][$id]->equals($fromPours['pours'][$id]), 'TRACE_POURS_' . $id);
    }
    $expected = stirOneDropNormative(
        $trace['oldBowls'],$index,$trace['drop'],
        $stones[$index],$trace['order'],$trace['pours']
    );
    $wrong = $trace['wrongBowls'];
    $directInput = $trace['oldBowls'];
    $direct = $legacy->stirOneDropWrong(
        $directInput,$index,$trace['drop'],$stones[$index],
        $trace['order'],$trace['pours']
    );
    foreach (range(1, 6) as $id) {
        sahKacau($direct[$id]->equals($wrong[$id]), 'TRACE_LEGACY_MATCH_' . $id);
        sahKacau($directInput[$id]->equals($wrong[$id]), 'TRACE_WRITES_IN_PLACE_' . $id);
    }
    $firstId = $trace['order'][0];
    sahKacau($wrong[$firstId]->equals($expected[$firstId]), 'REAL_FIRST_MATCH');
    for ($position=2; $position<=6; $position++) {
        $id=$trace['order'][$position-1];
        if (!$wrong[$id]->equals($expected[$id])) $realDifferences++;
    }
    sahKacau(array_keys($trace['oldBowls']) === range(1,6), 'TRACE_SHAPE');
    $real++;
}
sahKacau($real === 4 && $realDifferences > 0, 'REAL_CONTRAST');

$invalid = 0;
foreach ([[0,[1,2,3,4,5,6]],[47,[1,2,3,4,5,6]],[1,[1,2,3,4,5,5]]] as [$index,$order]) {
    $value = $old;
    try {
        $legacy->stirOneDropWrong($value,$index,$drop,$stone,$order,$pours);
        throw new RuntimeException('INVALID_STIR_ACCEPTED');
    } catch (InvalidArgumentException $error) {
        sahKacau($error->getMessage() === 'LEGACY_STIR_ARGUMENTS', 'BAD_ARGUMENT_CODE');
        sahKacau($value === $old, 'INVALID_MUTATION');
        $invalid++;
    }
}
$missing = $pours;
unset($missing[3]);
try {
    $input = $old;
    $legacy->stirOneDropWrong($input,1,$drop,$stone,[1,2,3,4,5,6],$missing);
    throw new RuntimeException('MISSING_POUR_ACCEPTED');
} catch (InvalidArgumentException $error) {
    sahKacau($error->getMessage() === 'LEGACY_STIR_BOWL_SHAPE', 'BAD_POUR_CODE');
    sahKacau($input === $old, 'BAD_POUR_MUTATION');
    $invalid++;
}
sahKacau($invalid === 4, 'VALIDATION_COUNT');

// Tidak wujud vault atau pending pada Stage 20.
$legacyCode=(string)file_get_contents(dirname(__DIR__).'/src/Legacy/LegacyInPlaceBowlStir.php');
$kernelCode=(string)file_get_contents(dirname(__DIR__).'/src/BootstrapKernel.php');
sahKacau(str_contains($legacyCode, '$bowls[$id] = $this->save->savePatch('), 'LEGACY_WRITES_EARLY');
sahKacau(str_contains($kernelCode,"dispatch('IN_PLACE_BOWL_STIR_LEGACY', ".'$context)'), 'LEGACY_ROUTE');
sahKacau(!str_contains($legacyCode,'vaultOld') && !str_contains($legacyCode,'pendingSnapshot'), 'PATCH10_TOO_EARLY');
sahKacau($kernel->stones()[2]['b']->equals($stones[2]['b']), 'STONE_REGRESSION');
echo "POSISI_PERTAMA_SEPADAN pangkat=720\n";
echo "POSISI_BERIKUT_TERCEMAR pangkat=720 kedudukan=2..6\n";
echo "KEPUTUSAN MERAH_DIJANGKA salah=3600 sepadan=720 pangkat=720 real=4 real_salah={$realDifferences} ralat=4 lain=0\n";
exit(1);
