<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use LogicException;
use Pastafari\Stage01\BigInt;

/** Stage56 B1: exact suffix count via last-symbol insertion, not yet rank/unrank/provider. */
final class MonthWeavingFrontier56
{
    /** @param list<int> $counts */
    public function count(array $counts): BigInt
    {
        if ($counts === [] || in_array(0, $counts, true)) {
            throw new InvalidArgumentException('STAGE56_WEAVING_COUNTS');
        }
        return $this->countSuffix($counts, 0);
    }

    /**
     * Number of legal completions after a prefix whose largest opened month ID is $opened.
     * Closed month IDs must form the zero prefix of $remaining.
     * This O(m * L) arithmetic-operation counter is exact but not yet an efficient ranker.
     * @param list<int> $remaining
     */
    public function countSuffix(array $remaining, int $opened): BigInt
    {
        $m = count($remaining);
        if (!array_is_list($remaining) || $m < 1 || $m > 47 || $opened < 0 || $opened > $m) {
            throw new InvalidArgumentException('STAGE56_WEAVING_ARGS');
        }
        $first = $m;
        $length = 0;
        $seen = false;
        foreach ($remaining as $i => $n) {
            if (!is_int($n) || $n < 0 || $n > 123 || ($seen && $n === 0)) {
                throw new InvalidArgumentException('STAGE56_WEAVING_COUNTS');
            }
            if ($n > 0 && !$seen) {
                $first = $i;
                $seen = true;
            }
            $length += $n;
        }
        if ($length > 5778 || ($first > $opened && $first < $m)) {
            throw new InvalidArgumentException('STAGE56_WEAVING_STATE');
        }
        if ($first === $m) {
            return BigInt::one();
        }
        $oldLength = 0;
        $previous = [BigInt::one()]; // Empty base word, first-position distribution at 0.
        for ($index = $first; $index < $m; ++$index) {
            $n = $remaining[$index];
            $total = BigInt::zero();
            foreach ($previous as $count) {
                $total = $total->add($count);
            }
            $current = array_fill(0, $oldLength + 2, BigInt::zero());
            if ($n === 1) {
                // Last occurrence order forces the newest label to the final position.
                $current[$oldLength + 1] = $total;
            } else {
                $prefixMass = $total;
                $weight = BigInt::one(); // C(n-2,n-2), gap=oldLength.
                $orderedFirst = ($index + 1 > $opened + 1);
                for ($gap = $oldLength; $gap >= 0; --$gap) {
                    $mass = $orderedFirst ? $prefixMass : $total;
                    $current[$gap + 1] = $mass->mul($weight);
                    if (isset($previous[$gap])) {
                        $prefixMass = $prefixMass->sub($previous[$gap]);
                    }
                    if ($gap > 0) {
                        $t = $oldLength - $gap + 1;
                        [$weight, $remainder] = $weight->mulSmall($n - 2 + $t)
                            ->divMod(BigInt::fromInt($t));
                        if (!$remainder->isZero()) {
                            throw new LogicException('STAGE56_WEAVING_NONEXACT');
                        }
                    }
                }
            }
            $previous = $current;
            $oldLength += $n;
        }
        $answer = BigInt::zero();
        foreach ($previous as $count) {
            $answer = $answer->add($count);
        }
        return $answer;
    }
}
