<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyMissingFourthDigit16;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\FourthDigitPatch16;
use Pastafari\Stage01\Patches\SavePatch01;

function wajib33(bool $ok, string $label): void
{
    if (!$ok) throw new RuntimeException('STAGE33_' . $label);
}

$m = NormativeMath::m();
$m3 = $m->square()->mul($m);
$m4 = $m->square()->square();
$save = new SavePatch01(new LegacyRemainder());
$legacy = new LegacyMissingFourthDigit16($save);
$patch = new FourthDigitPatch16($legacy, $save);
$oracle = new NormativeSauce();
$scars = 0;
$matches = 0;
$matrix = 0;

// 400 kes: 4 saiz, 50 titik mula, dua arah. Titik mula dekat M
// diselaraskan pada i=4 agar rejection ±1 tidak menjadi astronomi.
$sizes = [$m3->add(BigInt::one()), $m3->add(BigInt::fromInt(2)),
    $m4->sub(BigInt::one()), $m4];
$starts = [];
for ($i = 1; $i <= 25; $i++) {
    $starts[] = BigInt::fromInt($i);
    $starts[] = $m->sub(BigInt::fromInt($i === 4 ? 26 : $i - 1));
}
foreach ($sizes as $sizeNo => $n) {
    foreach ($starts as $startNo => $first) {
        foreach ([-1, 1] as $step) {
            $stream = ['first'=>$first, 'step'=>$step];
            $before = $first->toString();
            $want = $oracle->chooseRank($stream, $n);
            $got = $patch->choosePatched($stream, $n);
            $old = $legacy->chooseWrong($stream, $n);
            wajib33($got->equals($want), 'ORACLE_'.$sizeNo.'_'.$startNo.'_'.$step);
            wajib33($got->compare(BigInt::one()) >= 0
                && $got->compare($n) <= 0, 'DOMAIN_'.$matrix);
            wajib33($first->toString() === $before && $stream['step'] === $step,
                'STREAM_PRESERVED_'.$matrix);
            if ($old->equals($got)) $matches++;
            else $scars++;
            $matrix++;
        }
    }
}
wajib33($matrix === 400 && $scars === 392 && $matches === 8, 'MATRIX_COUNTS');

// Keempat-empat bukti Stage32: digit keempat mesti dikembalikan.
$witnesses = [[BigInt::one(),1], [BigInt::fromInt(2),1],
    [BigInt::fromInt(5),-1], [$m,1]];
$witnessScars = 0;
foreach ($witnesses as $index=>[$first,$step]) {
    $stream=['first'=>$first,'step'=>$step];
    $want=$oracle->chooseRank($stream,$m4);
    $got=$patch->choosePatched($stream,$m4);
    $old=$legacy->chooseWrong($stream,$m4);
    $digit4=NormativeMath::save($first->add(BigInt::fromInt(3*$step)));
    wajib33($got->equals($want), 'WITNESS_PATCH_'.$index);
    wajib33($want->sub($old)->equals(
        $digit4->sub(BigInt::one())->mul($m3)), 'WITNESS_LEGACY_'.$index);
    $witnessScars++;
}
wajib33($witnessScars === 4, 'WITNESS_COUNT');

// Panggilan sebenar dari PATCH12, dua kernel untuk memeriksa kebebasan state.
$kernel = new BootstrapKernel();
$secondKernel = new BootstrapKernel();
$real = 0;
$n = $m3->add(BigInt::one());
foreach ([
    [NormativeMath::FOUNDATION_DAY,NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY,NormativeMath::TABLETS_DAY+17],
    [10000000,-10000000],
] as [$c,$t]) {
    $sauce=$oracle->sauce($c,$t);
    for ($id=1;$id<=6;$id++) {
        $stream=$oracle->askBowl($sauce,$id,23);
        $want=$oracle->chooseRank($stream,$n);
        $actual=$kernel->chooseQuadRank($c,$t,$id,23,$n);
        $again=$secondKernel->chooseQuadRank($c,$t,$id,23,$n);
        $historical=$kernel->legacyChooseQuadRank($c,$t,$id,23,$n);
        wajib33($actual->equals($want) && $again->equals($actual),
            'NATIVE_'.$c.'_'.$t.'_'.$id);
        wajib33($historical->equals($legacy->chooseWrong($stream,$n)),
            'NATIVE_LEGACY_'.$c.'_'.$t.'_'.$id);
        $real++;
    }
}
wajib33($real === 18, 'NATIVE_TOTAL');

$invalid = 0;
foreach ([
    [['first'=>BigInt::zero(),'step'=>1], $m4],
    [['first'=>$m->add(BigInt::one()),'step'=>1], $m4],
    [['first'=>BigInt::one(),'step'=>0], $m4],
    [['first'=>BigInt::one(),'step'=>2], $m4],
    [['first'=>BigInt::one(),'step'=>1], $m3],
    [['first'=>BigInt::one(),'step'=>1], $m4->add(BigInt::one())],
] as [$stream,$n]) {
    try {
        $patch->choosePatched($stream,$n);
        throw new RuntimeException('INVALID_ACCEPTED');
    } catch (InvalidArgumentException $e) {
        $invalid++;
    }
}
wajib33($invalid === 6, 'INVALID_TOTAL');

$src=dirname(__DIR__).'/src';
$patchCode=(string)file_get_contents($src.'/Patches/FourthDigitPatch16.php');
$legacyCode=(string)file_get_contents($src.'/Legacy/LegacyMissingFourthDigit16.php');
$kernelCode=(string)file_get_contents($src.'/BootstrapKernel.php');
wajib33(str_contains($patchCode,'$this->legacy->chooseWrong($stream, $n)')
    && str_contains($patchCode,'for ($j = 0; $j < 4; $j++)')
    && str_contains($legacyCode,'for ($j = 0; $j < 3; $j++)')
    && str_contains($kernelCode,
        "dispatch('MISSING_FOURTH_DIGIT_LEGACY', " . '$context)')
    && str_contains($kernelCode,
        "dispatch('FOUR_DIGIT_PATCH_16', " . '$context)'), 'LEGACY_AND_DISPATCH');
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($src,FilesystemIterator::SKIP_DOTS)) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $source=(string)file_get_contents($file->getPathname());
    wajib33(!str_contains($source,'NormativeMath')
        && !str_contains($source,'NormativeSauce'), 'NO_ORACLE_PRODUCTION');
}
echo "LULUS Stage33 PATCH16 matrix={$matrix} parut={$scars}"
    . " sepadan={$matches} saksi={$witnessScars} real={$real} invalid={$invalid}\n";
