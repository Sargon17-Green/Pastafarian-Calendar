# Stage 24 / Discovery 12 — Na-verify na kontrata sa magkakatugmang implementasyon

**PROJECT_ID:** `PC-BRANCH-POWERSHELL-TAGALOG`  
**Petsa:** 2026-10-30  
**Pinagmulan:** mga kasalukuyang arkibo ng ibang independent implementation branch; hindi hinulaang lokal na kontrata.  
**Estado:** RESOLVED_SPECIFICATION / IMPLEMENTATION_NOT_YET_VERIFIED

## Parehong makasaysayang depekto sa magkakahiwalay na branch

Ang Stage 22 / Discovery 11 ay tungkol sa overwritten na drop-46 order memory. Ang Stage 23 / Patch 11 ay nakapagbigay na ng **hiwalay na `orderAt46Latch`** mula sa drop 46 habang nananatili ang lahat ng **46 + 12 = 58** original shared-memory writes.

Sa **Stage 24 / Discovery 12** ay *ibang* depekto ang susubukin: may consumer na nag-aakalang ang susunod na bowl ay ang **numerical successor ng ID**, anuman ang `orderAt46Latch`. Ang dating caller ay:

```text
oldNextBowlFixedName(queriedBowlId) = (queriedBowlId % 6) + 1
valid queriedBowlId: integer 1..6
numeric ring: 1→2→3→4→5→6→1
```

Ang normative helper na mayroon na sa `oracle/NormativeCore.ps1` ay `Get-NormNextBowlInDrop46Order`:

```text
O := a validated six-ID permutation from Stage 23 orderAt46Latch
p := indexOf(O, queriedBowlId)  // zero-based
correctNext := O[(p+1) mod 6]
```

**Huwag magpalit ng normative function sa Stage 24.** I-execute ang historical wrong numeric caller sa tunay na production dispatch at itala nang hiwalay ang `queriedBowlId`, `oldNumericNext`, at saved `orderAt46Latch` sa invocation-owned context. Panatilihing raw/wrong ang result sa Stage 24 (intentionally `EXPECTED_RED`). Ang Stage 25 / Patch 12 lamang ang maglalathala ng corrected positional successor habang patuloy na tinatawag at pinapanatili ang legacy scar.

**Mahalagang pagwawasto ng lumang gap audit:** ang pangalang `biasedLegacyPick` ay tumutukoy sa **Stage 26 / Discovery 13** (modulo rank selection na walang rejection), *hindi* sa Stage 24 bowl-successor. Ang naunang dokumentong `STAGE24_DISCOVERY12_CONTRACT_GAP.md` ay historical preflight na napawalang-bisa sa partikular na kakulangan ng specification sa pamamagitan ng cross-branch evidence na ito; huwag burahin ang original audit.

## Eksaktong test oracle at nakalkulang mga witness

Para sa Foundation, ginagamit sa ibang implementation ang latch `[4,5,2,3,6,1]` at ang mga result ay:

| queried ID | historical numeric ID | correct Drop 46 positional |
| --- | --- | --- |
| 1 | 2 | 4 |
| 2 | 3 | 3 |
| 3 | 4 | 6 |
| 4 | 5 | 5 |
| 5 | 6 | 2 |
| 6 | 1 | 1 |

Ibig sabihin, **tatlong EXPECTED_RED (1,3,5) at tatlong incidental MATCH (2,4,6)** sa test order. Ang panloob na verification sa buong 720 permutations × 6 queries = 4,320 kaso ay eksaktong **3,456 historical mismatch** at **864 incidental match**; may **576** mismatches sa last-position wrap. Hindi ito native PowerShell CI result.

## Teknikal na integration at gate

1. Bago magsulat, i-verify ang HEAD at kung may kasabay na editor. Huwag baguhin ang `main`.
2. Idagdag ang `src/Discovery12.ps1` na may old numeric successor at tahasang valid ID 1..6; walang `biasedLegacyPick`, rejection sampling o `Patch12` code.
3. Idagdag ang hiwalay na invocation-owned Stage 24 context fields at production route **pagkatapos** ng aktuwal na Stage23 Patch11 full 58-write sauce. Ang tamang latch ay test/witness lamang sa discovery at hindi nagtatama ng published legacy result.
4. Idagdag ang `tests/Stage24.Tests.ps1` para sa direct helper, anim na Foundation ID, 720 permutations × 6 queries, input refusal, tamang expected-red signature, Stage23 old-scar/latch at ownership regressions; ihiwalay ang deliberate RED sa unexpected exception.
5. Native **Windows PowerShell 5.1** CI para sa Stage 24 + lahat ng naaangkop na Stage1–23 regressions + frozen canonical name lock sa **iisang HEAD**; i-save ang logs, exit codes, test counts, SHA at artifact. Hindi maaaring mag-claim ng Native PASS mula sa mga numerong nakuha sa ibang wika.
6. `CURRENT_STAGE=24` at `LAST_COMPLETED_STAGE=23` habang hindi pa naa-accept ang Native; Stage 25 ay hindi sisimulan bago ang Stage24 acceptance. Ang paglipat ng stage ay hindi kailangan ng hiwalay na ceremonial approval.

## Mga direktang cross-branch na ebidensiya

- [TypeScript+मराठी Stage24 / Discovery12, CI 38239449544](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/TypeScript%2B%E0%A4%AE%E0%A4%B0%E0%A4%BE%E0%A4%A0%E0%A5%80/SPAGHETTI_DEVELOPMENT_HISTORY.md) — numeric ID increment, 3,456/864, real production path.
- [C++&Latina Stage24 / Stage25](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/C%2B%2B%26Latina/SPAGHETTI_DEVELOPMENT_HISTORY.md) — historical oldNextBowlFixedName vs latch-position patch; Foundation witness.
- [Kotlin+Cymraeg Stage24, CI 38282797263](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/Kotlin%2BCymraeg/SPAGHETTI_DEVELOPMENT_HISTORY.md) — six-ID numeric neighbor, two seals; 6,912 mismatches / 1,728 matches for 8,640 queries.
- [MATLAB+Polski Stage24 / Stage25 / Stage26](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/MATLAB%2BPolski/SPAGHETTI_DEVELOPMENT_HISTORY.md) — fixed-name bowl successor is Stage24; `biasedLegacyPick` is Stage26.
- [PHP+Bahasa-Melayu Stage24 / Stage26](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/PHP%2BBahasa-Melayu/SPAGHETTI_DEVELOPMENT_HISTORY.md) — 3,456/864, distinct later biased modulo selection.

**Hindi saklaw:** hindi pinatutunayan ng iba pang branch na gumagana na ang native PowerShell Stage24; iyon ang susunod na implementasyon at gate.
