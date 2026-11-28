<?php
declare(strict_types=1);

if (!extension_loaded('gmp')) {
    fwrite(STDOUT, json_encode(['status' => 'NOT_RUN', 'reason' => 'GMP extension missing'], JSON_THROW_ON_ERROR));
    exit(77);
}

$input = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
$lengths = $input['lengths'] ?? null;
if (!is_array($lengths) || !array_is_list($lengths) || $lengths === [] || count($lengths) > 47) {
    throw new InvalidArgumentException('SOURCE_SHAPE_LENGTHS');
}
$totalLength = 0;
foreach ($lengths as $length) {
    if (!is_int($length) || $length < 1 || $length > 123) {
        throw new InvalidArgumentException('SOURCE_SHAPE_LENGTH');
    }
    $totalLength += $length;
}
if ($totalLength > 5778) {
    throw new InvalidArgumentException('SOURCE_SHAPE_TOTAL');
}

final class SourceShapeGmpRows
{
    /** @var list<int> */
    private array $lengths;
    /** @var list<int> */
    private array $widths;
    /** @var array<int, list<GMP>> */
    private array $active = [];
    /** @var array<int, list<GMP>> */
    private array $checkpoints = [];
    private int $activeRows;
    private int $cellsBuilt = 0;
    private int $rebuilds = 0;
    private int $maxLiveRows = 0;
    private int $maxStoredRows = 0;

    /** @param list<int> $lengths */
    public function __construct(array $lengths)
    {
        $this->lengths = $lengths;
        $n = count($lengths);
        $this->widths = [$lengths[0]];
        for ($i = 1; $i < $n; ++$i) {
            $this->widths[] = $this->widths[$i - 1] + $lengths[$i] - 1;
        }
        $this->activeRows = 8 - intdiv($n - 2, 8);
        if ($this->activeRows < 1 || $this->activeRows > 8) {
            throw new LogicException('SOURCE_SHAPE_ACTIVE_ROW_BUDGET');
        }
    }

    public function value(int $index, int $q): GMP
    {
        $n = count($this->lengths);
        if ($index >= $n - 1) return gmp_init(1);
        if ($index < 0 || $q < 0) throw new InvalidArgumentException('SOURCE_SHAPE_ROW_INDEX');
        $row = $this->active[$index] ?? $this->checkpoints[$index] ?? null;
        if ($row !== null && count($row) > $q) return $row[$q];
        $this->rebuild($index, $q);
        $row = $this->active[$index] ?? $this->checkpoints[$index] ?? null;
        if ($row === null || count($row) <= $q) {
            throw new LogicException('SOURCE_SHAPE_ROW_COVERAGE');
        }
        return $row[$q];
    }

    /** @return array<string, int|array<int>> */
    public function stats(): array
    {
        $stored = $this->storedIndices();
        return [
            'planned_cells' => array_sum(array_slice($this->widths, 0, -1)),
            'cells_built' => $this->cellsBuilt,
            'rebuilds' => $this->rebuilds,
            'max_live_rows' => $this->maxLiveRows,
            'max_stored_rows' => $this->maxStoredRows,
            'active_indices' => array_values(array_map('intval', array_keys($this->active))),
            'checkpoint_indices' => array_values(array_map('intval', array_keys($this->checkpoints))),
            'stored_indices' => $stored,
        ];
    }

    private function storedIndices(): array
    {
        $keys = array_unique(array_merge(array_keys($this->active), array_keys($this->checkpoints)));
        sort($keys, SORT_NUMERIC);
        return array_values(array_map('intval', $keys));
    }

