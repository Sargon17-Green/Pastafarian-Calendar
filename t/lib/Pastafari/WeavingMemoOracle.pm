package Pastafari::WeavingMemoOracle;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);

# 四月份第 1 階段獨立驗證模型，非正式生產曆法實作。
# 按「目前各月剩餘天數 + 已開/已關月數」遞迴計數後綴；
# 和位置分布多項式模型沒有共同的後綴計數器或共享快取。
# 每個狀態的可變 BigInt 答案於本物件內快取，對外傳回 copy。
sub new ($class,$lengths) {
    die "月份長度須為 ARRAY 參照\n" if ref($lengths) ne 'ARRAY';
    die "獨立記憶式 Oracle 只支援最多四個月份\n" if @$lengths>4;
    my (@sizes,$total);
    $total=0;
    for my $value (@$lengths) {
        die "月份長度必須為 1..255 的正整數\n"
            if !defined($value)
            || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')))
            || "$value" !~ /\A[0-9]+\z/
            || $value<1 || $value>255;
        push @sizes,0+"$value";
        $total += $sizes[-1];
        die "所有月份總日數超過 5778\n" if $total>5778;
    }
    return bless {
        sizes=>\@sizes, months=>scalar(@sizes), total=>$total,
        counts=>{}, entries=>0, cache_hits=>0,
        visits=>0, peak_depth=>0, closed_forms=>0,
        choose=>{}, choose_queue=>[], choose_limit=>8192,
    },$class;
}

sub _choose ($self,$n,$k) {
    die "內部組合係數參數無效\n" if $n<0 || $k<0 || $k>$n;
    $k=$n-$k if $k>$n-$k;
    my $key=pack('L<L<',$n,$k);
    return $self->{choose}{$key}->copy
        if exists $self->{choose}{$key};
    my $result=Math::BigInt->bone;
    for my $i (1..$k) {
        $result->bmul($n-$k+$i)->bdiv($i);
    }
    if (@{$self->{choose_queue}}>=$self->{choose_limit}) {
        my $old=shift @{$self->{choose_queue}};
        delete $self->{choose}{$old};
    }
    $self->{choose}{$key}=$result->copy;
    push @{$self->{choose_queue}},$key;
    return $result;
}

sub _last_order ($self,$remaining,$closed) {
    my $m=$self->{months};
    my $sum=0;
    $sum += $_ for @$remaining;
    my $answer=Math::BigInt->bone;
    for (my $j=$m;$j>$closed;$j--) {
        my $n=$remaining->[$j-1];
        die "已開月份尚有不合法的空月\n" if $n<1;
        $answer->bmul($self->_choose($sum-1,$n-1));
        $sum-=$n;
    }
    die "已關月份仍有殘餘日數\n" if $sum;
    $self->{closed_forms}++;
    return $answer;
}

sub _count_state ($self,$remaining,$opened,$closed,$depth) {
    $self->{visits}++;
    $self->{peak_depth}=$depth if $depth>$self->{peak_depth};
    my $key=pack('C*',@$remaining,$opened,$closed);
    if (exists $self->{counts}{$key}) {
        $self->{cache_hits}++;
        return $self->{counts}{$key}->copy;
    }
    my $m=$self->{months};
    my $answer;
    if ($opened==$m) {
        $answer=$self->_last_order($remaining,$closed);
    } else {
        $answer=Math::BigInt->bzero;
        my $last=$opened+1;
        for my $j (1..$last) {
            next if !$remaining->[$j-1];
            next if $remaining->[$j-1]==1 && $j!=$closed+1;
            my @next=@$remaining;
            my $next_open=$j>$opened ? $j : $opened;
            --$next[$j-1];
            my $next_closed=$next[$j-1]==0 ? $j : $closed;
            $answer->badd($self->_count_state(
                \@next,$next_open,$next_closed,$depth+1
            ));
        }
    }
    die "獨立驗證狀態快取超過 200000 項\n"
        if $self->{entries}>=200000;
    $self->{counts}{$key}=$answer->copy;
    $self->{entries}++;
    return $answer;
}

sub count_prefix ($self,$prefix=undef) {
    die "指定前綴必須是 ARRAY 參照\n"
        if defined($prefix) && ref($prefix) ne 'ARRAY';
    $prefix //= [];
    die "前綴天數超過完整月份天數\n"
        if @$prefix>$self->{total};
    my @remaining=@{$self->{sizes}};
    my ($opened,$closed)=(0,0);
    my $m=$self->{months};
    for my $value (@$prefix) {
        die "前綴月份編號必須是 1..m 的正整數\n"
            if !defined($value)
            || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')))
            || "$value" !~ /\A[0-9]+\z/
            || $value<1 || $value>$m;
        my $j=0+"$value";
        die "前綴違反月份首次出現次序\n"
            if $j>$opened+1;
        die "前綴使用已耗盡的月份\n"
            if !$remaining[$j-1];
        die "前綴違反月份末次出現次序\n"
            if $remaining[$j-1]==1 && $j!=$closed+1;
        $opened=$j if $j>$opened;
        --$remaining[$j-1];
        $closed=$j if !$remaining[$j-1];
    }
    # 所有傳入參照均為唯讀；內部備份和快取不外洩。
    return $self->_count_state(\@remaining,$opened,$closed,0)->copy;
}

sub diagnostics ($self) {
    return {
        entries=>$self->{entries},cache_hits=>$self->{cache_hits},
        visits=>$self->{visits},peak_depth=>$self->{peak_depth},
        closed_forms=>$self->{closed_forms},
        binomial_entries=>scalar(@{$self->{choose_queue}}),
        total_days=>$self->{total},months=>$self->{months},
    };
}
1;
