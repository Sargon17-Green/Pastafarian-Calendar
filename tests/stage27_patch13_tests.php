<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyNoRejection13;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\RejectionSamplingPatch13;
use Pastafari\Stage01\Patches\SavePatch01;

function wajib27(bool $value, string $case): void
{
    if (!$value) {
        throw new RuntimeException('GAGAL_STAGE27_' . $case);
    }
}

$oracle = new NormativeSauce();
$m = NormativeMath::m();
$legacy = new LegacyNoRejection13();
$patch = new RejectionSamplingPatch13($legacy, new SavePatch01(new LegacyRemainder()));
$kernel = new BootstrapKernel();
$secondKernel = new BootstrapKernel();
$cases = 0;
$rejected = 0;
$controls = 0;
$scars = 0;

// Rekod setiap panggilan terhadap oracle PHP bebas.
function banding27(
    NormativeSauce $oracle,
    RejectionSamplingPatch13 $patch,
    LegacyNoRejection13 $legacy,
    array $stream,
    BigInt $n,
    string $tag,
    int &$cases,
    int &$rejected,
    int &$controls,
    int &$scars
): void {
    $m = NormativeMath::m();
    $limit = $m->floorDiv($n)->mul($n);
    $expected = $oracle->chooseRank($stream, $n);
    $actual = $patch->choosePatched($stream, $n);
    $old = $legacy->chooseWrong($stream, $n);
    wajib27($actual->equals($expected), 'ORACLE_' . $tag);
    wajib27($actual->compare(BigInt::one()) >= 0
        && $actual->compare($n) <= 0, 'DOMAIN_' . $tag);
    if ($stream['first']->compare($limit) <= 0) {
        $controls++;
        wajib27($actual->equals($old), 'CONTROL_' . $tag);
    } else {
        $rejected++;
        if (!$actual->equals($old)) {
            $scars++;
        }
    }
    $cases++;
}

// Saksi yang menonjolkan keperluan penolakan pada empat ruang DISCOVERY13.
foreach ([3, 10, 97, 720] as $size) {
    $n = BigInt::fromInt($size);
    $limit = $m->floorDiv($n)->mul($n);
    $stream = ['first'=>$limit->add(BigInt::one()),'step'=>-1];
    banding27($oracle,$patch,$legacy,$stream,$n,'SCAR_' . $size,
        $cases,$rejected,$controls,$scars);
    wajib27($patch->choosePatched($stream, $n)->equals($n),
        'SCAR_RESOLVED_' . $size);
}
wajib27($scars === 4, 'ALL_FOUR_SCARS');

// Domain 1..M pada sempadan dan kedua-dua arah, dengan setiap n 2..129.
// Tiada semakan berdasarkan kod produksi sahaja: semua dibandingkan kepada oracle.
for ($size = 2; $size <= 129; $size++) {
    $n = BigInt::fromInt($size);
    $limit = $m->floorDiv($n)->mul($n);
    $rema = $m->sub($limit);
    $values = [
        $limit,
        $limit->sub(BigInt::one()),
        $limit->add(BigInt::one()),
        $m,
        BigInt::one(),
        BigInt::fromInt($size),
    ];
    foreach ($values as $index=>$first) {
        if ($first->compare(BigInt::one()) < 0
            || $first->compare($m) > 0) continue;
        foreach ([-1,1] as $step) {
            banding27($oracle,$patch,$legacy,
                ['first'=>$first,'step'=>$step], $n,
                $size . '_' . $index . '_' . $step,
                $cases,$rejected,$controls,$scars);
        }
    }
}

// Kes n=1, n=M dan sempadan sangat luas tidak menolak sebarang sampel.
foreach ([$m, BigInt::one(), $m->sub(BigInt::one()), BigInt::fromInt(720)] as $n) {
    foreach ([BigInt::one(),$m] as $first) {
        foreach ([-1,1] as $step) {
            banding27($oracle,$patch,$legacy,
                ['first'=>$first,'step'=>$step],$n,
                'BOUND_' . $n->toString() . '_' . $first->toString() . '_' . $step,
                $cases,$rejected,$controls,$scars);
        }
    }
}

