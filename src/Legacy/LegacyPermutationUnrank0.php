<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;

/**
 * Penyahpangkat permutasi lama ini betul untuk pangkat sifar 0..719.
 * Cacat Stage 16 terletak pada pemanggil yang membekalkan pangkat satu.
 */
final class LegacyPermutationUnrank0
{
    /** @return list<int> */
    public function oldPermutationUnrank0(int $rank0): array
    {
        if ($rank0 < 0 || $rank0 >= 720) {
            throw new InvalidArgumentException('PERMUTATION_RANK_ZERO_RANGE');
        }
        $factorial = [1, 1, 2, 6, 24, 120, 720];
        $remaining = [1, 2, 3, 4, 5, 6];
        $result = [];
        for ($slots = 6; $slots >= 1; $slots--) {
            $block = $factorial[$slots - 1];
            $index = intdiv($rank0, $block);
            $rank0 %= $block;
            $result[] = $remaining[$index];
            array_splice($remaining, $index, 1);
        }
        return $result;
    }
}