    private function rebuild(int $start, int $qStart): void
    {
        $n = count($this->lengths);
        $needed = array_fill(0, $n, 0);
        $needed[$start] = $qStart;
        for ($index = $start; $index < $n - 1; ++$index) {
            $needed[$index + 1] = $needed[$index] + $this->lengths[$index + 1] - 1;
        }

        $following = null;
        $followingIndex = null;
        $stop = $n - 1;
        for ($index = $start + 1; $index < $n - 1; ++$index) {
            $checkpoint = $this->checkpoints[$index] ?? null;
            if ($checkpoint !== null && count($checkpoint) > $needed[$index]) {
                $following = $checkpoint;
                $followingIndex = $index;
                $stop = $index - 1;
                break;
            }
        }

        // Keep only the active window and absolute checkpoints; never retain a full row table.
        $this->active = [];
        ++$this->rebuilds;
        for ($index = $stop; $index >= $start; --$index) {
            $qMax = $needed[$index];
            if ($index === $n - 1) {
                $current = array_fill(0, $qMax + 1, gmp_init(1));
            } else {
                if (!is_array($following)) throw new LogicException('SOURCE_SHAPE_DP_SUFFIX');
                $current = [gmp_init(0)];
                $cumulative = gmp_init(0);
                $weight = gmp_init(1);
                $monthLength = $this->lengths[$index + 1];
                for ($q = 1; $q <= $qMax; ++$q) {
                    $r = $q - 1;
                    $target = $monthLength + $r;
                    if (!array_key_exists($target, $following)) {
                        throw new LogicException('SOURCE_SHAPE_DP_INDEX');
                    }
                    $cumulative = gmp_add($cumulative, gmp_mul($weight, $following[$target]));
                    $current[$q] = $cumulative;
                    [$nextWeight, $remainder] = gmp_div_qr(
                        gmp_mul($weight, $monthLength + $r - 1),
                        $r + 1
                    );
                    if (gmp_cmp($remainder, 0) !== 0) {
                        throw new LogicException('SOURCE_SHAPE_NONEXACT_WEIGHT');
                    }
                    $weight = $nextWeight;
                }
                $this->cellsBuilt += $qMax;
            }

            $isCheckpoint = $index > 0 && $index % 8 === 0 && $index < $n - 1;
            if ($isCheckpoint) {
                if (count($this->checkpoints[$index] ?? []) < count($current)) {
                    $this->checkpoints[$index] = $current;
                }
            } elseif ($index < $start + $this->activeRows) {
                $this->active[$index] = $current;
            }

            $stored = $this->storedIndices();
            $currentStored = in_array($index, $stored, true);
            $followingStored = $followingIndex !== null && in_array($followingIndex, $stored, true);
            $live = count($stored)
                + (($followingIndex !== null && !$followingStored) ? 1 : 0)
                + (!$currentStored ? 1 : 0);
            $this->maxLiveRows = max($this->maxLiveRows, $live);
            $this->maxStoredRows = max($this->maxStoredRows, count($stored));
            $following = $current;
            $followingIndex = $index;
            unset($current);
        }
    }
}

final class SourceShapeGmpRanker
{
    /** @var list<int> */
    private array $lengths;
    private int $monthCount;
    private int $totalLength;
    private SourceShapeGmpRows $rows;

    /** @param list<int> $lengths */
    public function __construct(array $lengths)
    {
        $this->lengths = array_values($lengths);
        $this->monthCount = count($lengths);
        $this->totalLength = array_sum($lengths);
        $this->rows = new SourceShapeGmpRows($this->lengths);
    }

    public function count(): GMP
    {
        if ($this->monthCount === 1) return gmp_init(1);
        return $this->rows->value(0, $this->lengths[0]);
    }

