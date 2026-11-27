<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use LogicException;
use Pastafari\Stage01\BigInt;

/** Exact lexicographic interleaving rank/unrank using suffix DP. Internal IDs are zero-based. */
final class MonthWeavingInterleaving56
{
    private const SMALL_FACTOR_LIMIT = 999999999;
    private static int $dpProfileSequence = 0;
    private static int $unrankProfileSequence = 0;
    /** @var array<int, list<BigInt>> */
    private array $suffixCache = [];
    /** @var array<int, list<BigInt>> Immutable reusable absolute-stride rows. */
    private array $suffixCheckpoints = [];
    /** @var list<int> */
    private array $lengths;
    private int $monthCount;
    private bool $scratchExperiment;
    private bool $scratchFailed = false;
    private ?SuffixScratchRows56 $scratch = null;
    private int $scratchLoads = 0;

    /** @param list<int> $lengths */
    public function __construct(array $lengths, bool $scratchExperiment = false)
    {
        if (!array_is_list($lengths) || $lengths === [] || count($lengths) > 47) {
            throw new InvalidArgumentException('STAGE56_INTERLEAVING_LENGTHS');
        }
        $total = 0;
        foreach ($lengths as $length) {
            if (!is_int($length) || $length < 1 || $length > 123) {
                throw new InvalidArgumentException('STAGE56_INTERLEAVING_LENGTHS');
            }
            $total += $length;
        }
        if ($total > 5778) throw new InvalidArgumentException('STAGE56_INTERLEAVING_TOTAL');
        $this->lengths = array_values($lengths);
        $this->monthCount = count($lengths);
        $this->scratchExperiment = $scratchExperiment;
    }

    public function count(): BigInt
    {
        if ($this->monthCount === 1) return BigInt::one();
        return $this->suffixCount(0, $this->lengths[0]);
    }

    /** @param list<int> $weave zero-based month IDs */
    public function rank(array $weave): BigInt
    {
        $totalLength = array_sum($this->lengths);
        if (!array_is_list($weave) || count($weave) !== $totalLength || ($weave[0] ?? null) !== 0) {
            throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD');
        }
        $remaining = $this->lengths;
        --$remaining[0];
        $low = 0;
        $high = 0;
        $activeTotal = $remaining[0];
        $baseCount = BigInt::one();
        $rank = BigInt::one();

        for ($position = 1; $position < $totalLength; ++$position) {
            $wanted = $weave[$position];
            if (!is_int($wanted) || $wanted < 0 || $wanted >= $this->monthCount) {
                throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD_ID');
            }
            $prefix = [];
            $running = 0;
            for ($index = $low; $index <= $high; ++$index) {
                $running += $remaining[$index];
                $prefix[] = $running;
            }
            $futureSame = $high < $this->monthCount - 1
                ? $this->suffixCount($high, $activeTotal)
                : BigInt::one();

            // All already-open sibling blocks share the same suffix factor.
            // Sum their bases before multiplying: exact distributivity preserves rank.
            $skippedBase = BigInt::zero();
            $selected = false;
            $previousMonth = null;
            $previousBaseCount = null;
            for ($month = $low; $month <= $high; ++$month) {
                $remainingForMonth = $remaining[$month];
                if ($remainingForMonth === 1 && $month !== $low) continue;
                $nextBaseCount = $previousMonth === null
                    ? self::firstBranchBaseCount($baseCount, $remainingForMonth, $prefix, $low, $month, $activeTotal)
                    : self::nextBranchBaseCount($previousBaseCount, $remaining, $prefix, $low, $previousMonth, $month);
                if ($month < $wanted) {
                    $skippedBase = $skippedBase->add($nextBaseCount);
                    $previousMonth = $month;
                    $previousBaseCount = $nextBaseCount;
                    continue;
                }
                if ($month > $wanted) throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD_INVALID');
                --$remaining[$month];
                --$activeTotal;
                $baseCount = $nextBaseCount;
                if ($remaining[$month] === 0) ++$low;
                $selected = true;
                break;
            }
            if (!$skippedBase->isZero()) $rank = $rank->add($skippedBase->mul($futureSame));
            if ($selected) continue;

            $month = $high + 1;
            if ($month >= $this->monthCount || $wanted !== $month) {
                throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD_INVALID');
            }
            $newRemaining = $this->lengths[$month] - 1;
            $nextBaseCount = self::multiplyByBinomial($baseCount, $activeTotal + $newRemaining - 1, $newRemaining - 1);
            $nextActiveTotal = $activeTotal + $newRemaining;
            $future = $month < $this->monthCount - 1
                ? $this->suffixCount($month, $nextActiveTotal + 1)
                : BigInt::one();
            if ($nextBaseCount->isZero() || $future->isZero()) {
                throw new LogicException('STAGE56_INTERLEAVING_EMPTY_NEW_MONTH');
            }
            $high = $month;
            --$remaining[$month];
            if ($low > $month - 1) $low = $month;
            $activeTotal = $nextActiveTotal;
            $baseCount = $nextBaseCount;
        }
        if (array_sum($remaining) !== 0) throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD_REMAINDER');
        return $rank;
    }

