<?php
declare(strict_types=1);

$p=proc_open(
    [PHP_BINARY,'-d','memory_limit=512M',__DIR__.'/stage30_discovery15_tests.php'],
    [0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes,dirname(__DIR__)
);
if (!is_resource($p)) throw new RuntimeException('STAGE30_PROC');
fclose($pipes[0]);
$out=stream_get_contents($pipes[1]);
$err=stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$exit=proc_close($p);
echo $out;
if ($err!=='') fwrite(STDERR,$err);
$valid=$exit===1 && $err===''
    && substr_count($out,'GAGAL_DIJANGKA saksi=')===4
    && str_contains($out,'GAGAL_DIJANGKA saksi=naik_1')
    && str_contains($out,'GAGAL_DIJANGKA saksi=naik_2')
    && str_contains($out,'GAGAL_DIJANGKA saksi=turun_4')
    && str_contains($out,'GAGAL_DIJANGKA saksi=lilit_M')
    && str_contains($out,
        'KEPUTUSAN MERAH_DIJANGKA parut=4 matriks=40 beza=36 real=3 ralat=5 lain=0')
    && !str_contains($out,'RALAT_')
    && !str_contains($out,'TIDAK_SAH');
$src=dirname(__DIR__).'/src';
$legacy=(string)file_get_contents($src.'/Legacy/LegacyMissingThirdDigit15.php');
$kernel=(string)file_get_contents($src.'/BootstrapKernel.php');
$valid=$valid && str_contains($legacy,'for ($j = 0; $j < 2; $j++)')
    && str_contains($kernel,"dispatch('MISSING_THIRD_DIGIT_LEGACY', " . '$context)')
    && (!is_file($src.'/Patches/ThirdDigitPatch15.php')
        || (str_contains($kernel,
                "dispatch('THIRD_DIGIT_PATCH_15', " . '$context)')
            && str_contains((string)file_get_contents(
                    $src.'/Patches/ThirdDigitPatch15.php'),
                '$this->legacy->chooseWrong($stream, $n)')));
foreach(new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($src,FilesystemIterator::SKIP_DOTS)
) as $file) {
    if(strtolower($file->getExtension())!=='php') continue;
    $source=(string)file_get_contents($file->getPathname());
    if(str_contains($source,'NormativeMath')||str_contains($source,'NormativeSauce'))
        $valid=false;
}
if (!$valid) {
    fwrite(STDERR,"GAGAL kontrak merah Stage30 tidak tepat\n");
    exit(1);
}
echo "LULUS kontrak merah 15; digit ketiga tersisih semasa pilihan besar\n";
