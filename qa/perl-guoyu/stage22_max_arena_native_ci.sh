#!/usr/bin/env bash
# PC-BRANCH-PERL-GUOYU: source-locked, isolated Stage22 12/52 witness.
set -Eeuo pipefail
cd "$(git rev-parse --show-toplevel)"
LOG=logs/stage22-maxarena
mkdir -p "$LOG"
printf 'STAGE22_MAX_ARENA_NATIVE=FAIL\n' > "$LOG/result.txt"
trap 'rc=$?; printf "%s\n" "$rc" > "$LOG/harness.exit"; exit "$rc"' EXIT
PRODUCER=lib/Pastafari/Monster/WeavingPrimitive.pm
ORACLE=qa/perl-guoyu/stage22_max_arena_forward_oracle.cpp
EXPECTED_PRODUCER=4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6
EXPECTED_ORACLE=993fd19509f970f4467eece681cc017e3d831959
EXPECTED_COUNT=214592873590014046152008360029870
MIDDLE=107296436795007023076004180014935
{
  printf 'PROJECT_ID=PC-BRANCH-PERL-GUOYU\n'
  printf 'BRANCH=%s\n' "$GITHUB_REF_NAME"
  printf 'HEAD=%s\n' "$(git rev-parse HEAD)"
  printf 'GITHUB_SHA=%s\n' "$GITHUB_SHA"
  printf 'PRODUCER_BLOB=%s\n' "$(git rev-parse "HEAD:$PRODUCER")"
  printf 'ORACLE_BLOB=%s\n' "$(git rev-parse "HEAD:$ORACLE")"
  printf 'PROFILE=3,4,4,5,5,5,5,5,5,4,4,3\n'
  printf 'EXPECTED_COUNT=%s\n' "$EXPECTED_COUNT"
  uname -srm
  perl -e 'die "Perl 5.40+ required\n" if $] < 5.040; print "PERL=$^V\n";'
  g++ --version | head -n 1
} > "$LOG/identity.txt"
test "$(git rev-parse "HEAD:$PRODUCER")" = "$EXPECTED_PRODUCER"
test "$(git rev-parse "HEAD:$ORACLE")" = "$EXPECTED_ORACLE"
test "$GITHUB_SHA" = "$(git rev-parse HEAD)"
test "$GITHUB_REF_NAME" = 'Perl+國語'
sha256sum "$PRODUCER" "$ORACLE" > "$LOG/source.sha256"
if [[ ! -r /usr/include/boost/multiprecision/cpp_int.hpp ]]; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq libboost-dev
fi
run_case() {
  local name="$1" status=0 rss
  shift
  set +e
  (
    ulimit -v 393216 || exit 88
    ulimit -c 0 || exit 89
    /usr/bin/time -f 'wall_seconds=%e\nmax_rss_kib=%M' -o "$LOG/$name.time" \
      timeout --signal=TERM --kill-after=5s 120s "$@" \
      > "$LOG/$name.stdout" 2> "$LOG/$name.stderr"
  ) || status=$?
  set -e
  printf '%s\n' "$status" > "$LOG/$name.exit"
  test "$status" -eq 0
  grep -q '^wall_seconds=' "$LOG/$name.time"
  rss="$(sed -n 's/^max_rss_kib=//p' "$LOG/$name.time")"
  [[ "$rss" =~ ^[0-9]+$ ]]
  test "$rss" -le 393216
}
run_case compile g++ -std=c++17 -O2 -Wall -Wextra -Werror "$ORACLE" -o "$LOG/oracle"
run_case perl_syntax perl -Ilib -c "$PRODUCER"
grep -Fq 'syntax OK' "$LOG/perl_syntax.stderr"
run_case cpp_count "$LOG/oracle"
test "$(cat "$LOG/cpp_count.stdout")" = "$EXPECTED_COUNT"
grep -Fq 'profile_months=12 days=52 capacity=4021367' "$LOG/cpp_count.stderr"
run_case perl_count perl -Ilib -MPastafari::Monster::WeavingPrimitive=count_weavings -e \
  'my @p=(3,4,4,5,5,5,5,5,5,4,4,3); print count_weavings(\@p),"\n";'
test "$(cat "$LOG/perl_count.stdout")" = "$EXPECTED_COUNT"
test ! -s "$LOG/perl_count.stderr"
for name in first middle last; do
  case "$name" in
    first) rank=1 ;;
    middle) rank="$MIDDLE" ;;
    last) rank="$EXPECTED_COUNT" ;;
  esac
  run_case "perl_unrank_$name" perl -Ilib \
    -MPastafari::Monster::WeavingPrimitive=unrank_weaving -e \
    'my @p=(3,4,4,5,5,5,5,5,5,4,4,3); my $w=unrank_weaving(\@p,$ARGV[0]); print join(",",@$w),"\n";' "$rank"
  test ! -s "$LOG/perl_unrank_$name.stderr"
  cp "$LOG/perl_unrank_$name.stdout" "$LOG/$name.csv"
  test "$(awk -F, 'NR==1 {print NF}' "$LOG/$name.csv")" -eq 52
  run_case "perl_rank_$name" perl -Ilib \
    -MPastafari::Monster::WeavingPrimitive=rank_weaving -e \
    'my @p=(3,4,4,5,5,5,5,5,5,4,4,3); open my $fh,"<",$ARGV[0] or die $!; my $s=<$fh>; chomp $s; my @w=split /,/, $s; print rank_weaving(\@p,\@w),"\n";' "$LOG/$name.csv"
  test ! -s "$LOG/perl_rank_$name.stderr"
  test "$(cat "$LOG/perl_rank_$name.stdout")" = "$rank"
  run_case "cpp_lex_$name" "$LOG/oracle" "$LOG/$name.csv"
  test "$(head -n 1 "$LOG/cpp_lex_$name.stdout")" = "$EXPECTED_COUNT"
  grep -Fxq "lexical_ordinal=$rank" "$LOG/cpp_lex_$name.stdout"
  grep -Fq 'profile_months=12 days=52 capacity=4021367' "$LOG/cpp_lex_$name.stderr"
done
printf 'STAGE22_MAX_ARENA_NATIVE=PASS\n' > "$LOG/result.txt"
printf 'RESULT=PASS\nPRODUCER_BLOB=%s\nORACLE_BLOB=%s\nCOUNT=%s\n' \
  "$EXPECTED_PRODUCER" "$EXPECTED_ORACLE" "$EXPECTED_COUNT" > "$LOG/summary.txt"
cat "$LOG/summary.txt"
