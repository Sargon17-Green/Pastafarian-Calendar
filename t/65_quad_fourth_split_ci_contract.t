use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub text_file ($relative) {
    my $path=File::Spec->catfile($Bin,'..',split('/',$relative));
    open my $fh,'<:encoding(UTF-8)',$path or die "檔案不可讀：$relative\n";
    local $/;my $s=<$fh>;close $fh;return $s;
}
my $script=text_file('tools/profile_canonical_window41_count.pl');
my $ci=text_file('.github/workflows/canonical-names-lock.yml');
like($script,qr/'fourth-day-target=s'\s*=>\s*\\\$fourth_day_target/,
     '第四日分片只能由明確 opt-in 指定');
like($script,qr/\$fourth_day_target\s*!~\s*\/\\A/,
     '允許的第四日分片只有完整固定的合法候選');
like($script,qr/countWeavingsFrontier\s*\(\s*\\\@L\s*,\s*\\%part_stats\s*,\s*\\\@prefix/,
     '全部三個第四日候選每一條都由獨立正向前沿驗證');
like($script,qr/\$n\s*!=\s*\$factor/,
     '每條前沿 BigInt 必須比對另一精確後綴模型');
like($script,qr/\$sum\s*!=\s*\$parent/,
     '第四日全合法候選之 BigInt 完工數和驗證');
like($script,qr/\$word->\[3\]\s*!=\s*\$split_fourth/,
     '第四日獨立選擇必須與索引反排名相符');
my (@jobs,%seen);
while ($ci =~ /^  canonical-window37-fourth-piece-([a-z0-9]+):[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg) {
    my ($name,$body)=($1,$2);
    push @jobs,$name;$seen{$name}++;
    like($body,qr/\Q--fourth-day-target $name --seconds 185 --rss-kib 393216\E/,
         "前綴 $name 具有獨立 185 秒及 RSS 界線");
    like($body,qr/\[weaving-window37-fourth-split\]/,
         "前綴 $name 僅在指定提交標記才啟動");
    like($body,qr/timeout-minutes:\s*5\b/,
         "前綴 $name GitHub 工作仍有硬總時限");
    like($body,qr/set -euo pipefail/,
         "前綴 $name 不能吞掉子工作 FAIL/BLOCKED");
}
is_deeply(\@jobs,[qw(parent 1 2 3 assembly)],
          '第四日四個獨立前沿與一個整合工作均存在');
ok(!(grep {$_!=1} values %seen),'每個分片 job 恰好一份');
done_testing;
