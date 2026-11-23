<?php
declare(strict_types=1);

/**
 * Stage56 source-bound QA harness. Not an independent PHP algorithm oracle.
 * Requires the separately executed Scroll comparator and pinned canonical bytes.
 * Invocation: php tests/stage56_source_bound_php_year.php CANONICAL_REPO REFERENCE GATES SCROLL_REPORT YEAR OUTPUT
 */
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/stage56_cutlet_semantic_oracle.php';
foreach (['YearStructureSlices56', 'MonthWeavingFrontier56', 'MonthWeavingAdjoint56',
    'MonthWeavingRanker56', 'UnboundedUniformChoice56', 'ContextualYear5000Anchor56',
    'YearStructureProvider56', 'CanonicalJdnBoundary56'] as $class) {
    require_once dirname(__DIR__) . '/src/Patches/' . $class . '.php';
}

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Patches\MonthWeavingRanker56;
use Pastafari\Stage01\Patches\YearStructureProvider56;

const S56_PROJECT = 'PC-BRANCH-PHP-MALAY';
const S56_SOURCE = 'cc2cf0b422757a5e7c33218ce30cffa8f99c6786';
const S56_REFERENCE_SHA = '46b2f316eb2b08c2dc99fd827d8e0a227061c9b97bbb708842318c08a7bf1880';
const S56_GATES_SHA = 'f2d5c4275dcc4294bd892b8699f8a41b07852940906c13c8f8e43229fefa46c1';
const S56_SCROLL_SHA = '21c103d3540eb5481445a190cef98f2628de7eb90b7240879fede0d519cf4a95';
const S56_JDN = -13334246;

