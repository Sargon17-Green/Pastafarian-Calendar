use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

# R67 Stage 1：獨立合法字序 DFS，不使用被測 Oracle、插入多項式或其快取。
# 對跨 64-bit 的四月份案例建立真正無損、可查前綴的 BigInt 參考。
sub independent_counter ($lengths) {
    my %memo;
    my $m=scalar(@$lengths);
    my $walk;
    $walk=sub ($remaining,$opened,$closed) {
        my $key=join(',',@$remaining).":$opened:$closed";
        return $memo{$key}->copy if exists $memo{$key};
        my $left=0;$left+=$_ for @$remaining;
        return $memo{$key}=Math::BigInt->bone if !$left;
        my $total=Math::BigInt->bzero;
        for my $j (1..($opened<$m?$opened+1:$m)) {
            next unless $remaining->[$j-1];
            next if $remaining->[$j-1]==1 && $j!=$closed+1;
            my @next=@$remaining;
            --$next[$j-1];
            $total->badd($walk->(
                \@next,$j>$opened?$j:$opened,
                $next[$j-1]==0?$j:$closed
            ));
        }
        $memo{$key}=$total->copy;
        return $total;
    };
    return ($walk,\%memo);
}

# 只選擇真正存在合法完工後綴的後繼；首末名次是兩條不同路徑。
sub witness_word ($lengths,$reference,$last) {
    my @rem=@$lengths;
    my ($opened,$closed)=(0,0);
    my @word;
    my $n=0;$n+=$_ for @rem;
    for (1..$n) {
        my @options;
        for my $j (1..($opened<4?$opened+1:4)) {
            next unless $rem[$j-1];
            next if $rem[$j-1]==1 && $j!=$closed+1;
            my @next=@rem;
            --$next[$j-1];
            my $newopened=$j>$opened?$j:$opened;
            my $newclosed=$next[$j-1]==0?$j:$closed;
            next if $reference->(\@next,$newopened,$newclosed)->is_zero;
            push @options,[$j,\@next,$newopened,$newclosed];
        }
        die "R67 找不到合法完整詞的下一個字元\n" if !@options;
        my $choice=$last?$options[-1]:$options[0];
        push @word,$choice->[0];
        @rem=@{$choice->[1]};
        ($opened,$closed)=($choice->[2],$choice->[3]);
    }
    die "R67 不完整的 witness\n" if grep {$_!=0} @rem;
    return \@word;
}

sub independent_prefix ($lengths,$prefix,$reference) {
    my @rem=@$lengths;
    my ($opened,$closed)=(0,0);
    for my $j (@$prefix) {
        die "R67 非法 witness 首次序\n" if $j>$opened+1;
        die "R67 非法 witness 末次序\n"
            if !$rem[$j-1] || ($rem[$j-1]==1 && $j!=$closed+1);
        $opened=$j if $j>$opened;
        --$rem[$j-1];
        $closed=$j if !$rem[$j-1];
    }
    return $reference->(\@rem,$opened,$closed);
}

my @cases=(
    [[10,10,10,11],'34837538497713607370'],
    [[11,11,11,11],'2134397833143177403516'],
    [[12,12,12,12],'474042534302340556453992'],
    [[15,14,13,12],'1331903513327335554982512328'],
);
my $int64=Math::BigInt->new('9223372036854775807');
my $checked=0;
for my $case (@cases) {
    my ($sizes,$expected)=@$case;
    my $label=join(',',@$sizes);
    my ($walk,$memo)=independent_counter($sizes);
    my $reference=$walk->([@$sizes],0,0);
    is("$reference",$expected,"$label 獨立後繼遞迴之固定 BigInt");
    cmp_ok($reference,'>',$int64,"$label 嚴格超過 signed int64");
    my $polynomial=countWeavingsPolynomial($sizes);
    is("$polynomial",$expected,"$label 不同狀態表示的插入多項式");
    my $old=Pastafari::WeavingMemoOracle->new($sizes);
    my $fifo=Pastafari::WeavingMemoOracle->new(
        $sizes,{bounded_cache=>1,cache_limit=>16,
                cache_policy=>'fifo',early_final_closed_form=>1}
    );
    my $clock=Pastafari::WeavingMemoOracle->new(
        $sizes,{bounded_cache=>1,cache_limit=>16,
                cache_policy=>'clock',early_final_closed_form=>1}
    );
    my @oracles=($old,$fifo,$clock);
    for my $index (0..2) {
        my $got=$oracles[$index]->count_prefix([]);
        is("$got",$expected,"$label Oracle $index 根計數不變");
        $got->badd(7);
        is(''.$oracles[$index]->count_prefix([]),$expected,
           "$label Oracle $index 回傳值變更不得污染快取");
    }

    # 前兩例各取首末兩個互斥詞，較大兩例只取首詞，
    # 每種路徑固定取根、首次、局部、中部、尾端的真正前綴。
    my @words=(witness_word($sizes,$walk,0));
    push @words,witness_word($sizes,$walk,1) if $checked<2;
    my $n=0;$n+=$_ for @$sizes;
    my %cuts=map {$_=>1} (0,1,2,int($n/2),$n-1,$n);
    for my $word (@words) {
        for my $cut (sort {$a<=>$b} keys %cuts) {
            my @prefix=$cut?@$word[0..$cut-1]:();
            my $correct=independent_prefix($sizes,\@prefix,$walk);
            for my $index (0..2) {
                my $actual=$oracles[$index]->count_prefix(\@prefix);
                is("$actual","$correct",
                   "$label Oracle $index 前綴 $cut 真正合法字序");
            }
        }
    }
    for my $i (1..2) {
        my $diagnostic=$oracles[$i]->diagnostics;
        cmp_ok($diagnostic->{entries},'<=',16,
               "$label 有界快取不超過 16 BigInt 項");
        cmp_ok($diagnostic->{early_closed_forms},'>',0,
               "$label 已實際使用早期末次序閉式");
    }
    ok(scalar(keys %$memo)>1000,
       "$label 獨立模型實際訪問超過一千個狀態");
    $checked++;
}
is($checked,4,'R67 恰好四個新的長窗口，不重用 R66 1..10 全空間');
done_testing;
