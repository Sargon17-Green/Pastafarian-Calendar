# Stage55 Polish — source-rank, cutlet-partition and canonical-name oracle

**Project:** `PC-BRANCH-MATLAB-POLSKI`
**Scope:** independent Python evidence bridge for the existing completed Native runs. It does not modify production MATLAB code and does not accept Stage55.

## 1. Provenance inputs

`tests/fixtures/stage55_polish_source_native_evidence.json` pins four completed successful run/job/artifact records, including run SHA, job ID, artifact ID/name, downloaded artifact ZIP SHA-256, extracted log SHA-256, and the exact short artifact log:

- Year-5000 month-length composition certificate — run `41110586119`, job `124251655051`, SHA `3be694df96418ebe5eea46423e1e9d2cc2fc188c`.
- Source month-selection rank Native — run `41117203268`, job `124274411337`, SHA `53ddfb99ef34d1f4280f9358c3ac83572d2c7095`.
- Source cutlet/name Native — run `41119621651`, job `124282723095`, SHA `83a83402f01992ae05810c57d1924be17fe20d94`.
- Source cutlet day-length Native — run `41121273668`, job `124287804533`, SHA `fa1a550520c48808bd55666b0a7c24e585031b25`.

The provenance file also pins the Git blob SHA-1 of every relevant source file. The run-specific path sets were compared against the historical run trees; every relevant blob is unchanged at the manifest-capture HEAD `7b37e6a74b351e10e6e229dba5bbd0d7438c458a`. The verifier rechecks all 26 current file blobs before using the Native records. No Native workflow is rerun.

## 2. Independent rederivation of all 45 month lengths

The completed Native source-month run supplies the actual source-stream rank, not a rank inferred from the length fixture:

`21706039149316943527912320903423885398156086660670683714452395033170314294340946533`.

The verifier independently counts the family of 45 integers in `[4,123]` summing to 4,244 in two ways:

1. inclusion-exclusion over the upper bounds;
2. a sliding-window dynamic program.

Both counts must equal the pinned family total. It then un-ranks the **Native source rank** using both suffix-count oracles, and independently ranks both resulting vectors back. Both unranked vectors must agree with each other and with the fixture's 45 values; the comma-joined vector hash must also match the earlier composition certificate. The fixture is therefore the comparison target, not the source of the derived vector.

## 3. Six cutlet segments

The completed Native source-name run records that the production compatibility route selected the filtered partition family and asserted its partition against the fixture. The independent verifier does not call that MATLAB route. It enumerates all positive compositions of eight gate gaps into six parts, filters for the required proper-prefix boundary `4`, and verifies:

- 21 unfiltered positive compositions;
- 15 filtered compositions;
- selected partition `[1,2,1,2,1,1]`, 1-based lexicographic rank `9/15`;
- the eight signed gate gaps from the completed Native log sum into the six independently aggregated lengths `[759,770,503,1163,831,218]`;
- all six lengths sum to 4,244 and match both the Native output and metadata fixture.

The signed gate values themselves remain Native evidence; this Python gate independently validates the partition family and the six segment sums, not a second implementation of the gate-question engine.

## 4. Polish name mapping

The normative oracle is `docs/SOURCE_LANGUAGE_CATALOG.md`, whose canonical-index tables define 17 cutlet names and 47 month names. The verifier parses those tables and compares them to the `cutletText` and `monthText` arrays in `src/+pastafari/sourceLanguageCatalog.m`; the implementation is checked against the document, never used as its own oracle.

The completed Native name run supplies the cutlet and month permutation ranks. A separate Python lexicographic partial-permutation unrank reconstructs the six cutlet indices and 45 month indices. Both must match the fixture. Those indices are then mapped through the normative Markdown tables to the selected Polish names, producing an explicit, auditable name list.

## 5. Output and limitations

The CI artifact contains `report.json`, `run.log`, `source_lock.txt`, the pinned provenance and metadata fixtures, and a complete snapshot of the 26 manifest files with `SHA256SUMS.txt`.

This is a Python/CI oracle, not a new MATLAB Native run. It consumes the source rank and gate-gap values from completed Native artifacts; it does not independently recreate the source sauce or signed gate-question engine. It does independently perform the month-length inverse mapping, partition enumeration and aggregation, permutation unranking, and normative Polish catalog mapping.

`LAST_COMPLETED_STAGE` remains `54`; Stage55 remains open. The next operation is the final audit on the exact live `MATLAB+Polski` HEAD, followed only by the remaining production/Native acceptance gates. No merge, main-branch change, or Stage55 acceptance is authorized by this contract.
