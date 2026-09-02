<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/TestHarness.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\SourceLanguageCatalog;
use Pastafari\Stage01\Oracle\BoundedCompositionCounter;
use Pastafari\Stage01\Oracle\CutletPartitionCounter;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;
use Pastafari\Stage01\Oracle\WeavingCounter;
use Pastafari\Stage01\Tests\TestHarness;

function normalizeBigArray(array $values): array
{
    $out = [];
    foreach ($values as $k => $v) {
        $out[(string)$k] = $v instanceof BigInt ? $v->toString() : $v;
    }
    return $out;
}

function boundedBruteForce(int $total, int $slots, int $lo, int $hi): array
{
    $out = [];
    $walk = function(int $rem, int $left, array $prefix) use (&$walk, &$out, $lo, $hi): void {
        if ($left === 0) {
            if ($rem === 0) {
                $out[] = $prefix;
            }
            return;
        }
        for ($x = $lo; $x <= $hi; $x++) {
            if ($rem - $x < 0) {
                break;
            }
            $next = $prefix;
            $next[] = $x;
            $walk($rem - $x, $left - 1, $next);
        }
    };
    $walk($total, $slots, []);
    return $out;
}

function positiveCompositionBruteForce(int $total, int $slots, ?int $required): array
{
    $out = [];
    $walk = function(int $rem, int $left, array $prefix) use (&$walk, &$out, $required): void {
        if ($left === 0) {
            if ($rem !== 0) {
                return;
            }
            if ($required !== null) {
                $sum = 0;
                $hit = false;
                foreach ($prefix as $v) {
                    $sum += $v;
                    if ($sum === $required) {
                        $hit = true;
                    }
                }
                if (!$hit) {
                    return;
                }
            }
            $out[] = $prefix;
            return;
        }
        $max = $rem - ($left - 1);
        for ($x = 1; $x <= $max; $x++) {
            $next = $prefix;
            $next[] = $x;
            $walk($rem - $x, $left - 1, $next);
        }
    };
    $walk($total, $slots, []);
    return $out;
}

function weavingBruteForce(array $lengths): array
{
    $m = count($lengths);
    $remaining = array_values($lengths);
    $out = [];
    $walk = function(array $rem, array $prefix) use (&$walk, &$out, $lengths, $m): void {
        if (array_sum($rem) === 0) {
            $first = [];
            $last = [];
            foreach ($prefix as $p => $j) {
                if (!isset($first[$j])) {
                    $first[$j] = $p;
                }
                $last[$j] = $p;
            }
            for ($j = 1; $j < $m; $j++) {
                if (!($first[$j] < $first[$j + 1] && $last[$j] < $last[$j + 1])) {
                    return;
                }
            }
            $out[] = $prefix;
            return;
        }
        for ($j = 1; $j <= $m; $j++) {
            if ($rem[$j - 1] === 0) {
                continue;
            }
            $nextRem = $rem;
            $nextRem[$j - 1]--;
            $nextPrefix = $prefix;
            $nextPrefix[] = $j;
            $walk($nextRem, $nextPrefix);
        }
    };
    $walk($remaining, []);
    usort($out, static function(array $a, array $b): int {
        $n = min(count($a), count($b));
        for ($i = 0; $i < $n; $i++) {
            if ($a[$i] !== $b[$i]) {
                return $a[$i] <=> $b[$i];
            }
        }
        return count($a) <=> count($b);
    });
    return $out;
}

$fixture = json_decode(file_get_contents(__DIR__ . '/fixtures_stage01.json'), true, flags: JSON_THROW_ON_ERROR);
$oracle = new NormativeOracle();
$sauce = $oracle->sauceEngine();
$h = new TestHarness();

$h->test('bigint_exact', function() use ($h): void {
    $m = NormativeMath::m();
    $value = $m->square()->add(BigInt::fromInt(123));
    [$q,$r] = $value->divMod($m);
    $h->same($m->toString(), $q->toString());
    $h->same('123', $r->toString());
    $h->same('99999999999999999999999999999999999999', BigInt::fromString('100000000000000000000000000000000000000')->sub(BigInt::one())->toString());    $h->same('-2000000000', BigInt::fromInt(-2)->mulSmall(1000000000)->toString());
    $h->same('2000000000', BigInt::fromInt(-2)->mulSmall(-1000000000)->toString());
    $h->same(NormativeMath::m()->sub(BigInt::one())->toString(), NormativeMath::save(-1)->toString());
});