    /** @return list<int> zero-based month IDs */
    public function unrank(BigInt $rank): array
    {
        $profilePath = getenv('STAGE56_UNRANK_PROFILE_PATH');
        $profileEnabled = is_string($profilePath) && $profilePath !== '';
        $profileId = $profileEnabled ? ++self::$unrankProfileSequence : 0;
        $unrankStartNs = $profileEnabled ? hrtime(true) : 0;
        $bucketStartNs = 0;
        $bucketStartPosition = 1;
        $bucketIndex = 1;
        $bucketPositions = 0;
        $setupElapsedNs = 0;
        $profile = $profileEnabled ? self::emptyUnrankProfile() : null;

        $totalLength = array_sum($this->lengths);
        $total = $this->monthCount === 1
            ? BigInt::one()
            : $this->suffixCount(0, $this->lengths[0], $profile);
        if ($profileEnabled) {
            self::trackUnrankDigits($profile, 'rank', $rank);
            self::trackUnrankDigits($profile, 'total', $total);
            ++$profile['direct_bigint_compare_calls'];
        }
        if ($rank->compare(BigInt::one()) < 0) {
            throw new InvalidArgumentException('STAGE56_INTERLEAVING_RANK_RANGE');
        }
        if ($profileEnabled) ++$profile['direct_bigint_compare_calls'];
        if ($rank->compare($total) > 0) {
            throw new InvalidArgumentException('STAGE56_INTERLEAVING_RANK_RANGE');
        }

        $weave = array_fill(0, $totalLength, 0);
        $remaining = $this->lengths;
        --$remaining[0];
        $low = 0;
        $high = 0;
        $activeTotal = $remaining[0];
        $baseCount = BigInt::one();
        if ($profileEnabled) {
            self::trackUnrankDigits($profile, 'base_count', $baseCount);
            $setupElapsedNs = hrtime(true) - $unrankStartNs;
            $bucketStartNs = hrtime(true);
        }

        for ($position = 1; $position < $totalLength; ++$position) {
            $prefix = [];
            $running = 0;
            for ($index = $low; $index <= $high; ++$index) {
                $running += $remaining[$index];
                $prefix[] = $running;
            }
            $futureSame = $high < $this->monthCount - 1
                ? $this->suffixCount($high, $activeTotal, $profile)
                : BigInt::one();
            if ($profileEnabled) self::trackUnrankDigits($profile, 'suffix_count', $futureSame);

            // Prefix sums of sibling bases are monotone. Compare scaled
            // prefix sums rather than multiplying each individual sibling.
            // At most 47 candidates, and the first candidate retains a fast path.
            $ids = [];
            $bases = [];
            $cumulative = [];
            $sum = BigInt::zero();
            $previousMonth = null;
            $previousBaseCount = null;
            $chosen = null;
            for ($month = $low; $month <= $high; ++$month) {
                $remainingForMonth = $remaining[$month];
                if ($remainingForMonth === 1 && $month !== $low) {
                    if ($profileEnabled) ++$profile['candidate_skipped_count'];
                    continue;
                }
                $branchBaseStartNs = $profileEnabled ? hrtime(true) : 0;
                if ($previousMonth === null) {
                    $nextBaseCount = self::firstBranchBaseCount(
                        $baseCount, $remainingForMonth, $prefix, $low, $month, $activeTotal
                    );
                    if ($profileEnabled) ++$profile['candidate_first_branch_count'];
                } else {
                    $nextBaseCount = self::nextBranchBaseCount(
                        $previousBaseCount, $remaining, $prefix, $low, $previousMonth, $month
                    );
                    if ($profileEnabled) ++$profile['candidate_next_branch_count'];
                }
                if ($profileEnabled) {
                    $profile['branch_base_generation_ns'] += hrtime(true) - $branchBaseStartNs;
                    ++$profile['candidate_count'];
                    self::trackUnrankDigits($profile, 'branch_base', $nextBaseCount);
                }
                $sum = $sum->add($nextBaseCount);
                if ($profileEnabled) self::trackUnrankDigits($profile, 'cumulative_base', $sum);
                $ids[] = $month;
                $bases[] = $nextBaseCount;
                $cumulative[] = $sum;
                if (count($ids) === 1) {
                    if ($profileEnabled) ++$profile['direct_bigint_mul_calls'];
                    $scaledFirst = $sum->mul($futureSame);
                    if ($profileEnabled) {
                        self::trackUnrankDigits($profile, 'scaled_first_block', $scaledFirst);
                        ++$profile['direct_bigint_compare_calls'];
                    }
                    if ($rank->compare($scaledFirst) <= 0) {
                        $chosen = 0;
                        break;
                    }
                }
                $previousMonth = $month;
                $previousBaseCount = $nextBaseCount;
            }
            if ($chosen === null && $ids !== []) {
                if ($profileEnabled) ++$profile['direct_bigint_mul_calls'];
                $scaledTotal = $sum->mul($futureSame);
                if ($profileEnabled) {
                    self::trackUnrankDigits($profile, 'scaled_total_block', $scaledTotal);
                    ++$profile['direct_bigint_compare_calls'];
                }
                if ($rank->compare($scaledTotal) > 0) {
                    if ($profileEnabled) ++$profile['direct_bigint_sub_calls'];
                    $rank = $rank->sub($scaledTotal);
                    if ($profileEnabled) self::trackUnrankDigits($profile, 'rank', $rank);
                } else {
                    // The first candidate was already ruled out.
                    $left = 1;
                    $right = count($ids) - 1;
                    while ($left < $right) {
                        $mid = intdiv($left + $right, 2);
                        if ($profileEnabled) ++$profile['direct_bigint_mul_calls'];
                        $scaledMid = $cumulative[$mid]->mul($futureSame);
                        if ($profileEnabled) {
                            self::trackUnrankDigits($profile, 'scaled_mid_block', $scaledMid);
                            ++$profile['direct_bigint_compare_calls'];
                        }
                        if ($rank->compare($scaledMid) <= 0) {
                            $right = $mid;
                        } else {
                            $left = $mid + 1;
                        }
                    }
                    $chosen = $left;
                    if ($profileEnabled) ++$profile['direct_bigint_mul_calls'];
                    $scaledPrefix = $cumulative[$chosen - 1]->mul($futureSame);
                    if ($profileEnabled) {
                        self::trackUnrankDigits($profile, 'scaled_prefix_block', $scaledPrefix);
                        ++$profile['direct_bigint_sub_calls'];
                    }
                    $rank = $rank->sub($scaledPrefix);
                    if ($profileEnabled) self::trackUnrankDigits($profile, 'rank', $rank);
                }
            }
            if ($chosen !== null) {
                $month = $ids[$chosen];
                $weave[$position] = $month;
                --$remaining[$month];
                --$activeTotal;
                $baseCount = $bases[$chosen];
                if ($profileEnabled) self::trackUnrankDigits($profile, 'base_count', $baseCount);
                if ($remaining[$month] === 0) ++$low;
            } else {
                $month = $high + 1;
                if ($month >= $this->monthCount) {
                    throw new LogicException('STAGE56_INTERLEAVING_EXHAUSTED');
                }
                $newRemaining = $this->lengths[$month] - 1;
                $branchBaseStartNs = $profileEnabled ? hrtime(true) : 0;
                $nextBaseCount = self::multiplyByBinomial(
                    $baseCount, $activeTotal + $newRemaining - 1, $newRemaining - 1
                );
                if ($profileEnabled) {
                    $profile['branch_base_generation_ns'] += hrtime(true) - $branchBaseStartNs;
                    ++$profile['new_month_branch_count'];
                    self::trackUnrankDigits($profile, 'branch_base', $nextBaseCount);
                }
                $nextActiveTotal = $activeTotal + $newRemaining;
                $future = $month < $this->monthCount - 1
                    ? $this->suffixCount($month, $nextActiveTotal + 1, $profile)
                    : BigInt::one();
                if ($profileEnabled) self::trackUnrankDigits($profile, 'suffix_count', $future);
                if ($nextBaseCount->isZero() || $future->isZero()) {
                    throw new LogicException('STAGE56_INTERLEAVING_EMPTY_NEW_MONTH');
                }
                if ($profileEnabled) ++$profile['direct_bigint_mul_calls'];
                $block = $nextBaseCount->mul($future);
                if ($profileEnabled) {
                    self::trackUnrankDigits($profile, 'new_month_block', $block);
                    ++$profile['direct_bigint_compare_calls'];
                }
                if ($rank->compare($block) > 0) {
                    throw new LogicException('STAGE56_INTERLEAVING_FINAL_BRANCH');
                }
                $weave[$position] = $month;
                $high = $month;
                --$remaining[$month];
                if ($low > $month - 1) $low = $month;
                $activeTotal = $nextActiveTotal;
                $baseCount = $nextBaseCount;
                if ($profileEnabled) self::trackUnrankDigits($profile, 'base_count', $baseCount);
            }

            if ($profileEnabled) {
                ++$bucketPositions;
                if ($bucketPositions >= 256 || $position === $totalLength - 1) {
                    self::writeUnrankProfileBucket(
                        $profilePath,
                        $profileId,
                        $bucketIndex,
                        $bucketStartPosition,
                        $position,
                        $bucketPositions,
                        $bucketStartNs,
                        $unrankStartNs,
                        $setupElapsedNs,
                        $profile
                    );
                    $bucketPositions = 0;
                    $bucketStartPosition = $position + 1;
                    $bucketStartNs = hrtime(true);
                    ++$bucketIndex;
                    // Record the incoming rank even when no subtraction occurs in this bucket.
                    if ($position < $totalLength - 1) self::trackUnrankDigits($profile, 'rank', $rank);
                }
            }
        }
        if (array_sum($remaining) !== 0) {
            throw new InvalidArgumentException('STAGE56_INTERLEAVING_WORD_REMAINDER');
        }
        if ($profileEnabled) ++$profile['direct_bigint_compare_calls'];
        if (!$rank->equals(BigInt::one())) {
            throw new LogicException('STAGE56_INTERLEAVING_REMAINDER');
        }
        return $weave;
    }

