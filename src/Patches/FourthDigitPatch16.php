<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyMissingFourthDigit16;

/**
 * PATCH16: bina pilihan empat digit dengan pemberat 1, M, M^2, M^3.
 * Kelas sejarah yang membuang digit keempat dikekalkan tanpa perubahan.
 */
final class FourthDigitPatch16
{
    private readonly BigInt $modulus;
    private readonly BigInt $space;

    public function __construct(
        private readonly LegacyMissingFourthDigit16 $legacy,
        private readonly SavePatch01 $save
    ) {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
        $this->space = $this->modulus->square()->square();
    }

    /** @param array{first:BigInt,step:int} $stream */
    public function choosePatched(array $stream, BigInt $n): BigInt
    {
        // Terus menjalankan parut legacy, termasuk semakan input asal.
        $oldRank = $this->legacy->chooseWrong($stream, $n);
        $wide = BigInt::one();
        $weight = BigInt::one();
        for ($j = 0; $j < 4; $j++) {
            $digit = $this->save->savePatch(
                $stream['first']->add(BigInt::fromInt($j * $stream['step']))
            );
            $wide = $wide->add($digit->sub(BigInt::one())->mul($weight));
            $weight = $weight->mul($this->modulus);
        }

        $cutoff = $this->space->floorDiv($n)->mul($n);
        $delta = BigInt::fromInt($stream['step']);
        while ($wide->compare($cutoff) > 0) {
            $wide = $wide->sub(BigInt::one())
                ->add($delta)->mod($this->space)->add(BigInt::one());
        }
        if ($oldRank->compare(BigInt::one()) < 0
            || $oldRank->compare($n) > 0) {
            throw new \LogicException('FOURTH_DIGIT_LEGACY_RANGE');
        }
        return $wide->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
