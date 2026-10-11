use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);

# 診斷是測試儀器，而非規範結果。兩種呼叫模式必須完全同值。
for my $lengths (
    [1], [1,1,1], [2,2,2], [4,4,4], [4,4,4,4], [4,123,4], [4,4,4,4,4,4],
) {
    my %stats = (stale => 999);
    my $value = countWeavings($lengths, \%stats);
    is("$value", ''.countWeavings($lengths),
        "有無診斷不影響精確數量：".join('-',@$lengths));
    ok(!exists($stats{stale}), '每次量測清除舊統計');
    is($stats{states}, $stats{preopen_states} + $stats{fully_open_states},
        '各類 memo 狀態數守恆');
    cmp_ok($stats{states}, '>=', 1, '至少一個計數狀態');
    cmp_ok($stats{max_stack}, '>=', 1, '顯式堆疊高水位可觀測');
    cmp_ok($stats{max_stack}, '<=', scalar(@$lengths)*123 + 1,
        '堆疊深度不超出月份日數保守上界');
    cmp_ok($stats{visited_transitions}, '>=', $stats{valid_transitions},
        '候選嘗試數不少於合法轉移數');
    cmp_ok($stats{preopen_states}, '>=', 1,
        '正式從所有月份未開啟的狀態會有 preopen');
    my %again;
    is(''.countWeavings($lengths,\%again),"$value",
        '全新獨立統計容器仍返回一致精確計數');
    is_deeply(\%again,\%stats,'重複執行具有完全相同的確定性統計');
}
my %stats;
countWeavings([4,4,4],\%stats);
ok($stats{fully_open_states} > 0, '完整開啟的閉式計數路徑有被計入');
ok($stats{pascal_max_n} <= 256, 'Pascal 行界不超過 256');
ok($stats{sparse_peak} <= 128, '大型二項式快取數量不超過 128');
for my $bad ([],[1]) {
    my $ok = eval { countWeavings([4,4],$bad); 1 };
    ok(!$ok,'非雜湊診斷容器會被拒絕');
    like($@,qr/交織診斷記錄必須是雜湊參照/,
        '不合法診斷容器的錯誤明確');
}
done_testing;
