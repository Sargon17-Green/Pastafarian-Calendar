package Pastafari::WeavingProfileDisk;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use File::Temp qw(tempfile);
use Storable qw(store_fd fd_retrieve);
use Exporter 'import';
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);

our @EXPORT_OK = qw(buildWeavingProfileDisk);

# Stage 1 測試專用：一個解碼器持有一個索引式暫存直方圖集合。
# 每個階段的首次出現位置 BigInt 直方圖以 Storable 二進位格式
# 一次寫入暫存檔，只有索引與最近讀取的一個階段常駐於記憶體。
# 讀取時交付 BigInt 深複製，以免外部修改污染快取。
#
# 此檔案採 File::Temp(UNLINK=>1)，在正常釋放及例外下清除；
# SIGKILL 無法保證執行 Perl 的關閉／解構。
sub buildWeavingProfileDisk ($lengths, $max_bytes = 128*1024*1024) {
    die "索引式直方圖暫存容量限制須為 1..1073741824 位元組\n"
        if !defined($max_bytes) || ref($max_bytes)
        || "$max_bytes" !~ /\A[1-9][0-9]*\z/
        || length("$max_bytes") > 10 || $max_bytes > 1_073_741_824;
    $max_bytes=0+"$max_bytes";
    my ($fh,$path)=tempfile(UNLINK=>1);
    binmode($fh) or die "索引式直方圖暫存檔無法設定二進位模式\n";
    my @offsets;
    my $previous_stage=0;
    my $bytes=0;
    my %stream_stats;
    my $total=countWeavingsPolynomialStream(
        $lengths,\%stream_stats,undef,
        {max_temp_file_bytes=>$max_bytes},
        sub ($stage,$histogram) {
            die "索引式直方圖階段次序錯誤\n"
                if $stage != $previous_stage+1;
            my $at=tell($fh);
            die "索引式直方圖無法記錄位移\n"
                if !defined($at) || $at<0;
            $offsets[$stage]=$at;
            store_fd($histogram,$fh);
            $bytes=tell($fh);
            die "索引式直方圖無法記錄暫存容量\n"
                if !defined($bytes) || $bytes<0;
            die "索引式直方圖暫存檔超過容量限制\n"
                if $bytes>$max_bytes;
            $previous_stage=$stage;
        }
    );
    seek($fh,0,0) or die "索引式直方圖暫存檔無法回到起點\n";
    return bless {
        fh=>$fh,
        path=>$path,
        offsets=>\@offsets,
        stages=>$previous_stage,
        total=>$total->copy,
        bytes=>$bytes,
        temp_frontier_bytes=>$stream_stats{max_temp_file_bytes}//0,
        serialized_rows=>$stream_stats{rows_serialized}//0,
        last_stage=>undef,
        last_hist=>undef,
        reads=>0,
        hits=>0,
    },__PACKAGE__;
}

sub _copy_histogram ($histogram) {
    return [map { defined($_) ? $_->copy : undef } @$histogram];
}

sub histogram ($self,$stage) {
    die "索引式直方圖需要有效的物件\n"
        if !ref($self) || !$self->isa(__PACKAGE__);
    die "索引式直方圖階段必須是範圍內整數\n"
        if !defined($stage) || ref($stage)
        || "$stage" !~ /\A[0-9]+\z/
        || $stage<1 || $stage>$self->{stages};
    $stage=0+$stage;
    if (defined($self->{last_stage}) && $stage==$self->{last_stage}) {
        $self->{hits}++;
        return _copy_histogram($self->{last_hist});
    }
    my $fh=$self->{fh};
    seek($fh,$self->{offsets}[$stage],0)
        or die "索引式直方圖讀取位移失敗\n";
    my $result=fd_retrieve($fh);
    die "索引式直方圖讀取的物件格式錯誤\n" if ref($result) ne 'ARRAY';
    $self->{last_stage}=$stage;
    $self->{last_hist}=$result;
    $self->{reads}++;
    return _copy_histogram($result);
}

sub total ($self) {
    return $self->{total}->copy;
}

sub diagnostics ($self) {
    return {
        stages=>$self->{stages},
        spool_bytes=>$self->{bytes},
        temp_frontier_bytes=>$self->{temp_frontier_bytes},
        serialized_rows=>$self->{serialized_rows},
        histogram_reads=>$self->{reads},
        histogram_hits=>$self->{hits},
    };
}
1;
