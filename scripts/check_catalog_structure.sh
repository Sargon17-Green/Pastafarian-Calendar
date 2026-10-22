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

# Check the 64-index immutable *concept* witness from the normative
# Scroll independently of the provisional Kalaallisut strings.
test -f catalog/NORMATIVE_NAME_WITNESS.csv
awk -F',' '
FNR == NR {
 if (FNR == 1) {
   if ($1!="kind" || $2!="canonical_index" ||
       $3!="normative_maltese_witness") {
      print "BAD_NORMATIVE_WITNESS_HEADER" > "/dev/stderr"
      exit 1
   }
 } else {
   witness_count++
   key=$1 ":" $2
   if (seen[key]++ || $3=="" || $5!="T" && $5!="W") {
      print "BAD_NORMATIVE_WITNESS",FNR > "/dev/stderr"
      exit 1
   }
   witness[key]=$3
   if ($1=="cutlet" && $5!="T" || $1=="month" && $5!="W") {
      print "BAD_NORMATIVE_SECTION",FNR > "/dev/stderr"
      exit 1
   }
   if ($1=="cutlet" && $2==6 && $4!="fraction" ||
       $1=="month" && $2==7 && $4!="fraction" ||
       $1=="cutlet" && $2==7 && $4!="invented" ||
       $1=="month" && $2==8 && $4!="invented") {
      print "BAD_SEMANTIC_CLASSIFICATION",FNR > "/dev/stderr"
      exit 1
   }
 }
 next
}
FNR==1 {next}
{
 key=$1 ":" $2
 if (!(key in witness)) {
   print "UNMATCHED_SOURCE_LANGUAGE_SLOT",FNR,key > "/dev/stderr"
   exit 1
 }
 rows++
}
END {
 if (witness_count != 64 || rows != 64) {
   print "NORMATIVE_WITNESS_CARDINALITY_FAIL" > "/dev/stderr"
   exit 1
 }
 print "NORMATIVE_INDEX_AND_MEANING_WITNESS_64_PASS"
}' catalog/NORMATIVE_NAME_WITNESS.csv catalog/catalog_review_queue.csv
