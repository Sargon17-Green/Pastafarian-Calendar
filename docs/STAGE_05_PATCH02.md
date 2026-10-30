# Stage 5 PATCH02 — చిన్న ర్యాంక్ నేరుగా స్వీకరణ

Stage 4 DISCOVERY02 was accepted: run 41136407730, 5/5 completed SUCCESS, GNAT13 compiled, bound and linked the test and logged STAGE04_DISCOVERY02_ASSERTIONS=18 on SHA 43c5fc2687ecd2d711f6d5732512ebdfda0f3dc7. Preserve its source witness (docs/STAGE_04_DISCOVERY02.md); no actual astronomical loop was executed.

## Exact API contract
Change only test-only Normative_Oracle.Choose_Rank_Short. Public API Choose_Rank(Stream:Answer_Stream;N:Big_Integer), short route 1<=N<=M. With L=floor(M/N)*N, x=Answer_At(Stream,0), return rank 1+((accepted-1) mod N). If x<=L, accepted=x. Otherwise a -1 stream's first accepted element is L, and a +1 stream's first accepted element is 1 after wrapping through M. For an initial rejected stationary stream, the old loop was nonterminating; now raise Constraint_Error. Accepted stationary input remains accepted. Ask_Bowl emits only +/-1. No production, wide selection, name catalog, or five-field Calendar_Date change; no claim that the synthetic witness is reachable from Ask_Bowl.

## Independent oracle and tests
Reconstruct a bounded historical cyclic loop for each mini M=7..13, each N=1..M, First=1..M, direction -1/+1. Compare ranks against independently derived direct endpoints (1,456 combinations); abort any mini loop exceeding M steps. Nine further assertions exercise the *actual patched original-M Ada code*: huge negative rejection, positive wrap, initially accepted, accepted/rejected stationary, First normalization, N=1, N=M, and unchanged M+1 wide dispatch. Total 1,465 checks. Independent Python BigInt preflight passed all 1,456 miniature cases plus both witness endpoints, but does not count as GNAT PASS. Never run the astronomical historical walk.

## Native acceptance
Runner: sh ./run_stage05_patch02.sh; GNAT Ada 2022 required. CI job native-stage05-patch02 (Ubuntu 24.04, 15-minute timeout). Require completed/success verify and stage05 native at exact HEAD, compile/bind/link evidence and log STAGE05_PATCH02_ASSERTIONS=1465. CI queued/in_progress is neither PASS nor blocker. No main merge or production-change permission inferred.
