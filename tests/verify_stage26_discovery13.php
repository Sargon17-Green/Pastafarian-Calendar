<?php
declare(strict_types=1);

// Pengesah menerima hanya empat ketidaksetaraan rejection sampling yang sah.
$command = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage26_discovery13_tests.php'];
$p = proc_open(
    $command, [0=>['pipe','r'], 1=>['pipe','w'], 2=>['pipe','w']],
    $pipes, dirname(__DIR__)
);
if (!is_resource($p)) {
    throw new RuntimeException('STAGE26_PROCESS_FAILED');
}
fclose($pipes[0]);
$out = stream_get_contents($pipes[1]);
$err = stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$exit = proc_close($p);
echo $out;
if ($err !== '') {
    fwrite(STDERR, $err);
}
$valid = $exit === 1 && $err === ''
    && substr_count($out, 'GAGAL_DIJANGKA ruang=') === 4
    && str_contains($out, 'GAGAL_DIJANGKA ruang=3 legacy=1 normatif=3')
    && str_contains($out, 'GAGAL_DIJANGKA ruang=10 legacy=1 normatif=10')
    && str_contains($out, 'GAGAL_DIJANGKA ruang=97 legacy=1 normatif=97')
    && str_contains($out, 'GAGAL_DIJANGKA ruang=720 legacy=1 normatif=720')
    && str_contains($out, 'KEPUTUSAN MERAH_DIJANGKA merah=4 kawalan=13 real=3 ralat=4 lain=0')
    && !str_contains($out, 'RALAT_')
    && !str_contains($out, 'TIDAK_SAH');

$src = dirname(__DIR__) . '/src';
$legacy = (string)file_get_contents($src . '/Legacy/LegacyNoRejection13.php');
$kernel = (string)file_get_contents($src . '/BootstrapKernel.php');
$valid = $valid
    && str_contains($legacy,
        'return $first->sub(BigInt::one())->mod($n)->add(BigInt::one());')
    && str_contains($kernel,
        "dispatch('NO_REJECTION_CHOICE_LEGACY', " . '$context)')
    && (!is_file($src . '/Patches/RejectionSamplingPatch13.php')
        || (str_contains($kernel,
                "dispatch('REJECTION_SAMPLING_PATCH_13', " . '$context)')
            && str_contains((string)file_get_contents(
                    $src . '/Patches/RejectionSamplingPatch13.php'),
                '$this->legacy->chooseWrong($stream, $n)')));
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($src, FilesystemIterator::SKIP_DOTS)
) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $source = (string)file_get_contents($file->getPathname());
    if (str_contains($source, 'NormativeMath')
        || str_contains($source, 'NormativeSauce')) {
        $valid = false;
    }
}
if (!$valid) {
    fwrite(STDERR, "GAGAL: bukti rejection sampling RED tidak tepat\n");
    exit(1);
}
echo "LULUS kontrak merah 13; empat sampel melebihi cutoff ditolak oleh oracle sahaja\n";
