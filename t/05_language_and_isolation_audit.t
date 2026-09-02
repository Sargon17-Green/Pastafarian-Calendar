use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use File::Find;

my @files;
find(sub {
    return if !-f $_;
    return if $File::Find::name =~ m{(?:^|/)STAGE_01_TEST_LOG\.txt\z};
    push @files, $File::Find::name if /\.(?:md|pm|t|txt)\z/;
}, '.');

my @hebrew;
my @oracle_in_production;
for my $file (@files) {
    open my $fh, '<:encoding(UTF-8)', $file or die "無法讀取稽核檔案：$file\n";
    local $/;
    my $text = <$fh>;
    my $check = $text;
    $check =~ s/^NATURAL_LANGUAGE=.*\R//m;
    push @hebrew, $file if $check =~ /\p{Hebrew}/;
    if ($file =~ m{\A\./lib/} && $text =~ /Pastafari::NormativeScroll/) {
        push @oracle_in_production, $file;
    }
}

is_deeply(\@hebrew, [], '除規格要求的機器欄位外，人工撰寫專案內容沒有希伯來文字');
is_deeply(\@oracle_in_production, [], '生產樹沒有載入測試專用規範參考');

open my $stage, '<:encoding(UTF-8)', 'DEVELOPMENT_STAGE.md' or die "無法讀取階段狀態\n";
my $state = do { local $/; <$stage> };
like($state, qr/^SOURCE_LANGUAGE_CATALOG_FROZEN=YES$/m, '來源語言目錄在第 1 階段已凍結');
like($state, qr/^CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO$/m, '沒有使用其他實作的產物');
like($state, qr/^CROSS_IMPLEMENTATION_HASH_CHECKS=NO$/m, '沒有做跨實作雜湊比較');
like($state, qr/^CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO$/m, '沒有做跨實作差異測試');
like($state, qr/^GITHUB_ACTIONS_PERFORMED=NO$/m, '沒有執行 GitHub 動作');
like($state, qr/^GIT_HISTORY_MUTATED=NO$/m, '沒有修改 Git 歷史');

done_testing;
