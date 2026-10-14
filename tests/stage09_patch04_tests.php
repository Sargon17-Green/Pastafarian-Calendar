<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyRemainder;
use Pastafari\Stage01\Legacy\LegacyStoneMutation;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\SavePatch01;
use Pastafari\Stage01\Patches\StonePatch04;

function sahBatu(bool $condition, string $code): void
{
    if (!$condition) {
        throw new RuntimeException($code);
    }
}

$save = new SavePatch01(new LegacyRemainder());
$legacy = new LegacyStoneMutation($save);
$patch = new StonePatch04($legacy, $save);
$kernel = new BootstrapKernel();
$oracle = (new NormativeSauce())->buildStones();
$actual = $kernel->stones();
$direct = $patch->buildStones();
$historical = $legacy->buildStonesWrong();
$keys = ['w', 'b', 's', 'm', 'r'];
$rows = 0;
$components = 0;
$historicalWrongRows = 0;
$historicalWrongComponents = 0;
$cases = 0;
$overrides = 0;
$unchanged = 0;

// Penutupan menyeluruh semua 46 rekod dan lima batu; setiap panggilan
// mesti menggunakan negeri tersendiri dan hasil normatif oracle tempatan.
sahBatu(count($actual) === 46 && array_keys($actual) === range(1, 46), 'BENTUK_JADUAL');
sahBatu(count($oracle) === 46 && count($historical) === 46, 'BENTUK_PERBANDINGAN');
$repeat = $kernel->stones();
$other = (new BootstrapKernel())->stones();
foreach ($oracle as $index => $expected) {
    sahBatu(array_keys($actual[$index]) === $keys, 'KEKUNCI_' . $index);
    $diverged = false;
    foreach ($keys as $key) {
        $value = $actual[$index][$key];
        sahBatu($value instanceof BigInt, 'JENIS_' . $index . '_' . $key);
        sahBatu($value->equals($expected[$key]), 'NORMATIF_' . $index . '_' . $key);
        sahBatu($value->equals($direct[$index][$key]), 'ADAPTER_' . $index . '_' . $key);
        sahBatu($value->equals($repeat[$index][$key]), 'ULANGAN_' . $index . '_' . $key);
        sahBatu($value->equals($other[$index][$key]), 'INSTANS_' . $index . '_' . $key);
        sahBatu($value->compare(BigInt::one()) >= 0 && $value->compare(NormativeMath::m()) <= 0, 'JULAT_' . $index);
        if (!$historical[$index][$key]->equals($value)) {
            $diverged = true;
            $historicalWrongComponents++;
        }
        $components++;
    }
    if ($diverged) {
        $historicalWrongRows++;
    }
    $rows++;
}
sahBatu($rows === 46 && $components === 230, 'LIPUTAN_JADUAL');
sahBatu($historicalWrongRows === 45 && $historicalWrongComponents >= 45, 'PARUT_45_KEKAL');
foreach (['w' => '378', 'b' => '1073', 's' => '2375', 'm' => '6195', 'r' => '10493'] as $key => $value) {
    sahBatu($actual[2][$key]->toString() === $value, 'VEKTOR_02_' . $key);
}
foreach (['w' => '378', 'b' => '1434', 's' => '3780', 'm' => '9932', 'r' => '25047'] as $key => $value) {
    sahBatu($historical[2][$key]->toString() === $value, 'PARUT_02_' . $key);
}

// Pembuktian formula terus pada state sintetik (termasuk >256 bit), tanpa
// menggunakan oracle batu yang telah dibina bagi negeri bukan kronologi.
$modulus = NormativeMath::m();
$huge = BigInt::fromString(str_repeat('314159265358979323846264338327950288419716939937510', 8));
$states = [
    ['w'=>BigInt::fromInt(17),'b'=>BigInt::fromInt(29),'s'=>BigInt::fromInt(43),'m'=>BigInt::fromInt(71),'r'=>BigInt::fromInt(101)],
    ['w'=>BigInt::one(),'b'=>BigInt::one(),'s'=>BigInt::one(),'m'=>BigInt::one(),'r'=>BigInt::one()],
    ['w'=>BigInt::zero(),'b'=>BigInt::zero(),'s'=>BigInt::zero(),'m'=>BigInt::zero(),'r'=>BigInt::zero()],
    ['w'=>$modulus,'b'=>$modulus,'s'=>$modulus,'m'=>$modulus,'r'=>$modulus],
    ['w'=>$huge,'b'=>$huge->neg(),'s'=>$modulus->mulSmall(7),'m'=>BigInt::fromInt(PHP_INT_MIN),'r'=>BigInt::fromInt(PHP_INT_MAX)],
    ['w'=>BigInt::fromInt(-137),'b'=>BigInt::fromInt(301),'s'=>BigInt::fromInt(-17),'m'=>BigInt::fromInt(0),'r'=>BigInt::fromInt(4096)],
    ['w'=>BigInt::fromString('10000000000000000000000000000000000000'),'b'=>BigInt::fromInt(2),'s'=>BigInt::fromInt(3),'m'=>BigInt::fromInt(5),'r'=>BigInt::fromInt(7)],
];
foreach ($states as $stateNumber => $state) {
    foreach (range(2, 46) as $index) {
        $before = $state;
        $fixed = $patch->stonePatch($index, $state);
        $broken = $state;
        $legacy->mutateStonesWrong($index, $broken);
        $expected = [
            'w' => NormativeMath::save($before['w']->square()->add($before['b']->mulSmall(3))->add(BigInt::fromInt($index))),
            'b' => NormativeMath::save($before['b']->square()->add($before['s']->mulSmall(5))->add($before['w'])),
            's' => NormativeMath::save($before['s']->square()->add($before['m']->mulSmall(7))->add($before['b'])),
            'm' => NormativeMath::save($before['m']->square()->add($before['r']->mulSmall(11))->add($before['s'])),
            'r' => NormativeMath::save($before['r']->square()->add($before['w']->mulSmall(13))->add($before['m'])),
        ];
        foreach ($keys as $key) {
            sahBatu($fixed[$key]->equals($expected[$key]), 'RUMUS_' . $stateNumber . '_' . $index . '_' . $key);
            sahBatu($state[$key]->equals($before[$key]), 'INPUT_KEKAL_' . $stateNumber . '_' . $index . '_' . $key);
            if (!$broken[$key]->equals($fixed[$key])) {
                $overrides++;
            } else {
                $unchanged++;
            }
        }
        $again = $patch->stonePatch($index, $state);
        foreach ($keys as $key) {
            sahBatu($fixed[$key]->equals($again[$key]), 'DETERMINISTIK_' . $stateNumber . '_' . $index . '_' . $key);
        }
        $cases++;
    }
}
sahBatu($cases === 315 && $overrides > 315 && $unchanged >= 315, 'CABANG_LEGACY');

