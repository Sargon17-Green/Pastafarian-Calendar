<?php
declare(strict_types=1);

// Pengawal hijau yang memastikan hanya kegagalan sejarah tertentu bersifat merah.
$cmd = [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage02_discovery01_tests.php'];
$process = proc_open(
    $cmd,
    [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']],
    $pipes,
    dirname(__DIR__)
);
if (!is_resource($process)) {
    throw new RuntimeException('PROCESS_FAILED');
}
fclose($pipes[0]);
$stdout = stream_get_contents($pipes[1]);
$stderr = stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$exitCode = proc_close($process);
echo $stdout;
if ($stderr !== '') {
    fwrite(STDERR, $stderr);
}
$names = ['M', '2M', '3M'];
$valid = $exitCode === 1
    && substr_count($stdout, 'GAGAL_DIJANGKA ') === 3
    && substr_count($stdout, 'LULUS M+1:') === 1
    && str_contains($stdout, 'KEPUTUSAN MERAH_DIJANGKA perbezaan=3 sepadan=1 lain=0')
    && $stderr === '';
foreach ($names as $name) {
    $valid = $valid && str_contains($stdout, 'GAGAL_DIJANGKA ' . $name . ':');
}
if (!$valid) {
    fwrite(STDERR, "GAGAL: keadaan merah tidak memenuhi kontrak penemuan pertama\n");
    exit(1);
}
// Semak bahawa kecacatan lama masih wujud sebagai bukti sejarah.
$fail = false;
$legacySource = dirname(__DIR__) . '/src/Legacy/LegacyRemainder.php';
if (!is_file($legacySource) || !str_contains((string)file_get_contents($legacySource), 'function oldRemainder(')) {
    $fail = true;
}
if ($fail) {
    fwrite(STDERR, "GAGAL: laluan sejarah sudah hilang\n");
    exit(1);
}
echo "LULUS kontrak penemuan lama masih merah dalam legacy sahaja\n";
