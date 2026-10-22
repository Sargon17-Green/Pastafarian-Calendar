<?php
declare(strict_types=1);

// Bukti langsung gagal secara sengaja; pengesah hanya menerima RED tepat.
$command = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage24_discovery12_tests.php'];
$p = proc_open($command, [0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],
    $pipes, dirname(__DIR__));
if (!is_resource($p)) throw new RuntimeException('STAGE24_PROCESS_FAILED');
fclose($pipes[0]);
$out = stream_get_contents($pipes[1]);
$err = stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$exit = proc_close($p);
echo $out;
if ($err !== '') fwrite(STDERR, $err);

$matches = [];
$valid = $exit === 1 && $err === ''
    && preg_match(
        '/KEPUTUSAN MERAH_DIJANGKA salah=3456 sepadan=864 pangkat=720'
        . ' real=18 real_salah=([0-9]+) ralat=3 lain=0/',
        $out, $matches
    ) === 1
    && (int)$matches[1] >= 1 && (int)$matches[1] <= 18
    && !str_contains($out, 'RALAT_')
    && !str_contains($out, 'TIDAK_SAH');

$root = dirname(__DIR__);
$code = (string)file_get_contents($root . '/src/Legacy/LegacyNumericSuccessor12.php');
$kernel = (string)file_get_contents($root . '/src/BootstrapKernel.php');
$valid = $valid
    && str_contains($code, '$nextId = ($queriedBowlId % 6) + 1;')
    && str_contains($kernel, "dispatch('NUMERIC_NEXT_BOWL_LEGACY', " . '$context)')
    && !is_file($root . '/src/Patches/NextBowlOrderPatch12.php');
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($root . '/src', FilesystemIterator::SKIP_DOTS)
) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $text = (string)file_get_contents($file->getPathname());
    if (str_contains($text, 'NormativeMath') || str_contains($text, 'NormativeSauce')) {
        $valid = false;
    }
}
if (!$valid) {
    fwrite(STDERR, "GAGAL: kontrak merah jiran nombor tidak terbukti\n");
    exit(1);
}
echo "LULUS kontrak merah 12; jiran ID berbeza daripada jiran susunan\n";