    /** @param list<int> $prefix @return array{rank_start:GMP,completion_count:GMP} */
    public function rankPrefix(array $prefix): array
    {
        if (!array_is_list($prefix) || $prefix === [] || ($prefix[0] ?? null) !== 0) {
            throw new InvalidArgumentException('SOURCE_SHAPE_PREFIX');
        }
        $remaining = $this->lengths;
        --$remaining[0];
        $low = 0;
        while ($low < $this->monthCount && $remaining[$low] === 0) ++$low;
        $high = 0;
        $activeTotal = $remaining[0];
        $baseCount = gmp_init(1);
        $rank = gmp_init(1);

        for ($position = 1, $n = count($prefix); $position < $n; ++$position) {
            $wanted = $prefix[$position];
            if (!is_int($wanted) || $wanted < 0 || $wanted >= $this->monthCount) {
                throw new InvalidArgumentException('SOURCE_SHAPE_PREFIX_ID');
            }
            $prefixSums = $this->prefixSums($remaining, $low, $high);
            $futureSame = ($high < $this->monthCount - 1 && $activeTotal > 0)
                ? $this->rows->value($high, $activeTotal)
                : gmp_init(1);

            $skippedBase = gmp_init(0);
            $selected = false;
            $previousMonth = null;
            $previousBase = null;
            for ($month = $low; $month <= $high; ++$month) {
                $remainingForMonth = $remaining[$month];
                if ($remainingForMonth <= 0 || ($remainingForMonth === 1 && $month !== $low)) continue;
                $nextBase = $previousMonth === null
                    ? $this->firstBranchBase($baseCount, $remainingForMonth, $prefixSums, $low, $month, $activeTotal)
                    : $this->nextBranchBase($previousBase, $remaining, $prefixSums, $low, $previousMonth, $month);
                if ($month < $wanted) {
                    $skippedBase = gmp_add($skippedBase, $nextBase);
                    $previousMonth = $month;
                    $previousBase = $nextBase;
                    continue;
                }
                if ($month > $wanted) {
                    throw new InvalidArgumentException('SOURCE_SHAPE_PREFIX_INVALID');
                }
                --$remaining[$month];
                --$activeTotal;
                $baseCount = $nextBase;
                if ($remaining[$month] === 0 && $month === $low) ++$low;
                $selected = true;
                break;
            }
            if (gmp_cmp($skippedBase, 0) !== 0) {
                $rank = gmp_add($rank, gmp_mul($skippedBase, $futureSame));
            }
            if ($selected) continue;

            $month = $high + 1;
            if ($month >= $this->monthCount || $wanted !== $month) {
                throw new InvalidArgumentException('SOURCE_SHAPE_PREFIX_INVALID');
            }
            $newRemaining = $this->lengths[$month] - 1;
            $nextBase = self::newMonthBase($baseCount, $activeTotal, $newRemaining);
            $nextActiveTotal = $activeTotal + $newRemaining;
            $future = $month < $this->monthCount - 1
                ? $this->rows->value($month, $nextActiveTotal + 1)
                : gmp_init(1);
            if (gmp_cmp($nextBase, 0) <= 0 || gmp_cmp($future, 0) <= 0) {
                throw new LogicException('SOURCE_SHAPE_EMPTY_NEW_MONTH');
            }
            $high = $month;
            --$remaining[$month];
            if ($remaining[$month] === 0) $low = $month + 1;
            elseif ($low > $month - 1) $low = $month;
            $activeTotal = $nextActiveTotal;
            $baseCount = $nextBase;
        }

        return [
            'rank_start' => $rank,
            'completion_count' => $this->completionCount($prefix),
        ];
    }

    /** @return array{prefix:list<int>,residual_rank:GMP,completion_count:GMP} */
    public function unrankPrefix(GMP $rank, int $depth): array
    {
        $total = $this->count();
        if ($depth < 1 || $depth > $this->totalLength || gmp_cmp($rank, 1) < 0 || gmp_cmp($rank, $total) > 0) {
            throw new InvalidArgumentException('SOURCE_SHAPE_RANK_RANGE');
        }
        $word = [0];
        $remaining = $this->lengths;
        --$remaining[0];
        $low = 0;
        while ($low < $this->monthCount && $remaining[$low] === 0) ++$low;
        $high = 0;
        $activeTotal = $remaining[0];
        $baseCount = gmp_init(1);

        for ($position = 1; $position < $depth; ++$position) {
            $prefixSums = $this->prefixSums($remaining, $low, $high);
            $futureSame = ($high < $this->monthCount - 1 && $activeTotal > 0)
                ? $this->rows->value($high, $activeTotal)
                : gmp_init(1);

            $chosen = null;
            $previousMonth = null;
            $previousBase = null;
            for ($month = $low; $month <= $high; ++$month) {
                $remainingForMonth = $remaining[$month];
                if ($remainingForMonth <= 0 || ($remainingForMonth === 1 && $month !== $low)) continue;
                $nextBase = $previousMonth === null
                    ? $this->firstBranchBase($baseCount, $remainingForMonth, $prefixSums, $low, $month, $activeTotal)
                    : $this->nextBranchBase($previousBase, $remaining, $prefixSums, $low, $previousMonth, $month);
                $block = gmp_mul($nextBase, $futureSame);
                if (gmp_cmp($rank, $block) <= 0) {
                    $chosen = $month;
                    --$remaining[$month];
                    --$activeTotal;
                    $baseCount = $nextBase;
                    if ($remaining[$month] === 0 && $month === $low) ++$low;
                    break;
                }
                $rank = gmp_sub($rank, $block);
                $previousMonth = $month;
                $previousBase = $nextBase;
            }

            if ($chosen === null) {
                $month = $high + 1;
                if ($month >= $this->monthCount) {
                    throw new LogicException('SOURCE_SHAPE_UNRANK_EXHAUSTED');
                }
                $newRemaining = $this->lengths[$month] - 1;
                $nextBase = self::newMonthBase($baseCount, $activeTotal, $newRemaining);
                $nextActiveTotal = $activeTotal + $newRemaining;
                $future = $month < $this->monthCount - 1
                    ? $this->rows->value($month, $nextActiveTotal + 1)
                    : gmp_init(1);
                $block = gmp_mul($nextBase, $future);
                if (gmp_cmp($rank, $block) > 0 || gmp_cmp($block, 0) <= 0) {
                    throw new LogicException('SOURCE_SHAPE_UNRANK_NEW_MONTH');
                }
                $chosen = $month;
                $high = $month;
                --$remaining[$month];
                if ($remaining[$month] === 0) $low = $month + 1;
                elseif ($low > $month - 1) $low = $month;
                $activeTotal = $nextActiveTotal;
                $baseCount = $nextBase;
            }
            $word[] = $chosen;
        }

        return [
            'prefix' => $word,
            'residual_rank' => $rank,
            'completion_count' => $this->completionCount($word),
        ];
    }

