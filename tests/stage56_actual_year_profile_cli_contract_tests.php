<?php
declare(strict_types=1);

/**
 * Stage56 B5 independent CLI boundary checks. All inputs are deliberately
 * malformed or synthetic; NEVER run a claimed production-year performance gate.
 * This file tests invalid-input short-circuiting, not production provenance.
 */
$entrypoint = __DIR__ . '/stage56_actual_year_profile.php';
if (!is_file($entrypoint)) {
    throw new RuntimeException('STAGE56_B5_CLI_MISSING_ENTRYPOINT');
}
$tmp = sys_get_temp_dir() . '/stage56-b5-cli-' . bin2hex(random_bytes(8));
if (!mkdir($tmp, 0700)) {
    throw new RuntimeException('STAGE56_B5_CLI_TEMP_FAILURE');
}
$checks = 0;
$files = [];

function stage56B5RunCli(array $args): array
{
    $command = array_merge([PHP_BINARY, '-d', 'memory_limit=512M', __DIR__ . '/stage56_actual_year_profile.php'], $args);
    $descriptors = [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
    $process = proc_open($command, $descriptors, $pipes, __DIR__);
    if (!is_resource($process)) {
        throw new RuntimeException('STAGE56_B5_CLI_PROC_OPEN');
    }
    fclose($pipes[0]);
    $stdout = stream_get_contents($pipes[1]);
    fclose($pipes[1]);
    $stderr = stream_get_contents($pipes[2]);
    fclose($pipes[2]);
    return [proc_close($process), $stdout, $stderr];
}

function stage56B5AssertFailure(array $args, int $exit, string $stderrMarker): void
{
    global $checks;
    [$code, $out, $err] = stage56B5RunCli($args);
    if ($code !== $exit || $out !== '' || !str_contains($err, $stderrMarker)) {
        throw new RuntimeException('STAGE56_B5_CLI_ASSERT_' . $checks . '_EXIT_' . $code . '_ERR_' . $err);
    }
    ++$checks;
}

try {
    $store = static function (string $name, string $bytes) use ($tmp, &$files): array {
        $path = $tmp . '/' . $name;
        if (file_put_contents($path, $bytes, LOCK_EX) !== strlen($bytes)) {
            throw new RuntimeException('STAGE56_B5_CLI_WRITE_FAILED');
        }
        $files[] = $path;
        return [$path, hash('sha256', $bytes)];
    };
    [$malformed, $malformedHash] = $store('malformed.json', '{ "project_id":');
    [$scalar, $scalarHash] = $store('scalar.json', '42');
    [$empty, $emptyHash] = $store('empty.json', '{}');
    [$null, $nullHash] = $store('null.json', 'null');
    [$wrongProject, $wrongProjectHash] = $store('project.json', '{"project_id":"WRONG"}');
    [$badSource, $badSourceHash] = $store('source.json', '{"project_id":"PC-BRANCH-PHP-MALAY","source":{"kind":"fixture"}}');
    [$badAnchor, $badAnchorHash] = $store('anchor.json', '{"project_id":"PC-BRANCH-PHP-MALAY","source":{"kind":"production_export","provider_path":"src/Provider.php","source_commit":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","provider_sha256":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","anchor_sha256":"cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"}}');
    $missingPath = $tmp . '/missing.json';

    stage56B5AssertFailure([], 2, 'usage:');
    stage56B5AssertFailure([$empty, $emptyHash, '5002'], 2, 'usage:');
    stage56B5AssertFailure([$empty, 'wrong-hash', '5000'], 2, 'usage:');
    stage56B5AssertFailure([$empty, str_repeat('0', 64), '5000'], 3, 'STAGE56_B5_INPUT_SHA');
    stage56B5AssertFailure([$missingPath, $emptyHash, '5000'], 3, 'STAGE56_B5_INPUT_SHA');
    stage56B5AssertFailure([$malformed, $malformedHash, '5000'], 3, 'JsonException');
    stage56B5AssertFailure([$scalar, $scalarHash, '5000'], 3, 'STAGE56_B5_JSON');
    stage56B5AssertFailure([$null, $nullHash, '5000'], 3, 'STAGE56_B5_JSON');
    stage56B5AssertFailure([$empty, $emptyHash, '5000'], 3, 'STAGE56_B5_PROJECT');
    stage56B5AssertFailure([$wrongProject, $wrongProjectHash, '5000'], 3, 'STAGE56_B5_PROJECT');
    stage56B5AssertFailure([$badSource, $badSourceHash, '5000'], 3, 'STAGE56_B5_SOURCE_CLAIM');
    stage56B5AssertFailure([$badAnchor, $badAnchorHash, '5000'], 3, 'STAGE56_B5_ANCHOR');
    // These are invalid-input-only tests; a full synthetic or real-year profile
    // is deliberately not invoked by this suite.
    if ($checks !== 12) {
        throw new RuntimeException('STAGE56_B5_CLI_CHECK_COUNT');
    }
    echo "STAGE56_B5_CLI_NEGATIVE checks=$checks real_year_profiles=0 provenance=NOT_VERIFIED status=PASS\n";
} finally {
    foreach ($files as $file) {
        @unlink($file);
    }
    @rmdir($tmp);
}
