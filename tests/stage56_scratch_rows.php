<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/src/BigInt.php';
require_once dirname(__DIR__) . '/src/Patches/MonthWeavingInterleaving56.php';
require_once dirname(__DIR__) . '/src/Patches/SuffixScratchRows56.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\MonthWeavingInterleaving56;
use Pastafari\Stage01\Patches\SuffixScratchRows56;

function check56(bool $ok, string $label): void {
    if (!$ok) throw new RuntimeException('STAGE56_SCRATCH_QA_' . $label);
}
function reject56(callable $fn, string $label): void {
    try { $fn(); } catch (LogicException $e) { return; }
    throw new RuntimeException('STAGE56_SCRATCH_EXPECT_REJECT_' . $label);
}

$cells = 0;
foreach ([[[2,3,2],[['0','3','11'],['0','1','2','3','4']]],[[3,1,2,3],[['0','3','3','3'],['0','3','9','19'],['0','1','3','6','10']]],[[4,2,3,4],[['0','50','205','584','1383'],['0','10','50','155','379','799'],['0','1','4','10','20','35','56','84']]]] as [$lengths,$expected]) {
    $engine = new MonthWeavingInterleaving56($lengths, true);
    check56($engine->count()->toString() === $expected[0][$lengths[0]], 'small_count');
    $method = new ReflectionMethod($engine, 'suffixCount');
    foreach ($expected as $i => $row) foreach ($row as $q => $value) {
        check56($method->invoke($engine, $i, $q)->toString() === $value, 'cell');
        ++$cells;
    }
    unset($engine, $method);
}

foreach ([[25,'1143433233166452213708275330375098141285116391578055346520242843926364172612','571716616583226106854137665187549070642558195789027673260121421963182086306',[0,1,2,3,4,0,5,5,6,6,7,8,9,10,6,11,12,13,14,11,15,0,15,16,17,14,8,12,13,0,18,2,9,13,7,15,2,18,19,12,19,1,8,20,3,16,3,4,1,21,17,1,19,14,2,22,16,20,17,10,18,5,23,7,3,4,22,4,11,5,6,24,7,8,9,10,23,9,10,24,11,12,13,14,15,16,17,21,20,21,18,19,20,23,24,21,22,22,23,24]],[45,'511450831603566635842431635061380097086835589165741668863877761837550078428239801390425493529408592938402092522571034259482326855962267094094250481647463405640','255725415801783317921215817530690048543417794582870834431938880918775039214119900695212746764704296469201046261285517129741163427981133547047125240823731702820',[0,1,2,3,4,5,1,6,7,8,9,10,11,12,0,13,14,2,9,15,16,12,17,18,19,20,21,22,6,23,14,24,20,22,23,16,25,4,26,27,7,5,25,21,28,29,2,22,3,5,30,31,32,6,33,3,29,16,13,34,8,32,30,18,24,14,7,35,31,15,34,36,1,34,0,37,19,26,0,8,15,9,21,17,4,1,20,27,35,38,12,27,2,32,39,3,38,30,17,4,18,5,10,40,38,24,39,41,42,6,28,33,7,13,10,8,25,41,37,33,43,35,9,11,11,10,43,11,44,42,44,12,39,13,14,19,15,29,16,37,26,28,44,17,23,40,18,19,20,21,22,23,36,24,25,26,27,31,36,28,41,43,29,30,31,32,33,40,34,35,36,42,37,38,39,40,41,42,43,44]],[46,'13581196218029437381585355263903987513757709166138434257280750049251153892567399950057832595323090920585018650185353788041788395544439984231314915779329821186650400','6790598109014718690792677631951993756878854583069217128640375024625576946283699975028916297661545460292509325092676894020894197772219992115657457889664910593325200',[0,1,2,3,4,5,2,6,0,7,8,5,9,10,1,11,12,0,13,14,15,16,13,17,9,18,0,19,5,20,8,21,22,23,6,9,16,8,1,15,23,16,6,24,25,26,27,28,22,10,29,23,11,11,4,26,30,1,27,24,17,22,31,3,32,33,28,7,4,29,2,18,3,20,2,17,3,34,35,34,7,36,12,33,18,25,4,31,5,10,6,37,21,38,7,13,19,39,40,38,14,8,40,36,25,30,9,41,10,42,43,15,11,19,24,12,41,14,20,28,37,12,13,32,14,39,33,26,44,15,16,45,44,35,17,38,27,18,36,21,19,31,20,21,22,23,24,25,45,26,39,43,35,29,27,32,45,44,43,37,28,30,29,34,30,31,32,40,33,34,35,42,36,37,42,41,38,39,40,41,42,43,44,45]]] as [$m,$count,$mid,$midWord]) {
    $start = hrtime(true);
    $engine = new MonthWeavingInterleaving56(array_fill(0,$m,4), true);
    $total = $engine->count();
    check56($total->toString() === $count, 'large_count');
    $first = [];
    for ($i=0;$i<$m;++$i) array_push($first,$i,$i,$i,$i);
    $last = range(0,$m-1);
    for ($i=$m-1;$i>=0;--$i) array_push($last,$i,$i);
    $last = array_merge($last, range(0,$m-1));
    foreach ([[BigInt::one(),$first],[$total,$last],[BigInt::fromString($mid),$midWord]] as [$r,$word]) {
        check56($engine->unrank($r) === $word, 'word');
        check56($engine->rank($word)->equals($r), 'rank');
    }
    $stats = $engine->scratchStats56();
    check56($stats['rows'] === $m-1 && $stats['loads'] > 0 && $stats['bytes'] <= 268435456, 'stats');
    echo json_encode(['months'=>$m,'scratch'=>$stats,'elapsed_ns'=>hrtime(true)-$start,
        'peak_bytes'=>memory_get_peak_usage(true)], JSON_THROW_ON_ERROR), "\n";
    unset($engine);
}

