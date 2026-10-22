<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\BowlShadowPatch10;
use Pastafari\Stage01\Patches\SavePatch01;

function sahBayang(bool $ok, string $code): void
{
    if (!$ok) throw new RuntimeException($code);
}

/**
 * Oracle khusus yang bebas: semua bacaan enam posisi daripada $old.
 * @param array<int,BigInt> $old
 * @param array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt} $stone
 * @param list<int> $order
 * @param array<int,BigInt> $pours
 * @return array<int,BigInt>
 */
function kisarSnapshotRujukan(
    array $old, int $i, BigInt $drop, array $stone,
    array $order, array $pours
): array {
    $types=[1=>'w',2=>'b',3=>'s',4=>'m',5=>'r',6=>'w'];
    $next = [];
    for ($pos = 1; $pos <= 6; $pos++) {
        $id = $order[$pos - 1];
        $prev = $order[($pos + 4) % 6];
        $after = $order[$pos % 6];
        $sum = $old[$id]
            ->add($old[$prev]->mulSmall(2))
            ->add($old[$after]->mulSmall(3))
            ->add($pours[$pos])
            ->add($drop)
            ->add($stone[$types[$pos]]);
        $next[$id] = NormativeMath::save(
            $sum->square()->add($old[$prev]->mul($old[$after])->mulSmall(5))
                ->add(BigInt::fromInt($i*$pos))
        );
    }
    return $next;
}

$save = new SavePatch01(new LegacyRemainder());
$legacy = new LegacyInPlaceBowlStir($save);
$patch = new BowlShadowPatch10($legacy, $save);
$kernel = new BootstrapKernel();
$oracle = new NormativeSauce();
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
$ranks=0; $components=0; $legacyWrong=0; $legacySame=0;
foreach (range(1,720) as $rank) {
    $order=$oracle->permutationUnrank1($rank);
    $initial=$old;
    $working=$old;
    $correct=$patch->stirOneDropViaShadow($working,1,$drop,$stone,$order,$pours);
    $expected=kisarSnapshotRujukan($initial,1,$drop,$stone,$order,$pours);
    $wrongInput=$old;
    $wrong=$legacy->stirOneDropWrong($wrongInput,1,$drop,$stone,$order,$pours);
    $againInput=$old;
    $again=$patch->stirOneDropViaShadow($againInput,1,$drop,$stone,$order,$pours);
    sahBayang($working === $correct && $againInput === $again, 'COMMIT_BERSAMA_'.$rank);
    sahBayang($old === $initial, 'INPUT_SUMBER_KEKAL_'.$rank);
    for ($pos=1;$pos<=6;$pos++) {
        $id=$order[$pos-1];
        sahBayang($correct[$id] instanceof BigInt
            && $correct[$id]->equals($expected[$id])
            && $correct[$id]->equals($again[$id]), 'SNAPSHOT_'.$rank.'_'.$pos);
        sahBayang($correct[$id]->compare(BigInt::one()) >= 0
            && $correct[$id]->compare(NormativeMath::m()) <= 0, 'SAVE_'.$rank.'_'.$pos);
        if ($wrong[$id]->equals($correct[$id])) {
            sahBayang($pos===1, 'PADAN_LEGACY_TERLALU_BANYAK_'.$rank.'_'.$pos);
            $legacySame++;
        } else {
            sahBayang($pos!==1, 'PARUT_POSISI_PERTAMA_'.$rank);
            $legacyWrong++;
        }
        $components++;
    }
    $ranks++;
}
sahBayang($ranks===720 && $components===4320
    && $legacyWrong===3600 && $legacySame===720, 'LIPUTAN_PERMUTASI');

