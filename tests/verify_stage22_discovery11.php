<?php
declare(strict_types=1);

// Pengesah hijau hanya menerima RED yang benar-benar terasing pada susunan.
$command = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage22_discovery11_tests.php'];
$process = proc_open(
    $command, [0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],
    $pipes, dirname(__DIR__)
);
if (!is_resource($process)) throw new RuntimeException('STAGE22_PROCESS_FAILED');
fclose($pipes[0]);
$out = stream_get_contents($pipes[1]);
$err = stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$exit = proc_close($process);
echo $out;
if ($err !== '') fwrite(STDERR, $err);

$valid = $exit === 1 && $err === ''
    && substr_count($out, 'GAGAL_DIJANGKA kes=') === 3
    && str_contains($out, 'GAGAL_DIJANGKA kes=asas susunan_46_ditindih_oleh_post_12')
    && str_contains($out, 'GAGAL_DIJANGKA kes=loh susunan_46_ditindih_oleh_post_12')
    && str_contains($out, 'GAGAL_DIJANGKA kes=jauh susunan_46_ditindih_oleh_post_12')
    && str_contains($out, 'KEPUTUSAN MERAH_DIJANGKA kes=3 susunan_salah=3 mangkuk_betul=18 kacau=36 lain=0')
    && !str_contains($out, 'RALAT_');

$root = dirname(__DIR__) . '/src';
$code = (string)file_get_contents($root . '/Legacy/LegacyOverwrittenOrder11.php');
$kernel = (string)file_get_contents($root . '/BootstrapKernel.php');
$valid = $valid
    && str_contains($code, 'function sauceWrong(')
    && str_contains($code, '$order = $this->permutation->permutationPatch($saved);')
    && str_contains($code, "'orderAtDrop46' => \$order")
    && str_contains($kernel, "dispatch('OVERWRITTEN_ORDER_46_LEGACY', " . '$context)')
    && !str_contains($code, 'orderAt46Latch');
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)
) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $text = (string)file_get_contents($file->getPathname());
    if (str_contains($text, 'NormativeMath')
        || str_contains($text, 'NormativeSauce')
        || str_contains($text, 'function latchOrderAt46(')) $valid = false;
}
if (!$valid) {
    fwrite(STDERR, "GAGAL: susunan titisan 46 yang ditindih tidak terbukti sebagai RED tepat\n");
    exit(1);
}
echo "LULUS kontrak merah 11; susunan 46 ditindih, mangkuk akhir tetap betul\n";