    /** @return array<string, int|array<string, int>> */
    private static function emptyUnrankProfile(): array
    {
        return [
            'candidate_count' => 0,
            'candidate_first_branch_count' => 0,
            'candidate_next_branch_count' => 0,
            'candidate_skipped_count' => 0,
            'new_month_branch_count' => 0,
            'branch_base_generation_ns' => 0,
            'direct_bigint_mul_calls' => 0,
            'direct_bigint_compare_calls' => 0,
            'direct_bigint_sub_calls' => 0,
            'suffix_count_calls' => 0,
            'suffix_cache_hits' => 0,
            'suffix_checkpoint_hits' => 0,
            'suffix_rebuilds' => 0,
            'suffix_terminal_shortcuts' => 0,
            'max_decimal_digits' => 0,
            'max_decimal_digits_by_role' => [],
        ];
    }

    private static function trackUnrankDigits(?array &$profile, string $role, BigInt $value): void
    {
        if ($profile === null) return;
        $digits = $value->decimalDigitCount();
        $profile['max_decimal_digits'] = max($profile['max_decimal_digits'], $digits);
        $profile['max_decimal_digits_by_role'][$role] = max(
            $profile['max_decimal_digits_by_role'][$role] ?? 0,
            $digits
        );
    }

    /** One JSONL write per 256 unrank positions; never per candidate or cell. */
    private static function writeUnrankProfileBucket(
        string $path,
        int $profileId,
        int $bucketIndex,
        int $positionStart,
        int $positionEnd,
        int $positions,
        int $bucketStartNs,
        int $unrankStartNs,
        int $setupElapsedNs,
        array &$profile
    ): void {
        $now = hrtime(true);
        $record = [
            'schema_version' => 1,
            'event' => 'bucket',
            'method' => 'MonthWeavingInterleaving56::unrank',
            'profile_id' => $profileId,
            'bucket_index' => $bucketIndex,
            'position_start' => $positionStart,
            'position_end' => $positionEnd,
            'positions' => $positions,
            'bucket_elapsed_ns' => $now - $bucketStartNs,
            'unrank_elapsed_ns' => $now - $unrankStartNs,
            'setup_elapsed_ns' => $bucketIndex === 1 ? $setupElapsedNs : 0,
            'timestamp_ns' => $now,
        ];
        foreach ($profile as $key => $value) $record[$key] = $value;
        $record['allocated_bytes'] = memory_get_usage(true);
        $record['process_peak_bytes'] = memory_get_peak_usage(true);
        $line = json_encode($record, JSON_THROW_ON_ERROR) . "\n";
        if (file_put_contents($path, $line, FILE_APPEND | LOCK_EX) !== strlen($line)) {
            throw new LogicException('STAGE56_UNRANK_PROFILE_WRITE');
        }
        $profile = self::emptyUnrankProfile();
    }

