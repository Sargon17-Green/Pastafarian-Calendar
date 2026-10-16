<?php
declare(strict_types=1);
// Pengesah hijau hanya menerima RED sejarah yang tepat.
$cmd=[PHP_BINARY,'-d','memory_limit=512M',__DIR__.'/stage12_discovery06_tests.php'];
$p=proc_open($cmd,[0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes,dirname(__DIR__));
if(!is_resource($p))throw new RuntimeException('STAGE12_PROCESS_FAILED');
fclose($pipes[0]);$out=stream_get_contents($pipes[1]);$err=stream_get_contents($pipes[2]);
fclose($pipes[1]);fclose($pipes[2]);$exit=proc_close($p);echo $out;
if($err!=='')fwrite(STDERR,$err);
$valid=$exit===1&&$err===''&&substr_count($out,'GAGAL_DIJANGKA kes=')===44
 &&str_contains($out,'GAGAL_DIJANGKA kes=asas_sama i=1 back=1 slot=0 hidden_k=1')
 &&str_contains($out,'GAGAL_DIJANGKA kes=jauh_balik i=1 back=7 slot=-6 hidden_k=7')
 &&str_contains($out,'KEPUTUSAN MERAH_DIJANGKA missing=44 found=508 hidden=28 lain=0')
 &&!str_contains($out,'RALAT_');
$root=dirname(__DIR__).'/src';
$iterator=new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root,FilesystemIterator::SKIP_DOTS));
$seen=false;
foreach($iterator as $file){
 if(strtolower($file->getExtension())!=='php')continue;
 $s=(string)file_get_contents($file->getPathname());
 if(str_contains($s,'NormativeMath')||str_contains($s,'NormativeSauce')||str_contains($s,'function priorPatch('))$valid=false;
 if(str_contains($s,'function legacyPrior(')){
   if($file->getFilename()!=='LegacyVisiblePrior.php')$valid=false;else $seen=true;
 }
}
$k=(string)file_get_contents($root.'/BootstrapKernel.php');
$valid=$valid&&$seen&&str_contains($k,"dispatch('VISIBLE_PRIOR_LEGACY', ".'$context)')
 &&str_contains($k,"dispatch('HIDDEN_PATCH_05', ".'$context)');
if(!$valid){fwrite(STDERR,"GAGAL: sejarah prior tidak terbukti\n");exit(1);}
echo "LULUS kontrak merah 06; prior legacy buta terhadap hidden\n";
