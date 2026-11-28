# Stage44 exact preflight adjudication and phase routing audit — 2026-11-28

Source: 608a4578dc3e726ce1db64cb2b5cfb184b183225. Run 46124384509, attempt 1, push on PowerShell+Tagalog, completed/success; 18/18 jobs. The 20 unexpired artifact API records bind this exact SHA.

- Job 140915611979: direct boundary 8/0 (exact LF, uniform CRLF accepted; BOM, extra blank line, duplicate pointer and three activated profiles rejected); classifier 240/0 PASS_SHAPE_ONLY; Stage43 2215/0. Artifact 15254657702 SHA256 a8840ded0073886c4b1639869da8dd78a8d0661131c704d697c133df0673916d; 15254679667 SHA256 4dd0cb02ec006f80f51789cfc70367ebebf85f53ee70526b546a3235c4199cba.
- Job 140915612055: numerical preflight 5027/0; source/oracle contexts 72/72, endpoints 720, rectangles 320, guards 67. Artifact 15254549299 SHA256 6cb57226e819d3b535968f82c82b16aeff820a6ef5377bc1839287ad4e0b3327.
- Job 140915612016: Stage23 finalizer twice already finalized, unchanged SHA256 EF31C98A432EBF68275014FDBAC26EE3927E5C5A5B1E0829A20779EA968D18AC; artifact 15254463336 SHA256 a6e09bd9b3ce8a190aedb9eb7ac37337b8c2367b73a4e5c302c2edc3460e4043. Canonical verify job 140915611950 succeeded.
- Upload log digests match API digests for these four artifacts; ZIP bytes not independently rehashed. This closes the exact checkout-byte repair CI, not Stage44 activation.

## Static pointer audit on the exact source
Stage01.Tests.ps1:94–96 uses a raw first-match CURRENT_STAGE regex before choosing the future-name exclusions. Duplicate pointers can be ambiguous at this decision point even though subsequent strict tests exist. Replace with a strict parsed snapshot, reject missing/duplicate/malformed pointer before any decision; preserve historical threshold 23 and test 22/23/43/44 plus invalid cases.

canonical-names-lock.yml has 12 raw metadata reads at lines 44,376,446,515,565,626,691,755,809,867,925,984. These are audit candidates, not 12 proven defects: inspect each read's relationship to the compatibility gateway and replace direct lifecycle decisions with validated values. The final reusable Stage44 job (1154–1160) is unconditional on phase for branch pushes. Its called workflow checks the pinned Stage43 Git blob, and Assert-Stage44PreflightMetadata refuses all activated profiles. Thus changing CURRENT_STAGE to 44 now would conflict with the current preflight entry point.

## Proposed phase output contract, not yet wired
Single byte snapshot; strict classifier precedes route output. Frozen Stage43 exact LF or uniform CRLF -> RESEARCH_PREFLIGHT; valid STAGE44_PENDING_SHAPE_ONLY -> IMPLEMENTATION_CANDIDATE; valid STAGE44_IMPLEMENTING_SHAPE_ONLY -> NATIVE_EVIDENCE_CANDIDATE; valid STAGE44_SEALED_SHAPE_ONLY -> SEAL_RECHECK_CANDIDATE. All other states fail closed with no route output. Candidate output never authenticates provenance: bind actual exact run/job/artifact/SHA through the existing evidence validation separately. Preserve Stage43 predecessor compatibility as a separate profile. Test each route, reject altered bytes, duplicate keys, malformed UTF8, unrecognized profile, and mismatched evidence; ensure no activated shape can call the frozen-only entry point. Gate outputs and dedicated workflow routing must be verified on unchanged Stage43 metadata before any PENDING_NATIVE transition. No lifecycle or production change made in this audit.


## Revalidation against the live branch (2026-11-28)

The two parser findings in the original audit were historical, not still-current defects:

- At audit commit \`608a4578dc3e726ce1db64cb2b5cfb184b183225\`, \`tests/Stage01.Tests.ps1\` blob \`6be04d4d5be64c075d5bf849127b87c78bb9dea3\` extracted \`CURRENT_STAGE\` with a first-match regular expression. That finding was accurate for that commit.
- By commit \`26d41224ef09425cd3117f6cfdeeeea15b32a02d\`, the file had changed to blob \`613dceb098946ba8bc2de5e41802b41880bc392d\`: it dot-sources \`StrictUtf8StageMetadata.ps1\` and calls \`Get-StrictCurrentStage\`. The strict parser rejects duplicate keys, malformed input, invalid UTF-8, non-positive values, leading zeroes and Int32 overflow.
- The 12 previously flagged \`Assert-Stage43MetadataCompatibility\` consumers are not unvalidated raw reads at commit \`c1bc46969676b309792c45a828f3ff3d1d9017ed\`. Each calls the strict compatibility gate and constructs its \`$stageLines\`/\`$md\` membership view from \`$stage43State.Values\`. A thirteenth call site, the Stage43 evidence-output job, was added at line 1123. The Stage44 route classifier separately calls \`Get-Stage44ExecutionRoute -Bytes\`, which also uses the strict parser.
- Consequently, replacing those consumers with another parser would duplicate validation without fixing an extant defect. Keep their exact key/value comparisons over the validated map.

**Remaining test gap addressed:** commit \`8fd4e559db7ae381e3458fe92536b750f8933724\` adds Stage01 boundary tests for 22, 23, 43 and 44, including the legacy-name threshold at 23, plus rejection cases for missing, duplicate, empty, zero, leading-zero, negative, nonnumeric, overflowing, malformed and invalid-UTF-8 pointers. These tests are implemented but remain unaccepted until their exact-SHA CI run completes successfully.