    /** Experimental diagnostics, never shared with another engine. */
    public function scratchStats56(): array
    {
        return ['bytes' => $this->scratch?->bytes() ?? 0, 'loads' => $this->scratchLoads,
            'rows' => $this->scratch?->rows() ?? 0];
    }

    private function scratchCount56(int $index, int $q, ?array &$profile): BigInt
    {
        if ($this->scratchFailed) throw new LogicException('STAGE56_SCRATCH_FAILED');
        try {
            if ($this->scratch === null) {
                require_once __DIR__ . '/SuffixScratchRows56.php';
                $this->scratch = new SuffixScratchRows56($this->lengths);
                if ($profile !== null) ++$profile['suffix_rebuilds'];
                $this->rebuildSuffix(0, $this->lengths[0]);
            }
            if (!isset($this->suffixCache[$index])) {
                // Evict before decoding: never retain a second decoded cache row.
                $this->suffixCache = [];
                $this->suffixCache[$index] = $this->scratch->load($index);
                ++$this->scratchLoads;
            } elseif ($profile !== null) {
                ++$profile['suffix_cache_hits'];
            }
            return $this->suffixCache[$index][$q]
                ?? throw new LogicException('STAGE56_SCRATCH_WIDTH');
        } catch (\Throwable $error) {
            $this->suffixCache = [];
            $this->scratch = null;
            $this->scratchFailed = true;
            throw $error;
        }
    }