$invalidCases = 0;
// Sempadan invalid mesti dilepasi ke legacy sebenar, tanpa mengubah input.
foreach ([1, 47] as $invalid) {
    $original = $states[0];
    try {
        $patch->stonePatch($invalid, $original);
        throw new RuntimeException('TERIMA_INDEKS_TIDAK_SAH');
    } catch (InvalidArgumentException $e) {
        sahBatu($e->getMessage() === 'STONE_INDEX_RANGE', 'RALAT_INDEKS');
        sahBatu($original === $states[0], 'INPUT_GAGAL_DILINDUNGI');
        $invalidCases++;
    }
}
$malformed = $states[0];
unset($malformed['s']);
try {
    $patch->stonePatch(2, $malformed);
    throw new RuntimeException('TERIMA_STATE_TIDAK_SAH');
} catch (InvalidArgumentException $e) {
    sahBatu($e->getMessage() === 'STONE_STATE_SHAPE', 'RALAT_BENTUK');
    $invalidCases++;
}
$badType = $states[0];
$badType['m'] = 'x';
try {
    $patch->stonePatch(2, $badType);
    throw new RuntimeException('TERIMA_JENIS_TIDAK_SAH');
} catch (InvalidArgumentException $e) {
    sahBatu($e->getMessage() === 'STONE_STATE_TYPE', 'RALAT_JENIS');
    $invalidCases++;
}
sahBatu($invalidCases === 4, 'LIPUTAN_RALAT');

// Invarian kunci untuk mengelakkan penggantian algoritma dengan oracle.
$patchCode = (string)file_get_contents(dirname(__DIR__) . '/src/Patches/StonePatch04.php');
$legacyCode = (string)file_get_contents(dirname(__DIR__) . '/src/Legacy/LegacyStoneMutation.php');
$kernelCode = (string)file_get_contents(dirname(__DIR__) . '/src/BootstrapKernel.php');
sahBatu(str_contains($patchCode, '$this->legacy->mutateStonesWrong($index, $garbage);'), 'PANGGILAN_LEGACY_SEBENAR');
sahBatu(str_contains($patchCode, '$old = $state;') && str_contains($patchCode, '$garbage = $state;'), 'SNAPSHOT_LEGACY_BERPISAH');
sahBatu(str_contains($legacyCode, 'function mutateStonesWrong('), 'LEGACY_KEKAL');
sahBatu(str_contains($kernelCode, "register('STONE_MUTATION_LEGACY'"), 'DISPATCH_LAMA_KEKAL');
sahBatu(str_contains($kernelCode, "dispatch('STONE_PATCH_04', " . '$context)'), 'DISPATCH_TAMPALAN');
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator(dirname(__DIR__) . '/src', FilesystemIterator::SKIP_DOTS)
);
foreach ($iterator as $file) {
    if (strtolower($file->getExtension()) !== 'php') {
        continue;
    }
    $code = (string)file_get_contents($file->getPathname());
    sahBatu(!str_contains($code, 'NormativeMath') && !str_contains($code, 'NormativeSauce'), 'ORACLE_DI_PRODUKSI');
}

// Operasi asas terdahulu mesti bebas daripada pembinaan jadual batu.
$foundation = NormativeMath::FOUNDATION_DAY;
sahBatu($kernel->distance($foundation, $foundation)->equals(BigInt::one()), 'JARAK_KEKAL');
sahBatu($kernel->dayCount($foundation)->equals(BigInt::one()), 'HARI_KEKAL');
sahBatu($kernel->save($modulus)->equals($modulus), 'SAVE_KEKAL');
sahBatu($kernel->probe($foundation, $foundation)['status'] === 'READY', 'PROBE_KEKAL');

echo "LULUS Stage 9 PATCH 04 baris={$rows} komponen={$components} warisan_merah={$historicalWrongRows} kes_langsung={$cases} ganti={$overrides} kekal={$unchanged} ralat={$invalidCases}\n";
