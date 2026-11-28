# INT-02 有界 Windows Native 验收 / bounded acceptance

PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
TESTED_HEAD=d4cdf1f6e510727088647e6a3bd794762b5408aa
SOURCE_LOCK=4177479dea3f7662df383148a471a411f6419a0c
VERDICT=ACCEPTED_BOUNDED_SIX_NATIVE_GATES
CONVERTER=NOT_READY

## Evidence

User-returned COBOL-INT02-20261128-101609-715ce5.zip (15164 bytes), independently calculated SHA256 0580fd6f2ae8fa7f613bcb14a26ba8e4b0b6177b88196b5ec6c1887359adcd78. ZIP CRC pass; exact manifest coverage of all 36 non-manifest entries and 36/36 SHA256 match. V4 runner independently hashed as 6c5f7f535a0167fe66e873cb20266d98c3f139ffeac66ac3aa791040f3ba0638, equal to runner.log. Project ID, tested HEAD, source lock and all 23 path/blob pairs in source-lock.log match the runner's embedded pins; prior verified tree 775fb003eb5b30598c36b2776d8b8aebac2b212e. Branch HEAD verified unchanged before this documentation-only commit. This is user Windows evidence, not GitHub Actions CI evidence.

Windows UCRT64 x64, GnuCOBOL 3.2.0 package 1~3.2-10, GCC 16.2.0-7, Node 26.13.1-3. Exit-code selftest 0/17, pinned MSYS2 base SHA256 bd267f65e3656706d5e3b27d4f7d6c498e8ee3a54fcc3be200b7079bfc01f74a, all mirror checks/install and toolchain probes exit 0. INT02_TOOLCHAIN_PROBE=042; NODE_NATIVE_SPAWN=PASS; COMPILE_LINK_EXECUTE_PREFLIGHT=PASS. All six strict compilation and execution gates exit 0. FAILED_GATES=0; NATIVE_GATE_PROCESS_EXIT=0; RUNNER_EXIT=0; TEMP_CLEANUP=PASS reported, not independently observed. UTC start 10:16:09.5403486, end 10:34:59.3652033; gates 10:23:34.9941880–10:34:41.2075486.

| Gate | Cases | Observed marker | Log SHA256 |
|---|---:|---|---|
| SAVE | 48 | SAVE_GATE=PASS | 8e4bc7f009f9ff132945a63d356ab1d17ac2df1984a1395706654beb5888713d |
| candidates | 58 | PASS_BOUNDED_CANDIDATES_ONLY | 1f3ef35a964624d9032af100c04f224a8ec708c80b5cbe14954fdf413a3b8b25 |
| wide | 1051 | MATCH; statuses 0:702,22:3,24:346 | 99a287d6c5e7d9b7eea43f11dc1075ac946acad1dc1432bc002bbc4ba730a538 |
| gap-window | 27 | GAP_WINDOW_GATE=PASS | 93184b8da7aa1c12839896f76387fd0d6b2206b0878be4ae092e1a3403196bb1 |
| short-rank | 196009 | MATCH_NATIVE_RANK_ONLY; INVALID=9; REJECTED_TAIL=39198 | 0659b2996a522b5ea5d9c3e15fb780c3a420e65fdd66d78b5051c9b4e4d62399 |
| generated-year | 11 | MATCH_NATIVE_BOUNDED_ONLY | 1262ce97fe04d035016d7ebe292ed1b3d740eec16d7b58178f47ac2b2c174033 |

Total 197204 reported cases across six gates, not a claim of 197204 distinct complete calendar conversions. The generated-year gate contains nine valid action days and two out-of-scope probes. CALENDAR-SELECT-YEAR is explicitly limited to epoch RD -15055671 +/- 20000, and returns status 22 outside the supported interval. No general unbounded year claim. Historical Stage55/INT-01/QA51-B scoped acceptances remain unchanged. No production modifications, no reruns, no Stage56/main/merge/release.

## Next authorized work

Follow POST_STAGE55_CALENDAR_INTEGRATION_CONTRACT_2026-11-27.md and INT01_NATIVE_ACCEPTANCE_AND_INTEGRATION_DESIGN_2026-11-27.md. The existing source-pinned forward RD scope permits independent specification of remaining selection/family count and rank/unrank, and weaving. First recover the exact author text Pasted text(20261127-150032).txt (recorded SHA256 0add0726ef80f160f73594eba50c246c0bdeb0a5f613e14b6baa23e2f5321aae) and identify the exact rule clauses before implementation; compare independent exhaustive small-domain enumeration and large exact counts, first/last and invalid ranks; specify bounded complexity and caller-owned outputs. Do not extend the tested year interval without a proof and independent validation. Do not invent Appendix A, civil epoch or inverse semantics: inverse ambiguity and nonexistence, historical source revision, and three NOT_TESTED decision-A exclusions remain open. Full production readiness requires all applicable forward and inverse integration gates, independent differential/round-trip, and resource bounds. No production use of Node or oracle; Node here is QA only.

This document records evidence from the tested SHA, not a new Native test of the documentation-only child.
