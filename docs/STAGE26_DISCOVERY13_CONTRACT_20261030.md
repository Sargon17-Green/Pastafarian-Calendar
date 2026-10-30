# Stage 26 / Discovery 13 — first-answer modulo without rejection

Branch: PowerShell+Tagalog. Predecessor: Stage25 Patch12 Native seal at ae0583ed63744309dacecf812172c63c9661afde.

The historical choice consumes the first answer of the existing SAVE stream and immediately returns 1+((first-1) mod n). It **does not** discard values above floor(M/n)*n. Here M=2^127-1; this stage is defined for 1<=n<=M only. Wide N belongs to a later stage.

The actual Stage25 precursor runs 46 drop writes, 12 post-stir writes, Patch11 drop46 latch and Patch12 corrected positional bowl successor. The Discovery13 entrypoint derives first and ±1 step from the existing final bowl state and caller-supplied seal (1..10); it reads the corrected Patch12 next bowl, never the numeric Stage24 scar. The precursor currently exposes one bowl query (ID 1). It does not modify historical predecessors, canonical names or test-only normative oracle.

Direct deterministic EXPECTED_RED: for n=3,10,97,720, first=floor(M/n)*n+1 and step=-1. Old rank=1 while independent rejection rank=n. Control: first=floor(M/n)*n agrees with rank=n. Independent test-only oracle also compares three real precursor first/step streams with full 58-write histories. Native/CI verification must finish before sealing Stage26; no Patch13 repair or Stage27 opening in this change.

CI: canonical-names-lock.yml verify + native Windows PowerShell 5.1 Stage01, Stage23, Stage24, Stage25 and Stage26 suites. A queued run is not PASS. The stage metadata remains AWAITING until successful evidence is inspected and a subsequent seal records it.
