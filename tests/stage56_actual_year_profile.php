<?php
declare(strict_types=1);

/**
 * Stage56 B5: SHA-pinned actual-year input preflight and bounded rank/unrank
 * profiler. This does NOT authenticate the input's production provenance.
 * Review the external provider and Year5000 anchor independently before
 * treating any result as a genuine-year performance gate.
 */
function stage56B5Reject(string $reason): never
{
    throw new InvalidArgumentException('STAGE56_B5_' . $reason);
}

function stage56B5Sha(mixed $value): bool
{
    return is_string($value) && preg_match('/\A[a-f0-9]{64}\z/iD', $value) === 1;
}

/**
 * Mirror the independent Git-byte audit's conservative source path policy.
 * This is a structural filter, NOT proof of production provenance.
 */
function stage56B5SafeProviderPath(mixed $value): bool
{
    if (!is_string($value) || $value === '' || str_contains($value, '\\') ||
        str_contains($value, "\0")) {
        return false;
    }
    $parts = explode('/', $value);
    if (count($parts) < 2 || $parts[0] !== 'src' ||
        !str_ends_with($value, '.php')) {
        return false;
    }
    foreach ($parts as $part) {
        if (in_array($part, ['', '.', '..'], true) ||
            in_array(strtolower($part), ['tests', 'fixtures', 'oracle'], true)) {
            return false;
        }
    }
    return true;
}

/** @return array<int, array<string, mixed>> keyed by year */
function stage56B5Validate(array $input): array
{
    if (($input['project_id'] ?? null) !== 'PC-BRANCH-PHP-MALAY') {
        stage56B5Reject('PROJECT');
    }
    $source = $input['source'] ?? null;
    if (!is_array($source) || ($source['kind'] ?? null) !== 'production_export' ||
        !stage56B5SafeProviderPath($source['provider_path'] ?? null) ||
        !is_string($source['source_commit'] ?? null) ||
        preg_match('/\A[a-f0-9]{40}\z/iD', $source['source_commit']) !== 1 ||
        !stage56B5Sha($source['provider_sha256'] ?? null) ||
        !stage56B5Sha($source['anchor_sha256'] ?? null)) {
        stage56B5Reject('SOURCE_CLAIM');
    }
    $anchor = $input['year5000_anchor'] ?? null;
    if (!is_array($anchor) || ($anchor['number'] ?? null) !== 5000 ||
        !is_int($anchor['open_gate_day'] ?? null)) {
        stage56B5Reject('ANCHOR');
    }
    $entries = $input['years'] ?? null;
    if (!is_array($entries) || !array_is_list($entries) || count($entries) !== 3) {
        stage56B5Reject('YEARS_SHAPE');
    }
    $years = [];
    $lastClose = null;
    foreach ([4999, 5000, 5001] as $i => $year) {
        $r = $entries[$i];
        if (!is_array($r) || ($r['number'] ?? null) !== $year ||
            !is_int($r['open_gate_day'] ?? null) ||
            !is_int($r['close_gate_day'] ?? null)) {
            stage56B5Reject('YEAR_RECORD');
        }
        $open = $r['open_gate_day'];
        $close = $r['close_gate_day'];
        if ($close <= $open || $close - $open < 252 || $close - $open > 5778 ||
            ($lastClose !== null && $open !== $lastClose)) {
            stage56B5Reject('YEAR_BOUNDARY');
        }
        $lastClose = $close;
        if ($year === 5000 && $open !== $anchor['open_gate_day']) {
            stage56B5Reject('ANCHOR_MISMATCH');
        }
        $lengths = $r['month_lengths'] ?? null;
        $word = $r['month_weaving'] ?? null;
        if (!is_array($lengths) || !array_is_list($lengths) ||
            !is_array($word) || !array_is_list($word) ||
            count($lengths) < 3 || count($lengths) > 47 ||
            count($word) !== $close - $open) {
            stage56B5Reject('MONTH_SHAPE');
        }
        $m = count($lengths);
        $total = 0;
        foreach ($lengths as $length) {
            if (!is_int($length) || $length < 4 || $length > 123) {
                stage56B5Reject('MONTH_LENGTH');
            }
            $total += $length;
        }
        if ($total !== $close - $open) {
            stage56B5Reject('MONTH_TOTAL');
        }
        $counts = array_fill(1, $m, 0);
        $first = [];
        $last = [];
        foreach ($word as $pos => $id) {
            if (!is_int($id) || $id < 1 || $id > $m) {
                stage56B5Reject('MONTH_ID');
            }
            if (!isset($first[$id])) {
                $first[$id] = $pos;
            }
            $last[$id] = $pos;
            ++$counts[$id];
        }
        for ($id = 1; $id <= $m; ++$id) {
            if ($counts[$id] !== $lengths[$id - 1]) {
                stage56B5Reject('MONTH_COUNTS');
            }
            if ($id > 1 && ($first[$id] <= $first[$id - 1] ||
                $last[$id] <= $last[$id - 1])) {
                stage56B5Reject('MONTH_ORDER');
            }
        }
        $years[$year] = $r;
    }
    return $years;
}

