# Stage39 / PATCH19 — gate index at or before day

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Parent: faad86e39307a3af5f6c5129d0c38a5092fdb5be
Gate: Stage38 run 41136551478 completed/success, 67/67 jobs; lua_stage38_discovery job 124357488417 completed/success; artifact 13019610081; 15 exact EXPECTED_RED, 14 interior MATCH, 96 synthetic BigInt, 9 rejects. Linux Native Lua5.3, exit=0 and empty stderr.
Status: OPEN / Stage39 Native CI NOT YET VERIFIED.

## Kontra egzak

Antre: day BigInt/oswa string integer, gate records index -8..8; 17 jou kontigu, strictly increasing ak gap 42..963; day in [Gate(-7),Gate(7)]. Records se rezilta PATCH17/PATCH18 ke caller bay. Pa kalkile oracle nan pwodiksyon.

Stage38 toujou retounen istorik h=max{k:Gate(k)<day}. PATCH19 dwe repare li a k=max{k:Gate(k)<=day}. Pou chak target legal gen yon gate anvan day; evalye sèlman pwochen gate a, Gate(h+1): si day=Gate(h+1), k=h+1, sinon k=h. Verifye inegalite Gate(k)<=day<Gate(k+1). Pa modifye istorik la; prezève semantic state li epi ajoute yon dezyèm commit otantik, metrics ak diagnostic san alias.

## Oracles and measurable acceptance

Independent canonical oracle: test/normative_oracle.lua gateIndexAtOrBefore(day), not imported in production. Signed canonical 15 gate days k=-7..7: each legacy returns k-1 and patch returns k; 14 interiors Gate(k)+1 (k=-7..6) remain k. Synthetic: 96 strictly increasing signed BigInt 17-gate chains over 2^127; 96 boundary corrections and 96 unmodified interior indexes. Nine malformed inputs rejected; two equal-output independent replays and context mutation isolation. Lua syntax checked for all src/test files; legacy source blob locked to 36d90537407ca7f95183800b3d21912081f3035e; PATCH17/PATCH18 unchanged; stderr empty, exit zero, stdout three exact markers, artifact source+version+exit+stderr+stdout+result. Previous 67 jobs green; Stage39 new job needs Stage38.

No main/merge, calendarDateSpaghetti, postStir12, year5000, or full calendar date in this stage. No Stage40 before completed/success with Stage39 evidence. CI pending is not blocking and not PASS.
