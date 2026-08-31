#!/usr/bin/env bash
set -euo pipefail
./build.sh
for n in $(seq 1 14); do ./build/stage55_end_to_end_$n; done
for n in 1 2 3; do ./build/stage55_far_end_to_end_$n; done
./build/stage55_observability_audit
for n in 0 1 2 3; do ./build/stage55_recovery_$n; done
./build/stage55_error_cleanup_audit
./build/stage55_history_audit

./build/stage55_save_edges_audit
./build/stage55_wide_edges_audit
./build/stage55_short_edges_audit
./build/stage55_locale_catalog_audit
