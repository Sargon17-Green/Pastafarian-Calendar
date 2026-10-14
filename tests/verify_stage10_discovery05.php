<?php
declare(strict_types=1);

// Penerimaan penemuan hanya apabila regresi legacy merah dengan corak tepat.
$command = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage10_discovery05_tests.php'];
$process = proc_open(
    $command,
    [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']],
    $pipes,
    dirname(__DIR__)
);
if (!is_resource($process)) {
    throw new RuntimeException('PROSES_STAGE10_GAGAL');
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
    && substr_count($stdout, 'GAGAL_DIJANGKA kes=') === 72
    && substr_count($stdout, 'SEPADAN_DIJANGKA kes=') === 12
    && str_contains($stdout, 'GAGAL_DIJANGKA kes=asas_sama slot=1:')
    && str_contains($stdout, 'GAGAL_DIJANGKA kes=jauh_belakang slot=7:')
    && str_contains($stdout, 'SEPADAN_DIJANGKA kes=loh_sama slot=4')
    && str_contains($stdout, 'KEPUTUSAN MERAH_DIJANGKA perbezaan=72 sepadan=12 pasangan=12 lain=0')
    && !str_contains($stdout, 'RALAT_');

$src = dirname(__DIR__) . '/src';
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($src, FilesystemIterator::SKIP_DOTS)
);
$foundWrongStorage = false;
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') {
        continue;
    }
    $body = (string)file_get_contents($file->getPathname());
    if (str_contains($body, 'NormativeMath')
        || str_contains($body, 'NormativeSauce')
        || str_contains($body, 'function hiddenByNearness(')) {
        $valid = false;
    }
    if (str_contains($body, 'function wrongNearness(')) {
        $foundWrongStorage = $foundWrongStorage
            || $file->getFilename() === 'LegacyHiddenBackward.php';
        if ($file->getFilename() !== 'LegacyHiddenBackward.php') {
            $valid = false;
        }
    }
}
$kernel = (string)file_get_contents($src . '/BootstrapKernel.php');
$valid = $valid && $foundWrongStorage
    && str_contains($kernel, "dispatch('HIDDEN_BACKWARD_LEGACY', " . '$context)');
if (!$valid) {
    fwrite(STDERR, "GAGAL: bukti stor terbalik bukan merah yang diwajibkan\n");
    exit(1);
}
echo "LULUS kontrak merah 05; stor terbalik wujud dan pembetulan belum hadir\n";