$foundation=NormativeMath::FOUNDATION_DAY;
$tablets=NormativeMath::TABLETS_DAY;
$dates=[
    [$foundation,$foundation,1],[$foundation,$foundation+7,7],
    [$tablets,$tablets,23],[10000000,-10000000,46],
];
$stones=$oracle->buildStones();
$real=0; $realComponents=0; $realWrong=0; $realSame=0;
foreach ($dates as [$c,$t,$i]) {
    $trace=$kernel->stirAt($c,$t,$i);
    $legacyTrace=$kernel->legacyStirAt($c,$t,$i);
    $poursTrace=$kernel->poursAt($c,$t,$i);
    $expected=kisarSnapshotRujukan(
        $trace['oldBowls'],$i,$trace['drop'],$stones[$i],
        $trace['order'],$trace['pours']
    );
    $working=$trace['oldBowls'];
    $direct=$patch->stirOneDropViaShadow(
        $working,$i,$trace['drop'],$stones[$i],$trace['order'],$trace['pours']
    );
    $again=$kernel->stirAt($c,$t,$i);
    $other=(new BootstrapKernel())->stirAt($c,$t,$i);
    sahBayang($trace['order'] === $legacyTrace['order']
        && $trace['order'] === $poursTrace['order'], 'JEJAK_ORDER');
    for ($id=1;$id<=6;$id++) {
        sahBayang($trace['oldBowls'][$id]->equals($legacyTrace['oldBowls'][$id]), 'JEJAK_OLD');
        sahBayang($trace['pours'][$id]->equals($poursTrace['pours'][$id]), 'JEJAK_POUR');
        sahBayang($trace['bowls'][$id]->equals($expected[$id])
            && $trace['bowls'][$id]->equals($direct[$id])
            && $trace['bowls'][$id]->equals($working[$id])
            && $trace['bowls'][$id]->equals($again['bowls'][$id])
            && $trace['bowls'][$id]->equals($other['bowls'][$id]), 'JEJAK_BAYANG_'.$id);
        $realComponents++;
    }
    for ($pos=1;$pos<=6;$pos++) {
        $id=$trace['order'][$pos-1];
        if ($legacyTrace['wrongBowls'][$id]->equals($trace['bowls'][$id])) {
            sahBayang($pos===1, 'REAL_PARUT_HILANG');
            $realSame++;
        } else {
            sahBayang($pos!==1, 'REAL_PARUT_PERTAMA');
            $realWrong++;
        }
    }
    $real++;
}
sahBayang($real===4 && $realComponents===24
    && $realSame===4 && $realWrong===20, 'LIPUTAN_REAL');

// Legacy mengesahkan input sebelum mutasi. Pembetul tidak melakukan commit
// apabila data tidak sah; sebarang pengecualian mesti kekal sama.
$invalid=0;
$cases=[
    [0,[1,2,3,4,5,6],$pours,$stone,'LEGACY_STIR_ARGUMENTS'],
    [47,[1,2,3,4,5,6],$pours,$stone,'LEGACY_STIR_ARGUMENTS'],
    [1,[1,2,3,4,5,5],$pours,$stone,'LEGACY_STIR_ARGUMENTS'],
];
$missing=$pours;unset($missing[3]);
$cases[]=[1,[1,2,3,4,5,6],$missing,$stone,'LEGACY_STIR_BOWL_SHAPE'];
$badStone=$stone;unset($badStone['s']);
$cases[]=[1,[1,2,3,4,5,6],$pours,$badStone,'LEGACY_STIR_STONE_SHAPE'];
foreach ($cases as [$idx,$order,$p,$st,$code]) {
    $input=$old;
    try {
        $patch->stirOneDropViaShadow($input,$idx,$drop,$st,$order,$p);
        throw new RuntimeException('TERIMA_INPUT_TIDAK_SAH');
    } catch (InvalidArgumentException $error) {
        sahBayang($error->getMessage()===$code, 'RALAT_INPUT_'.$code);
        sahBayang($input===$old, 'INPUT_TERPELIHARA_'.$code);
        $invalid++;
    }
}
sahBayang($invalid===5, 'LIPUTAN_RALAT');

$root=dirname(__DIR__).'/src';
$patchCode=(string)file_get_contents($root.'/Patches/BowlShadowPatch10.php');
$legacyCode=(string)file_get_contents($root.'/Legacy/LegacyInPlaceBowlStir.php');
$kernelCode=(string)file_get_contents($root.'/BootstrapKernel.php');
sahBayang(str_contains($patchCode,'$this->legacy->stirOneDropWrong('), 'PANGGILAN_LEGACY_SEBENAR');
sahBayang(str_contains($patchCode,'$vaultOld = $bowls;')
    && str_contains($patchCode,'$pending = $bowls;'), 'VAULT_PENDING');
sahBayang(str_contains($patchCode,'$bowls = $pending;'), 'COMMIT_SEKALI');
sahBayang(str_contains($legacyCode,'$bowls[$id] = $this->save->savePatch('), 'PARUT_WRITES_EARLY');
sahBayang(str_contains($kernelCode,"dispatch('IN_PLACE_BOWL_STIR_LEGACY', ".'$context)'), 'DISPATCH_LEGACY');
sahBayang(str_contains($kernelCode,"dispatch('BOWL_SHADOW_PATCH_10', ".'$context)'), 'DISPATCH_BAYANG');
foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root,FilesystemIterator::SKIP_DOTS)) as $file) {
    if (strtolower($file->getExtension())!=='php') continue;
    $code=(string)file_get_contents($file->getPathname());
    sahBayang(!str_contains($code,'NormativeMath')&&!str_contains($code,'NormativeSauce'), 'ORACLE_DALAM_PRODUKSI');
}
echo "LULUS Stage 21 PATCH 10 pangkat={$ranks} komponen={$components}"
    ." parut={$legacyWrong} sepadan_legacy={$legacySame}"
    ." real={$real} real_komponen={$realComponents}"
    ." real_parut={$realWrong} real_sepadan={$realSame} ralat={$invalid}\n";
