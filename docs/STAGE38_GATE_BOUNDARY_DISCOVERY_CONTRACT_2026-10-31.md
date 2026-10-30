# Stage38 / DISCOVERY19 — strict boundary gate lookup

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Stage37 gate: run 41126772793 completed/success, 66/66 jobs, SHA bf6684edf8915d95d7d7d6c83a57d69b5adf8dd2, job 124326081378; artifact 13013946396.
Status: OPEN / Native Stage38 NOT VERIFIED until its own CI completed.

## Kontra ak motivasyon
Oracle test/normative_oracle.lua gen gateIndexAtOrBefore(day), sa vle di pi gwo endis k ki satisfè Gate(k) <= day. Apre PATCH17 ak PATCH18, jou pòtay pozitif/negatif egziste. Nou chwazi yon ti adaptè istorik sou limit egzak pou DISCOVERY19 anvan ane 5000, postStir12 oswa dat senk konpozan. Sa a se yon defo LEGACY nou entwodui volontèman nan nouvo kòd Stage38, pa yon pretansyon ke yon bug istorik te deja obsève.

Antre: target day kòm BigInt oswa chèn desimal antye, 17 dosye {index,day} kontigu pou k=-8..8. Gap 42..963, strictly increasing; target nan [Gate(-7),Gate(7)]. Caller dwe konstwi jou sa yo ak PATCH17/PATCH18. Pwodiksyon pa kalkile orak, pa fè sauce, pa chanje patch anvan yo.

Sòti: fonksyon S.legacyGateIndexProbe(day,gates) remèt pi gwo k kote Gate(k) < day (strict LT), avèk semantic state posede, yon commit, metrics, diagnostics. Domèn presi a gen 15 temwen Gate(k) pou k=-7..7, ki dwe bay k-1 epi montre 15 EXPECTED_RED kont O.gateIndexAtOrBefore(day). Pou 14 jou Gate(k)+1, k=-7..6, dwe gen 14 MATCH. Gap minimòm 42 fè moun ka pwouve enteryè. 96 chèn sentetik BigInt avèk baz pozitif ak negatif pi gran pase 2^127, chak gen 1 exact RED ak 1 interior MATCH. Nèf rejè malformed, biyè context isolation, retry; legacy separe de orak.

Gate: Lua 5.3 Native syntax ak SHA, immutability src/positive_gate_patch.lua ak src/negative_gate_patch.lua, stdout/sderr/exit, artifact ak 3 markers egzak, prior CI green. Stage38 CI pending pa PASS. Stage39/PATCH19 ta itilize <= ak yon kontra separe sèlman apre completed/success Stage38. Pa gen main/merge/year5000/postStir12/calendarDate.