$zero = BigInt::zero();
$one = BigInt::one();
$two = BigInt::fromInt(2);
foreach (['0','1','999999999','1000000000',str_repeat('9',9077)] as $s) {
    check56(BigInt::fromScratchUnsignedLimbs56(BigInt::fromString($s)->scratchUnsignedLimbs56())->toString() === $s, 'codec');
}
reject56(fn()=>BigInt::fromInt(-1)->scratchUnsignedLimbs56(),'negative');
reject56(fn()=>BigInt::fromScratchUnsignedLimbs56(pack('V',1000000000)),'limb_range');
reject56(fn()=>BigInt::fromScratchUnsignedLimbs56(pack('V2',1,0)),'noncanonical');
reject56(fn()=>BigInt::fromScratchUnsignedLimbs56('abc'),'partial');
$store = new SuffixScratchRows56([2,2]);
$store->append(0,[$zero,$one,$two]);
reject56(fn()=>$store->append(0,[$zero,$one,$two]),'duplicate');
reject56(fn()=>$store->load(1),'missing');
$prop = new ReflectionProperty($store,'file');
$file = $prop->getValue($store);
$path = stream_get_meta_data($file)['uri'];
fseek($file,0); fwrite($file,'BAD'); fflush($file);
reject56(fn()=>$store->load(0),'foreign_header');
unset($store);
check56(!is_file($path),'cleanup');
foreach (['truncated','digest'] as $kind) {
    $store = new SuffixScratchRows56([2,2]);
    $store->append(0,[$zero,$one,$two]);
    $file = $prop->getValue($store);
    if ($kind === 'truncated') ftruncate($file,$store->bytes()-1);
    else { fseek($file,-4,SEEK_END); fwrite($file,pack('V',3)); }
    fflush($file);
    reject56(fn()=>$store->load(0),$kind);
    unset($store);
}
$store = new SuffixScratchRows56([2,2],48);
reject56(fn()=>$store->append(0,[$zero,$one,$two]),'budget');
unset($store);
echo "STAGE56_SCRATCH_SYNTHETIC_PASS cells=$cells shapes=3 negative=10 status=PASS\n";
