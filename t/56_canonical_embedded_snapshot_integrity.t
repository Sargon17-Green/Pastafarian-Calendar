use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use FindBin qw($Bin);
use File::Spec;

# 第 34 輪曾將「322」誤作全年月份向量中的某個數字一併替換，
# 其原生 402 日工具因此最先在 SHA-256 完整性檢查 FAIL。
# 這個快測在任何大型計數開始前直接檢查每份來源的固定真實年份快照。
my $fingerprint =
    '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134';

my @sources=(
    ['t/48_canonical_year_month_vector.t', qr/\bmy\s+\@selected\s*=\s*\(([^()]*)\)\s*;/s],
    ['t/49_canonical_adjacent_pairs.t', qr/\bmy\s+\@L\s*=\s*\(([^()]*)\)\s*;/s],
    ['tools/profile_canonical_four_months.pl', qr/\bmy\s+\@year\s*=\s*\(([^()]*)\)\s*;/s],
    ['tools/profile_canonical_memo_prefix.pl', qr/\bmy\s+\@year\s*=\s*\(([^()]*)\)\s*;/s],
    ['tools/profile_canonical_memo_multi_ranks.pl', qr/\bmy\s+\@year\s*=\s*\(([^()]*)\)\s*;/s],
    ['tools/profile_canonical_window40_count.pl', qr/\bmy\s+\@year\s*=\s*\(([^()]*)\)\s*;/s],
    ['tools/profile_canonical_window41_count.pl', qr/\bmy\s+\@year\s*=\s*\(([^()]*)\)\s*;/s],
    ['tools/profile_canonical_all_triples.pl', qr/\bmy\s+\@year\s*=\s*\(([^()]*)\)\s*;/s],
    ['tools/profile_canonical_triple_rank_paths.pl', qr/\bmy\s+\@year\s*=\s*\(([^()]*)\)\s*;/s],
);

my %source;
my %vector;
for my $spec (@sources) {
    my ($relative,$pattern)=@$spec;
    my $full=File::Spec->catfile($Bin,'..',split('/', $relative));
    open my $fh,'<:encoding(UTF-8)',$full
        or die "找不到真實月份稽核來源 $relative：$!\n";
    local $/;
    my $body=<$fh>;
    close $fh;
    $source{$relative}=$body;
    my @found=($body =~ /$pattern/g);
    is(scalar(@found),1,"$relative: 原生 45 月長的固定快照恰有一份");
    next if @found!=1;
    my $raw=$found[0];
    if ($raw =~ /[^0-9,\s]/) {
        fail("$relative: 月份向量只能包含以逗號分隔的十進整數");
        next;
    }
    pass("$relative: 不經 Perl eval 解析固定整數向量");
    my @months=map {s/\s+//gr} split(/,/,$raw,-1);
    is(scalar(@months),45,"$relative: 固定月份數為 45");
    my $total=0;
    $total+=$_ for @months;
    is($total,4244,"$relative: 全年固定長度為 4244 日");
    is(sha256_hex(join(',',@months)),$fingerprint,
       "$relative: 沒有單一數字因全域字串替換而遭污染");
    like($body,qr/\Q$fingerprint\E/,
       "$relative: 腳本／回歸測試保留獨立已核對雜湊");
    $vector{$relative}=\@months;
}
is(scalar(keys %vector),scalar(@sources),
   '全部九份規範年份快照均解析並通過來源完整性驗證');

my $vec=$vector{'t/48_canonical_year_month_vector.t'};
if ($vec) {
    for my $case (
        ['zero-based 38',38,[88,40,25,77],230],
        ['zero-based 39',39,[40,25,77,98],240],
        ['zero-based 40',40,[25,77,98,122],322],
        ['zero-based 41',41,[77,98,122,105],402],
    ) {
        my ($label,$offset,$expected,$days)=@$case;
        my @window=@$vec[$offset..$offset+3];
        is_deeply(\@window,$expected,"$label: 真實四月窗次序固定");
        my $sum=0;
        $sum+=$_ for @window;
        is($sum,$days,"$label: 真實窗口日數固定");
    }
}
# 除了向量自身，也驗證工具的月份選取位置；
# 防止長度／窗口總日數剛好相同，但取錯第 5000 年的月份。
like($source{'tools/profile_canonical_four_months.pl'},
     qr/\bmy\s+\@L\s*=\s*\@year\s*\[\s*39\s*\.\.\s*42\s*\]/,
     '四月份歷史稽核仍選 39..42');
like($source{'tools/profile_canonical_memo_prefix.pl'},
     qr/\bmy\s+\@L\s*=\s*\@year\s*\[\s*39\s*\.\.\s*42\s*\]/,
     '逐日記憶式前綴稽核仍選 39..42');
like($source{'tools/profile_canonical_window40_count.pl'},
     qr/\bmy\s+\@L\s*=\s*\@year\s*\[\s*40\s*\.\.\s*43\s*\]/,
     '322 日窗口明確選 40..43');
like($source{'tools/profile_canonical_window41_count.pl'},
     qr/\bmy\s+\$window_offset\s*=\s*41\s*;/,
     '402 日窗口明確從月索引 41 開始');
like($source{'tools/profile_canonical_window41_count.pl'},
     qr/\bmy\s+\@L\s*=\s*\@year\s*\[\s*\$window_offset\s*\.\.\s*\$window_offset\s*\+\s*3\s*\]/,
     '402 日窗口實際使用偏移量，而不只是記錄名稱');
like($source{'tools/profile_canonical_memo_multi_ranks.pl'},
     qr/\bmy\s+\@L\s*=\s*\@year\s*\[\s*\$offset\s*\.\.\s*\$offset\s*\+\s*3\s*\]/,
     '多排名工具使用經檢查的動態起始月份');

done_testing;
