use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(
    M FOUNDATION_DAY TABLETS_DAY SAVE regularMod dayCount workCounts buildStones
    bowlOrderFromDrop chooseRankShort chooseRankWide fallingFactorial unrankDistinctIndices
);

my $M = M();
is("$M", '170141183460469231731687303715884105727', '大計數 M 精確為二的一百二十七次方減一');
is("" . TABLETS_DAY()->copy->bsub(FOUNDATION_DAY()), '14777149', '泥版日與奠基日距離精確');

is("" . SAVE(1), '1', 'SAVE 保留一');
is("" . SAVE($M->copy->bsub(1)), "" . $M->copy->bsub(1), 'SAVE 保留 M 減一');
is("" . SAVE($M), "$M", 'SAVE 將 M 保存為 M 而不是零');
is("" . SAVE($M->copy->badd(1)), '1', 'SAVE 在 M 加一時回到一');
is("" . SAVE($M->copy->bmul(2)), "$M", 'SAVE 對二倍 M 仍返回 M');
is("" . regularMod(-1,7), '6', '一般模數對負數使用歐幾里得餘數');

my $f = FOUNDATION_DAY();
is("" . dayCount($f), '1', '奠基日計數為一');
is("" . dayCount($f->copy->bsub(1)), '2', '奠基日前一天計數為偶數二');
is("" . dayCount($f->copy->badd(1)), '3', '奠基日後一天計數為奇數三');

my $same = workCounts($f,$f);
is("$same->{distance}",'1','同一天的距離計數為一');
is($same->{direction},2,'同一天的方向為二');
my $past = workCounts($f,$f->copy->bsub(3));
is("$past->{distance}",'4','距離來自實際日差再加一');
is($past->{direction},1,'向過去的方向為一');
my $future = workCounts($f,$f->copy->badd(3));
is($future->{direction},3,'向未來的方向為三');

my $stones = buildStones();
is_deeply([map { "$_" } @{$stones->[1]}], [qw(17 29 43 71 101)], '第一列五顆石頭固定');
is_deeply([map { "$_" } @{$stones->[2]}], [qw(378 1073 2375 6195 10493)], '第二列五顆石頭全部從同一舊快照推導');
is(scalar(@$stones)-1,46,'建立四十六列石頭');

is_deeply(bowlOrderFromDrop(1), [1,2,3,4,5,6], '排列排名一是遞增順序');
is_deeply(bowlOrderFromDrop(720), [6,5,4,3,2,1], '排列排名七百二十是遞減順序');
is_deeply(bowlOrderFromDrop(1440), [6,5,4,3,2,1], '七百二十的倍數仍指向排名七百二十');

my $stream = { first => M(), directionStep => 1 };
is("" . chooseRankShort($stream,1), '1', '短選擇在單一候選時固定為一');
is("" . chooseRankShort({first=>1,directionStep=>1},7), '1', '短選擇使用一基排名');
my $wideN = M()->badd(1);
is("" . chooseRankWide({first=>1,directionStep=>1},$wideN), "$wideN", '寬選擇由同一答案環建立固定寬數');

is("" . fallingFactorial(17,3), '4080', '部分排列計數精確');
is_deeply(unrankDistinctIndices(4,3,1), [1,2,3], '不同名稱反排名第一列正確');
is_deeply(unrankDistinctIndices(4,3,24), [4,3,2], '不同名稱反排名最後一列正確');

done_testing;
