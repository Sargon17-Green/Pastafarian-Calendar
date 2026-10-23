use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub source ($path) {
    my $f=File::Spec->catfile($Bin,'..',split('/',$path));
    open my $h,'<:encoding(UTF-8)',$f or die "R69 缺少 $path\n";
    local $/;my $s=<$h>;close $h;return $s;
}
my $src=source('tools/audit_r69_bigint_neighbors.pl');
my $watch=source('tools/profile_r69_bigint_neighbors.pl');
my $ci=source('.github/workflows/canonical-names-lock.yml');
for my $n ('34837538497713607370','2134397833143177403516',
          '1331903513327335554982512328','9223372036854775808') {
    ok(index($src,$n)>=0,"R69 大數基線 $n 在完整程式中");
}
like($src,qr/\$whole!=\$count->/,'母前綴被獨立合法後繼 BigInt 分割');
like($src,qr/\$direction>0\?\$possible\[0\]:\$possible\[-1\]/,
     '相鄰詞左右方向須用字元替換而非排名加一');
like($src,qr/unrank_independent\(\$neighbor_rank\)/,
     '真實鄰詞須另與獨立反解排名相同');
like($src,qr/lex_compare\(\$word,\$adjacent\)/,
     '驗證兩個完整合法詞的真正字典序');
like($src,qr/\$adjacent_checked!=28/,'每個 profile 恰好驗證 28 個有效相鄰關係');
like($src,qr/sha512_hex/,'保留獨立域分離 SHA-512 名次');
for my $profile (qw(a b c)) {
    my @jobs=($ci =~ /^  canonical-r69-lex-neighbor-\Q$profile\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"R69 $profile 恰有一份原生分片");
    if (@jobs==1) {
        like($jobs[0],qr/\[weaving-r69-lex-neighbors\]/,"R69 $profile 明確 opt-in");
        like($jobs[0],qr/timeout-minutes:\s*5\b/,"R69 $profile 五分鐘上限");
        like($jobs[0],qr/--profile \Q$profile\E --seconds 185 --rss-kib 393216/,
             "R69 $profile 有明確 RSS / walltime 上限");
        like($jobs[0],qr/set -euo pipefail/,"R69 $profile 不吞原生失敗");
    }
}
like($watch,qr/waitpid\(\$pid,WNOHANG\)/,'獨立 Linux 父監督器');
like($watch,qr/\$rss>\$rss_limit/,'RSS 限額實際執行');
like($watch,qr/\$elapsed>\$seconds/,'walltime 限額實際執行');
like($watch,qr/exit 3;/,'資源限制不可轉成 PASS');
done_testing;
