<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyMissingThirdDigit15;

/** PATCH15: pulihkan digit ketiga pada pemberat M^2. */
final class ThirdDigitPatch15
{
    private readonly BigInt $modulus;
    private readonly BigInt $space;
    public function __construct(
        private readonly LegacyMissingThirdDigit15 $legacy,
        private readonly SavePatch01 $save
    ) {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
        $this->space = $this->modulus->square()->mul($this->modulus);
    }
    /** @param array{first:BigInt,step:int} $stream */
    public function choosePatched(array $stream, BigInt $n): BigInt
    {
        // Validasi input dan jalankan parut legacy sebenar tanpa membetulkannya.
        $oldRank = $this->legacy->chooseWrong($stream, $n);
        $wide = BigInt::one();
        $weight = BigInt::one();
        for ($j = 0; $j < 3; $j++) {
            $digit = $this->save->savePatch(
                $stream['first']->add(BigInt::fromInt($j * $stream['step']))
            );
            $wide = $wide->add($digit->sub(BigInt::one())->mul($weight));
            $weight = $weight->mul($this->modulus);
        }
        $cutoff = $this->space->floorDiv($n)->mul($n);
        while ($wide->compare($cutoff) > 0) {
            $wide = $wide->sub(BigInt::one())
                ->add(BigInt::fromInt($stream['step']))
                ->mod($this->space)->add(BigInt::one());
        }
        if ($oldRank->compare(BigInt::one()) < 0 || $oldRank->compare($n) > 0) {
            throw new \LogicException('THIRD_DIGIT_LEGACY_RANGE');
        }
        return $wide->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
