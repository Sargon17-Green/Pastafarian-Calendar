<?php
declare(strict_types=1);
require_once __DIR__.'/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyMissingFifthDigit17;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;
use Pastafari\Stage01\Patches\FifthDigitPatch17;

function semak35(bool $ok,string $label):void
{
    if (!$ok) throw new RuntimeException('STAGE35_'.$label);
}

$m = NormativeMath::m();
$m4 = $m->square()->square();
$m5 = $m4->mul($m);
$save = new SavePatch01(new LegacyRemainder());
$legacy = new LegacyMissingFifthDigit17($save);
$patch = new FifthDigitPatch17($legacy, $save);
$oracle = new NormativeSauce();
$spaces = [$m4->add(BigInt::one()),$m4->add(BigInt::fromInt(2)),
    $m5->sub(BigInt::one()),$m5];
$starts = [];
for ($i=1;$i<=25;$i++) {
    // Elak kes rejection +1/-1 astronomi pada n=M^4+1/+2.
    $starts[] = BigInt::fromInt($i===4 ? 27 : $i);
    $starts[] = $m->sub(BigInt::fromInt($i===5 ? 27 : $i-1));
}
$matrix=0; $scars=0; $matched=0;
foreach ($spaces as $ni=>$n) {
    foreach ($starts as $fi=>$first) {
        foreach ([-1,1] as $step) {
            $stream=['first'=>$first,'step'=>$step];
            $before=(string)$first;
            $wanted=$oracle->chooseRank($stream,$n);
            $actual=$patch->choosePatched($stream,$n);
            $historical=$legacy->chooseWrong($stream,$n);
            semak35($actual->equals($wanted),'ORACLE_'.$ni.'_'.$fi.'_'.$step);
            semak35($actual->compare(BigInt::one())>=0
                && $actual->compare($n)<=0,'DOMAIN_'.$matrix);
            semak35((string)$first===$before && $stream['step']===$step,
                'PRESERVE_STREAM_'.$matrix);
            if ($historical->equals($actual)) $matched++; else $scars++;
            $matrix++;
        }
    }
}
semak35($matrix===400 && $scars===392 && $matched===8,'MATRIX_COUNTS');

// Empat parut Stage34 mesti kekal salah; pembaikan mesti setara oracle.
$witnesses=[[BigInt::one(),1],[BigInt::fromInt(2),1],
    [BigInt::fromInt(6),-1],[$m,1]];
$witness=0;
foreach ($witnesses as [$first,$step]) {
    $stream=['first'=>$first,'step'=>$step];
    $wanted=$oracle->chooseRank($stream,$m5);
    $actual=$patch->choosePatched($stream,$m5);
    $historical=$legacy->chooseWrong($stream,$m5);
    $fifth=NormativeMath::save($first->add(BigInt::fromInt(4*$step)));
    semak35($actual->equals($wanted),'WITNESS_ORACLE_'.$witness);
    semak35(!$historical->equals($wanted)
        && $wanted->sub($historical)->equals(
            $fifth->sub(BigInt::one())->mul($m4)),
        'WITNESS_SCAR_'.$witness);
    $witness++;
}
semak35($witness===4,'WITNESS_COUNT');

// Jejak Native: enam mangkuk bagi tiga pasang hari, kernel baharu bebas.
$kernel=new BootstrapKernel();$otherKernel=new BootstrapKernel();$real=0;
foreach ([
    [NormativeMath::FOUNDATION_DAY,NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY,NormativeMath::TABLETS_DAY+17],
    [10000000,-10000000]
] as [$c,$t]) {
    $sauce=$oracle->sauce($c,$t);
    for ($id=1;$id<=6;$id++) {
        $stream=$oracle->askBowl($sauce,$id,23);
        $expected=$oracle->chooseRank($stream,$m5);
        $first=$kernel->chooseQuintRank($c,$t,$id,23,$m5);
        $second=$otherKernel->chooseQuintRank($c,$t,$id,23,$m5);
        $old=$kernel->legacyChooseQuintRank($c,$t,$id,23,$m5);
        semak35($first->equals($expected)&&$first->equals($second),
            'REAL_'.$c.'_'.$t.'_'.$id);
        semak35($old->equals($legacy->chooseWrong($stream,$m5)),
            'LEGACY_REAL_'.$c.'_'.$t.'_'.$id);
        $real++;
    }
}
semak35($real===18,'REAL_COUNT');

$invalid=0;
foreach ([
    [['first'=>BigInt::zero(),'step'=>1],$m5],
    [['first'=>$m->add(BigInt::one()),'step'=>1],$m5],
    [['first'=>BigInt::one(),'step'=>0],$m5],
    [['first'=>BigInt::one(),'step'=>2],$m5],
    [['first'=>BigInt::one(),'step'=>1],$m4],
    [['first'=>BigInt::one(),'step'=>1],$m5->add(BigInt::one())]
] as [$stream,$n]) {
    try {
        $patch->choosePatched($stream,$n);
        throw new RuntimeException('INVALID_ACCEPTED');
    } catch(InvalidArgumentException $e) {
        $invalid++;
    }
}
semak35($invalid===6,'INVALID_COUNT');

$src=dirname(__DIR__).'/src';
$patchCode=(string)file_get_contents($src.'/Patches/FifthDigitPatch17.php');
$legacyCode=(string)file_get_contents($src.'/Legacy/LegacyMissingFifthDigit17.php');
$kernelCode=(string)file_get_contents($src.'/BootstrapKernel.php');
semak35(str_contains($patchCode,'$this->legacy->chooseWrong($stream, $n)')
    && str_contains($patchCode,'for ($j = 0; $j < 5; $j++)')
    && str_contains($legacyCode,'for ($j = 0; $j < 4; $j++)')
    && str_contains($kernelCode,
        "dispatch('MISSING_FIFTH_DIGIT_LEGACY', ".'$context)')
    && str_contains($kernelCode,
        "dispatch('FIFTH_DIGIT_PATCH_17', ".'$context)'),
    'STATIC_SCAR');
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($src,FilesystemIterator::SKIP_DOTS)
) as $file) {
    if (strtolower($file->getExtension())!=='php') continue;
    $source=(string)file_get_contents($file->getPathname());
    semak35(!str_contains($source,'NormativeMath')
        && !str_contains($source,'NormativeSauce'),
        'NO_ORACLE_PRODUCTION');
}
echo "LULUS Stage35 PATCH17 matrix={$matrix} parut={$scars}"
    ." sepadan={$matched} saksi={$witness} real={$real} invalid={$invalid}\n";
