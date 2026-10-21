<?php
declare(strict_types=1);

// Pembalut hijau hanya menerima pencemaran berulang yang dijangka.
$command = [PHP_BINARY,'-d','memory_limit=512M',__DIR__.'/stage20_discovery10_tests.php'];
$process = proc_open($command,[0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes,dirname(__DIR__));
if (!is_resource($process)) throw new RuntimeException('STAGE20_PROCESS_FAILED');
fclose($pipes[0]);
$out = stream_get_contents($pipes[1]);
$err = stream_get_contents($pipes[2]);
fclose($pipes[1]);fclose($pipes[2]);
$exit = proc_close($process);
echo $out;
if ($err !== '') fwrite(STDERR,$err);
$valid = $exit === 1 && $err === ''
    && str_contains($out,'POSISI_PERTAMA_SEPADAN pangkat=720')
    && str_contains($out,'POSISI_BERIKUT_TERCEMAR pangkat=720 kedudukan=2..6')
    && preg_match('/KEPUTUSAN MERAH_DIJANGKA salah=3600 sepadan=720 pangkat=720 real=4 real_salah=[1-9][0-9]* ralat=4 lain=0/', $out) === 1
    && !str_contains($out,'RALAT_');

$root=dirname(__DIR__).'/src';
$legacy=(string)file_get_contents($root.'/Legacy/LegacyInPlaceBowlStir.php');
$kernel=(string)file_get_contents($root.'/BootstrapKernel.php');
$valid = $valid
    && str_contains($legacy,'function stirOneDropWrong(')
    && str_contains($legacy,'$bowls[$id] = $this->save->savePatch(')
    && str_contains($kernel,"dispatch('IN_PLACE_BOWL_STIR_LEGACY', ".'$context)')
    && str_contains($kernel,"dispatch('POURS_ALIAS_PATCH_09', ".'$context)');

foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($root,FilesystemIterator::SKIP_DOTS)
) as $file) {
    if (strtolower($file->getExtension())!=='php') continue;
    $body=(string)file_get_contents($file->getPathname());
    if (str_contains($body,'NormativeMath') || str_contains($body,'NormativeSauce')) {
        $valid=false;
    }
}
if (!$valid) {
    fwrite(STDERR,"GAGAL: pencemaran mangkuk legacy tidak mengikut penemuan terkawal\n");
    exit(1);
}
echo "LULUS kontrak merah 10; mangkuk legacy tercemar tanpa snapshot\n";
