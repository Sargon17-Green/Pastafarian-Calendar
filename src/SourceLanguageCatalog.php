<?php
declare(strict_types=1);

namespace Pastafari\Stage01;

use OutOfBoundsException;

final class SourceLanguageCatalog
{
    public const VERSION = 'ms-1.0.0-stage01';
    public const LANGUAGE = 'ms';

    /** @var array<int,string> */
    private const CUTLETS = [
        1 => 'gangsa',
        2 => 'rubah',
        3 => 'buah pinggang',
        4 => 'Lagash',
        5 => 'pemikiran',
        6 => 'empat bahagian daripada sembilan',
        7 => 'Palgurasy',
        8 => 'gelagah',
        9 => 'gugusan',
        10 => 'kala jengking',
        11 => 'abu',
        12 => 'gandum',
        13 => 'sungai',
        14 => 'ketawa',
        15 => 'Akkad',
        16 => 'tanduk',
        17 => 'kendi kosong',
    ];

    /** @var array<int,string> */
    private const MONTHS = [
        1 => 'tanah liat',
        2 => 'delima',
        3 => 'siku',
        4 => 'iri hati',
        5 => 'Eridu',
        6 => 'ubat gigi',
        7 => 'tiga bahagian daripada lima',
        8 => 'Karsyumab',
        9 => 'harimau bintang',
        10 => 'timah',
        11 => 'kabus',
        12 => 'kemenyan',
        13 => 'gelendong',
        14 => 'rusuk',
        15 => 'karob',
        16 => 'Uruk',
        17 => 'malu',
        18 => 'unta',
        19 => 'tembaga',
        20 => 'perigi',
        21 => 'kuning telur',
        22 => 'bintang',
        23 => 'madu',
        24 => 'limpa',
        25 => 'batu kapur',
        26 => 'kegembiraan',
        27 => 'buah ara',
        28 => 'Nineveh',
        29 => 'katak',
        30 => 'tar',
        31 => 'lilin',
        32 => 'pintu tertutup',
        33 => 'bijan',
        34 => 'tengkuk',
        35 => 'perak',
        36 => 'lili',
        37 => 'ribut',
        38 => 'keldai',
        39 => 'tepung',
        40 => 'penyesalan',
        41 => 'Babylon',
        42 => 'lidah',
        43 => 'flaks',
        44 => 'garam',
        45 => 'pir',
        46 => 'busur',
        47 => 'pasir',
    ];

    public static function cutletName(int $canonicalIndex): string
    {
        if (!isset(self::CUTLETS[$canonicalIndex])) {
            throw new OutOfBoundsException('CUTLET_INDEX');
        }
        return self::CUTLETS[$canonicalIndex];
    }

    public static function monthName(int $canonicalIndex): string
    {
        if (!isset(self::MONTHS[$canonicalIndex])) {
            throw new OutOfBoundsException('MONTH_INDEX');
        }
        return self::MONTHS[$canonicalIndex];
    }

    /** @return array<int,string> */
    public static function cutlets(): array
    {
        return self::CUTLETS;
    }

    /** @return array<int,string> */
    public static function months(): array
    {
        return self::MONTHS;
    }
}
