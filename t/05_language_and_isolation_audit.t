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
my ($actions_performed) = $state =~ /^GITHUB_ACTIONS_PERFORMED=(YES|NO)$/m;
my $actions_audit_ok = defined($actions_performed) && $actions_performed eq 'NO';
if (defined($actions_performed) && $actions_performed eq 'YES') {
    for my $report (glob 'docs/STAGE_*_NATIVE_CI_ACCEPTANCE_*.md') {
        open my $fh, '<:encoding(UTF-8)', $report or die "無法讀取 CI 驗收紀錄：$report\n";
        my $record = do { local $/; <$fh> };
        if ($record =~ m{https://github\.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/[1-9]\d*}
            && $record =~ m{https://github\.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/[1-9]\d*/artifacts/[1-9]\d*}
            && $record =~ /\b[0-9a-f]{40}\b/) {
            $actions_audit_ok = 1;
            last;
        }
    }
}
ok($actions_audit_ok, 'GitHub Actions 執行狀態附有來源雜湊、CI 執行及原始產物證據');
like($state, qr/^GIT_HISTORY_MUTATED=NO$/m, '沒有修改 Git 歷史');

done_testing;
