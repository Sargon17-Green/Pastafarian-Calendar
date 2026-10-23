<?php
declare(strict_types=1);

// Lulus hanya untuk empat saksi digit terbalik dan tiada ralat lain.
$p=proc_open(
    [PHP_BINARY,'-d','memory_limit=512M',__DIR__.'/stage28_discovery14_tests.php'],
    [0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes,dirname(__DIR__)
);
if (!is_resource($p)) {
    throw new RuntimeException('STAGE28_PROCESS');
}
fclose($pipes[0]);
$out=stream_get_contents($pipes[1]);
$err=stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$exit=proc_close($p);
echo $out;
if ($err !== '') fwrite(STDERR,$err);

$valid=$exit===1 && $err===''
    && substr_count($out,'GAGAL_DIJANGKA kes=')===4
    && str_contains($out,'GAGAL_DIJANGKA kes=asas')
    && str_contains($out,'GAGAL_DIJANGKA kes=menaik')
    && str_contains($out,'GAGAL_DIJANGKA kes=menurun')
    && str_contains($out,'GAGAL_DIJANGKA kes=lilitan')
    && preg_match('/KEPUTUSAN MERAH_DIJANGKA merah=4 matriks=48'
        . ' salah_matriks=([0-9]+) real=3 ralat=5 lain=0/', $out,$groups)===1
    && (int)$groups[1]>=40 && (int)$groups[1]<=48
    && !str_contains($out,'RALAT_')
    && !str_contains($out,'TIDAK_SAH');
$src=dirname(__DIR__).'/src';
$legacy=(string)file_get_contents($src.'/Legacy/LegacyBigEndianDigits14.php');
$kernel=(string)file_get_contents($src.'/BootstrapKernel.php');
$valid=$valid
    && str_contains($legacy,'$digitWeights = [$this->modulus, BigInt::one()];')
    && str_contains($kernel,"dispatch('BIG_ENDIAN_DIGITS_LEGACY', " . '$context)')
    && (!is_file($src.'/Patches/BigEndianDigitsPatch14.php')
        || (str_contains($kernel,
                "dispatch('TWO_DIGIT_WEIGHTS_PATCH_14', " . '$context)')
            && str_contains((string)file_get_contents(
                    $src.'/Patches/BigEndianDigitsPatch14.php'),
                '$this->legacy->chooseWrong($stream, $n)')));
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($src,FilesystemIterator::SKIP_DOTS)
) as $file) {
    if (strtolower($file->getExtension())!=='php') continue;
    $source=(string)file_get_contents($file->getPathname());
    if (str_contains($source,'NormativeMath')||str_contains($source,'NormativeSauce')) {
        $valid=false;
    }
}
if (!$valid) {
    fwrite(STDERR,"GAGAL: bukti salah susunan digit tidak tepat\n");
    exit(1);
}
echo "LULUS kontrak merah 14; sampel pertama bukan digit paling penting\n";
