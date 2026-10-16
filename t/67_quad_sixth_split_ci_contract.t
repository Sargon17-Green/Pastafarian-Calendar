use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub load ($name) {
    my $p=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $fh,'<:encoding(UTF-8)',$p or die "不能讀取 $name\n";
    local $/;my $s=<$fh>;close $fh;return $s;
}
my $script=load('tools/profile_canonical_window41_count.pl');
my $wf=load('.github/workflows/canonical-names-lock.yml');
like($script,qr/'sixth-day-target=s'\s*=>\s*\\\$sixth_day_target/,
     '第六日分片需要單獨明示');
like($script,qr/\$sixth_day_target\s*!~\s*\/\\A/,
     '所有可能第六日分支嚴格列舉');
like($script,qr/countWeavingsFrontier\s*\(\s*\\\@L\s*,\s*\\%sixth_stats\s*,\s*\\\@prefix/,
     '六個工作中的分支均須與獨立前沿比對');
like($script,qr/\$n\s*!=\s*\$factor/,
     '每個 BigInt 精確前綴另與因子式後綴核對');
like($script,qr/\$sum\s*!=\s*\$parent/,
     '四個合法第六日候選全部形成母前綴分割');
like($script,qr/\$word->\[5\]\s*!=\s*\$split_sixth/,
     '最終第五日之後的第六個字元須吻合索引反排名');
like($script,qr/\$local->bsub\(\$p12121\)->bsub\(\$p12122\)/,
     '必須扣除第五天較小的兩種 BigInt 分支');
my (@jobs,%seen);
while ($wf =~ /^  canonical-window37-sixth-piece-([a-z0-9]+):[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg) {
    my ($name,$body)=($1,$2);
    push @jobs,$name;$seen{$name}++;
    like($body,qr/\Q--sixth-day-target $name --seconds 185 --rss-kib 393216\E/,
        "工作 $name 保留單窗 185 秒和 393216 KiB RSS 上限");
    like($body,qr/\[weaving-window37-sixth-split\]/,
        "工作 $name 保持獨立 opt-in 標記");
    like($body,qr/timeout-minutes:\s*5\b/,
        "工作 $name 不放寬 GitHub 五分鐘硬預算");
    like($body,qr/set -euo pipefail/,
        "工作 $name 不吞失敗退出碼");
}
is_deeply(\@jobs,[qw(parent 1 2 3 4 assembly)],
    '第六日五個前綴 + 一個彙總工作不漏不重');
ok(!(grep {$_!=1} values %seen),'每份分片只出現一次');
done_testing;