    /** @param list<int> $prefix */
    public function completionCount(array $prefix): GMP
    {
        if ($prefix === []) return $this->count();
        $remaining = $this->lengths;
        $high = -1;
        foreach ($prefix as $month) {
            if (!is_int($month) || $month < 0 || $month >= $this->monthCount ||
                $month > $high + 1 || $remaining[$month] === 0) {
                return gmp_init(0);
            }
            if ($month === $high + 1) $high = $month;
            if ($remaining[$month] === 1) {
                for ($lower = 0; $lower < $month; ++$lower) {
                    if ($remaining[$lower] > 0) return gmp_init(0);
                }
            }
            --$remaining[$month];
        }
        if (($prefix[0] ?? null) !== 0) return gmp_init(0);

        $low = 0;
        while ($low <= $high && $remaining[$low] === 0) ++$low;
        if ($low > $high) {
            if ($high >= $this->monthCount - 1) return gmp_init(1);
            return $this->rows->value($high + 1, $this->lengths[$high + 1]);
        }

        $activeTotal = 0;
        $base = gmp_init(1);
        for ($month = $low; $month <= $high; ++$month) {
            if ($remaining[$month] <= 0) return gmp_init(0);
            $activeTotal += $remaining[$month];
            if ($month > $low) {
                $base = self::multiplyByBinomial($base, $activeTotal - 1, $remaining[$month] - 1);
            }
        }
        if ($high >= $this->monthCount - 1) return $base;
        return gmp_mul($base, $this->rows->value($high, $activeTotal + 1));
    }

    /** @param list<int> $remaining @return list<int> */
    private function prefixSums(array $remaining, int $low, int $high): array
    {
        $prefix = [];
        $running = 0;
        for ($index = $low; $index <= $high; ++$index) {
            $running += $remaining[$index];
            $prefix[] = $running;
        }
        return $prefix;
    }

    /** @param list<int> $prefix @param list<int> $numerators @param list<int> $denominators */
    private static function scaleBySmallRatio(GMP $value, array $numerators, array $denominators): GMP
    {
        foreach ($numerators as &$numerator) {
            if ($numerator === 0) return gmp_init(0);
            foreach ($denominators as &$denominator) {
                if ($denominator <= 1) continue;
                $gcd = self::gcd($numerator, $denominator);
                if ($gcd > 1) {
                    $numerator = intdiv($numerator, $gcd);
                    $denominator = intdiv($denominator, $gcd);
                }
                if ($numerator === 1) break;
            }
            unset($denominator);
        }
        unset($numerator);
        foreach ($numerators as $factor) {
            if ($factor > 1) $value = gmp_mul($value, $factor);
        }
        foreach ($denominators as $factor) {
            if ($factor > 1) {
                [$quotient, $remainder] = gmp_div_qr($value, $factor);
                if (gmp_cmp($remainder, 0) !== 0) throw new LogicException('SOURCE_SHAPE_NONEXACT_RATIO');
                $value = $quotient;
            }
        }
        return $value;
    }

    private function firstBranchBase(
        GMP $baseCount,
        int $remainingForMonth,
        array $prefix,
        int $low,
        int $month,
        int $activeTotal
    ): GMP {
        $offset = $month - $low;
        $firstFactor = $remainingForMonth > 1 ? $offset : $offset + 1;
        $numerators = $remainingForMonth > 1 ? [$remainingForMonth - 1] : [];
        $denominators = [$activeTotal];
        for ($index = $firstFactor, $n = count($prefix); $index < $n; ++$index) {
            $numerators[] = $prefix[$index];
            $denominators[] = $prefix[$index] - 1;
        }
        return self::scaleBySmallRatio($baseCount, $numerators, $denominators);
    }

