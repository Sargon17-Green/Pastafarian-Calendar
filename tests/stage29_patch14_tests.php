<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyBigEndianDigits14;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\BigEndianDigitsPatch14;
use Pastafari\Stage01\Patches\SavePatch01;

function wajib29(bool $ok, string $label): void
{
    if (!$ok) throw new RuntimeException('STAGE29_' . $label);
}

$m = NormativeMath::m();
$oracle = new NormativeSauce();
$save = new SavePatch01(new LegacyRemainder());
$legacy = new LegacyBigEndianDigits14($save);
$patch = new BigEndianDigitsPatch14($legacy, $save);
$kernel = new BootstrapKernel();
$independent = new BootstrapKernel();
$cases = 0;
$scar = 0;
$matched = 0;
$wrap = 0;

// Semua pangkat dikira oleh oracle PHP bebas; input tidak diubah.
function compare29(
    NormativeSauce $oracle, LegacyBigEndianDigits14 $legacy,
    BigEndianDigitsPatch14 $patch, array $stream, BigInt $n,
    string $label, int &$cases, int &$scar, int &$matched
): void {
    $beforeFirst = $stream['first']->toString();
    $beforeStep = $stream['step'];
    $normative = $oracle->chooseRank($stream, $n);
    $actual = $patch->choosePatched($stream, $n);
    $historical = $legacy->chooseWrong($stream, $n);
    wajib29($actual->equals($normative), 'ORACLE_' . $label);
    wajib29($actual->compare(BigInt::one()) >= 0
        && $actual->compare($n) <= 0, 'SPACE_' . $label);
    wajib29($beforeFirst === $stream['first']->toString()
        && $beforeStep === $stream['step'], 'STATE_' . $label);
    if ($historical->equals($actual)) {
        $matched++;
    } else {
        $scar++;
    }
    $cases++;
}

// Empat saksi eksplisit DISCOVERY14 kekal boleh diuji.
$n = $m->add(BigInt::one());
$witnesses = [
    ['first'=>BigInt::one(), 'step'=>1, 'expected'=>$n],
    ['first'=>BigInt::fromInt(2), 'step'=>1, 'expected'=>$n],
    ['first'=>BigInt::fromInt(2), 'step'=>-1, 'expected'=>BigInt::fromInt(2)],
    ['first'=>$m, 'step'=>1, 'expected'=>$m],
];
foreach ($witnesses as $index=>$w) {
    $stream = ['first'=>$w['first'], 'step'=>$w['step']];
    compare29($oracle,$legacy,$patch,$stream,$n,'WITNESS_'.$index,
        $cases,$scar,$matched);
    wajib29($patch->choosePatched($stream,$n)->equals($w['expected']),
        'WITNESS_CORRECTED_'.$index);
}
wajib29($scar===4,'SCARS_RETAINED');

// 90 nilai first x dua arah x empat saiz = 720 perbandingan sintetik.
$starts=[];
for($k=1;$k<=45;$k++) {
    $starts[]=BigInt::fromInt($k);
    $starts[]=$m->sub(BigInt::fromInt($k-1));
}
$sizes=[
    $m->add(BigInt::one()), $m->add(BigInt::fromInt(2)),
    $m->square()->sub(BigInt::one()), $m->square()
];
$matrix=0;
foreach($sizes as $sizeIndex=>$space) {
    foreach($starts as $startIndex=>$first) {
        foreach([-1,1] as $step) {
            $stream=['first'=>$first,'step'=>$step];
            compare29($oracle,$legacy,$patch,$stream,$space,
                'MATRIX_'.$sizeIndex.'_'.$startIndex.'_'.$step,
                $cases,$scar,$matched);
            if ($first->equals($m) && $step===1) $wrap++;
            $matrix++;
        }
    }
}
wajib29($matrix===720 && $wrap===4, 'MATRIX_COVERAGE');
wajib29($scar>=700,'MATRIX_SCAR_COVERAGE');

// Semakan sebenar membandingkan penghala PATCH14 dengan oracle,
// dan memastikan penghala legacy tidak hilang atau diperbetulkan.
$real=0;
foreach([
    [NormativeMath::FOUNDATION_DAY,NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY,NormativeMath::TABLETS_DAY+17],
    [10000000,-10000000],
] as [$c,$t]) {
    $sauce=$oracle->sauce($c,$t);
    for($id=1;$id<=6;$id++) {
        $stream=$oracle->askBowl($sauce,$id,23);
        $want=$oracle->chooseRank($stream,$n);
        $actual=$kernel->chooseWideRank($c,$t,$id,23,$n);
        $again=$independent->chooseWideRank($c,$t,$id,23,$n);
        $old=$kernel->legacyChooseWideRank($c,$t,$id,23,$n);
        wajib29($actual->equals($want) && $actual->equals($again),
            'NATIVE_'.$c.'_'.$t.'_'.$id);
        wajib29($old->equals($legacy->chooseWrong(
            $kernel->askBowl($c,$t,$id,23),$n)),
            'LEGACY_NATIVE_'.$c.'_'.$t.'_'.$id);
        $real++;
    }
}
wajib29($real===18,'REAL_CASES');

// Mengekalkan semakan domain dan kesalahan jalur besar tanpa oracle produksi.
$invalid=0;
foreach([
    [['first'=>BigInt::zero(),'step'=>1],$n],
    [['first'=>$m->add(BigInt::one()),'step'=>1],$n],
    [['first'=>BigInt::one(),'step'=>0],$n],
    [['first'=>BigInt::one(),'step'=>2],$n],
    [['first'=>BigInt::one(),'step'=>1],$m],
    [['first'=>BigInt::one(),'step'=>1],$m->square()->add(BigInt::one())],
] as [$stream,$space]) {
    try {
        $patch->choosePatched($stream,$space);
        throw new RuntimeException('INVALID_ACCEPTED');
    } catch(InvalidArgumentException $e) {
        $invalid++;
    }
}
wajib29($invalid===6,'INVALID_COUNT');

$src=dirname(__DIR__).'/src';
$patchText=(string)file_get_contents($src.'/Patches/BigEndianDigitsPatch14.php');
$legacyText=(string)file_get_contents($src.'/Legacy/LegacyBigEndianDigits14.php');
$kernelText=(string)file_get_contents($src.'/BootstrapKernel.php');
wajib29(
    str_contains($patchText,'$this->legacy->chooseWrong($stream, $n)')
    && str_contains($patchText,'$wide = BigInt::one()->add($low)->add($high->mul($this->modulus));')
    && str_contains($legacyText,'$digitWeights = [$this->modulus, BigInt::one()];')
    && str_contains($kernelText,"dispatch('BIG_ENDIAN_DIGITS_LEGACY', " . '$context)')
    && str_contains($kernelText,"dispatch('TWO_DIGIT_WEIGHTS_PATCH_14', " . '$context)'),
    'LEGACY_PRODUCTION_SCAR'
);
foreach(new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($src,FilesystemIterator::SKIP_DOTS)
) as $file) {
    if(strtolower($file->getExtension())!=='php')continue;
    $code=(string)file_get_contents($file->getPathname());
    wajib29(!str_contains($code,'NormativeMath')
        && !str_contains($code,'NormativeSauce'), 'NO_ORACLE_IN_SRC');
}
echo "LULUS Stage29 PATCH14 cases={$cases} matrix={$matrix}"
    . " parut={$scar} sepadan={$matched} wrap={$wrap}"
    . " real={$real} invalid={$invalid}\n";
