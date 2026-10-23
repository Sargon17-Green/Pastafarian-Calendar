<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyNumericSuccessor12;

/**
 * PATCH 12: jiran bagi ID mangkuk ialah ID seterusnya dalam orderAtDrop46,
 * bukannya ID angka seterusnya. Fungsi legacy dipanggil secara benar.
 */
final class NextBowlOrderPatch12
{
    public function __construct(
        private readonly LegacyNumericSuccessor12 $legacy,
        private readonly SavePatch01 $save
    ) {
    }

    /**
     * @param array{bowls:array<int,BigInt>,orderAtDrop46:list<int>} $sauce
     * @return array{first:BigInt,step:int,nextBowlId:int}
     */
    public function askPatched(array $sauce, int $queriedBowlId, int $seal): array
    {
        // Panggilan ini mengekalkan pengesahan input serta parut pengiraan lama.
        // Hasil sejarah tidak digunakan sebagai pengganti hasil yang sah.
        $historical = $this->legacy->askWrong($sauce, $queriedBowlId, $seal);
        $order = $sauce['orderAtDrop46'];
        $position = array_search($queriedBowlId, $order, true);
        // Legacy telah mengesahkan keahlian dan permutasi penuh 1..6.
        $nextId = $order[($position + 1) % 6];
        $bowls = $sauce['bowls'];

        $base = $bowls[$queriedBowlId]->add(BigInt::fromInt($seal + 181));
        $first = $this->save->savePatch(
            $base->square()
                ->add($bowls[$nextId]->mulSmall(179))
                ->add(BigInt::fromInt($seal))
        );
        $directionBase = $first->add(BigInt::fromInt($seal + 194));
        $direction = $this->save->savePatch(
            $directionBase->square()
                ->add($first->mulSmall(193))
                ->add($bowls[6]->mulSmall(197))
        );
        // Simpan panggilan legacy sebagai bukti boleh diperiksa tanpa
        // menjadikan susunan angka suatu input semantik ke hasil produksi.
        if (!isset($historical['nextBowlId'])) {
            throw new \LogicException('LEGACY_SUCCESSOR_TRACE_MISSING');
        }
        return [
            'first' => $first,
            'step' => $direction->modSmall(2) === 1 ? 1 : -1,
            'nextBowlId' => $nextId,
        ];
    }
}
