<?php
declare(strict_types=1);

// Verifier: exactly two *named* historical RED cases are expected.
// Any warning, additional failure, absent red or wrong exit status fails CI.
$p = proc_open(
    [PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage36_discovery18_tests.php'],
    [0=>['pipe','r'], 1=>['pipe','w'], 2=>['pipe','w']], $pipes,
    dirname(__DIR__)
);
if (!is_resource($p)) {
    throw new RuntimeException('STAGE36_CHILD_PROCESS');
}
fclose($pipes[0]);
$out = stream_get_contents($pipes[1]);
$err = stream_get_contents($pipes[2]);
fclose($pipes[1]);
fclose($pipes[2]);
$code = proc_close($p);
echo $out;
if ($err !== '') {
    fwrite(STDERR, $err);
}
$valid = $code === 1
    && $err === ''
    && substr_count($out, 'GAGAL_DIJANGKA witness=') === 2
    && preg_match('/^GAGAL_DIJANGKA witness=selepas_365 lama=\d+ sah=5000$/m', $out) === 1
    && preg_match('/^GAGAL_DIJANGKA witness=akhir_tahun lama=\d+ sah=5000$/m', $out) === 1
    && str_contains($out,
        'LULUS Stage36 DISCOVERY18 kawalan=1 merah=2 real=3 invalid=6 floor=10 lain=0')
    && !str_contains($out, 'STAGE36_UNEXPECTED')
    && !str_contains($out, 'RALAT_')
    && !str_contains($out, 'TIDAK_SAH');
if (!$valid) {
    fwrite(STDERR, "GAGAL: tandatangan Stage36 EXPECTED_RED tidak tepat; code={$code}\n");
    exit(1);
}
echo "STAGE36_DISCOVERY18_NATIVE_EXPECTED_RED_COMPLETE\n";
exit(0);
