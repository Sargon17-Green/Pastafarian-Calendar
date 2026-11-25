#!/usr/bin/env bash
set -euo pipefail
CASE_ID="${1:-}"
case "$CASE_ID" in
  prev_3_prev_last|next_3_next_middle) ;;
  *) echo "invalid case_id: $CASE_ID" >&2; exit 2 ;;
esac
EVIDENCE=timeout-evidence
PG_NAME=tamil-s25-stone-reuse
BASELINE_SHA=452fa839f8116ec5d55791365308099b9eb8cd36
PG_IMAGE=postgres:17.12
mkdir -p "$EVIDENCE/baseline"
cleanup() {
  docker logs "$PG_NAME" > "$EVIDENCE/postgres-container.log" 2>&1 || true
  docker rm -f "$PG_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

test "$(git rev-parse HEAD)" = "$GITHUB_SHA"
test "$GITHUB_REF_NAME" = 'SQL+தமிழ்'
test "$(git rev-parse "${GITHUB_SHA}^")" = "$BASELINE_SHA"
mapfile -t changed_prod < <(git diff --name-only "$BASELINE_SHA" "$GITHUB_SHA" -- sql \
  | grep -E '^sql/[0-9]{2}_.*\.sql$' | sort)
test "${#changed_prod[@]}" -eq 2
test "${changed_prod[0]}" = sql/06_stage02_visible_drops.sql
test "${changed_prod[1]}" = sql/08_stage02_bowl_round.sql

while read -r expected path; do test "$(git hash-object "$path")" = "$expected"; done < sql/test/181_source_locks.txt
test "$(wc -l < sql/test/181_source_locks.txt)" -eq 29
while read -r expected path; do test "$(git hash-object "$path")" = "$expected"; done < sql/test/181_test_locks.txt
test "$(wc -l < sql/test/181_test_locks.txt)" -eq 5

git cat-file -e "$BASELINE_SHA^{commit}"
git show "$BASELINE_SHA:sql/06_stage02_visible_drops.sql" > "$EVIDENCE/baseline/06_stage02_visible_drops.sql"
git show "$BASELINE_SHA:sql/08_stage02_bowl_round.sql" > "$EVIDENCE/baseline/08_stage02_bowl_round.sql"
test "$(git hash-object "$EVIDENCE/baseline/06_stage02_visible_drops.sql")" = 2cc67c27b1f5e0c2f22537e479e42956a5711b9e
test "$(git hash-object "$EVIDENCE/baseline/08_stage02_bowl_round.sql")" = 68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6
cat sql/test/181_legacy_visible_drops.sql sql/test/181_legacy_bowl_round.sql \
  "sql/test/181_${CASE_ID}.sql" > "$EVIDENCE/test.sql"

case "$CASE_ID" in
  prev_3_prev_last)
    cat > "$EVIDENCE/manifest.json" <<'JSON'
{"project_id":"PC-BRANCH-SQL-TAMIL","case_id":"prev_3_prev_last","calculation_day":-15055671,"target_day":-15070673,"expected":{"year_number":4996,"cutlet_name":"சாம்பல்","day_in_cutlet":213,"month_name":"மாதுளை","day_in_month":115},"component_equivalence_offsets":82,"component_equivalence_visible_drops":3772,"component_equivalence_bowl_rounds":3772,"legacy_visible_drop_stone_value_calls_per_drop":16,"legacy_bowl_round_stone_value_calls_per_round":9,"expected_legacy_stone_value_calls":94300,"expected_optimized_stone_state_calls":7544,"fixture_git_blob":"21f38cd280498070b08b6c3074780f1742c36957","fixture_source_commit":"1ddaef9a315f83402ececaf4dc31f96dbdd051bd","baseline_source_commit":"452fa839f8116ec5d55791365308099b9eb8cd36","baseline_visible_file_blob":"2cc67c27b1f5e0c2f22537e479e42956a5711b9e","baseline_bowl_round_file_blob":"68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6","statement_timeout_seconds":720,"watchdog_seconds":750,"job_timeout_minutes":15,"full_slice25":"NOT_ACCEPTED"}
JSON
    ;;
  next_3_next_middle)
    cat > "$EVIDENCE/manifest.json" <<'JSON'
{"project_id":"PC-BRANCH-SQL-TAMIL","case_id":"next_3_next_middle","calculation_day":-15055671,"target_day":-15037302,"expected":{"year_number":5004,"cutlet_name":"கொத்து","day_in_cutlet":1703,"month_name":"நினவே","day_in_month":61},"component_equivalence_offsets":76,"component_equivalence_visible_drops":3496,"component_equivalence_bowl_rounds":3496,"legacy_visible_drop_stone_value_calls_per_drop":16,"legacy_bowl_round_stone_value_calls_per_round":9,"expected_legacy_stone_value_calls":87400,"expected_optimized_stone_state_calls":6992,"fixture_git_blob":"21f38cd280498070b08b6c3074780f1742c36957","fixture_source_commit":"1ddaef9a315f83402ececaf4dc31f96dbdd051bd","baseline_source_commit":"452fa839f8116ec5d55791365308099b9eb8cd36","baseline_visible_file_blob":"2cc67c27b1f5e0c2f22537e479e42956a5711b9e","baseline_bowl_round_file_blob":"68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6","statement_timeout_seconds":720,"watchdog_seconds":750,"job_timeout_minutes":15,"full_slice25":"NOT_ACCEPTED"}
JSON
    ;;
