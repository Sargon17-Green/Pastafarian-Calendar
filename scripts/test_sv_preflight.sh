#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

cat > "$temp_dir/valid.sv" <<'SV'
module preflight_good;
  integer anchor, guard;
  task automatic op;
    integer anchor;
    begin
      anchor = 1;
    end
  endtask
  function automatic integer echo(input integer n);
    integer guard;
    begin
      guard = n;
      echo = guard;
    end
  endfunction
endmodule
SV

cat > "$temp_dir/duplicate.sv" <<'SV'
module preflight_duplicate;
  integer first, repeated;
  integer repeated, last;
endmodule
SV

cat > "$temp_dir/unbalanced.sv" <<'SV'
module preflight_unbalanced;
  task automatic work;
    integer local_variable;
endmodule
SV

bash scripts/check_sv_declarations.sh "$temp_dir/valid.sv" > "$temp_dir/valid.log"
if bash scripts/check_sv_declarations.sh "$temp_dir/duplicate.sv" > "$temp_dir/duplicate.log" 2>&1; then
  echo 'DUPLICATE_GLOBAL_NOT_DETECTED' >&2
  exit 1
fi
grep -q 'DUPLICATE_MODULE_INTEGER:repeated' "$temp_dir/duplicate.log"

if bash scripts/check_sv_declarations.sh "$temp_dir/unbalanced.sv" > "$temp_dir/unbalanced.log" 2>&1; then
  echo 'UNBALANCED_TASK_NOT_DETECTED' >&2
  exit 1
fi
grep -q 'UNBALANCED_SUBPROGRAM_SCOPES' "$temp_dir/unbalanced.log"

cat > "$temp_dir/reserved.sv" <<'SV'
module preflight_reserved;
  logic signed [383:0] count, dist;
endmodule
SV

if bash scripts/check_sv_declarations.sh "$temp_dir/reserved.sv" > "$temp_dir/reserved.log" 2>&1; then
  echo 'RESERVED_SYSTEMVERILOG_IDENTIFIER_NOT_DETECTED' >&2
  exit 1
fi
grep -q 'RESERVED_IDENTIFIER:dist' "$temp_dir/reserved.log"

cat > "$temp_dir/arrays.sv" <<'SV'
module preflight_legal_arrays;
  logic [383:0] month_dp [0:45][0:4244];
  logic signed [383:0] q, rem_value;
  integer month_lengths [0:44], ordinals [0:16];
endmodule
SV
bash scripts/check_sv_declarations.sh "$temp_dir/arrays.sv" > "$temp_dir/arrays.log"
grep -q 'SV_MODULE_DECLARATION_PREFLIGHT_PASS' "$temp_dir/arrays.log"

bash scripts/check_sv_declarations.sh rtl/*.sv tests/*.sv
echo 'SV_PREFLIGHT_FIVE_FIXTURES_PASS'
