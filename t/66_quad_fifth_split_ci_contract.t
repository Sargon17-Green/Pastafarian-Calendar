use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub read_text ($name) {
    my $path=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $fh,'<:encoding(UTF-8)',$path or die "檔案不能讀取：$name\n";
    local $/;my $t=<$fh>;close $fh;return $t;
}
my $script=read_text('tools/profile_canonical_window41_count.pl');
my $ci=read_text('.github/workflows/canonical-names-lock.yml');
like($script,qr/'fifth-day-target=s'\s*=>\s*\\\$fifth_day_target/,
     '第五日分片選項需明確指定');
like($script,qr/\$fifth_day_target\s*!~\s*\/\\A/,
     '只接受明列的合法分片');
like($script,qr/countWeavingsFrontier\s*\(\s*\\\@L\s*,\s*\\%fifth_stats\s*,\s*\\\@prefix/,
     '各指定前綴透過獨立正向合法狀態 Oracle');
like($script,qr/\$forward\s*!=\s*\$factor/,
     '不可把多項式後綴替代獨立前沿而假報 PASS');
like($script,qr/\$sum\s*!=\s*\$parent/,
     '第五日三條候選 BigInt 精確和必須等於母前綴');
like($script,qr/\$word->\[4\]\s*!=\s*\$split_fifth/,
     '第五日獨立分支選擇必須與索引反排名一致');
like($script,qr/\$local->bsub\(\$smaller_fourth\)/,
     '一基中位排名須扣除第四日較小分支再進第五日');
my (@jobs,%seen);
while ($ci =~ /^  canonical-window37-fifth-piece-([a-z0-9]+):[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg) {
    my ($name,$body)=($1,$2);
    push @jobs,$name;$seen{$name}++;
    like($body,qr/\Q--fifth-day-target $name --seconds 185 --rss-kib 393216\E/,
         "分片 $name 每次保持原始 185 秒和 RSS 界線");
    like($body,qr/\[weaving-window37-fifth-split\]/,
         "分片 $name 有獨立啟動標記");
    like($body,qr/timeout-minutes:\s*5\b/,
         "分片 $name 的 CI 工作不能逾五分鐘");
    like($body,qr/set -euo pipefail/,
         "分片 $name 不吞任何 FAIL 或 BLOCKED");
}
is_deeply(\@jobs,[qw(parent 1 2 3 assembly)],
          '第五日四個獨立前沿與一個 BigInt 總和工作完整存在');
ok(!(grep {$_!=1} values %seen),'不重複執行或漏掉任何分片');
done_testing;