function stage56B5Main(array $argv): int
{
    if (count($argv) !== 4 || !in_array($argv[3], ['4999', '5000', '5001'], true) ||
        !stage56B5Sha($argv[2])) {
        fwrite(STDERR, "usage: php -d memory_limit=512M tests/stage56_actual_year_profile.php INPUT.json PINNED_INPUT_SHA256 YEAR\n");
        return 2;
    }
    try {
        $bytes = @file_get_contents($argv[1]);
        if (!is_string($bytes) || !hash_equals(strtolower($argv[2]), hash('sha256', $bytes))) {
            stage56B5Reject('INPUT_SHA');
        }
        $input = json_decode($bytes, true, 512, JSON_THROW_ON_ERROR);
        if (!is_array($input)) {
            stage56B5Reject('JSON');
        }
        $years = stage56B5Validate($input);
        $year = (int)$argv[3];
        $record = $years[$year];
        require_once dirname(__DIR__) . '/src/BigInt.php';
        require_once dirname(__DIR__) . '/src/Patches/MonthWeavingFrontier56.php';
        require_once dirname(__DIR__) . '/src/Patches/MonthWeavingAdjoint56.php';
        require_once dirname(__DIR__) . '/src/Patches/MonthWeavingRanker56.php';
        $ranker = new \Pastafari\Stage01\Patches\MonthWeavingRanker56();
        $start = hrtime(true);
        $count = $ranker->count($record['month_lengths']);
        $afterCount = hrtime(true);
        $rank = $ranker->rank($record['month_lengths'], $record['month_weaving']);
        $afterRank = hrtime(true);
        $roundtrip = $ranker->unrank($record['month_lengths'], $rank);
        $afterUnrank = hrtime(true);
        if ($roundtrip !== $record['month_weaving'] ||
            $rank->compare($count) > 0 || $rank->sign() < 1) {
            throw new RuntimeException('STAGE56_B5_DIFFERENTIAL_MISMATCH');
        }
        $seconds = ($afterUnrank - $start) / 1e9;
        $peak = memory_get_peak_usage(true);
        if ($seconds > 900 || $peak > 536870912) {
            throw new RuntimeException('STAGE56_B5_RESOURCE_LIMIT');
        }
        echo json_encode([
            'project_id' => 'PC-BRANCH-PHP-MALAY',
            'year' => $year,
            'source_commit_claim' => $input['source']['source_commit'],
            'input_sha256' => strtolower($argv[2]),
            'provider_sha256_claim' => $input['source']['provider_sha256'],
            'anchor_sha256_claim' => $input['source']['anchor_sha256'],
            'month_count' => count($record['month_lengths']),
            'day_count' => count($record['month_weaving']),
            'total_rank_digits' => strlen($count->toString()),
            'rank_digits' => strlen($rank->toString()),
            'count_seconds' => ($afterCount - $start) / 1e9,
            'rank_seconds' => ($afterRank - $afterCount) / 1e9,
            'unrank_seconds' => ($afterUnrank - $afterRank) / 1e9,
            'total_seconds' => $seconds,
            'peak_bytes' => $peak,
            'roundtrip' => 'PASS',
            'provenance' => 'UNATTESTED_REQUIRES_INDEPENDENT_REVIEW',
            'result' => 'PROFILE_ONLY_NOT_STAGE56_ACCEPTANCE',
        ], JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES) . "\n";
        return 0;
    } catch (Throwable $error) {
        fwrite(STDERR, get_class($error) . ': ' . $error->getMessage() . "\n");
        return 3;
    }
}

if (isset($_SERVER['SCRIPT_FILENAME']) && realpath((string)$_SERVER['SCRIPT_FILENAME']) === __FILE__) {
    exit(stage56B5Main($argv));
}
