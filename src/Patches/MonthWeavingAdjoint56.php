<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use LogicException;
use Pastafari\Stage01\BigInt;

/** Stage56 B3: exact sibling block cardinalities from a shared backward adjoint. */
final class MonthWeavingAdjoint56
{
    /**
     * Return [1-based next month ID => number of valid completions after that ID].
     * Only zero-prefix states are accepted. No provider integration in this phase.
     *
     * @param list<int> $remaining
     * @return array<int,BigInt>
     */
    public function candidateBlocks(array $remaining, int $opened): array
    {
        $m = count($remaining);
        if (!array_is_list($remaining) || $m < 1 || $m > 47 || $opened < 0 || $opened > $m) {
            throw new InvalidArgumentException('STAGE56_B3_ARGS');
        }
        $first = $m;
        $seen = false;
        $length = 0;
        foreach ($remaining as $i => $n) {
            if (!is_int($n) || $n < 0 || $n > 123 || ($seen && $n === 0)) {
                throw new InvalidArgumentException('STAGE56_B3_COUNTS');
            }
            if ($n > 0 && !$seen) {
                $first = $i;
                $seen = true;
            }
            $length += $n;
        }
        if ($length > 5778 || ($first > $opened && $first < $m)) {
            throw new InvalidArgumentException('STAGE56_B3_STATE');
        }
        if ($first === $m) {
            return [];
        }

        $cum = array_fill(0, $m + 1, 0);
        for ($i = $first; $i < $m; ++$i) {
            $cum[$i + 1] = $cum[$i] + $remaining[$i];
        }

        // If any family before j loses exactly one symbol, family j sees the
        // same shortened old-length cum[j]-1, regardless of which family lost it.
        // Preserve only compressed decimal adjoint rows, not a matrix of BigInts.
        $packed = [];
        $adj = array_fill(0, $length, BigInt::one()); // terminal linear functional
        $packed[$m] = self::pack($adj);
        for ($j = $m - 1; $j > $first; --$j) {
            $adj = self::backward($adj, $cum[$j] - 1, $remaining[$j], $j + 1 > $opened + 1);
            $packed[$j] = self::pack($adj);
        }
        unset($adj);

        $prefix = [BigInt::one()];
        $blocks = [];
        $latestCandidate = min($m - 1, $opened);
        for ($i = $first; $i <= $latestCandidate; ++$i) {
            $id = $i + 1;
            $n = $remaining[$i];
            // A last symbol can close only the earliest still-active family.
            if ($n > 1 || $i === $first) {
                $after = self::unpack($packed[$i + 1]);
                // Opening the next family changes the first-occurrence constraint
                // for exactly ONE later family: ID opened+2, if present.
                if ($i === $opened && $i + 1 < $m) {
                    $after = self::backward(
                        self::unpack($packed[$i + 2]),
                        $cum[$i + 1] - 1,
                        $remaining[$i + 1],
                        false
                    );
                }
                if ($n === 1) {
                    // Only first can close. The remaining suffix begins empty.
                    $blocks[$id] = $after[0];
                } else {
                    $candidateRow = self::forward($prefix, $cum[$i], $n - 1, false);
                    $sum = BigInt::zero();
                    foreach ($candidateRow as $position => $ways) {
                        if (!$ways->isZero()) {
                            $sum = $sum->add($ways->mul($after[$position]));
                        }
                    }
                    $blocks[$id] = $sum;
                }
            }
            // The untouched prefix is reused by the next sibling candidate.
            if ($i < $latestCandidate) {
                $prefix = self::forward($prefix, $cum[$i], $n, $id > $opened + 1);
            }
        }
        return $blocks;
    }

    /** @param list<BigInt> $input @return list<BigInt> */
    private static function forward(array $input, int $old, int $n, bool $orderedFirst): array
    {
        $total = BigInt::zero();
        foreach ($input as $part) $total = $total->add($part);
        $result = array_fill(0, $old + 2, BigInt::zero());
        if ($n === 1) {
            $result[$old + 1] = $total;
            return $result;
        }
        $prefixMass = $total;
        $weight = BigInt::one();
        for ($gap = $old; $gap >= 0; --$gap) {
            $mass = $orderedFirst ? $prefixMass : $total;
            $result[$gap + 1] = $mass->mul($weight);
            if (isset($input[$gap])) $prefixMass = $prefixMass->sub($input[$gap]);
            if ($gap > 0) {
                $t = $old - $gap + 1;
                $weight = self::advance($weight, $n - 2 + $t, $t);
            }
        }
        return $result;
    }

    /**
     * Transpose the exact first-position insertion operator. The terminal
     * adjoint is all ones; a shifted input length covers every sibling branch.
     * @param list<BigInt> $after @return list<BigInt>
     */
    private static function backward(array $after, int $old, int $n, bool $orderedFirst): array
    {
        if ($old < 0 || $n < 1 || count($after) !== $old + $n + 1) {
            throw new LogicException('STAGE56_B3_ADJOINT_SHAPE');
        }
        if ($n === 1) return array_fill(0, $old + 1, $after[$old + 1]);
        $before = array_fill(0, $old + 1, BigInt::zero());
        $sum = BigInt::zero();
        $weight = BigInt::one();
        for ($h = $old; $h >= 0; --$h) {
            $term = $after[$h + 1]->mul($weight);
            $sum = $sum->add($term);
            $before[$h] = $sum;
            if ($h > 0) {
                $t = $old - $h + 1;
                $weight = self::advance($weight, $n - 2 + $t, $t);
            }
        }
        return $orderedFirst ? $before : array_fill(0, $old + 1, $sum);
    }

    private static function advance(BigInt $weight, int $numerator, int $denominator): BigInt
    {
        [$next, $remainder] = $weight->mulSmall($numerator)->divMod(BigInt::fromInt($denominator));
        if (!$remainder->isZero()) throw new LogicException('STAGE56_B3_NONEXACT');
        return $next;
    }

    /** @param list<BigInt> $row */
    private static function pack(array $row): string
    {
        $decimals = [];
        foreach ($row as $value) $decimals[] = $value->toString();
        $bytes = gzcompress(implode("\n", $decimals), 1);
        if ($bytes === false) throw new LogicException('STAGE56_B3_COMPRESS');
        return $bytes;
    }

    /** @return list<BigInt> */
    private static function unpack(string $packed): array
    {
        $bytes = gzuncompress($packed);
        if ($bytes === false) throw new LogicException('STAGE56_B3_DECOMPRESS');
        return array_map(static fn(string $v): BigInt => BigInt::fromString($v), explode("\n", $bytes));
    }
}