    private function nextBranchBase(
        GMP $previousBase,
        array $remaining,
        array $prefix,
        int $low,
        int $previousMonth,
        int $month
    ): GMP {
        $previousOffset = $previousMonth - $low;
        $offset = $month - $low;
        $currentRemaining = $remaining[$month];
        $previousRemaining = $remaining[$previousMonth];
        if ($currentRemaining <= 1) throw new LogicException('SOURCE_SHAPE_BRANCH_ORDER');
        $numerators = [$currentRemaining - 1];
        $denominators = [];
        $firstPrefix = $previousRemaining === 1 ? $previousOffset + 1 : $previousOffset;
        if ($previousRemaining > 1) $denominators[] = $previousRemaining - 1;
        for ($index = $firstPrefix; $index < $offset; ++$index) {
            $numerators[] = $prefix[$index] - 1;
            $denominators[] = $prefix[$index];
        }
        return self::scaleBySmallRatio($previousBase, $numerators, $denominators);
    }

    private static function newMonthBase(GMP $base, int $activeTotal, int $newRemaining): GMP
    {
        if ($newRemaining === 0) return $activeTotal === 0 ? $base : gmp_init(0);
        return self::multiplyByBinomial($base, $activeTotal + $newRemaining - 1, $newRemaining - 1);
    }

    private static function multiplyByBinomial(GMP $value, int $n, int $k): GMP
    {
        if ($k < 0 || $n < 0 || $k > $n) return gmp_init(0);
        $k = min($k, $n - $k);
        $numerators = [];
        $denominators = [];
        for ($index = 1; $index <= $k; ++$index) {
            $numerators[] = $n - $k + $index;
            $denominators[] = $index;
        }
        return self::scaleBySmallRatio($value, $numerators, $denominators);
    }

    private static function gcd(int $a, int $b): int
    {
        while ($b !== 0) [$a, $b] = [$b, $a % $b];
        return $a;
    }

    public function rowStats(): array
    {
        return $this->rows->stats();
    }
}

$smallSelftest = null;
if (isset($input['small_cases'])) {
    $shapeCount = 0;
    $wordCount = 0;
    $prefixCount = 0;
    foreach ($input['small_cases'] as $case) {
        $smallRanker = new SourceShapeGmpRanker($case['lengths']);
        $smallTotal = $smallRanker->count();
        if (gmp_strval($smallTotal, 10) !== (string)$case['count']) {
            throw new LogicException('SOURCE_SHAPE_SMALL_COUNT');
        }
        foreach ($case['words'] as $ordinal => $word) {
            $expectedRank = gmp_init($ordinal + 1);
            $ranked = $smallRanker->rankPrefix($word);
            if (gmp_cmp($ranked['rank_start'], $expectedRank) !== 0 ||
                gmp_cmp($ranked['completion_count'], 1) !== 0) {
                throw new LogicException('SOURCE_SHAPE_SMALL_RANK');
            }
            $unranked = $smallRanker->unrankPrefix($expectedRank, count($word));
            if ($unranked['prefix'] !== $word || gmp_cmp($unranked['residual_rank'], 1) !== 0 ||
                gmp_cmp($unranked['completion_count'], 1) !== 0) {
                throw new LogicException('SOURCE_SHAPE_SMALL_UNRANK');
            }
            ++$wordCount;
        }
        foreach ($case['prefix_counts'] as $entry) {
            $actual = $smallRanker->completionCount($entry['prefix']);
            if (gmp_strval($actual, 10) !== (string)$entry['count']) {
                throw new LogicException('SOURCE_SHAPE_SMALL_PREFIX_COUNT');
            }
            ++$prefixCount;
        }
        ++$shapeCount;
    }
    $smallSelftest = ['shapes' => $shapeCount, 'legal_words' => $wordCount, 'distinct_prefixes' => $prefixCount, 'status' => 'PASS'];
}

