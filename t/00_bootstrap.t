use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use File::Find;
use lib 'lib';

use_ok('Pastafari::SpaghettiMonster', qw(calendarDateSpaghetti bootstrap_components));
use_ok('Pastafari::Monster::BaseContext');
use_ok('Pastafari::Monster::BaseDispatcher');
use_ok('Pastafari::Monster::BaseValidator');
use_ok('Pastafari::Monster::BaseErrorBoundary');
use_ok('Pastafari::Monster::BaseMetrics');

my $parts = bootstrap_components();
is(ref($parts->{dispatcher}), 'Pastafari::Monster::BaseDispatcher', '中立分派器已建立');
is(ref($parts->{validator}),  'Pastafari::Monster::BaseValidator',  '中立驗證器已建立');
is(ref($parts->{errors}),     'Pastafari::Monster::BaseErrorBoundary', '錯誤邊界已建立');
is(ref($parts->{metrics}),    'Pastafari::Monster::BaseMetrics', '非語意指標外殼已建立');

my $error = eval { calendarDateSpaghetti(-15055671,-15055671); 1 } ? '' : $@;
like($error, qr/第 1 階段只建立生產骨架/, '生產入口在歷史修補尚未形成前不偽造答案');

my @foreign_code;
find(sub {
    return if !-f $_;
    push @foreign_code, $File::Find::name if /\.(?:py|js|ts|rb|php|java|kt|scala|go|rs|c|cc|cpp|cs|hs|lua|r|jl|m)$/i;
}, '.');
is_deeply(\@foreign_code, [], '專案沒有其他程式語言的原始碼');

my @production_files;
find(sub {
    return if !-f $_ || $_ !~ /\.pm\z/;
    push @production_files, $File::Find::name if $File::Find::name =~ m{\A\./lib/};
}, '.');
my $future = '';
for my $file (@production_files) {
    open my $fh, '<:raw', $file or die "無法讀取生產檔案：$file\n";
    local $/;
    my $text = <$fh>;
    $future .= "$file\n" if $text =~ /oldRemainder|oldDayTag|oldDistance|mutateStonesWrong|savePatch|LEGACY_YEAR_MAX|orderAt46Latch|VirtualLegacyList/;
}
is($future, '', '第 1 階段沒有提前加入未來修補或 legacy 傷痕');

done_testing;
