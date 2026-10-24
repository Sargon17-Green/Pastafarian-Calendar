<?php
declare(strict_types=1);
$p = proc_open(
    [PHP_BINARY,'-d','memory_limit=512M',__DIR__.'/stage32_discovery16_tests.php'],
    [0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes,dirname(__DIR__)
);
if (!is_resource($p)) throw new RuntimeException('STAGE32_PROCESS');
fclose($pipes[0]);
$out=stream_get_contents($pipes[1]);
$err=stream_get_contents($pipes[2]);
fclose($pipes[1]); fclose($pipes[2]);
$exit=proc_close($p);
echo $out;
if ($err!=='') fwrite(STDERR,$err);
$valid = $exit===1 && $err===''
    && substr_count($out,'GAGAL_DIJANGKA saksi=')===4
    && str_contains($out,'GAGAL_DIJANGKA saksi=asas')
    && str_contains($out,'GAGAL_DIJANGKA saksi=menaik')
    && str_contains($out,'GAGAL_DIJANGKA saksi=menurun')
    && str_contains($out,'GAGAL_DIJANGKA saksi=lilitan')
    && str_contains($out,'KEPUTUSAN MERAH_DIJANGKA parut=4 matriks=56 beza=52 real=3 ralat=5 lain=0')
    && !str_contains($out,'RALAT_') && !str_contains($out,'TIDAK_SAH');
$root=dirname(__DIR__).'/src';
$legacy=(string)file_get_contents($root.'/Legacy/LegacyMissingFourthDigit16.php');
$kernel=(string)file_get_contents($root.'/BootstrapKernel.php');
$valid=$valid
    && str_contains($legacy,'for ($j = 0; $j < 3; $j++)')
    && str_contains($kernel,"dispatch('MISSING_FOURTH_DIGIT_LEGACY', " . '$context)')
    && !is_file($root.'/Patches/FourthDigitPatch16.php');
foreach(new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($root,FilesystemIterator::SKIP_DOTS)) as $file) {
    if(strtolower($file->getExtension())!=='php')continue;
    $code=(string)file_get_contents($file->getPathname());
    if(str_contains($code,'NormativeMath')||str_contains($code,'NormativeSauce')) $valid=false;
}
if (!$valid) {
    fwrite(STDERR,"GAGAL: kontrak merah Stage32 tidak tepat\n");
    exit(1);
}
echo "LULUS kontrak merah 16; digit keempat hilang daripada pilihan empat digit\n";
