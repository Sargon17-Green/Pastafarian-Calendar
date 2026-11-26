<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/src/BigInt.php';
require_once dirname(__DIR__) . '/src/Patches/MonthWeavingInterleaving56.php';

$environmentKey = 'STAGE56_UNRANK_PROFILE_PATH';
$previousEnvironment = getenv($environmentKey);
$profilePath = tempnam(sys_get_temp_dir(), 'stage56-unrank-profile-');
if (!is_string($profilePath) || $profilePath === '') {
    throw new RuntimeException('STAGE56_UNRANK_PROFILE_TEMPFILE');
}

try {
    if (!putenv($environmentKey)) {
        throw new RuntimeException('STAGE56_UNRANK_PROFILE_DISABLE');
    }

    // Decimal width oracle: independent string representation, including limb boundaries.
    foreach (['0', '1', '-1', '999999999', '1000000000', '-1000000000',
        '999999999999999999', '1000000000000000000', str_repeat('9', 6800),
        '-1' . str_repeat('0', 6800)] as $literal) {
        $number = \Pastafari\Stage01\BigInt::fromString($literal);
        if ($number->decimalDigitCount() !== strlen(ltrim($literal, '-')) ||
            $number->decimalDigitCount() !== strlen(ltrim($number->toString(), '-'))) {
            throw new RuntimeException('STAGE56_UNRANK_PROFILE_DECIMAL_WIDTH');
        }
    }
    $lengths = array_fill(0, 5, 52);
    $plain = (new \Pastafari\Stage01\Patches\MonthWeavingInterleaving56($lengths))
        ->unrank(\Pastafari\Stage01\BigInt::one());

    if (!putenv($environmentKey . '=' . $profilePath)) {
        throw new RuntimeException('STAGE56_UNRANK_PROFILE_ENABLE');
    }

    $profiled = (new \Pastafari\Stage01\Patches\MonthWeavingInterleaving56($lengths))
        ->unrank(\Pastafari\Stage01\BigInt::one());

    if ($plain !== $profiled || count($profiled) !== 260) {
        throw new RuntimeException('STAGE56_UNRANK_PROFILE_OUTPUT_CHANGED');
    }

    $lines = file($profilePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if (!is_array($lines) || count($lines) !== 2) {
        throw new RuntimeException('STAGE56_UNRANK_PROFILE_BUCKET_COUNT');
    }

    $expectedPositions = [256, 3];
    $expectedStarts = [1, 257];
    $expectedEnds = [256, 259];
    $profileId = null;
    $totalPositions = 0;

    foreach ($lines as $index => $line) {
        $record = json_decode($line, true, 512, JSON_THROW_ON_ERROR);
        if (!is_array($record) ||
            ($record['schema_version'] ?? null) !== 1 ||
            ($record['event'] ?? null) !== 'bucket' ||
            ($record['method'] ?? null) !== 'MonthWeavingInterleaving56::unrank') {
            throw new RuntimeException('STAGE56_UNRANK_PROFILE_SCHEMA');
        }
        if (($record['bucket_index'] ?? null) !== $index + 1 ||
            ($record['positions'] ?? null) !== $expectedPositions[$index] ||
            ($record['position_start'] ?? null) !== $expectedStarts[$index] ||
            ($record['position_end'] ?? null) !== $expectedEnds[$index]) {
            throw new RuntimeException('STAGE56_UNRANK_PROFILE_BUCKET_RANGE');
        }
        if (!is_int($record['profile_id'] ?? null) ||
            ($profileId !== null && $profileId !== $record['profile_id'])) {
            throw new RuntimeException('STAGE56_UNRANK_PROFILE_ID');
        }
        $profileId = $record['profile_id'];

        foreach ([
            'bucket_elapsed_ns',
            'unrank_elapsed_ns',
            'setup_elapsed_ns',
            'candidate_count',
            'candidate_first_branch_count',
            'candidate_next_branch_count',
            'candidate_skipped_count',
            'new_month_branch_count',
            'branch_base_generation_ns',
            'direct_bigint_mul_calls',
            'direct_bigint_compare_calls',
            'direct_bigint_sub_calls',
            'suffix_count_calls',
            'suffix_cache_hits',
            'suffix_checkpoint_hits',
            'suffix_rebuilds',
            'suffix_terminal_shortcuts',
            'max_decimal_digits',
            'allocated_bytes',
            'process_peak_bytes',
            'timestamp_ns',
        ] as $field) {
            if (!is_int($record[$field] ?? null) || $record[$field] < 0) {
                throw new RuntimeException('STAGE56_UNRANK_PROFILE_FIELD_' . $field);
            }
        }
        if ($record['direct_bigint_mul_calls'] < 1 ||
            $record['direct_bigint_compare_calls'] < 1 ||
            $record['max_decimal_digits'] < 1 ||
            !is_array($record['max_decimal_digits_by_role'] ?? null) ||
            !isset($record['max_decimal_digits_by_role']['rank']) ||
            !isset($record['max_decimal_digits_by_role']['branch_base'])) {
            throw new RuntimeException('STAGE56_UNRANK_PROFILE_METRICS');
        }
        $totalPositions += $record['positions'];
    }

    if ($totalPositions !== 259) {
        throw new RuntimeException('STAGE56_UNRANK_PROFILE_POSITION_TOTAL');
    }

    echo "STAGE56_UNRANK_PROFILE_SCHEMA_PASS positions=259 buckets=2 status=PASS\n";
} finally {
    if ($previousEnvironment === false) {
        putenv($environmentKey);
    } else {
        putenv($environmentKey . '=' . $previousEnvironment);
    }
    @unlink($profilePath);
}