esac
printf 'PROJECT_ID=PC-BRANCH-SQL-TAMIL\nGITHUB_SHA=%s\nBRANCH=%s\nRUN_ID=%s\nCASE=%s\nPG_IMAGE=%s\nSTATEMENT_TIMEOUT_SECONDS=720\nWATCHDOG_SECONDS=750\nJOB_TIMEOUT_MINUTES=15\n' \
  "$GITHUB_SHA" "$GITHUB_REF_NAME" "$GITHUB_RUN_ID" "$CASE_ID" "$PG_IMAGE" \
  > "$EVIDENCE/versions.txt"

: > "$EVIDENCE/production-blobs.txt"
for i in $(seq -w 0 27); do
  mapfile -t found < <(find sql -maxdepth 1 -type f -name "$i"'_*.sql')
  test "${#found[@]}" -eq 1
  printf '%s  %s\n' "$(git hash-object "${found[0]}")" "${found[0]}" >> "$EVIDENCE/production-blobs.txt"
done
test "$(wc -l < "$EVIDENCE/production-blobs.txt")" -eq 28
sha256sum \
  sql/test/181_source_locks.txt sql/test/181_test_locks.txt \
  sql/test/181_legacy_visible_drops.sql sql/test/181_legacy_bowl_round.sql \
  sql/test/181_prev_3_prev_last.sql sql/test/181_next_3_next_middle.sql \
  sql/test/run_181_stage25_bowl_round_stone_reuse.sh \
  .github/workflows/sql-tamil-stage02-slice25-bowl-round-stone-reuse.yml \
  sql/00_schema.sql sql/01_source_language_catalog.sql \
  sql/02_monster_bootstrap.sql sql/03_stage02_production_core.sql \
  sql/04_stage02_stone_states.sql sql/05_stage02_hidden_drop.sql \
  sql/06_stage02_visible_drops.sql sql/07_stage02_bowls.sql \
  sql/08_stage02_bowl_round.sql sql/09_stage02_post_stir_round.sql \
  sql/10_stage02_sauce.sql sql/11_stage02_answer_stream.sql \
  sql/12_stage02_choose_rank.sql sql/13_stage02_gate_gaps.sql \
  sql/14_stage02_gate_day_selector.sql sql/15_stage02_year5000_gate_candidates.sql \
  sql/16_stage02_year5000.sql sql/17_stage02_adjacent_year_navigation.sql \
  sql/18_stage02_target_year_navigation.sql sql/19_stage02_cutlet_count.sql \
  sql/20_stage02_cutlet_partition.sql sql/21_stage02_cutlet_names.sql \
  sql/22_stage02_month_count.sql sql/23_stage02_month_lengths.sql \
  sql/24_stage02_month_weaving.sql sql/25_stage02_month_names.sql \
  sql/26_stage02_year_structure.sql sql/27_stage02_calendar_date.sql \
  sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl \
  "$EVIDENCE"/*.sql "$EVIDENCE"/baseline/*.sql \
  "$EVIDENCE"/manifest.json "$EVIDENCE"/versions.txt "$EVIDENCE"/production-blobs.txt \
  > "$EVIDENCE/source-sha256.txt"

docker run -d --name "$PG_NAME" --network none \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -v "$GITHUB_WORKSPACE:/work:ro" "$PG_IMAGE" >/dev/null
ready=0
for _ in $(seq 1 45); do
  if docker exec -u postgres "$PG_NAME" pg_isready -q -U postgres; then ready=1; break; fi
  sleep 2
done
if [ "$ready" -ne 1 ]; then echo 'PG_READY=FAIL' > "$EVIDENCE/status.txt"; exit 1; fi
docker exec -u postgres "$PG_NAME" postgres --version | tee -a "$EVIDENCE/versions.txt"
docker exec -u postgres "$PG_NAME" psql --version | tee -a "$EVIDENCE/versions.txt"

args=()
for i in $(seq -w 0 27); do
  mapfile -t found < <(find sql -maxdepth 1 -type f -name "$i"'_*.sql')
  test "${#found[@]}" -eq 1
  args+=(-f "/work/${found[0]}")
done
test "${#args[@]}" -eq 56
set +e
docker exec -u postgres "$PG_NAME" psql -At -X -v ON_ERROR_STOP=1 -U postgres -d postgres \
  "${args[@]}" > "$EVIDENCE/production-load.log" 2>&1
LOAD_EXIT=$?
set -e
printf 'LOAD_PSQL_EXIT=%s\n' "$LOAD_EXIT" > "$EVIDENCE/load-exit.txt"
if [ "$LOAD_EXIT" -ne 0 ]; then
  echo "RESULT=NOT_ACCEPTED; production_load_exit=$LOAD_EXIT" > "$EVIDENCE/status.txt"
  exit_code=1
else
  docker exec -u postgres "$PG_NAME" psql -At -X -v ON_ERROR_STOP=1 -U postgres -d postgres \
    -c "SELECT 1 / ((to_regnamespace('pastafari_sql_tamil') IS NOT NULL AND to_regprocedure('pastafari_sql_tamil.calendar_date(numeric,numeric)') IS NOT NULL)::integer)" \
    > "$EVIDENCE/schema-check.log" 2>&1
  set +e
  timeout --signal=TERM --kill-after=15s 750s \
    docker exec -u postgres "$PG_NAME" psql -At -X -v ON_ERROR_STOP=1 -U postgres -d postgres \
    -f /work/timeout-evidence/test.sql > "$EVIDENCE/psql.log" 2>&1
  PSQL_EXIT=$?
  set -e
  printf 'PSQL_EXIT=%s\nEND_UTC=%s\n' "$PSQL_EXIT" "$(date -u +%FT%TZ)" > "$EVIDENCE/exit.txt"
  if [ "$PSQL_EXIT" -eq 0 ] \
    && grep -q "SLICE25_VISIBLE_DROPS_LEGACY_EQUIVALENCE=PASS; CASE=$CASE_ID" "$EVIDENCE/psql.log" \
    && grep -q "SLICE25_BOWL_ROUND_LEGACY_EQUIVALENCE=PASS; CASE=$CASE_ID" "$EVIDENCE/psql.log" \
    && grep -q "SLICE25_TIMEOUT_CASE_ORACLE=PASS; CASE=$CASE_ID; FIELDS=5/5" "$EVIDENCE/psql.log" \
    && grep -q 'SLICE25_FULL_SLICE=NOT_ACCEPTED' "$EVIDENCE/psql.log"; then
    echo 'RESULT=CASE_NATIVE_ORACLE_AND_COMPONENT_EQUIVALENCE_PASS; FULL_SLICE25=NOT_ACCEPTED' > "$EVIDENCE/status.txt"
    exit_code=0
  else
    echo "RESULT=NOT_ACCEPTED; psql_or_marker_failure; exit=$PSQL_EXIT" > "$EVIDENCE/status.txt"
    tail -100 "$EVIDENCE/psql.log" || true
    exit_code=1
  fi
fi
cleanup
trap - EXIT
find "$EVIDENCE" -type f ! -name artifact-files-sha256.txt -print0 \
  | sort -z | xargs -0 -r sha256sum > "$EVIDENCE/artifact-files-sha256.txt"
exit "$exit_code"