$started = hrtime(true);
$ranker = new SourceShapeGmpRanker($lengths);
$total = $ranker->count();
$sampleResults = [];
foreach (($input['samples'] ?? []) as $sample) {
    $rank = gmp_init((string)($sample['rank'] ?? ''), 10);
    $depth = $sample['depth'] ?? null;
    if (!is_int($depth)) throw new InvalidArgumentException('SOURCE_SHAPE_SAMPLE_DEPTH');
    $unranked = $ranker->unrankPrefix($rank, $depth);
    $ranked = $ranker->rankPrefix($unranked['prefix']);
    $sampleResults[] = [
        'root_rank' => gmp_strval($rank, 10),
        'prefix' => $unranked['prefix'],
        'residual_rank' => gmp_strval($unranked['residual_rank'], 10),
        'unrank_completion_count' => gmp_strval($unranked['completion_count'], 10),
        'rank_start' => gmp_strval($ranked['rank_start'], 10),
        'rank_completion_count' => gmp_strval($ranked['completion_count'], 10),
    ];
}

$boundaryResults = [];
foreach (($input['boundary_prefixes'] ?? []) as $item) {
    $prefix = $item['prefix'] ?? null;
    if (!is_array($prefix)) throw new InvalidArgumentException('SOURCE_SHAPE_BOUNDARY_PREFIX');
    $ranked = $ranker->rankPrefix($prefix);
    $boundaryResults[] = [
        'high' => $item['high'],
        'depth' => count($prefix),
        'completion_count' => gmp_strval($ranked['completion_count'], 10),
        'rank_start' => gmp_strval($ranked['rank_start'], 10),
    ];
}

$twoLeft = $input['two_left_prefix'] ?? null;
$oneLeft = $input['one_left_prefix'] ?? null;
if (!is_array($twoLeft) || !is_array($oneLeft)) throw new InvalidArgumentException('SOURCE_SHAPE_LONG_PREFIXES');
$twoLeftCount = $ranker->completionCount($twoLeft);
$oneLeftCount = $ranker->completionCount($oneLeft);

$fullGrouped = [];
foreach ($lengths as $month => $length) {
    for ($i = 0; $i < $length; ++$i) $fullGrouped[] = $month;
}
$fullUnrank = $ranker->unrankPrefix(gmp_init(1), $totalLength);
$fullRank = $ranker->rankPrefix($fullUnrank['prefix']);

$invalidResults = [];
foreach (($input['invalid_prefixes'] ?? []) as $prefix) {
    $count = $ranker->completionCount($prefix);
    $threw = false;
    try {
        $ranker->rankPrefix($prefix);
    } catch (Throwable) {
        $threw = true;
    }
    $invalidResults[] = [
        'completion_count' => gmp_strval($count, 10),
        'rank_rejected' => $threw,
    ];
}

$invalidRanksRejected = [];
foreach ([gmp_init(0), gmp_add($total, 1)] as $invalidRank) {
    $threw = false;
    try {
        $ranker->unrankPrefix($invalidRank, 1);
    } catch (Throwable) {
        $threw = true;
    }
    $invalidRanksRejected[] = $threw;
}

$stats = $ranker->rowStats();
echo json_encode([
    'status' => 'SOURCE_SHAPE_GMP_RANK_RESULT',
    'php_version' => PHP_VERSION,
    'php_int_size' => PHP_INT_SIZE,
    'gmp_version' => phpversion('gmp') ?: 'unknown',
    'gmp_library' => defined('GMP_VERSION') ? GMP_VERSION : 'unknown',
    'root_count' => gmp_strval($total, 10),
    'small_selftest' => $smallSelftest,
    'samples' => $sampleResults,
    'boundary_prefixes' => $boundaryResults,
    'two_left' => ['depth' => count($twoLeft), 'completion_count' => gmp_strval($twoLeftCount, 10)],
    'one_left' => ['depth' => count($oneLeft), 'completion_count' => gmp_strval($oneLeftCount, 10)],
    'full_rank1' => [
        'depth' => count($fullUnrank['prefix']),
        'word_matches_grouped' => $fullUnrank['prefix'] === $fullGrouped,
        'residual_rank' => gmp_strval($fullUnrank['residual_rank'], 10),
        'completion_count' => gmp_strval($fullUnrank['completion_count'], 10),
        'rank_start' => gmp_strval($fullRank['rank_start'], 10),
        'rank_completion_count' => gmp_strval($fullRank['completion_count'], 10),
    ],
    'invalid_prefixes' => $invalidResults,
    'invalid_ranks_rejected' => $invalidRanksRejected,
    'metrics' => $stats + [
        'elapsed_ns' => hrtime(true) - $started,
        'php_peak_bytes' => memory_get_peak_usage(true),
        'root_count_digits' => strlen(gmp_strval($total, 10)),
    ],
], JSON_THROW_ON_ERROR);
