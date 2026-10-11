<?php
declare(strict_types=1);

// Terima hanya regresi merah yang dijadualkan bagi jarak sejarah.
$command = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage06_discovery03_tests.php'];
$process = proc_open(
    $command,
    [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']],
    $pipes,
    dirname(__DIR__)
);
if (!is_resource($process)) {
    throw new RuntimeException('PROSES_STAGE06_TIDAK_WUJUD');
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
    && substr_count($stdout, 'GAGAL_DIJANGKA kes=') === 144
    && substr_count($stdout, 'KEPUTUSAN MERAH_DIJANGKA perbezaan=144 jumlah=144 tepi=8 lain=0') === 1
    && !str_contains($stdout, 'RALAT_');
foreach (['grid_6_6', 'grid_0_10', 'grid_10_0', 'sifar_sama', 'tablet_sama', 'min_max', 'max_min', 'min_sama', 'max_sama'] as $case) {
    $valid = $valid && str_contains($stdout, 'GAGAL_DIJANGKA kes=' . $case . ':');
}

$root = dirname(__DIR__) . '/src';
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)
);
$legacyLocated = false;
$patchLocated = false;
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') {
        continue;
    }
    $body = (string)file_get_contents($file->getPathname());
    if (str_contains($body, 'function distanceCountPatch03(')) {
        $patchLocated = $patchLocated || $file->getFilename() === 'DistanceCountPatch03.php';
        if ($file->getFilename() !== 'DistanceCountPatch03.php') {
            $valid = false;
        }
    }
    if (str_contains($body, 'function oldDistance(')) {
        $legacyLocated = $legacyLocated || $file->getFilename() === 'LegacyDistance.php';
        if ($file->getFilename() !== 'LegacyDistance.php') {
            $valid = false;
        }
    }
    if (str_contains($body, 'NormativeMath')) {
        $valid = false;
    }
}
$kernel = (string)file_get_contents($root . '/BootstrapKernel.php');
$valid = $valid && $legacyLocated && $patchLocated
    && str_contains($kernel, "register('DISTANCE_LEGACY'")
    && str_contains($kernel, "dispatch('DISTANCE_PATCH_03', " . '$context)');

if (!$valid) {
    fwrite(STDERR, "GAGAL: bukti jarak sejarah atau pemisahan tampalan tidak sah\n");
    exit(1);
}
echo "LULUS kontrak merah khusus 03; legacy kekal salah dan produksi ditampal\n";
