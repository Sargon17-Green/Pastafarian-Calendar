<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyFixedPositionPours;

/**
 * Alias sementara mengubah bacaan posisi legacy menjadi identiti mangkuk
 * mengikut permutasi. Pembaca fixed-ID sejarah tidak diubah.
 */
final class PoursAliasPatch09
{
    public function __construct(private readonly LegacyFixedPositionPours $legacy)
    {
    }

    /** @param list<int> $order @return array<int,int> */
    public function installOrderAliases(array $order): array
    {
        if (array_keys($order) !== range(0, 5)) {
            throw new InvalidArgumentException('BOWL_ALIAS_ORDER');
        }
        $sorted = $order;
        sort($sorted);
        if ($sorted !== [1, 2, 3, 4, 5, 6]) {
            throw new InvalidArgumentException('BOWL_ALIAS_ORDER');
        }
        $aliases = [];
        for ($position = 1; $position <= 6; $position++) {
            $aliases[$position] = $order[$position - 1];
        }
        return $aliases;
    }

    /**
     * @param array<int,BigInt> $bowls
     * @param array<int,int> $aliases
     */
    public function bowlByLegacyPosition(array $bowls, array $aliases, int $position): BigInt
    {
        if ($position < 1 || $position > 6 || !isset($aliases[$position])) {
            throw new InvalidArgumentException('BOWL_ALIAS_POSITION');
        }
        $id = $aliases[$position];
        if (!isset($bowls[$id]) || !$bowls[$id] instanceof BigInt) {
            throw new InvalidArgumentException('BOWL_ALIAS_MISSING');
        }
        return $bowls[$id];
    }

    /**
     * @param array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt} $stone
     * @param array<int,BigInt> $oldBowls
     * @param list<int> $order
     * @return array<int,BigInt>
     */
    public function patchedPours(
        int $i,
        BigInt $drop,
        array $stone,
        array $oldBowls,
        array $order
    ): array {
        $aliases = $this->installOrderAliases($order);
        $view = [];
        for ($position = 1; $position <= 6; $position++) {
            $view[$position] = $this->bowlByLegacyPosition($oldBowls, $aliases, $position);
        }
        // Bacaan ketiga-tiga posisi masih berjalan melalui kod legacy asal.
        return $this->legacy->legacyPours($i, $drop, $stone, $view, $order);
    }
}
