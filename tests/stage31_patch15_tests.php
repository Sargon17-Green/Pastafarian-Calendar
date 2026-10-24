<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyMissingThirdDigit15;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;
use Pastafari\Stage01\Patches\ThirdDigitPatch15;

function wajib31(bool $ok, string $label): void {
    if (!$ok) throw new RuntimeException('STAGE31_' . $label);
}
$m = NormativeMath::m();
$m3 = $m->square()->mul($m);
$save = new SavePatch01(new LegacyRemainder());
$legacy = new LegacyMissingThirdDigit15($save);
$patch = new ThirdDigitPatch15($legacy, $save);
$oracle = new NormativeSauce();
$cases = 0; $scars = 0; $matches = 0;
$sizes = [$m->square()->add(BigInt::one()),
    $m->square()->add(BigInt::fromInt(2)), $m3->sub(BigInt::one()), $m3];
foreach ($sizes as $sizeNo => $n) {
    for ($i = 1; $i <= 25; $i++) {
        foreach ([BigInt::fromInt($i), $m->sub(BigInt::fromInt($i === 3 ? 26 : $i - 1))] as $first) {
            foreach ([-1, 1] as $step) {
                $stream = ['first'=>$first, 'step'=>$step];
                $correct = $oracle->chooseRank($stream, $n);
                $actual = $patch->choosePatched($stream, $n);
                $old = $legacy->chooseWrong($stream, $n);
                wajib31($correct->equals($actual), 'ORACLE_'.$cases);
                wajib31($actual->compare(BigInt::one()) >= 0
                    && $actual->compare($n) <= 0, 'RANGE_'.$cases);
                if ($old->equals($correct)) $matches++; else $scars++;
                $cases++;
            }
        }
    }
}
wajib31($cases === 400 && $scars > 350 && $matches > 0, 'MATRIX');
$witnesses = [[BigInt::one(),1],[BigInt::fromInt(2),1],
    [BigInt::fromInt(4),-1],[$m,1]];
foreach ($witnesses as $id => [$first,$step]) {
    $stream = ['first'=>$first,'step'=>$step];
    wajib31($patch->choosePatched($stream,$m3)->equals(
        $oracle->chooseRank($stream,$m3)), 'WITNESS_'.$id);
    wajib31(!$legacy->chooseWrong($stream,$m3)->equals(
        $oracle->chooseRank($stream,$m3)), 'SCAR_'.$id);
}
$real = 0; $kernel = new BootstrapKernel();
$other = new BootstrapKernel(); $n = $m->square()->add(BigInt::one());
foreach ([[NormativeMath::FOUNDATION_DAY,NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY,NormativeMath::TABLETS_DAY+17],
    [10000000,-10000000]] as [$c,$t]) {
    $sauce = $oracle->sauce($c,$t);
    for ($id=1;$id<=6;$id++) {
        $stream = $oracle->askBowl($sauce,$id,23);
        $want = $oracle->chooseRank($stream,$n);
        $got = $kernel->chooseTripleRank($c,$t,$id,23,$n);
        $again = $other->chooseTripleRank($c,$t,$id,23,$n);
        $old = $kernel->legacyChooseTripleRank($c,$t,$id,23,$n);
        wajib31($got->equals($want) && $again->equals($got), 'REAL_'.$id);
        wajib31($old->equals($legacy->chooseWrong($stream,$n)), 'HISTORY_'.$id);
        $real++;
    }
}
$invalid=0;
foreach ([[['first'=>BigInt::zero(),'step'=>1],$m3],
    [['first'=>$m->add(BigInt::one()),'step'=>1],$m3],
    [['first'=>BigInt::one(),'step'=>0],$m3],
    [['first'=>BigInt::one(),'step'=>2],$m3],
    [['first'=>BigInt::one(),'step'=>1],$m->square()],
    [['first'=>BigInt::one(),'step'=>1],$m3->add(BigInt::one())]] as [$stream,$n]) {
    try { $patch->choosePatched($stream,$n); throw new RuntimeException('INVALID_ACCEPTED'); }
    catch (InvalidArgumentException $e) { $invalid++; }
}
wajib31($invalid === 6 && $real === 18, 'INPUTS_AND_NATIVE');
$src=dirname(__DIR__).'/src';
$code=(string)file_get_contents($src.'/Patches/ThirdDigitPatch15.php');
$legacyCode=(string)file_get_contents($src.'/Legacy/LegacyMissingThirdDigit15.php');
$kernelCode=(string)file_get_contents($src.'/BootstrapKernel.php');
wajib31(str_contains($code,'$this->legacy->chooseWrong($stream, $n)')
    && str_contains($code,'$j < 3')
    && str_contains($legacyCode,'$j < 2')
    && str_contains($kernelCode, "dispatch('THIRD_DIGIT_PATCH_15', " . '$context)'), 'SCAR');
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($src,FilesystemIterator::SKIP_DOTS)) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $text=(string)file_get_contents($file->getPathname());
    wajib31(!str_contains($text,'NormativeMath') && !str_contains($text,'NormativeSauce'), 'ORACLE_SRC');
}
echo "LULUS Stage31 PATCH15 cases={$cases} scars={$scars} matches={$matches} real={$real} invalid={$invalid}\n";
