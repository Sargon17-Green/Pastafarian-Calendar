#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test -f catalog/catalog_review_queue.csv
awk -F',' '
NR==1 {
 if (NF != 8 || $1!="catalog" || $2!="canonical_index" ||
     $3!="kalaallisut_candidate" || $4!="native_review_status") {
   print "BAD_CATALOG_HEADER" > "/dev/stderr"; exit 1
 }
 next
}
{
 if (NF != 8) {
   print "BAD_CATALOG_COLUMNS", NR > "/dev/stderr"; exit 1
 }
 if ($1=="cutlet") { cutlet++; if ($2 != cutlet) {
   print "BAD_CUTLET_INDEX", NR > "/dev/stderr"; exit 1
 } }
 else if ($1=="month") { month++; if ($2 != month || cutlet != 17) {
   print "BAD_MONTH_INDEX", NR > "/dev/stderr"; exit 1
 } }
 else { print "BAD_CATALOG_TYPE", NR > "/dev/stderr"; exit 1 }
 if ($4 != "PENDING" && $4 != "APPROVED" && $4 != "REJECTED") {
   print "BAD_REVIEW_STATUS", NR > "/dev/stderr"; exit 1
 }
 if ($4 == "APPROVED" &&
     ($3=="" || $5=="" || $6=="" || $7=="" || $8=="")) {
   print "APPROVAL_MISSING_EVIDENCE", NR > "/dev/stderr"; exit 1
 }
}
END {
 if (NR != 65 || cutlet != 17 || month != 47) {
   print "CATALOG_CARDINALITY_ERROR", NR,cutlet,month > "/dev/stderr"
   exit 1
 }
 print "CATALOG_STRUCTURE_17_47_PASS"
}' catalog/catalog_review_queue.csv