$h->test('save_fixture', function() use ($h,$fixture): void {
    $m = NormativeMath::m();
    $actual = [
        '1'=>NormativeMath::save(1)->toString(),
        'M-1'=>NormativeMath::save($m->sub(BigInt::one()))->toString(),
        'M'=>NormativeMath::save($m)->toString(),
        'M+1'=>NormativeMath::save($m->add(BigInt::one()))->toString(),
        '2M'=>NormativeMath::save($m->mulSmall(2))->toString(),
    ];
    $h->same($fixture['save'], $actual);
});

$h->test('day_count_and_work_counts', function() use ($h,$fixture): void {
    $f = NormativeMath::FOUNDATION_DAY;
    $h->same($fixture['dayCount']['before'], NormativeMath::dayCount($f-1)->toString());
    $h->same($fixture['dayCount']['foundation'], NormativeMath::dayCount($f)->toString());
    $h->same($fixture['dayCount']['after'], NormativeMath::dayCount($f+1)->toString());
    $c = NormativeMath::workCounts($f-2,$f+3);
    $actual = [
        'action'=>$c['action']->toString(), 'target'=>$c['target']->toString(),
        'distance'=>$c['distance']->toString(), 'connection'=>$c['connection']->toString(),
        'direction'=>$c['direction'],
    ];
    $h->same($fixture['workCountsCrossFoundation'], $actual);
});

$h->test('source_language_catalog', function() use ($h): void {
    $cutlets = SourceLanguageCatalog::cutlets();
    $months = SourceLanguageCatalog::months();
    $h->same(range(1,17), array_keys($cutlets));
    $h->same(range(1,47), array_keys($months));
    $h->same(17, count(array_unique($cutlets)));
    $h->same(47, count(array_unique($months)));
    $h->same('gandum', SourceLanguageCatalog::cutletName(12));
    $h->same('garam', SourceLanguageCatalog::monthName(44));
    $h->same('Palgurasy', SourceLanguageCatalog::cutletName(7));
    $h->same('Karsyumab', SourceLanguageCatalog::monthName(8));
});

$h->test('bootstrap_infrastructure', function() use ($h): void {
    $probe = (new BootstrapKernel())->probe(NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY);
    $h->same('READY', $probe['status']);
    $h->same(17, $probe['cutletCount']);
    $h->same(47, $probe['monthCount']);
});

$h->test('stone_fixtures', function() use ($h,$fixture,$sauce): void {
    $stones = $sauce->buildStones();
    $h->same($fixture['stone2'], normalizeBigArray($stones[2]));
    $h->same($fixture['stone46'], normalizeBigArray($stones[46]));
});

$h->test('sauce_fixtures', function() use ($h,$fixture,$sauce): void {
    $f = NormativeMath::FOUNDATION_DAY;
    $cases = [
        'foundation'=>[$f,$f],
        'cross'=>[$f-1,$f+1],
        'forward'=>[$f+7,$f+19],
    ];
    foreach ($cases as $name => [$c,$t]) {
        $r = $sauce->sauce($c,$t);
        $actual = [
            'bowls'=>normalizeBigArray($r['bowls']),
            'orderAtDrop46'=>$r['orderAtDrop46'],
            'hidden1'=>$r['hidden'][1]->toString(),
            'hidden7'=>$r['hidden'][7]->toString(),
            'visible1'=>$r['visible'][1]->toString(),
            'visible46'=>$r['visible'][46]->toString(),
        ];
        $h->same($fixture['sauce'][$name], $actual, 'SAUCE_' . $name);
    }
});

$h->test('gate_gap_fixtures', function() use ($h,$fixture,$oracle): void {
    $h->same($fixture['gateGap']['positive1'], $oracle->positiveGateGap(1));
    $h->same($fixture['gateGap']['negative1'], $oracle->negativeGateGap(1));
    $h->true($fixture['gateGap']['positive1'] >= 42 && $fixture['gateGap']['positive1'] <= 963);
    $h->true($fixture['gateGap']['negative1'] >= 42 && $fixture['gateGap']['negative1'] <= 963);
});

