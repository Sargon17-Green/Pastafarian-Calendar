<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use Pastafari\Stage01\BigInt;

/**
 * Baki lama ini sengaja mengekalkan sifat sifar pada gandaan M.
 * Pada peringkat DISCOVERY, belum ada lapisan pembetulan SAVE.
 */
final class LegacyRemainder
{
    private BigInt $modulus;

    public function __construct()
    {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
    }

    public function oldRemainder(BigInt $value): BigInt
    {
        return $value->mod($this->modulus);
    }

    public function calculateWithoutPatch(BigInt $value): BigInt
    {
        return $this->oldRemainder($value);
    }
}
