#!/usr/bin/env bash
set -euo pipefail
if (( $# == 0 )); then echo 'NO_SOURCE_FILES' >&2; exit 2; fi
for file in "$@"; do
  test -f "$file" || { echo "MISSING_SOURCE:$file" >&2; exit 2; }
  awk '
    BEGIN {
      split("dist rand randc constraint solve soft inside matches before throughout within bins cross covergroup clocking",words," ")
      for (i in words) reserved[words[i]]=1
    }
    /^[[:space:]]*(task|function)([[:space:]]|$)/ { scope++; next }
    /^[[:space:]]*(endtask|endfunction)([[:space:]]|$)/ {
      if (scope == 0) { print FILENAME ":UNMATCHED_END" > "/dev/stderr"; bad=1 }
      else scope--
      next
    }
    scope == 0 && /^[[:space:]]*(integer|logic)[[:space:]]/ {
      rest=$0
      sub(/^[[:space:]]+/,"",rest)
      type=rest
      sub(/[[:space:]].*/,"",type)
      sub(/^[^[:space:]]+[[:space:]]+/,"",rest)
      sub(/;.*/,"",rest)
      sub(/^[[:space:]]*(signed|unsigned)[[:space:]]+/,"",rest)
      sub(/^[[:space:]]*\[[^]]+\][[:space:]]*/,"",rest)
      count=split(rest, fields, ",")
      for (i=1; i<=count; i++) {
        item=fields[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "",item)
        sub(/[[:space:]]*\[.*/,"",item)
        sub(/[[:space:]]*=.*/,"",item)
        if (item !~ /^[A-Za-z_][A-Za-z0-9_$]*$/) {
          print FILENAME ":UNSUPPORTED_DECLARATION:" item > "/dev/stderr"; bad=1
        } else if (reserved[item]) {
          print FILENAME ":RESERVED_IDENTIFIER:" item > "/dev/stderr"; bad=1
        } else if (seen[item]++) {
          print FILENAME ":DUPLICATE_MODULE_" toupper(type) ":" item > "/dev/stderr"; bad=1
        }
      }
    }
    END {
      if (scope != 0) { print FILENAME ":UNBALANCED_SUBPROGRAM_SCOPES" > "/dev/stderr"; bad=1 }
      if (bad) exit 1
    }
  ' "$file"
done
echo "SV_MODULE_DECLARATION_PREFLIGHT_PASS files=$#"
