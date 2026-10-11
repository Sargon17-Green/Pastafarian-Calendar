<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyRemainder;

/**
 * Lapisan pembetulan pertama sengaja membiarkan baki sejarah tidak berubah.
 * Semua gandaan M yang mendapat baki sifar diangkat semula kepada M.
 * Tiada oracle atau hasil ujian digunakan dalam laluan pengeluaran.
 */
final class SavePatch01
{
    private LegacyRemainder $legacy;
    private BigInt $modulus;

    public function __construct(LegacyRemainder $legacy)
    {
        $this->legacy = $legacy;
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
    }

    public function savePatch(BigInt $value): BigInt
    {
        $remainder = $this->legacy->oldRemainder($value);
        if ($remainder->isZero()) {
            return $this->modulus;
        }
        return $remainder;
    }
}