function s56Require(bool $ok, string $why): void {
    if (!$ok) throw new RuntimeException('STAGE56_PHP_QA_' . $why);
}
function s56FirstDifference(array $actual, array $expected): ?array {
    $limit = max(count($actual), count($expected));
    for ($i = 0; $i < $limit; ++$i) {
        $a = $actual[$i] ?? null;
        $e = $expected[$i] ?? null;
        if ($a !== $e) return ['index'=>$i, 'actual'=>$a, 'expected'=>$e];
    }
    return null;
}
function s56Json(string $path, ?string $pin = null): array {
    $raw = @file_get_contents($path);
    s56Require(is_string($raw), 'INPUT_UNREADABLE');
    if ($pin !== null) s56Require(hash_equals($pin, hash('sha256', $raw)), 'INPUT_PIN');
    $value = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
    s56Require(is_array($value), 'INPUT_TYPE');
    return $value;
}
function s56Git(string $root, string ...$args): string {
    $p = proc_open(array_merge(['git', '-C', $root], $args),
        [0=>['pipe','r'], 1=>['pipe','w'], 2=>['pipe','w']], $pipes);
    s56Require(is_resource($p), 'GIT_START');
    fclose($pipes[0]);
    $out = stream_get_contents($pipes[1]); fclose($pipes[1]);
    $err = stream_get_contents($pipes[2]); fclose($pipes[2]);
    s56Require(proc_close($p) === 0 && is_string($out) && $err === '', 'GIT_FAILURE');
    return $out;
}
function s56BoundFile(string $repo, string $path, string $pin): void {
    $disk = @file_get_contents($repo . '/' . $path);
    $git = s56Git($repo, 'show', S56_SOURCE . ':' . $path);
    s56Require(is_string($disk) && hash_equals($git, $disk) &&
        hash_equals($pin, hash('sha256', $disk)), 'SOURCE_BYTES_' . $path);
}
function s56Main(array $args): int {
    s56Require(count($args) === 7 && in_array($args[5], ['4999','5000','5001'], true),
        'USAGE');
    $root = realpath($args[1]);
    s56Require(is_string($root) && is_dir($root), 'CANONICAL_REPO');
    $origin = trim(s56Git($root, 'remote', 'get-url', 'origin'));
    s56Require(in_array($origin, [
        'https://github.com/Sargon17-Green/pastafari-calendar',
        'https://github.com/Sargon17-Green/pastafari-calendar.git',
        'git@github.com:Sargon17-Green/pastafari-calendar.git'], true), 'SOURCE_ORIGIN');
    s56Require(trim(s56Git($root,'rev-parse','HEAD')) === S56_SOURCE &&
        trim(s56Git($root,'status','--porcelain','--untracked-files=all')) === '',
        'SOURCE_HEAD_OR_DIRTY');
    $reference = s56Json($args[2], S56_REFERENCE_SHA);
    $gates = s56Json($args[3], S56_GATES_SHA);
    $scroll = s56Json($args[4]);
    $source = $reference['source'] ?? null;
    s56Require(($reference['project_id'] ?? null) === S56_PROJECT &&
        ($reference['status'] ?? null) === 'EXTERNAL_REFERENCE_NOT_PHP_PROVIDER' &&
        ($reference['calculation_jdn'] ?? null) === S56_JDN &&
        is_array($source) && ($source['kind'] ?? null) === 'external_canonical_reference' &&
        ($source['source_commit'] ?? null) === S56_SOURCE &&
        ($source['repository'] ?? null) === 'Sargon17-Green/pastafari-calendar' &&
        ($source['provider']['path'] ?? null) === 'implementations/python/pastafari_calendar/core.py',
        'REFERENCE_IDENTITY');
    s56Require(is_string($source['provider']['sha256'] ?? null), 'PROVIDER_PIN');
    s56BoundFile($root, 'implementations/python/pastafari_calendar/core.py',
        $source['provider']['sha256']);
    s56BoundFile($root, 'verification/reference-oracle/reference.mjs', S56_SCROLL_SHA);
    $anchorRef = $reference['year5000_anchor'] ?? null;
    s56Require(is_array($anchorRef), 'ANCHOR_TYPE');
    $sorted = $anchorRef; ksort($sorted, SORT_STRING);
    $anchorBytes = json_encode($sorted, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES) . "\n";
    s56Require(hash_equals($source['anchor_sha256'] ?? '',
        hash('sha256', $anchorBytes)), 'REFERENCE_ANCHOR_SHA');
    s56Require(($anchorRef['number'] ?? null) === 5000 &&
        ($anchorRef['calculation_jdn'] ?? null) === S56_JDN, 'REFERENCE_ANCHOR_CONTEXT');
    s56Require(($gates['project_id'] ?? null) === S56_PROJECT &&
        ($gates['status'] ?? null) === 'EXTERNAL_GATE_WITNESS_QA_ONLY_NOT_PHP_PRODUCTION' &&
        ($gates['source_commit'] ?? null) === S56_SOURCE &&
        ($gates['calculation_jdn'] ?? null) === S56_JDN &&
        ($gates['reference_sha256'] ?? null) === S56_REFERENCE_SHA,
        'GATE_ENVELOPE');
    s56Require(($scroll['project_id'] ?? null) === S56_PROJECT &&
        ($scroll['status'] ?? null) === 'INDEPENDENT_SCROLL_GATES_PASS_NOT_PHP_PRODUCTION' &&
        ($scroll['source_commit'] ?? null) === S56_SOURCE &&
        ($scroll['reference_oracle_sha256'] ?? null) === S56_SCROLL_SHA &&
        ($scroll['external_gate_witness_sha256'] ?? null) === S56_GATES_SHA &&
        ($scroll['calculation_jdn'] ?? null) === S56_JDN &&
        ($scroll['checked_gate_positions'] ?? null) === 27 &&
        ($scroll['year_boundaries'] ?? null) === [4999,5000,5001] &&
        ($scroll['stage56_accepted'] ?? null) === false,
        'INDEPENDENT_SCROLL_REPORT');
    $years = $gates['years'] ?? null; $refs = $reference['years'] ?? null;
    $positions = $gates['gate_positions'] ?? null;
    s56Require(is_array($years) && is_array($refs) && is_array($positions) &&
        count($years) === 3 && count($refs) === 3 &&
        count($positions) === 27, 'YEARS_OR_GATES_SHAPE');
    $keys = array_map('intval', array_keys($positions)); sort($keys, SORT_NUMERIC);
    s56Require($keys === range(-12,14), 'GATE_COVERAGE');
    foreach ($positions as $day) s56Require(is_int($day), 'GATE_DAY_TYPE');
    foreach ([4999,5000,5001] as $i=>$num) {
        $y=$years[$i]; $r=$refs[$i];
        s56Require(($y['number'] ?? null)===$num && ($r['number'] ?? null)===$num &&
            $y['openGateDay']===$r['open_gate_day'] &&
            $y['closeGateDay']===$r['close_gate_day'] &&
            $positions[(string)$y['openGateIndex']] === $y['openGateDay'] &&
            $positions[(string)$y['closeGateIndex']] === $y['closeGateDay'], 'YEAR_BOUNDARY');
        if ($i > 0) s56Require(
            $years[$i-1]['closeGateIndex']===$y['openGateIndex'] &&
            $years[$i-1]['closeGateDay']===$y['openGateDay'], 'ADJACENT_SEAM');
        for ($j=$y['openGateIndex']+1; $j<=$y['closeGateIndex']; $j++) {
            $gap=$positions[(string)$j]-$positions[(string)($j-1)];
            s56Require($gap>=42 && $gap<=963, 'GATE_GAP');
        }
    }
    $anchor = $years[1];
    s56Require($anchor === $gates['year5000_anchor'] &&
        $anchor['openGateIndex'] === $anchorRef['open_gate_index'] &&
        $anchor['closeGateIndex'] === $anchorRef['close_gate_index'] &&
        $anchor['openGateDay'] === $anchorRef['open_gate_day'] &&
        $anchor['openGateDay'] < S56_JDN && S56_JDN <= $anchor['closeGateDay'],
        'YEAR5000_CROSS_SOURCE');
    $trustedAnchorYear = [
        'number'=>5000, 'openGateIndex'=>$anchorRef['open_gate_index'],
        'closeGateIndex'=>$anchorRef['close_gate_index'],
        'openGateDay'=>$anchorRef['open_gate_day'],
        'closeGateDay'=>$refs[1]['close_gate_day']];
    $envelope = static fn(array $y): array => [
        'calculation_jdn'=>S56_JDN,'source_commit'=>S56_SOURCE,'year'=>$y];
    $candidate = $envelope($anchor);
    $trustedAnchor = static fn(int $day): array => $envelope($trustedAnchorYear);
    $trustedYear = static function(int $day,int $num) use ($years,$refs,$envelope):array {
        $idx=$num-4999;
        s56Require($day === S56_JDN && $idx>=0 && $idx<=2, 'YEAR_CALLBACK_CONTEXT');
        return $envelope([
            'number'=>$num, 'openGateIndex'=>$years[$idx]['openGateIndex'],
            'closeGateIndex'=>$years[$idx]['closeGateIndex'],
            'openGateDay'=>$refs[$idx]['open_gate_day'],
            'closeGateDay'=>$refs[$idx]['close_gate_day']]);
    };
    $gateDay = static function(int $idx) use ($positions):int {
        s56Require(array_key_exists((string)$idx, $positions), 'GATE_CALLBACK_RANGE');
        return $positions[(string)$idx];
    };
    $idx=(int)$args[5]-4999;
    $start=hrtime(true);
    echo "STAGE56_PHP_REAL_YEAR_BEGIN year={$args[5]} source_commit=" . S56_SOURCE . "\n";
    flush();
    $provider = new YearStructureProvider56(new BootstrapKernel(), S56_SOURCE);
    $profilePath = $args[6] . '.profile.jsonl';
    @unlink($profilePath);
    $profile = static function(string $type,string $stage,array $metadata) use ($profilePath,$args):void {
        $record = [
            'project_id'=>S56_PROJECT,
            'year'=>(int)$args[5],
            'source_commit'=>S56_SOURCE,
            'branch_sha'=>getenv('GITHUB_SHA') ?: null,
            'type'=>$type,
            'stage'=>$stage,
            'timestamp_ns'=>hrtime(true)
        ] + $metadata;
        $line=json_encode($record,JSON_THROW_ON_ERROR|JSON_UNESCAPED_SLASHES)."\n";
        if (@file_put_contents($profilePath,$line,FILE_APPEND|LOCK_EX)!==strlen($line)) {
            throw new RuntimeException('STAGE56_PROFILE_WRITE');
        }
    };
    $structure = $provider->buildVerified(S56_JDN, $candidate,
        $trustedAnchor, $years[$idx], $trustedYear, $gateDay, $profile);
    unset($provider);
    gc_collect_cycles();
    $providerSeconds = (hrtime(true)-$start)/1e9;
    $cutletOracleStart = hrtime(true);
    $cutletReport = Stage56CutletSemanticOracle::validateStructure(
        $structure, $years[$idx], $positions, S56_JDN);
    $cutletOracleSeconds = (hrtime(true)-$cutletOracleStart)/1e9;
    $branchSha = getenv('GITHUB_SHA');
    $cutletEvidence = [
        'project_id'=>S56_PROJECT,
        'status'=>'PHP_CUTLET_SEMANTIC_ORACLE_PASS_NOT_STAGE56_ACCEPTANCE',
        'branch_sha'=>is_string($branchSha) ? $branchSha : null,
        'source_commit'=>S56_SOURCE,
        'reference_sha256'=>S56_REFERENCE_SHA,
        'gates_sha256'=>S56_GATES_SHA,
        'scroll_oracle_sha256'=>S56_SCROLL_SHA,
        'year'=>(int)$args[5],
        'calculation_jdn'=>S56_JDN,
        'year_record'=>$years[$idx],
        'cutlet_report'=>$cutletReport,
        'cutlet_partition'=>$structure['cutletPartition'],
        'cutlet_name_indices'=>$structure['cutletNameIndices'],
        'cutlets'=>$structure['cutlets'],
        'provider_seconds'=>$providerSeconds,
        'oracle_seconds'=>$cutletOracleSeconds,
        'stage56_accepted'=>false
    ];
    $cutletEncoded=json_encode($cutletEvidence,JSON_THROW_ON_ERROR|JSON_UNESCAPED_SLASHES)."\n";
    s56Require(@file_put_contents($args[6].'.cutlet.json',$cutletEncoded,LOCK_EX)===strlen($cutletEncoded),
        'CUTLET_ORACLE_OUTPUT');
    $requiredLabel=$cutletReport['required_cut']===null?'none':(string)$cutletReport['required_cut'];
    echo "STAGE56_PHP_CUTLET_ORACLE_PASS year={$args[5]} gaps={$cutletReport['gap_count']} " .
        "cutlets={$cutletReport['cutlet_count']} required_cut={$requiredLabel}\n";
    flush();

    $actualLengths=$structure['monthLengths'];
    $expectedLengths=$refs[$idx]['month_lengths'];
    $actualWeaving=$structure['monthWeaving'];
    $expectedWeaving=$refs[$idx]['month_weaving'];
    $lengthsMatch=$actualLengths===$expectedLengths;
    $weavingMatch=$actualWeaving===$expectedWeaving;
    if (!$lengthsMatch || !$weavingMatch) {
        $diagnostic=[
            'project_id'=>S56_PROJECT,
            'status'=>'PHP_EXTERNAL_MONTH_DIFFERENTIAL_FAIL',
            'branch_sha'=>is_string($branchSha)?$branchSha:null,
            'source_commit'=>S56_SOURCE,
            'year'=>(int)$args[5],
            'provider_seconds'=>$providerSeconds,
            'cutlet_oracle'=>'PASS_SOURCE_FREE_ORACLE',
            'cutlet_oracle_seconds'=>$cutletOracleSeconds,
            'month_count_actual'=>$structure['monthCount'],
            'month_count_expected'=>count($expectedLengths),
            'month_lengths_match'=>$lengthsMatch,
            'month_lengths_actual'=>$actualLengths,
            'month_lengths_expected'=>$expectedLengths,
            'month_lengths_first_difference'=>s56FirstDifference($actualLengths,$expectedLengths),
            'month_weaving_match'=>$weavingMatch,
            'month_weaving_length_actual'=>count($actualWeaving),
            'month_weaving_length_expected'=>count($expectedWeaving),
            'month_weaving_first_difference'=>s56FirstDifference($actualWeaving,$expectedWeaving),
            'month_weaving_actual_prefix'=>array_slice($actualWeaving,0,32),
            'month_weaving_expected_prefix'=>array_slice($expectedWeaving,0,32),
            'month_weaving_actual_tail'=>array_slice($actualWeaving,-16),
            'month_weaving_expected_tail'=>array_slice($expectedWeaving,-16),
            'stage56_accepted'=>false
        ];
        $diagnosticEncoded=json_encode($diagnostic,JSON_THROW_ON_ERROR|JSON_UNESCAPED_SLASHES)."\n";
        s56Require(@file_put_contents($args[6].'.diagnostic.json',$diagnosticEncoded,LOCK_EX)===strlen($diagnosticEncoded),
            'MONTH_DIAGNOSTIC_OUTPUT');
        fwrite(STDERR,'STAGE56_PHP_MONTH_DIAGNOSTIC:'.$diagnosticEncoded);
        throw new RuntimeException('STAGE56_PHP_QA_PHP_EXTERNAL_MONTH_DIFFERENTIAL');
    }
    s56Require(array_sum($structure['cutletPartition']) ===
        $years[$idx]['closeGateIndex']-$years[$idx]['openGateIndex'] &&
        count($structure['cutlets']) === $structure['cutletCount'],
        'PHP_CUTLET_COVERAGE');
    $ranker=new MonthWeavingRanker56();
    $tCount=hrtime(true);
    $count=$ranker->count($structure['monthLengths']); $tRank=hrtime(true);
    $rank=$ranker->rank($structure['monthLengths'], $structure['monthWeaving']);
    $tUnrank=hrtime(true);
    $roundtrip=$ranker->unrank($structure['monthLengths'], $rank);
    $end=hrtime(true);
    s56Require($roundtrip === $structure['monthWeaving'] &&
        $rank->sign() > 0 && $rank->compare($count) <= 0,
        'PHP_RANK_ROUNDTRIP');
    s56Require(($end-$start)/1e9 <= 900 && memory_get_peak_usage(true) <= 536870912,
        'PROFILE_BOUNDS');
    s56Require(trim(s56Git($root,'status','--porcelain','--untracked-files=all')) === '',
        'SOURCE_MUTATED');
    $branchSha=getenv('GITHUB_SHA');
    s56Require(is_string($branchSha) && preg_match('/\A[a-f0-9]{40}\z/D',$branchSha)===1 &&
        trim(s56Git(dirname(__DIR__),'rev-parse','HEAD'))===$branchSha, 'BRANCH_SHA');
    $result=[
        'project_id'=>S56_PROJECT, 'status'=>'PHP_REAL_YEAR_QA_PASS_NOT_STAGE56_ACCEPTANCE',
        'branch_sha'=>$branchSha, 'source_commit'=>S56_SOURCE,
        'reference_sha256'=>S56_REFERENCE_SHA, 'gates_sha256'=>S56_GATES_SHA,
        'scroll_oracle_sha256'=>S56_SCROLL_SHA,'year'=>(int)$args[5],
        'calculation_jdn'=>S56_JDN, 'year_record'=>$years[$idx],
        'structure'=>$structure, 'rank_digits'=>strlen($rank->toString()),
        'count_digits'=>strlen($count->toString()),
        'provider_seconds'=>$providerSeconds,
        'cutlet_oracle_seconds'=>$cutletOracleSeconds,
        'cutlet_oracle'=>$cutletReport,
        'count_seconds'=>($tRank-$tCount)/1e9,
        'rank_seconds'=>($tUnrank-$tRank)/1e9,
        'unrank_seconds'=>($end-$tUnrank)/1e9,
        'total_seconds'=>($end-$start)/1e9,
        'peak_bytes'=>memory_get_peak_usage(true),
        'month_differential'=>'PASS', 'rank_roundtrip'=>'PASS',
        'cutlet_external_semantics'=>'PASS_SOURCE_FREE_ORACLE',
        'stage56_accepted'=>false
    ];
    $encoded=json_encode($result,JSON_THROW_ON_ERROR|JSON_UNESCAPED_SLASHES)."\n";
    s56Require(@file_put_contents($args[6],$encoded,LOCK_EX)===strlen($encoded),
        'OUTPUT_WRITE');
    echo json_encode(['year'=>(int)$args[5],'status'=>$result['status'],
        'days'=>count($structure['monthWeaving']),'months'=>$structure['monthCount'],
        'sha256'=>hash('sha256',$encoded), 'seconds'=>$result['total_seconds'],
        'peak_bytes'=>$result['peak_bytes']],JSON_THROW_ON_ERROR)."\n";
    return 0;
}
try { exit(s56Main($argv)); }
catch (Throwable $e) {
    fwrite(STDERR,'STAGE56_PHP_REAL_YEAR_REJECTED: '.$e->getMessage()."\n");
    exit(2);
}
