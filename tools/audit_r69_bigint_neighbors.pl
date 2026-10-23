#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Digest::SHA qw(sha512_hex);
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingRank qw(rankWeavingPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

# R69 Stage 1：獨立 DFS 算詞數，另外以實際字元替換加上
# 最大/最小合法尾串計算真正的詞典相鄰者。不能靠同一套
# rank/unrank 互返假象取得綠燈。
my $profile='';
GetOptions('profile=s'=>\$profile) or die "R69 profile 參數無效\n";
my %profiles=(
 a=>[[10,10,10,11],'34837538497713607370'],
 b=>[[11,11,11,11],'2134397833143177403516'],
 c=>[[15,14,13,12],'1331903513327335554982512328'],
);
die "R69 profile 只接受 a/b/c\n" unless exists $profiles{$profile};
my ($lengths,$expected)=@{$profiles{$profile}};
my @source_copy=@$lengths;
my ($m,$days)=(scalar(@$lengths),0);
$days+=$_ for @$lengths;
my %memo;
my ($subtree_checks,$adjacent_checked,$rank_checked)=(0,0,0);
my $count;
$count=sub ($rem,$opened,$closed) {
    my $key=join(',',@$rem).":$opened:$closed";
    return $memo{$key}->copy if exists $memo{$key};
    my $left=0;$left+=$_ for @$rem;
    return $memo{$key}=Math::BigInt->bone if !$left;
    my $sum=Math::BigInt->bzero;
    for my $j (1..($opened<$m?$opened+1:$m)) {
        next unless $rem->[$j-1];
        next if $rem->[$j-1]==1 && $j!=$closed+1;
        my @next=@$rem;
        --$next[$j-1];
        $sum->badd($count->(\@next,$j>$opened?$j:$opened,
                             $next[$j-1]==0?$j:$closed));
    }
    $memo{$key}=$sum->copy;
    return $sum;
};
sub branches ($rem,$opened,$closed) {
    my @out;
    for my $j (1..($opened<$m?$opened+1:$m)) {
        next unless $rem->[$j-1];
        next if $rem->[$j-1]==1 && $j!=$closed+1;
        my @next=@$rem;
        --$next[$j-1];
        my $new_open=$j>$opened?$j:$opened;
        my $new_closed=$next[$j-1]==0?$j:$closed;
        my $ways=$count->(\@next,$new_open,$new_closed);
        next if $ways->is_zero;
        push @out,[$j,\@next,$new_open,$new_closed,$ways];
    }
    return @out;
}
sub unrank_independent ($onebased) {
    my $local=Math::BigInt->new("$onebased");
    my @rem=@$lengths;
    my ($opened,$closed)=(0,0);
    my @word;
    for my $step (1..$days) {
        my @options=branches(\@rem,$opened,$closed);
        my $whole=Math::BigInt->bzero;
        $whole->badd($_->[4]) for @options;
        die "R69 第 $step 日子樹未正確切分母前綴\n"
            if $whole!=$count->(\@rem,$opened,$closed);
        $subtree_checks++;
        my $chosen;
        for my $opt (@options) {
            if ($local<=$opt->[4]) {
                $chosen=$opt;last;
            }
            $local->bsub($opt->[4]);
        }
        die "R69 無法獨立反解 BigInt 排名\n" unless $chosen;
        push @word,$chosen->[0];
        @rem=@{$chosen->[1]};
        ($opened,$closed)=($chosen->[2],$chosen->[3]);
    }
    die "R69 葉節點排名應為一\n" if $local!=1;
    die "R69 獨立完整詞未耗盡月份\n" if grep {$_} @rem;
    return \@word;
}
# 完全不用排名加一來「尋找」下一個詞，而是右起找第一個
# 能提高的合法月份標籤，再以最小合法後綴完成；前詞反向。
sub neighbor ($word,$direction) {
    for (my $pivot=$days-1;$pivot>=0;$pivot--) {
        my @rem=@$lengths;
        my ($opened,$closed)=(0,0);
        my @left;
        for my $i (0..$pivot-1) {
            my $chosen;
            for my $opt (branches(\@rem,$opened,$closed)) {
                if ($opt->[0]==$word->[$i]) {$chosen=$opt;last}
            }
            die "R69 無效參考詞前綴\n" unless $chosen;
            push @left,$chosen->[0];
            @rem=@{$chosen->[1]};
            ($opened,$closed)=($chosen->[2],$chosen->[3]);
        }
        my @possible=grep {
            $direction>0 ? $_->[0]>$word->[$pivot]
                         : $_->[0]<$word->[$pivot]
        } branches(\@rem,$opened,$closed);
        next unless @possible;
        my $chosen=$direction>0?$possible[0]:$possible[-1];
        my @answer=(@left,$chosen->[0]);
        @rem=@{$chosen->[1]};
        ($opened,$closed)=($chosen->[2],$chosen->[3]);
        while (@answer<$days) {
            my @next=branches(\@rem,$opened,$closed);
            die "R69 相鄰者不能完成合法後綴\n" if !@next;
            my $opt=$direction>0?$next[0]:$next[-1];
            push @answer,$opt->[0];
            @rem=@{$opt->[1]};
            ($opened,$closed)=($opt->[2],$opt->[3]);
        }
        die "R69 相鄰者仍有未關閉月份\n" if grep {$_} @rem;
        return \@answer;
    }
    return undef;
}
sub lex_compare ($a,$b) {
    for my $i (0..$#$a) {
        return -1 if $a->[$i]<$b->[$i];
        return 1 if $a->[$i]>$b->[$i];
    }
    return 0;
}
my $N=$count->([@$lengths],0,0);
die "R69 獨立總數固定 BigInt 不符\n" if "$N" ne $expected;
die "R69 位置多項式計數不符\n"
    if countWeavingsPolynomial($lengths)!=$N;
my $int64=Math::BigInt->new('9223372036854775808');
my $middle=$N->copy->bdiv(2);
my @ranks=(
 Math::BigInt->bone,Math::BigInt->new(2),
 Math::BigInt->new(3),
 $int64->copy->bsub(2),$int64->copy->bsub(1),
 $int64->copy,$int64->copy->badd(1),$int64->copy->badd(2),
 $middle->copy->bsub(1),$middle->copy,$middle->copy->badd(1),
 $N->copy->bsub(2),$N->copy->bsub(1),$N->copy,
);
my $digest=sha512_hex("PASTAFARIAN-R69-ADJACENT:$profile");
my $hashed=Math::BigInt->from_hex("0x$digest")->bmod($N)->badd(1);
push @ranks,$hashed;
my %used;
for my $rank (@ranks) {
    die "R69 名次超出 1..N\n" if $rank<1 || $rank>$N;
    die "R69 樣本發生重複\n" if $used{"$rank"}++;
    my $original="$rank";
    my $word=unrank_independent($rank);
    my $native=unrankWeavingPolynomial($lengths,$rank);
    die "R69 非獨立反排名器回傳錯誤詞\n"
        if join(',',@$word) ne join(',',@$native);
    my $forward=rankWeavingPolynomial($lengths,$word);
    die "R69 被測正向排名值不一致\n" if "$forward" ne "$rank";
    $rank_checked++;
    for my $dir (-1,1) {
        my $adjacent=neighbor($word,$dir);
        my $neighbor_rank=$rank->copy->badd($dir);
        if ($neighbor_rank<1 || $neighbor_rank>$N) {
            die "R69 最初／最終詞竟有不存在的相鄰者\n"
                if defined $adjacent;
            next;
        }
        die "R69 合法內部詞沒有相鄰者\n" unless $adjacent;
        die "R69 新詞不符合正確字典序方向\n"
            if lex_compare($word,$adjacent)!=$dir*-1;
        my $expected_word=unrank_independent($neighbor_rank);
        die "R69 真正字元變更得到的鄰詞非下一個全域排名\n"
            if join(',',@$adjacent) ne join(',',@$expected_word);
        my $actual_word=unrankWeavingPolynomial($lengths,$neighbor_rank);
        die "R69 真正鄰詞與被測 unrank 不同\n"
            if join(',',@$adjacent) ne join(',',@$actual_word);
        my $actual_rank=rankWeavingPolynomial($lengths,$adjacent);
        die "R69 真正鄰詞與被測 rank 不同\n"
            if "$actual_rank" ne "$neighbor_rank";
        $adjacent_checked++;
    }
    die "R69 母排名遭到修改\n" if "$rank" ne $original;
    printf "R69_SAMPLE status=PASS profile=%s rank=%s\n",$profile,$original;
}
die "R69 固定應有十五個不同中心排名\n" if $rank_checked!=15;
die "R69 所有可存在的相鄰兩方向皆須核對\n"
    if $adjacent_checked!=28;
die "R69 輸入長度遭到更動\n"
    if join(',',@$lengths) ne join(',',@source_copy);
printf "R69_COMPLETE status=PASS profile=%s centers=%d neighbors=%d prefix_partitions=%d states=%d days=%d\n",
    $profile,$rank_checked,$adjacent_checked,$subtree_checks,scalar(keys %memo),$days;