// Ujian penolakan berganda: guna titik akhir zon ditolak untuk beberapa n.
foreach ([10, 97, 720, 1025] as $size) {
    $n = BigInt::fromInt($size);
    $limit = $m->floorDiv($n)->mul($n);
    if ($limit->equals($m)) continue;
    banding27($oracle,$patch,$legacy,
        ['first'=>$m,'step'=>-1],$n,'MULTI_' . $size,
        $cases,$rejected,$controls,$scars);
    banding27($oracle,$patch,$legacy,
        ['first'=>$limit->add(BigInt::one()),'step'=>1],$n,
        'WRAP_' . $size,
        $cases,$rejected,$controls,$scars);
}

// Laluan produksi bukan hanya fungsi tampalan: tiga pasangan hari dan enam mangkuk.
$real = 0;
foreach ([
    [NormativeMath::FOUNDATION_DAY,NormativeMath::FOUNDATION_DAY],
    [NormativeMath::TABLETS_DAY,NormativeMath::TABLETS_DAY+17],
    [10000000,-10000000],
] as [$c,$t]) {
    $referenceSauce = $oracle->sauce($c,$t);
    for($id=1;$id<=6;$id++) {
        $stream=$oracle->askBowl($referenceSauce,$id,23);
        $wanted=$oracle->chooseRank($stream,BigInt::fromInt(97));
        $actual=$kernel->chooseRank($c,$t,$id,23,BigInt::fromInt(97));
        $again=$secondKernel->chooseRank($c,$t,$id,23,BigInt::fromInt(97));
        $historical=$kernel->legacyChooseRank($c,$t,$id,23,BigInt::fromInt(97));
        wajib27($actual->equals($wanted)&&$actual->equals($again),
            'REAL_' . $c . '_' . $t . '_' . $id);
        wajib27($historical->equals(
            $legacy->chooseWrong($kernel->askBowl($c,$t,$id,23),BigInt::fromInt(97))),
            'LEGACY_REMAINS_' . $id);
        $real++;
    }
}

$invalid=0;
foreach ([
    [['first'=>BigInt::zero(),'step'=>1],BigInt::fromInt(10)],
    [['first'=>BigInt::one(),'step'=>0],BigInt::fromInt(10)],
    [['first'=>BigInt::one(),'step'=>1],BigInt::zero()],
    [['first'=>BigInt::one(),'step'=>1],$m->add(BigInt::one())],
    [['first'=>$m->add(BigInt::one()),'step'=>-1],BigInt::fromInt(10)],
    [['first'=>BigInt::one(),'step'=>2],BigInt::fromInt(10)],
] as [$stream,$n]) {
    try {
        $patch->choosePatched($stream,$n);
        throw new RuntimeException('BAD_INPUT_ACCEPTED');
    } catch (InvalidArgumentException $error) {
        $invalid++;
    }
}
wajib27($invalid===6,'BAD_INPUTS');

// Pemeriksaan statik bagi bukti panggilan legacy, pemilihan cutoff, dan route.
$root=dirname(__DIR__) . '/src';
$patchText=(string)file_get_contents($root.'/Patches/RejectionSamplingPatch13.php');
$legacyText=(string)file_get_contents($root.'/Legacy/LegacyNoRejection13.php');
$kernelText=(string)file_get_contents($root.'/BootstrapKernel.php');
wajib27(
    str_contains($patchText,'$this->legacy->chooseWrong($stream, $n)')
    && str_contains($patchText,'$cutoff = $this->modulus->floorDiv($n)->mul($n);')
    && str_contains($patchText,'$this->save->savePatch($candidate->add($delta))')
    && str_contains($legacyText,'return $first->sub(BigInt::one())->mod($n)->add(BigInt::one());')
    && str_contains($kernelText,"dispatch('NO_REJECTION_CHOICE_LEGACY', " . '$context)')
    && str_contains($kernelText,"dispatch('REJECTION_SAMPLING_PATCH_13', " . '$context)'),
    'STATIC_CONTRACT'
);
wajib27($cases>=1500 && $rejected>0 && $controls>0
    && $real===18,'COUNTS');
echo "LULUS Stage27 PATCH13 cases={$cases} rejected={$rejected}"
    . " controls={$controls} historical_scars={$scars}"
    . " real={$real} invalid={$invalid}\n";
