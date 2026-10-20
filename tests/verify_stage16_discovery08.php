<?php
declare(strict_types=1);

// Pembalut hijau: hanya hasil RED sejarah yang tepat boleh diterima.
$command = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage16_discovery08_tests.php'];
$process = proc_open(
    $command,
    [0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],
    $pipes,
    dirname(__DIR__)
);
if (!is_resource($process)) throw new RuntimeException('STAGE16_PROCESS_FAILED');
fclose($pipes[0]);
$out = stream_get_contents($pipes[1]);
$err = stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$exit = proc_close($process);
echo $out;
if ($err !== '') fwrite(STDERR, $err);
$valid = $exit === 1 && $err === ''
    && str_contains($out, 'ORDINAL1_MISALIGNED rank=1')
    && str_contains($out, 'RANK720_REJECTED rank=720')
    && str_contains($out, 'CHECK_VISIBLE46 titisan=46')
    && str_contains($out, 'KEPUTUSAN MERAH_DIJANGKA salah=719 luar=1 jumlah=720 fungsi_sifar=720 titisan=46 lain=0')
    && !str_contains($out, 'RALAT_');
$source = dirname(__DIR__) . '/src';
$caller = (string)file_get_contents($source . '/Legacy/LegacyBowlPermutation.php');
$raw = (string)file_get_contents($source . '/Legacy/LegacyPermutationUnrank0.php');
$kernel = (string)file_get_contents($source . '/BootstrapKernel.php');
$valid = $valid
    && str_contains($caller, '$this->unrank->oldPermutationUnrank0($oneBased)')
    && str_contains($raw, 'function oldPermutationUnrank0(')
    && str_contains($kernel, "dispatch('BOWL_PERMUTATION_LEGACY', " . '$context)')
    && !str_contains($kernel, 'oldPermutationUnrank0')
    && !str_contains($caller, '$oneBased - 1');
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($source, FilesystemIterator::SKIP_DOTS)
);
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $body = (string)file_get_contents($file->getPathname());
    if (str_contains($body, 'NormativeMath')
        || str_contains($body, 'NormativeSauce')
        || str_contains($body, 'function permutationPatch(')) {
        $valid = false;
    }
}
if (!$valid) {
    fwrite(STDERR, "GAGAL: ordinal satu dan sifar tidak menghasilkan merah sejarah yang wajib\n");
    exit(1);
}
echo "LULUS kontrak merah 08; pangkat satu dihantar ke fungsi pangkat sifar\n";