    private function suffixCount(int $lastSeen, int $q, ?array &$profile = null): BigInt
    {
        if ($profile !== null) ++$profile['suffix_count_calls'];
        if ($lastSeen >= $this->monthCount - 1) {
            if ($profile !== null) ++$profile['suffix_terminal_shortcuts'];
            return BigInt::one();
        }
        if ($this->scratchExperiment) return $this->scratchCount56($lastSeen, $q, $profile);
        $cached = $this->suffixCache[$lastSeen] ?? null;
        if ($cached !== null && count($cached) > $q) {
            if ($profile !== null) ++$profile['suffix_cache_hits'];
            return $cached[$q];
        }
        $checkpoint = $this->suffixCheckpoints[$lastSeen] ?? null;
        if ($checkpoint !== null && count($checkpoint) > $q) {
            if ($profile !== null) ++$profile['suffix_checkpoint_hits'];
            return $checkpoint[$q];
        }
        if ($profile !== null) ++$profile['suffix_rebuilds'];
        $this->rebuildSuffix($lastSeen, $q);
        return $this->suffixCache[$lastSeen][$q]
            ?? throw new LogicException('STAGE56_INTERLEAVING_CACHE_MISS');
    }

    private function rebuildSuffix(int $start, int $qStart): void
    {
        $needed = array_fill(0, $this->monthCount, 0);
        $needed[$start] = $qStart;
        for ($index = $start; $index < $this->monthCount - 1; ++$index) {
            $needed[$index + 1] = $needed[$index] + $this->lengths[$index + 1] - 1;
        }
        // A covering checkpoint is the exact same DP row, possibly with extra
        // entries. Never reuse a shorter row; recompute from the terminal row.
        $following = null;
        $stop = $this->monthCount - 1;
        for ($index = $start + 1; $index < $this->monthCount - 1; ++$index) {
            $checkpoint = $this->suffixCheckpoints[$index] ?? null;
            if ($checkpoint !== null && count($checkpoint) > $needed[$index]) {
                $following = $checkpoint;
                $stop = $index - 1;
                break;
            }
        }
        // At most five absolute checkpoints (8,16,24,32,40); reserve
        // the remaining slots of the original eight-row cache for active rows.
        $activeRows = $this->scratchExperiment ? 1 : 8 - intdiv($this->monthCount - 2, 8);
        $profilePath = getenv('STAGE56_DP_PROFILE_PATH');
        $profileEnabled = is_string($profilePath) && $profilePath !== '';
        $profileId = $profileEnabled ? ++self::$dpProfileSequence : 0;
        $profileStart = $profileEnabled ? hrtime(true) : 0;
        $plannedCells = 0;
        if ($profileEnabled) {
            for ($i = $start; $i <= min($stop, $this->monthCount - 2); ++$i) $plannedCells += $needed[$i];
            self::writeDpProfile($profilePath, ['event'=>'start', 'id'=>$profileId, 'engine'=>spl_object_id($this),
                'month_count'=>$this->monthCount, 'start'=>$start, 'stop'=>$stop, 'q_start'=>$qStart,
                'planned_cells'=>$plannedCells, 'checkpoint_reused'=>$stop < $this->monthCount - 1,
                'timestamp_ns'=>$profileStart]);
        }
        $this->suffixCache = [];
        for ($index = $stop; $index >= $start; --$index) {
            $qMax = $needed[$index];
            if ($index === $this->monthCount - 1) {
                $current = array_fill(0, $qMax + 1, BigInt::one());
            } else {
                if (!is_array($following)) throw new LogicException('STAGE56_INTERLEAVING_DP_SUFFIX');
                $current = array_fill(0, $qMax + 1, BigInt::zero());
                $monthLength = $this->lengths[$index + 1];
                $cumulative = BigInt::zero();
                $weight = BigInt::one();
                for ($q = 1; $q <= $qMax; ++$q) {
                    $r = $q - 1;
                    $target = $monthLength + $r;
                    if (!isset($following[$target])) throw new LogicException('STAGE56_INTERLEAVING_DP_INDEX');
                    $cumulative = $cumulative->add($weight->mul($following[$target]));
                    $current[$q] = $cumulative;
                    $weight = $weight->mulSmall($monthLength + $r - 1)
                        ->divSmallExact($r + 1);
                }
            }
            $following = $current;
            if ($index < $start + $activeRows) $this->suffixCache[$index] = $current;
            if ($this->scratchExperiment && $index < $this->monthCount - 1) {
                $this->scratch->append($index, $current);
            }
            if (!$this->scratchExperiment && $index > 0 && $index % 8 === 0 && $index < $this->monthCount - 1 &&
                count($this->suffixCheckpoints[$index] ?? []) < count($current)) {
                $this->suffixCheckpoints[$index] = $current;
            }
            if ($profileEnabled) self::writeDpProfile($profilePath, ['event'=>'row', 'id'=>$profileId,
                'index'=>$index, 'q_max'=>$qMax, 'cells'=>$index === $this->monthCount - 1 ? 0 : $qMax,
                'active_rows'=>count($this->suffixCache), 'checkpoint_rows'=>count($this->suffixCheckpoints),
                'timestamp_ns'=>hrtime(true)]);
        }
        if ($profileEnabled) self::writeDpProfile($profilePath, ['event'=>'end', 'id'=>$profileId,
            'cells'=>$plannedCells, 'seconds'=>(hrtime(true)-$profileStart)/1e9, 'timestamp_ns'=>hrtime(true)]);
    }

