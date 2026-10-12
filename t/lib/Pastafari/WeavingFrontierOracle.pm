package Pastafari::WeavingFrontierOracle;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);
use Exporter 'import';
our @EXPORT_OK = qw(countWeavingsFrontier);

# 獨立狀態轉移模型，不使用位置直方圖或新月份插入多項式。
# 逐日只保留目前可達的前綴狀態（剩餘月長、opened、closed）。
# 最後一種月份首次出現後，所有先後首次條件均已滿足：
# 利用逐次固定最後字元的組合恆等式完成剩餘月份，避免遍歷大量
# 全開狀態。這並非以被測多項式引擎當作預言機。
sub countWeavingsFrontier ($lengths,$stats=undef) {
    die "月份長度必須是陣列參照\n" if ref($lengths) ne 'ARRAY';
    die "診斷記錄必須是雜湊參照\n"
        if defined($stats) && ref($stats) ne 'HASH';
    die "獨立前綴稽核最多驗證四個月\n"
        if @$lengths>4;
    my @sizes;
    my $total=0;
    for my $item (@$lengths) {
        die "月份長度必須是有效的 1..255 正整數\n"
            if !defined($item)
            || (ref($item) && !(blessed($item) && $item->isa('Math::BigInt')))
            || "$item" !~ /\A[0-9]+\z/
            || $item<1 || $item>255;
        push @sizes,0+"$item";
        $total+=$sizes[-1];
        die "總日數不能超過 5778\n" if $total>5778;
    }
    if (defined $stats) {
        %$stats=(
            states=>0, transitions=>0, terminal_shortcuts=>0,
            steps=>0, frontier_peak=>0, binomial_cache_peak=>0,
            total_days=>$total,
        );
    }
    return Math::BigInt->bone if !@sizes;
    my $m=scalar @sizes;

    # 計算 C(n,k)；只有本次驗證有效的可變 BigInt 私有快取，
    # 有限項數防止過度常駐記憶體。
    my (%binomial_cache,@fifo);
    my $cache_limit=8192;
    my $choose = sub ($n,$k) {
        die "二項係數索引無效\n" if $n<0 || $k<0 || $k>$n;
        $k=$n-$k if $k>$n-$k;
        my $key="$n,$k";
        return $binomial_cache{$key}->copy if exists $binomial_cache{$key};
        my $v=Math::BigInt->bone;
        for my $i (1..$k) {
            $v->bmul($n-$k+$i)->bdiv($i);
        }
        if (@fifo>=$cache_limit) {
            my $victim=shift @fifo;
            delete $binomial_cache{$victim};
        }
        $binomial_cache{$key}=$v->copy;
        push @fifo,$key;
        if (defined($stats) && @fifo>$stats->{binomial_cache_peak}) {
            $stats->{binomial_cache_peak}=scalar @fifo;
        }
        return $v;
    };

    my $finish = sub ($remaining,$closed) {
        my $sum=0;
        $sum+=$_ for @$remaining;
        my $factor=Math::BigInt->bone;
        for (my $j=$m;$j>$closed;$j--) {
            my $size=$remaining->[$j-1];
            die "全開狀態仍含錯誤的已關閉月份\n" if $size<1;
            $factor->bmul($choose->($sum-1,$size-1));
            $sum-=$size;
        }
        die "已關閉月份仍有剩餘日\n" if $sum;
        return $factor;
    };

    my %frontier=(pack('C*',@sizes,0,0)=>Math::BigInt->bone);
    my $answer=Math::BigInt->bzero;
    while (%frontier) {
        my %next;
        if (defined $stats) {
            $stats->{steps}++;
            $stats->{frontier_peak}=scalar(keys %frontier)
                if scalar(keys %frontier)>$stats->{frontier_peak};
        }
        while (my ($key,$weight)=each %frontier) {
            my @state=unpack('C*',$key);
            my @remaining=@state[0..$m-1];
            my ($opened,$closed)=@state[$m,$m+1];
            $stats->{states}++ if defined $stats;
            my $limit=$opened<$m ? $opened+1 : $m;
            for my $j (1..$limit) {
                next if !$remaining[$j-1];
                next if $remaining[$j-1]==$sizes[$j-1] && $j!=$opened+1;
                next if $remaining[$j-1]==1 && $j!=$closed+1;
                $stats->{transitions}++ if defined $stats;
                my @new=@remaining;
                my $open=$opened;
                $open=$j if $new[$j-1]==$sizes[$j-1];
                $new[$j-1]--;
                my $close=$closed;
                $close=$j if $new[$j-1]==0;
                if ($open==$m) {
                    $answer->badd($weight->copy->bmul($finish->(\@new,$close)));
                    $stats->{terminal_shortcuts}++ if defined $stats;
                } else {
                    my $nk=pack('C*',@new,$open,$close);
                    if (exists $next{$nk}) {
                        $next{$nk}->badd($weight);
                    } else {
                        $next{$nk}=$weight->copy;
                    }
                }
            }
        }
        %frontier=%next;
    }
    return $answer;
}
1;
