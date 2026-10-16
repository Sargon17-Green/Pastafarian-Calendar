<?php
declare(strict_types=1);

// Pengesah hijau mengiktiraf hanya tiga jadual merah yang tepat.
$cmd = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage14_discovery07_tests.php'];
$p = proc_open($cmd, [0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']], $pipes, dirname(__DIR__));
if (!is_resource($p)) {
    throw new RuntimeException('STAGE14_PROCESS_FAILED');
}
fclose($pipes[0]);
$out = stream_get_contents($pipes[1]);
$err = stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$exit = proc_close($p);
echo $out;
if ($err !== '') fwrite(STDERR, $err);
$valid = $exit === 1
    && $err === ''
    && substr_count($out, 'GAGAL_DIJANGKA kes=') === 138
    && str_contains($out, 'GAGAL_DIJANGKA kes=asas_sama i=1')
    && str_contains($out, 'GAGAL_DIJANGKA kes=jauh_balik i=46')
    && str_contains($out, 'KEPUTUSAN MERAH_DIJANGKA divergence=138 kes=3 julat=138 lain=0')
    && !str_contains($out, 'RALAT_');

$src = dirname(__DIR__) . '/src';
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($src, FilesystemIterator::SKIP_DOTS)
);
$foundLegacy = false;
$foundPatch = false;
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $s = (string)file_get_contents($file->getPathname());
    if (str_contains($s, 'NormativeMath')
        || str_contains($s, 'NormativeSauce')
       ) $valid = false;
    if (str_contains($s, 'function grindPatch(')) {
        if ($file->getFilename() !== 'GrindTablePatch07.php') $valid = false;
        else $foundPatch = true;
    }
    if (str_contains($s, 'function legacyRowAt(')) {
        if ($file->getFilename() !== 'LegacyVisibleGrind.php') $valid = false;
        else $foundLegacy = true;
    }
}
$kernel = (string)file_get_contents($src . '/BootstrapKernel.php');
$valid = $valid && $foundLegacy && $foundPatch
    && str_contains($kernel, "dispatch('VISIBLE_GRIND_PATCH_07', " . '$context)')
    && str_contains($kernel, "dispatch('VISIBLE_GRIND_LEGACY', " . '$context)')
    && str_contains($kernel, "dispatch('PRIOR_PATCH_06', " . '$context)');
if (!$valid) {
    fwrite(STDERR, "GAGAL: bukti indeks grind legacy bukan merah yang tepat\n");
    exit(1);
}
echo "LULUS kontrak merah 07; legacy kekal salah dan sentinel hanya dalam tampalan\n";
