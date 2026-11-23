# Logo+Ido Stage2 — isolated source-locked Native dispatcher QA contract

PROJECT_ID=PC-BRANCH-LOGO-IDO, 2026-11-23. Canonical Logo+Ido SHA ad001c6aeeb6c758f5004b206a656fec5d6fc403 unchanged. QA parent SHA 85ccf99873c398cfb11713b166be950ecd09a295.

Input: stream [canonical first BI 1..M, step exactly ±1], canonical BI N>=1; M=2^127-1. Valid output: canonical rank in 1..N, invalid input -> []. Native invokes monster.stage02.choose.rank, not helpers alone. Independent Python oracle derives integer digit sample, width and accepted-prefix rank, checked by separate exhaustive rejection walks for bases 2..6; does not import Logo, project oracle or fixtures.

Fixed Native matrix: small (12 valid, 10 invalid)=22 cases/46 checks, boundaries M,M+1,M²,M²+1, wrap ± and rejected suffix ±; deep31 (8 valid)=8/24, widths k31/k32/k33 and transition ±1; deep64 (5 valid)=5/15, widths k64/k65. Bounded timeouts small 360s, deep 900s; exact source/blob locks, pinned UCBLogo 6.2.5 SHA a0215433f07384e4c42fe247525867f11e6f32f7, explicit failure exit, check counters, fixed artifacts and SHA256 manifests. All three jobs passing would give 35 cases / 85 checks, but ONLY bounded dispatcher QA. No D19 ASK stream or downstream unranking/calendar validation, no arbitrary-width claim, no Stage2 acceptance. LAST_COMPLETED_STAGE=1.

Natural push-only workflow; no manual duplicate dispatch. ACCEPT requires completed exact-SHA run, real Native case/check markers, all jobs, log+artifact contents and independent ZIP SHA256 verification. queued/in_progress not PASS or blocker. No promotion to canonical, main, merge or publication.
