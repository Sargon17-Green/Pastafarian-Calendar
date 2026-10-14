<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyStoneMutation;

/**
 * Lapisan batu keempat mengekalkan panggilan mutasi sejarah yang salah.
 * Keputusan sah ditulis semula daripada snapshot asal sahaja.
 */
final class StonePatch04
{
    public function __construct(
        private readonly LegacyStoneMutation $legacy,
        private readonly SavePatch01 $save
    ) {
    }

    /**
     * @param array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt} $state
     * @return array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}
     */
    public function stonePatch(int $index, array $state): array
    {
        // Snapshot pembacaan berasingan daripada salinan untuk panggilan lama.
        $old = $state;
        $garbage = $state;

        // Panggilan sejarah mesti benar-benar berlaku; jangan buang kesannya.
        $this->legacy->mutateStonesWrong($index, $garbage);

        // Semua lima bacaan hanya menggunakan keadaan old, bukan garbage.
        $garbage['w'] = $this->save->savePatch(
            $old['w']->square()->add($old['b']->mulSmall(3))->add(BigInt::fromInt($index))
        );
        $garbage['b'] = $this->save->savePatch(
            $old['b']->square()->add($old['s']->mulSmall(5))->add($old['w'])
        );
        $garbage['s'] = $this->save->savePatch(
            $old['s']->square()->add($old['m']->mulSmall(7))->add($old['b'])
        );
        $garbage['m'] = $this->save->savePatch(
            $old['m']->square()->add($old['r']->mulSmall(11))->add($old['s'])
        );
        $garbage['r'] = $this->save->savePatch(
            $old['r']->square()->add($old['w']->mulSmall(13))->add($old['m'])
        );
        return $garbage;
    }

    /** @return array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> */
    public function buildStones(): array
    {
        $state = [
            'w' => BigInt::fromInt(17),
            'b' => BigInt::fromInt(29),
            's' => BigInt::fromInt(43),
            'm' => BigInt::fromInt(71),
            'r' => BigInt::fromInt(101),
        ];
        $table = [1 => $state];
        for ($index = 2; $index <= 46; $index++) {
            $state = $this->stonePatch($index, $state);
            $table[$index] = $state;
        }
        return $table;
    }
}
