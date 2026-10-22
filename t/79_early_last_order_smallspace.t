use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;

# 以獨立且不帶快取的合法字序枚舉，核對「前三月已開啟、
# 第四月尚未首次出現」時，末次序閉式取代 DFS 之等價性。
# 僅在小型四月份枚舉所有可到達前綴，絕不依賴受測閉式。
sub brute_suffix ($r,$opened,$closed) {
    my $left=0; $left+=$_ for @$r;
    return 1 if !$left;
    my $ways=0;
    for my $j (1..($opened<4 ? $opened+1 : 4)) {
        next unless $r->[$j-1];
        next if $r->[$j-1]==1 && $j!=$closed+1;
        my @next=@$r;
        $next[$j-1]--;
        $ways+=brute_suffix(
            \@next,$j>$opened?$j:$opened,
            !$next[$j-1]?$j:$closed
        );
    }
    return $ways;
}
my @vectors=(
    [2,2,2,2],[3,2,3,2],[2,3,2,3],[3,3,2,2],[2,2,3,3]
);
my $total_states=0;
for my $lengths (@vectors) {
    my $old=Pastafari::WeavingMemoOracle->new($lengths);
    my $optimized=Pastafari::WeavingMemoOracle->new(
        $lengths,{
            bounded_cache=>1,cache_limit=>200000,
            cache_policy=>'clock',early_final_closed_form=>1
        }
    );
    my $label=join(',',@$lengths);
    my %seen;
    my @todo=([[ ],[@$lengths],0,0]);
    my $compared=0;
    while (@todo) {
        my ($prefix,$remaining,$opened,$closed)=@{shift @todo};
        my $state=join(',',@$remaining)."|$opened|$closed";
        next if $seen{$state}++;
        if ($opened==3) {
            is(''.$optimized->count_prefix($prefix),
               ''.Math::BigInt->new(brute_suffix($remaining,$opened,$closed)),
               "$label：前三月已開、第四月待開之精確後綴");
            is(''.$optimized->count_prefix($prefix),
               ''.$old->count_prefix($prefix),
               "$label：新閉式和歷史完整 DFS 比對");
            $compared++;
        }
        for my $j (1..($opened<4?$opened+1:4)) {
            next unless $remaining->[$j-1];
            next if $remaining->[$j-1]==1 && $j!=$closed+1;
            my @next=@$remaining;
            $next[$j-1]--;
            push @todo,[
                [@$prefix,$j],\@next,($j>$opened?$j:$opened),
                (!$next[$j-1]?$j:$closed)
            ];
        }
    }
    cmp_ok($compared,'>',0,"$label：已實際觸及未開第四月的合法狀態");
    $total_states+=$compared;
    my $diag=$optimized->diagnostics;
    is($diag->{early_final_closed_form},1,
       "$label：只有 opt-in 的私有 QA 對閉式啟用");
    cmp_ok($diag->{early_closed_forms},'>',0,
       "$label：提前末次序閉式有真實呼叫");
    cmp_ok($diag->{entries},'<=',200000,
       "$label：原有 200000 同時 BigInt 項上限未改");
    is($old->diagnostics->{early_closed_forms},0,
       "$label：未 opt-in 的歷史 Oracle 完全不變");
}
cmp_ok($total_states,'>',40,
       '跨多組獨立小空間的提前閉式可到達狀態足夠多');
for my $bad (
    {early_final_closed_form=>1},
    {bounded_cache=>1,early_final_closed_form=>2},
    {bounded_cache=>1,early_final_closed_form=>'unknown'},
    {bounded_cache=>1,early_final_closed_form=>1,cache_limit=>200001},
    {bounded_cache=>1,early_final_closed_form=>1,unknown_setting=>1},
) {
    my $ok=eval {
        Pastafari::WeavingMemoOracle->new([2,2,2,2],$bad);
        1;
    };
    ok(!$ok,'非法、未啟用或超界的提前閉式選項必須拒絕');
}
for my $wrong_months ([2,3,2],[2,2,2,2,2]) {
    my $ok=eval {
        Pastafari::WeavingMemoOracle->new(
            $wrong_months,{bounded_cache=>1,early_final_closed_form=>1}
        );
        1;
    };
    ok(!$ok,'提前閉式只允許明確的四月份 QA');
}
done_testing;
