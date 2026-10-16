use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
my $path=File::Spec->catfile($Bin,'..','.github','workflows','canonical-names-lock.yml');
open my $fh,'<:encoding(UTF-8)',$path or die "Cannot read workflow: $!\n";
local $/; my $yaml=<$fh>; close $fh;
my (@starts,@all,%seen);
while ($yaml =~ /^  canonical-triple-neighbor-batch-(\d+):[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg) {
  my ($start,$body)=(0+$1,$2);
  push @starts,$start;
  my @matches=($body =~ /^\s+for offset in ([0-9 ]+); do[ \t]*$/mg);
  is(scalar(@matches),1,"batch $start has exactly one list");
  next if @matches!=1;
  my @values=map {0+$_} grep {length} split(/\s+/,$matches[0]);
  is_deeply(\@values,[$start..($start+3>42?42:$start+3)],"batch $start consecutive");
  like($body,qr/\[weaving-all-triple-neighbor-ranks\]/,"batch $start gated");
  like($body,qr/timeout-minutes:\s*15\b/,"batch $start outer bound");
  like($body,qr/set -euo pipefail/,"batch $start exit forwarding");
  like($body,qr/--window-offset "\$offset" --rank-set neighbors --seconds 185 --rss-kib 393216/,"batch $start local bounds");
  like($body,qr/CANONICAL_TRIPLE_NEIGHBOR_BATCH status=PASS start=$start count=/,"batch $start completion marker");
  for my $i (@values) {push @all,$i;$seen{$i}++;}
}
is_deeply(\@starts,[0,4,8,12,16,20,24,28,32,36,40],"11 exact batches");
is_deeply(\@all,[0..42],"43 triple-month windows");
is(scalar(keys %seen),43,"43 unique starts");
ok(!(grep {$_!=1} values %seen),"each window once");
done_testing;
