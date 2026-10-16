<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyVisibleGrind;

/**
 * Baris kosong pada indeks 0 mengekalkan pembaca grind lama (1..11).
 * Sebelas baris sebenar tidak ditukar susunan atau dikira semula.
 */
final class GrindTablePatch07
{
    private LegacyVisibleGrind $legacyWithSentinel;

    public function __construct(SavePatch01 $save, PriorAccessPatch06 $prior)
    {
        $this->legacyWithSentinel = new LegacyVisibleGrind(
            $save, $prior, self::rowsWithSentinel()
        );
    }

    /** @return array<int,array{0:int,1:int,2:int,3:int,4:string}> */
    public static function rowsWithSentinel(): array
    {
        $rows = [0 => [0, 0, 0, 0, 'none']];
        foreach (LegacyVisibleGrind::legacyGrindRows() as $index => $row) {
            $rows[$index + 1] = $row;
        }
        return $rows;
    }

    /** @return array{0:int,1:int,2:int,3:int,4:string} */
    public function grindPatch(int $grind): array
    {
        // Pembaca sejarah yang sebenar menerima jadual berindeks baharu.
        return $this->legacyWithSentinel->legacyRowAt($grind);
    }

    /**
     * @param array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} $counts
     * @param array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> $stones
     * @param array<int,BigInt> $hiddenBackward
     * @return array<int,BigInt>
     */
    public function buildVisible(array $counts, array $stones, array $hiddenBackward): array
    {
        // Seluruh sebelas pengisaran setiap titisan masih melalui legacyRowAt.
        return $this->legacyWithSentinel->buildVisibleWrong(
            $counts, $stones, $hiddenBackward
        );
    }
}
