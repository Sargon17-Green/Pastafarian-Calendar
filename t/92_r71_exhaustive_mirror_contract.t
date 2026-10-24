use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub read_source ($name) {
    my $path=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $fh,'<:encoding(UTF-8)',$path
        or die "R71 找不到 $name\n";
    local $/;my $text=<$fh>;close $fh;return $text;
}
my $audit=read_source('tools/audit_r71_exhaustive_mirror.pl');
my $watch=read_source('tools/profile_r71_exhaustive_mirror.pl');
my $ci=read_source('.github/workflows/canonical-names-lock.yml');
like($audit,qr/1=>215,2=>892,3=>2596/,'三份 27 向量的精確總詞數已錨定');
like($audit,qr/for my \$b \(1\.\.3\)/,'第二月份窮舉 1..3');
like($audit,qr/for my \$c \(1\.\.3\)/,'第三月份窮舉 1..3');
like($audit,qr/for my \$d \(1\.\.3\)/,'第四月份窮舉 1..3');
like($audit,qr/next if \$remaining\[\$j-1\]==1 && \$j!=\$closed\+1/,
     '合法後繼檢查完整末次出現次序');
like($audit,qr/my \@mirror=map \{5-\$_\} reverse \@\$word/,
     '不以排名器生成逆序補標籤鏡射詞');
like($audit,qr/\$hit\{\$mkey\}\+\+/,
     '鏡射不可把兩個來源詞映到同一目標詞');
like($audit,qr/keys\(%hit\)!=\$n/,
     '必須覆蓋目標全集而不只是若干樣本');
like($audit,qr/rankWeavingPolynomial\(\\\@rev,\\\@mirror\)/,
     '真正反轉詞亦須接受反向排名驗證');
like($audit,qr/\$roundtrip_checks!=\$source_words\*4/,
     '每個完整詞對兩種長度順序均核對 rank 和 unrank');
for my $shard (1..3) {
    my @jobs=($ci =~ /^  canonical-r71-exhaustive-mirror-\Q$shard\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"R71 shard $shard 恰有一份獨立 CI");
    next unless @jobs==1;
    like($jobs[0],qr/\[weaving-r71-exhaustive-mirror\]/,
         "R71 shard $shard 僅 opt-in 執行");
    like($jobs[0],qr/timeout-minutes:\s*5\b/,
         "R71 shard $shard GitHub 硬限時五分鐘");
    like($jobs[0],qr/--shard \Q$shard\E --seconds 185 --rss-kib 393216/,
         "R71 shard $shard RSS 和 walltime 保持上限");
    like($jobs[0],qr/set -euo pipefail/,"R71 shard $shard 不吞失敗");
}
like($watch,qr/waitpid\(\$pid,WNOHANG\)/,'獨立父程序監測');
like($watch,qr/\$rss>\$rss_limit/,'檢驗原生 RSS');
like($watch,qr/\$elapsed>\$seconds/,'檢驗執行 walltime');
like($watch,qr/exit 3;/,'BLOCKED 有獨立非零退出碼');
done_testing;
