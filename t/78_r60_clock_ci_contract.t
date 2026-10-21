use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub src ($name) {
    my $p=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $f,'<:encoding(UTF-8)',$p or die "來源不存在 $name\n";
    local $/;my $t=<$f>;close $f;return $t;
}
my $oracle=src('t/lib/Pastafari/WeavingMemoOracle.pm');
my $tool=src('tools/profile_canonical_memo_multi_ranks.pl');
my $wf=src('.github/workflows/canonical-names-lock.yml');
like($oracle,qr/\$policy ne 'fifo' && \$policy ne 'clock'/,
     '新的 cache policy 只包含原 FIFO 和 clock');
like($oracle,qr/\$self->\{entries\}>=\$self->\{cache_limit\}/,
     'cache_limit 硬界線完全保留');
like($oracle,qr/\$self->\{second_chances\}\+\+/,
     'clock 明確執行有引用命中的 second-chance');
like($tool,qr/\$case_filter =~ \/\\Ahash36-\(\?:08\|09\|10\)\\z\//,
     '僅限上一輪三個 BLOCKED 名次啟用 clock');
like($tool,qr/\$cache_options->\{cache_policy\}='clock'/,
     'clock 僅作獨立驗證器的顯式選項');
for my $n (qw(08 09 10)) {
    my @jobs=($wf =~ /^  canonical-fourmonth-r60-clock-\Q$n\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"R60 $n 只有一個 opt-in Native 工作");
    next unless @jobs==1;
    like($jobs[0],qr/\[weaving-fourmonth-r60-clock\]/,
         '原有 R59 24 matrix 不再被觸發');
    like($jobs[0],qr/timeout-minutes:\s*5\b/,
         'R60 仍為 GitHub 5 分鐘上限');
    like($jobs[0],qr/--window-offset 36 --case-filter hash36-\Q$n\E --seconds 185 --rss-kib 393216/,
         '每個完整排名保留 185 秒和 393216 KiB RSS');
}
done_testing;