    /** Opt-in QA only: no per-cell I/O; process allocated memory is not OS RSS. */
    private static function writeDpProfile(string $path, array $record): void
    {
        $record['allocated_bytes'] = memory_get_usage(true);
        $record['process_peak_bytes'] = memory_get_peak_usage(true);
        $line = json_encode($record, JSON_THROW_ON_ERROR) . "\n";
        if (file_put_contents($path, $line, FILE_APPEND | LOCK_EX) !== strlen($line)) {
            throw new LogicException('STAGE56_DP_PROFILE_WRITE');
        }
    }

    private static function firstBranchBaseCount(BigInt $baseCount, int $remainingForMonth, array $prefix, int $low, int $month, int $activeTotal): BigInt
    {
        $offset = $month - $low;
        $firstFactor = $remainingForMonth > 1 ? $offset : $offset + 1;
        $numerators = $remainingForMonth > 1 ? [$remainingForMonth - 1] : [];
        $denominators = [$activeTotal];
        for ($i = $firstFactor, $n = count($prefix); $i < $n; ++$i) {
            $numerators[] = $prefix[$i];
            $denominators[] = $prefix[$i] - 1;
        }
        return self::scaleBySmallRatio($baseCount, $numerators, $denominators);
    }

    private static function nextBranchBaseCount(BigInt $previousBaseCount, array $remaining, array $prefix, int $low, int $previousMonth, int $month): BigInt
    {
        $previousOffset = $previousMonth - $low;
        $offset = $month - $low;
        $currentRemaining = $remaining[$month];
        $previousRemaining = $remaining[$previousMonth];
        if ($currentRemaining <= 1) throw new LogicException('STAGE56_INTERLEAVING_BRANCH_ORDER');
        $numerators = [$currentRemaining - 1];
        $denominators = [];
        $firstPrefix = $previousRemaining === 1 ? $previousOffset + 1 : $previousOffset;
        if ($previousRemaining > 1) $denominators[] = $previousRemaining - 1;
        for ($i = $firstPrefix; $i < $offset; ++$i) {
            $numerators[] = $prefix[$i] - 1;
            $denominators[] = $prefix[$i];
        }
        return self::scaleBySmallRatio($previousBaseCount, $numerators, $denominators);
    }

