<?php
declare(strict_types=1);

// Kod ujian merah dijalankan sebagai proses PHP berasingan agar kod keluarannya nyata.
$cmd = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage04_discovery02_tests.php'];
$process = proc_open(
    $cmd,
    [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']],
    $pipes,
    dirname(__DIR__)
);
if (!is_resource($process)) {
    throw new RuntimeException('PROSES_PHP_GAGAL');
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
    && substr_count($stdout, 'GAGAL_DIJANGKA offset=') === 65
    && substr_count($stdout, 'LULUS_TEPAT offset=') === 64
    && substr_count($stdout, 'LULUS_TEPI day=') === 2
    && str_contains($stdout, 'GAGAL_DIJANGKA offset=0:')
    && str_contains($stdout, 'GAGAL_DIJANGKA offset=1:')
    && str_contains($stdout, 'GAGAL_DIJANGKA offset=64:')
    && str_contains($stdout, 'LULUS_TEPAT offset=-1:')
    && str_contains($stdout, 'KEPUTUSAN MERAH_DIJANGKA perbezaan=65 sepadan=64 tepi=2 lain=0')
    && !str_contains($stdout, 'RALAT_');

// Selepas Stage 5, ujian ini mesti mengekalkan kecacatan lama serta wujudnya pembetul yang berasingan.
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator(dirname(__DIR__) . '/src', FilesystemIterator::SKIP_DOTS)
);
$legacyExists = false;
$patchExists = false;
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') {
        continue;
    }
    $contents = (string)file_get_contents($file->getPathname());
    if (str_contains($contents, 'function dayTagWithFoundationScar(')) {
        $patchExists = true;
        if (basename($file->getPathname()) !== 'FoundationScarPatch02.php') {
            $valid = false;
        }
    }
    if (str_contains($contents, 'function oldDayTag(')) {
        $legacyExists = true;
    }
}
$valid = $valid && $legacyExists && $patchExists;

if (!$valid) {
    fwrite(STDERR, "GAGAL: corak merah penemuan 02 atau pemisahan tampalan salah\n");
    exit(1);
}
echo "LULUS bukti merah khusus 02; semua penyelewengan dan had disahkan\n";
