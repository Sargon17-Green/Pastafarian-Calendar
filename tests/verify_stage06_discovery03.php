<?php
declare(strict_types=1);

$command = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage06_discovery03_tests.php'];
$process = proc_open($command, [0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']], $pipes, dirname(__DIR__));
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
if ($stderr !== '') fwrite(STDERR, $stderr);

$valid = $exit === 1 && $stderr === ''
    && substr_count($stdout, 'GAGAL_DIJANGKA kes=') === 130
    && substr_count($stdout, 'LULUS_TEPAT kes=') === 14
    && str_contains($stdout, 'KEPUTUSAN MERAH_DIJANGKA perbezaan=130 sepadan=14 lencongan=124 tepi=8 lain=0')
    && !str_contains($stdout, 'RALAT_');
foreach (['grid_6_6', 'grid_0_10', 'grid_10_0', 'sifar_sama', 'tablet_sama', 'min_max', 'max_min'] as $name) {
    $valid = $valid && str_contains($stdout, 'GAGAL_DIJANGKA kes=' . $name . ':');
}
foreach (['grid_4_5', 'grid_4_6', 'grid_6_4', 'grid_6_7', 'sifar_depan', 'sifar_belakang', 'min_depan', 'max_depan'] as $name) {
    $valid = $valid && str_contains($stdout, 'LULUS_TEPAT kes=' . $name . ':');
}
$root = dirname(__DIR__) . '/src';
$legacyCode = (string)file_get_contents($root . '/Legacy/LegacyDistance.php');
$patchCode = (string)file_get_contents($root . '/Patches/DistanceCountPatch03.php');
$kernelCode = (string)file_get_contents($root . '/BootstrapKernel.php');
$valid = $valid
    && str_contains($legacyCode, 'function oldDistance(')
    && str_contains($legacyCode, '$actionTag->sub($targetTag)->abs()')
    && str_contains($patchCode, 'if (!$distanceByTags->equals($chronological))')
    && str_contains($kernelCode, "register('DISTANCE_LEGACY'")
    && str_contains($kernelCode, "dispatch('DISTANCE_PATCH_03', " . '$context)');
if (!$valid) {
    fwrite(STDERR, "GAGAL: regresi sejarah jarak tag atau cabang pembetulan tidak tepat\n");
    exit(1);
}
echo "LULUS bukti sejarah tag dan lencongan PATCH 03, 130 merah dijangka\n";
