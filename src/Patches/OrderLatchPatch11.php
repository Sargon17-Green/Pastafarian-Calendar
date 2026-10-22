<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyOverwrittenOrder11;

/** PATCH11: kunci susunan titisan 46, kekalkan semua parut sejarah. */
final class OrderLatchPatch11
{
    public function __construct(
        private readonly LegacyOverwrittenOrder11 $legacy,
        private readonly PermutationPatch08 $permutation
    ) {
    }

    /**
     * @param array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} $counts
     * @param array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> $stones
     * @param array<int,BigInt> $visible
     * @return array{bowls:array<int,BigInt>,orderAtDrop46:list<int>,postStirs:int,dropCount:int}
     */
    public function sauceWithOrderLatch(array $counts, array $stones, array $visible): array
    {
        if (array_keys($visible) !== range(1, 46)
            || array_keys($stones) !== range(1, 46)
            || !$visible[46] instanceof BigInt) {
            throw new InvalidArgumentException('ORDER_LATCH_SHAPE');
        }
        // Permutasi tulen sebelum penggunaan hasil kacauan akhir.
        $orderAt46Latch = $this->permutation->permutationPatch($visible[46]);

        // Pengiraan sejarah penuh berlaku secara sebenar pada semua 46 titisan.
        $historical = $this->legacy->sauceWrong($counts, $stones, $visible);

        // Satu medan sahaja ditampal; keenam-enam mangkuk kekal asal.
        $historical['orderAtDrop46'] = $orderAt46Latch;
        return $historical;
    }
}
