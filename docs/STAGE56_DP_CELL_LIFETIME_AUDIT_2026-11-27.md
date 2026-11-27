# Stage56 DP cell lifetime audit (2026-11-27)
PC-BRANCH-PHP-MALAY. Analysis only, based on current HEAD c68c56c604240d610d2ce4f2945d2b48b1dcb76b, source blob 7e844369cbca2ae25c68afc96ce90bbd7641405c, ranker and provider read from HEAD. No production or acceptance change.

## Evidence and method
Historical artifact 15157797537, run 45900520391, branch e8840ce832af2079ce46901cd15512eeda5c2958 (same stride8 policy); ZIP SHA256 e33910c24db19d0168f51abda15f945c78e1688fd974b5d5cc0201353fdd0c17, 81 CRC and exact 80-file SHA256 manifest verified independently; project and branch match. Not a result on current SHA. Join DP rebuild start timestamps to stage-start timestamps, account only emitted row records (q=1..q_max), check completed rebuild planned/end sums and active+checkpoint <=8. For each fixed year, row index and engine ID keep the maximum prior emitted q_max; repeated cells = min(current cells, prior q_max). Cross-engine comparison is meaningful here because the source-bound harness uses structure.monthLengths from the provider. IDs are process-local, not global identities.

|year|stage|engine|rebuilds completed/started|cells emitted|repeated same engine|completed DP seconds|
|---|---|---:|---:|---:|---:|---:|
|4999|provider count|25882|1/1|67743|0|98.452|
|4999|provider unrank|25882|7/7|80988|80988|114.187|
|4999|roundtrip count|9|1/1|67743|0|98.607|
|4999|roundtrip rank|9|7/7|80988|80988|114.066|
|4999|roundtrip unrank|9|8/8|85352|85352|125.334|
|5000|provider count|74463|1/1|97394|0|126.280|
|5000|provider unrank|74463|15/15|137838|137838|180.705|
|5000|roundtrip count|8|1/1|97394|0|126.229|
|5000|roundtrip rank|8|15/15|137838|137838|180.759|
|5000|roundtrip unrank (partial)|8|4/5|18205|18205|47.719|
|5001|provider count|66134|1/1|124263|0|287.013|
|5001|provider unrank (partial stage)|66134|16/16|179253|179253|418.171|

Exits 0/124/124; all unrank/rank repeats in emitted rows are identical mathematical cells (not necessarily retained), and roundtrip initial counts repeat 67743/97394 cells across distinct engines. Do not conflate completed rebuilds with completed stage. Do not eliminate fresh roundtrip engine or change QA assertions to claim speedup.

## Exact independent integer model
Initial count builds widths Q_0=L_0 and Q_i=Q_(i-1)+L_i-1. Recover original lengths from initial full-rebuild widths. For fixed vector L, terminal F_(n-1)(q)=1; F_i(0)=0 for nonterminal, F_i(q)=sum_{r=0}^{q-1} binom(L_(i+1)+r-2,r)*F_(i+1)(L_(i+1)+r). Therefore a cell is invariant across rank, count, and unrank, regardless of word, and every requested width is bounded by the initial count widths. An offline Python integer model evaluated each coefficient independently with math.comb, rolled one row at a time, and matched the full provider choice count for all three years. No PHP execution or timing claim. Measured minimal binary payload (unsigned integer bytes plus 4-byte length per cell; nonterminal rows only, not PHP allocation or actual file size):
|year|months|days|count digits|all row payload bytes|max row bytes|
|---|---:|---:|---:|---:|---:|
|4999|34|4126|6196|62866571|2792870|
|5000|45|4244|6765|94435164|3151498|
|5001|46|5567|9077|167274798|5482652|

Reproduction: verify ZIP digest, CRC, manifest and identity; parse each YEAR.json.dp.jsonl and YEAR.json.profile.jsonl, group start/row/end by ID, join by timestamps, check row counts and per-stage overlap as described. Derive L from q_max of rebuild 1, use Python int and math.comb for the above recurrence; compare total to month_weaving_choice end.count, compute sum(4+(value.bit_length()+7)//8) per nonterminal row. This is an independent arithmetic audit of the logged count, not an independent calendar or PHP rank oracle.

## Next bounded experiment (not implemented)
Prefer per-engine immutable scratch row store over changing stride again. Count emits complete nonterminal rows to an exclusive, private, bounded temporary file, with explicit version, vector identity, row index/width, exact unsigned limb encoding and checked offsets/lengths. Use a small row directory; decode a requested row/prefix into existing active slots, evict before load, no second unbounded decoded table. Keep existing fresh QA engine isolated; never share its cache with provider. Initial upper-bound candidate 256 MiB scratch per engine, verify actual encoded size before accepting; binary model is not a guarantee. Fail closed on invalid/truncated data, budget violation, or I/O failure, clean temporary files on success/failure, no reusable persisted calendar state. No increase to eight retained DP rows, PHP 512M, or 900s. Explicitly account transient decode buffers and process allocator peak, not just row counters. First run isolated synthetic 25/45/46 vectors, independent expected counts and endpoints/midpoints plus invalid/truncated/foreign-vector scratch negative tests; compare every small vector cell against math.comb recurrence, verify identical rank/unrank and unchanged profiling semantics. Only then measure actual years against stride8 baseline on exact SHA; require no peak regression and material elapsed improvement, all existing B4 and real-year assertions unchanged. If scratch cannot meet caps or is not faster, reject it; do not retry stride9 unchanged. No PATCH22/PATCH23/main/merge/publication. Raw Sauce remains FAIL; Stage56 NOT ACCEPTED.

CI discovery limitation: connector combined statuses empty, commit-workflow query limited to pull-request runs and returned none; automatic push for rollback SHA not established. No manual dispatch.
