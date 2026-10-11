use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use Digest::SHA qw(sha256_hex);
use lib 'lib';
use Pastafari::SpaghettiMonster qw(calendarDateSpaghetti bootstrap_components);
use Pastafari::Monster::BaseContext;
use Pastafari::Monster::BaseDispatcher;
use Pastafari::Monster::BaseValidator;
use Pastafari::Monster::BaseErrorBoundary;
use Pastafari::Monster::BaseMetrics;

my $parts1 = bootstrap_components();
my $parts2 = bootstrap_components();
for my $key (qw(dispatcher validator errors metrics)) {
    isnt($parts1->{$key}, $parts2->{$key}, "獨立呼叫不共用 $key 元件");
}

my $a = Pastafari::Monster::BaseContext->new(calculationDay => '1', targetDay => '2');
my $b = Pastafari::Monster::BaseContext->new(calculationDay => '3', targetDay => '4');
$a->{semanticState}{selected} = 123;
$a->{logs}[0] = '甲';
$a->{metrics}{calls} = 5;
$a->{diagnostics}[0] = '訊息';
is_deeply($b->semantic_snapshot(), {}, '不同呼叫的語意狀態互不影響');
is_deeply($b->{logs}, [], '不同呼叫的記錄互不影響');
is_deeply($b->{metrics}, {}, '不同呼叫的指標互不影響');
is_deeply($b->{diagnostics}, [], '不同呼叫的診斷互不影響');
my $snapshot = $a->semantic_snapshot();
$snapshot->{selected} = 999;
is($a->{semanticState}{selected}, 123, '語意快照的頂層修改不會回寫');

my $validator = Pastafari::Monster::BaseValidator->new();
for my $valid ('0', '-1', '+12', '0007', '9' x 300, Math::BigInt->new('9' x 300)) {
    ok(eval { $validator->require_integer_day($valid); 1 }, '接受完整十進位整數');
}
for my $invalid (undef, '', ' ', '1.0', '1e2', '12 3', 'NaN', 'Infinity', '1a') {
    my $accepted = eval { $validator->require_integer_day($invalid); 1 };
    ok(!$accepted, '拒絕非十進位整數');
}
ok($validator->require_semantic_state_owned($a), '正確辨識單次呼叫擁有者');
my $owner_error = eval { $validator->require_semantic_state_owned({}); 1 };
ok(!$owner_error, '拒絕沒有擁有者的語意狀態');

my $dispatcher = Pastafari::Monster::BaseDispatcher->new();
ok($dispatcher->register('檢查', sub ($ctx) { return $ctx->{targetDay} }), '可以註冊處理階段');
is($dispatcher->dispatch('檢查', $a), '2', '處理階段收到指定的呼叫內容');
ok(!eval { $dispatcher->register('檢查', sub { 0 }); 1 }, '重複註冊會失敗');
ok(!eval { $dispatcher->dispatch('未定義', $a); 1 }, '未定義階段會失敗');

my $boundary = Pastafari::Monster::BaseErrorBoundary->new();
my $successful = Pastafari::Monster::BaseContext->new();
is($boundary->run($successful, sub { 42 }), 42, '錯誤邊界正常回傳結果');
is($successful->{status}, 'NEW', '成功不會憑空改寫狀態');
my $failed = Pastafari::Monster::BaseContext->new();
my $threw = eval { $boundary->run($failed, sub { die "測試失敗\n" }); 1 };
ok(!$threw, '錯誤邊界會重新拋出失敗');
is($failed->{status}, 'FAILED', '失敗只標記本次呼叫');
is($failed->{lastError}, "測試失敗\n", '保留原始失敗內容');
is($successful->{status}, 'NEW', '另一個呼叫的狀態不被污染');

my $metrics = Pastafari::Monster::BaseMetrics->new();
is($metrics->bump('次數'), 1, '第一次指標遞增');
is($metrics->bump('次數'), 2, '第二次指標遞增');
my $metrics_snapshot = $metrics->snapshot();
$metrics_snapshot->{'次數'} = 100;
is($metrics->snapshot()->{'次數'}, 2, '外部修改指標快照不會污染原物件');

for my $pair (['0','0'], ['-15055671','-15055671'], ['9' x 200, '9' x 200]) {
    my $err = eval { calendarDateSpaghetti(@$pair); 1 } ? '' : $@;
    like($err, qr/第 1 階段只建立生產骨架/, '未完成的生產入口不偽造曆法答案');
}

open my $manifest, '<:encoding(UTF-8)', 'MANIFEST_STAGE_01.txt' or die "無法讀取階段清單\n";
my @listed = grep { length } map { chomp; $_ } <$manifest>;
close $manifest;
my %seen;
for my $path (@listed) {
    ok(!$seen{$path}++, "清單沒有重複條目：$path");
    ok(-f $path, "清單檔案真實存在：$path");
    unlike($path, qr/(?:^|\/)HANDOFF[^\/]*\z/i, '使用者專用的交接文件不列入來源清單');
}
ok(!-e 'HANDOFF_STAGE_01.md', '交接檔案未混入來源樹');

open my $lock, '<:encoding(UTF-8)', 'CANONICAL_NAMES_LOCK.sha256' or die "無法讀取名稱鎖定檔\n";
my @locks = grep { length } map { chomp; $_ } <$lock>;
close $lock;
is(scalar @locks, 1, '名稱鎖定檔只有一筆指定權威來源');
for my $entry (@locks) {
    like($entry, qr/\A[0-9a-f]{64}  lib\/Pastafari\/SourceLanguageCatalog\.pm\z/,
        '鎖定檔格式和來源路徑完全符合規定');
    my ($digest, $path) = split /  /, $entry, 2;
    open my $fh, '<:raw', $path or die "無法讀取名稱來源\n";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    is(sha256_hex($bytes), $digest, '來源語言名稱鎖定雜湊與位元內容一致');
}

done_testing;
