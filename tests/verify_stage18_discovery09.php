<?php
declare(strict_types=1);

// Penemuan mesti gagal secara terkawal kerana tuangan membaca ID tetap.
$cmd=[PHP_BINARY,'-d','memory_limit=512M',__DIR__.'/stage18_discovery09_tests.php'];
$process=proc_open($cmd,[0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes,dirname(__DIR__));
if(!is_resource($process))throw new RuntimeException('STAGE18_PROCESS_FAILED');
fclose($pipes[0]);
$out=stream_get_contents($pipes[1]);
$err=stream_get_contents($pipes[2]);
fclose($pipes[1]);fclose($pipes[2]);
$exit=proc_close($process);
echo $out;
if($err!=='')fwrite(STDERR,$err);
$valid=$exit===1&&$err===''
    &&str_contains($out,'KEPUTUSAN MERAH_DIJANGKA salah=1800 sepadan=360 pangkat=720 real=4 lain=0')
    &&!str_contains($out,'RALAT_');
$root=dirname(__DIR__).'/src';
$legacy=(string)file_get_contents($root.'/Legacy/LegacyFixedPositionPours.php');
$factory=(string)file_get_contents($root.'/Legacy/LegacyBowlFactory.php');
$kernel=(string)file_get_contents($root.'/BootstrapKernel.php');
$valid=$valid
    &&str_contains($legacy,'$oldBowls[1]')
    &&str_contains($legacy,'$oldBowls[2]')
    &&str_contains($legacy,'$oldBowls[3]')
    &&str_contains($factory,'function initialBowls(')
    &&str_contains($kernel,"dispatch('FIXED_POSITION_POURS_LEGACY', ".'$context)')
    &&str_contains($kernel,"dispatch('BOWL_PERMUTATION_PATCH_08', ".'$context)')
    &&str_contains($kernel,"dispatch('POURS_ALIAS_PATCH_09', ".'$context)');
foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root,FilesystemIterator::SKIP_DOTS)) as $file){
    if(strtolower($file->getExtension())!=='php')continue;
    $body=(string)file_get_contents($file->getPathname());
    if(str_contains($body,'NormativeMath')
       ||str_contains($body,'NormativeSauce')){
        $valid=false;
    }
    if ((str_contains($body,'function patchedPours(')
       || str_contains($body,'function installOrderAliases('))
       && $file->getFilename() !== 'PoursAliasPatch09.php') {
        $valid=false;
    }
}
if(!$valid){fwrite(STDERR,"GAGAL: bukti tuangan posisi tetap tidak sah\n");exit(1);}
echo "LULUS kontrak merah 09; tuangan menggunakan identiti tetap bukan posisi\n";
