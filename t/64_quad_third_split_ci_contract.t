use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub load_text ($name) {
    my $path=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $fh,'<:encoding(UTF-8)',$path or die "來源不存在：$name\n";
    local $/;my $text=<$fh>;close $fh;return $text;
}
my $source=load_text('tools/profile_canonical_window41_count.pl');
my $ci=load_text('.github/workflows/canonical-names-lock.yml');
like($source,qr/'third-day-target=s'\s*=>\s*\\\$third_day_target/,
     '只經過顯式 opt-in 的第三天分片選項');
like($source,qr/countWeavingsFrontier\s*\(\s*\\\@L\s*,\s*\\%prefix_stats\s*,\s*\\\@prefix/,
     '每一條真實前綴由獨立正向前沿重新精確計數');
like($source,qr/\$forward\s*!=\s*\$factor/,
     '正向前沿與另一後綴模型的 BigInt 逐項吻合');
like($source,qr/\$sum\s*!=\s*\$parent/,
     '三條候選整合後精確等於父前綴');
like($source,qr/\$word->\[2\]\s*!=\s*\$split_third/,
     '獨立第三天選擇需核對索引反排名');
my (@names,%found);
while ($ci =~ /^  canonical-window37-third-piece-([a-z0-9]+):[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg) {
    my ($name,$body)=($1,$2);
    push @names,$name;
    $found{$name}++;
    like($body,qr/\Q--third-day-target $name --seconds 185 --rss-kib 393216\E/,
         "前綴分片 $name 保留硬資源限制");
    like($body,qr/\[weaving-window37-third-split\]/,
         "前綴分片 $name 的精確 opt-in 標記");
    like($body,qr/timeout-minutes:\s*5\b/,
         "前綴分片 $name 的 CI 工作上限");
    like($body,qr/set -euo pipefail/,
         "前綴分片 $name 會傳播失敗退出狀態");
}
is_deeply(\@names,[qw(parent 1 2 3 assembly)],
          '四份獨立前沿分片和總和整合工作沒有漏驗');
ok(!(grep {$_!=1} values %found),'所有固定分片只有一個受控工作');
done_testing;