$h->test('selection_fixtures', function() use ($h,$fixture,$sauce): void {
    $short = $sauce->chooseRank(['first'=>BigInt::fromInt(123456789),'step'=>1], BigInt::fromInt(10));
    $wide = $sauce->chooseRank(['first'=>BigInt::fromInt(42),'step'=>1], NormativeMath::m()->add(BigInt::one()));
    $h->same($fixture['selection']['short10'], $short->toString());
    $h->same($fixture['selection']['wideMPlus1'], $wide->toString());
});

$h->test('bounded_family_vs_bruteforce', function() use ($h,$fixture): void {
    $brute = boundedBruteForce(12,3,2,6);
    $family = new BoundedCompositionCounter(12,3,2,6);
    $h->same((string)count($brute), $family->countAll()->toString());
    foreach ($brute as $i => $row) {
        $h->same($row, $family->unrank1(BigInt::fromInt($i+1)));
    }
    $h->same($fixture['bounded']['rank5'], $family->unrank1(BigInt::fromInt(5)));
});

$h->test('cutlet_partition_vs_bruteforce', function() use ($h,$fixture): void {
    $brute = positiveCompositionBruteForce(8,3,4);
    $family = new CutletPartitionCounter(8,3,4);
    $h->same((string)count($brute), $family->countAll()->toString());
    foreach ($brute as $i => $row) {
        $h->same($row, $family->unrank1(BigInt::fromInt($i+1)));
    }
    $h->same($fixture['cutletPartition']['rank3'], $family->unrank1(BigInt::fromInt(3)));
});

$h->test('weaving_vs_bruteforce', function() use ($h,$fixture): void {
    $brute = weavingBruteForce([2,2,1]);
    $family = new WeavingCounter([2,2,1]);
    $h->same((string)count($brute), $family->countAll()->toString());
    foreach ($brute as $i => $row) {
        $h->same($row, $family->unrank1(BigInt::fromInt($i+1)));
    }
    $h->same($fixture['weaving']['rank1'], $family->unrank1(BigInt::one()));
    $h->same($fixture['weaving']['last'], $family->unrank1($family->countAll()));
});

$h->test('year5000_fixture', function() use ($h,$fixture,$oracle): void {
    $actual = $oracle->year5000(NormativeMath::FOUNDATION_DAY);
    $h->same($fixture['year5000Foundation'], $actual);
    $length = $actual['closeGateDay'] - $actual['openGateDay'];
    $h->true($length >= 252 && $length <= 5778);
});

$h->test('no_future_patch_code_in_src', function() use ($h): void {
    $root = dirname(__DIR__) . '/src';
    $banned = [
        'oldRemainder','oldDayTag','oldDistance','mutateStonesWrong','hiddenBackward',
        'GRIND_TABLE_WITH_SENTINEL','oldPermutationUnrank0','bowlAlias','vaultOld','pendingSnapshot',
        'orderAt46Latch','oldNextBowlFixedName','biasedLegacyPick','wideDetour','oldGateQuestionDay',
        'LEGACY_YEAR_MAX','oldJumpGuess','LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER','oldStructureSauce',
        'legacyPositiveCompositions','legacyNameRowWithRepeats','VirtualLegacyList',
        'legacyChooseEachDaySeparately','oldContiguousMonthDayGuess',
    ];
    $files = glob($root . '/*.php');
    foreach ($files as $file) {
        $text = file_get_contents($file);
        foreach ($banned as $token) {
            $h->true(!str_contains($text, $token), 'FUTURE_TOKEN_' . $token);
        }
    }
});

$h->test('source_php_has_no_hebrew_prose', function() use ($h): void {
    foreach (glob(dirname(__DIR__) . '/src/*.php') as $file) {
        $text = file_get_contents($file);
        $h->true(preg_match('/\p{Hebrew}/u', $text) !== 1, 'HEBREW_IN_SOURCE_' . basename($file));
    }
});

exit($h->finish());