    /** @param list<int> $numerators @param list<int> $denominators */
    private static function scaleBySmallRatio(BigInt $value, array $numerators, array $denominators): BigInt
    {
        foreach ($numerators as $i => $numerator) {
            if ($numerator < 1) throw new LogicException('STAGE56_INTERLEAVING_RATIO_NUMERATOR');
            for ($j = 0, $n = count($denominators); $j < $n && $numerator > 1; ++$j) {
                $denominator = $denominators[$j];
                if ($denominator < 1) throw new LogicException('STAGE56_INTERLEAVING_RATIO_DENOMINATOR');
                $gcd = self::gcd($numerator, $denominator);
                if ($gcd > 1) {
                    $numerator = intdiv($numerator, $gcd);
                    $denominators[$j] = intdiv($denominator, $gcd);
                }
            }
            $numerators[$i] = $numerator;
        }
        foreach (self::packSmallFactors($numerators) as $factor) $value = $value->mulSmall($factor);
        foreach (self::packSmallFactors($denominators) as $factor) {
            $value = $value->divSmallExact($factor);
        }
        return $value;
    }

    /** @param list<int> $factors @return list<int> */
    private static function packSmallFactors(array $factors): array
    {
        $packed = [];
        $product = 1;
        foreach ($factors as $factor) {
            if ($factor < 1) throw new LogicException('STAGE56_INTERLEAVING_FACTOR');
            if ($factor === 1) continue;
            if ($product > intdiv(self::SMALL_FACTOR_LIMIT, $factor)) {
                $packed[] = $product;
                $product = 1;
            }
            $product *= $factor;
        }
        if ($product > 1) $packed[] = $product;
        return $packed;
    }

    private static function multiplyByBinomial(BigInt $value, int $n, int $k): BigInt
    {
        if ($k < 0 || $n < 0 || $k > $n) return BigInt::zero();
        $k = min($k, $n - $k);
        $numerators = [];
        $denominators = [];
        for ($i = 1; $i <= $k; ++$i) {
            $numerators[] = $n - $k + $i;
            $denominators[] = $i;
        }
        return self::scaleBySmallRatio($value, $numerators, $denominators);
    }

    private static function gcd(int $a, int $b): int
    {
        while ($b !== 0) [$a, $b] = [$b, $a % $b];
        return $a;
    }
}
