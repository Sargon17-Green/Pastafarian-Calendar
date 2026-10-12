use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use File::Temp qw(tempdir);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);
use lib 'lib','t/lib';
use Pastafari::WeavingProfileDisk qw(buildWeavingProfileDisk);
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);

# 僅在生命週期存在的私有測試中檢查暫存路徑；
# 不依賴正式對外的月份語義 API 或位置命名。
my $first_path;
{
    my $store=buildWeavingProfileDisk([3,2,3],1024*1024);
    $first_path=$store->{path};
    ok(defined($first_path) && -f $first_path,'建立時保有單一暫存檔');
    my $before=$store->diagnostics;
    my $h=$store->histogram(2);
    ok(ref($h) eq 'ARRAY','可正常讀取已儲存的階段');
    my $second=$store->histogram(2);
    is_deeply($second,$h,'同階段快取回傳的精確值保持一致');
    my $after=$store->diagnostics;
    cmp_ok($after->{histogram_hits},'>',$before->{histogram_hits},
           '相同階段查詢重用快取');
}
ok(!-e $first_path,'最後持有者解除後暫存索引檔已刪除');

my ($cached_path,$expected);
{
    my %shared;
    my @lengths=(4,4,4,4);
    my %diagnostics;
    $expected=countWeavingSuffixFactored(\@lengths,[1,2],\%shared,
        \%diagnostics,{profile_engine=>'stream-indexed'});
    my @stores=grep {ref($_) eq 'Pastafari::WeavingProfileDisk'} values %shared;
    is(scalar(@stores),1,'每份獨立解碼器快取只擁有一個磁碟索引物件');
    $cached_path=$stores[0]{path};
    ok(-f $cached_path,'快取持有物件時磁碟索引仍存在');
    my $once=$stores[0]->histogram(2);
    for my $v (@$once) {
        next if !defined($v);
        $v->badd(9000);
        last;
    }
    is(''.countWeavingSuffixFactored(\@lengths,[1,2],\%shared,undef,
          {profile_engine=>'stream-indexed'}),"$expected",
       '外部修改索引副本不污染下一次完整後綴計數');
}
ok(!-e $cached_path,'共享快取生命週期結束後索引立即刪除');

for my $n (0,1,2,3) {
    my $ok=eval {
        buildWeavingProfileDisk([4,4,4],$n);
        1;
    };
    ok(!$ok,'過小容量不會留下不完整的可用索引物件');
    like($@,qr/暫存容量限制|暫存檔超過容量限制/,
          '超限時原因可識別');
}

# 將新建的階段暫存檔限定到一個可枚舉的私人目錄：
# 每次階段轉換應立刻清除舊矩陣，成功或例外都不能
# 將數百份臨時檔留在執行中的長壽 Perl 程序裡。
my $scratch=tempdir(CLEANUP=>1);
{
    local $ENV{TMPDIR}=$scratch;
    my $exact=countWeavingsPolynomialStream([4,4,4,4]);
    ok("$exact" ne '', '私有暫存目錄下的精確串流計數正常完成');
    opendir my $dh,$scratch or die "無法讀取私有暫存目錄：$!\n";
    my @left=grep {$_ ne '.' && $_ ne '..'} readdir($dh);
    closedir $dh;
    is(scalar(@left),0,'所有階段檔於計數返回後均立即刪除');
    my $good=eval {
        countWeavingsPolynomialStream([4,4,4],undef,undef,
                                      {max_temp_file_bytes=>1});
        1;
    };
    ok(!$good,'磁碟容量失敗確實觸發例外路徑');
    opendir my $dh2,$scratch or die "無法再次讀取暫存目錄：$!\n";
    @left=grep {$_ ne '.' && $_ ne '..'} readdir($dh2);
    closedir $dh2;
    is(scalar(@left),0,'容量失敗後部分寫入的階段檔也立即刪除');
}
done_testing;
