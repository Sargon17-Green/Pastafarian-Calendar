<?php
declare(strict_types=1);

// Pengesah hijau hanya menerima kegagalan legacy yang tepat dan konsisten.
$command = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage08_discovery04_tests.php'];
$process = proc_open(
    $command,
    [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']],
    $pipes,
    dirname(__DIR__)
);
if (!is_resource($process)) {
    throw new RuntimeException('PROSES_STAGE08_GAGAL');
}
fclose($pipes[0]);
$stdout = stream_get_contents($pipes[1]);
$stderr = stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$exit = proc_close($process);
echo $stdout;
if ($stderr !== '') {
    fwrite(STDERR, $stderr);
}
$valid = $exit === 1
    && $stderr === ''
    && substr_count($stdout, 'GAGAL_DIJANGKA batu=') === 45
    && substr_count($stdout, 'LULUS_ASAS batu=1 semua=5') === 1
    && str_contains($stdout, 'GAGAL_DIJANGKA batu=2 komponen=4')
    && str_contains($stdout, 'GAGAL_DIJANGKA batu=46 komponen=')
    && str_contains($stdout, 'KEPUTUSAN MERAH_DIJANGKA perbezaan=45 sepadan=1 lain=0')
    && !str_contains($stdout, 'RALAT_');

$root = dirname(__DIR__) . '/src';
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)
);
$legacyFound = false;
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') {
        continue;
    }
    $body = (string)file_get_contents($file->getPathname());
    if (str_contains($body, 'NormativeMath') || str_contains($body, 'stonePatch(')) {
        $valid = false;
    }
    if (str_contains($body, 'function mutateStonesWrong(')) {
        $legacyFound = $legacyFound || $file->getFilename() === 'LegacyStoneMutation.php';
        if ($file->getFilename() !== 'LegacyStoneMutation.php') {
            $valid = false;
        }
    }
}
$kernel = (string)file_get_contents($root . '/BootstrapKernel.php');
$valid = $valid && $legacyFound
    && str_contains($kernel, "dispatch('STONE_MUTATION_LEGACY', " . '$context)');
if (!$valid) {
    fwrite(STDERR, "GAGAL: bukti mutasi merah bukan corak Stage 8 yang ditetapkan\n");
    exit(1);
}
echo "LULUS kontrak merah 04; mutasi legacy aktif, tampalan 04 belum hadir\n";
