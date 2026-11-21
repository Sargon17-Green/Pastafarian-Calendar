# Lua+Kreyòl-ayisyen — static finite candidate-domain audit (QA only)

Date: 2026-11-21  
PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Branch: `Lua+Kreyòl-ayisyen`  
Audited predecessor HEAD: `8a046e1fc62184ae75519780bb3cd150275318b3`  
No production Lua changes, Stage56, main, merge, release or new Native dispatch.

## Provenance and independent method

The authoritative geometric input is the existing radius96 scan ZIP [artifact 14670954537](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820267079/artifacts/14670954537), with verified ZIP SHA-256 `6e5aeec25cae0201e3181d652e63da0642196e39b414150a748c1fe80291cbca`, source `ce4d541029c5d81c9f9c185ff734da0ed1d7c18a`. The existing [four-target Native run 44883988537](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537) was completed/success on `139c01b634c856bb79611cbf15493942870971d6`; its focused job was `136785194889`. These are prior observations, **not rerun by this audit**.

An independent Python 3 script parsed `stdout.txt` from actual ZIP bytes and verified all 193 ordered integer gate indices -96..96, 192 increasing gaps in 42..963, and every one of 187 reported six-gap windows against recomputed exact `G[i+6]-G[i]`. It checked ZIP SHA, CRC, source SHA, manifest, exit=0, empty stderr and scan-only markers. It enumerated **every** finite pair `-96 <= a < b <= 96` satisfying `b-a >= 6` and `252 <= G[b]-G[a] <= 1968` using only direct integer subtraction (not Lua, a borrowed oracle or interpolation). `minimum_months = ceil(length/123) = (length+122)//123`. Candidate day semantics were `(G[a], G[b]]`, i.e., day integers `G[a]+1` through `G[b]`. All previously sampled negative target days were explicitly excluded, with no duplicate counted twice in the union.

## Exhaustive finite result

| gate pair | open G[a] | close G[b] | length | minimum months | previously negative days inside | previously untested days in this interval |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 36..42 | -15035001 | -15033050 | 1951 | 16 | 5 | 1946 |
| 37..43 | -15034763 | -15032970 | 1793 | 15 | 5 | 1788 |
| 38..44 | -15033996 | -15032302 | 1694 | 14 | 4 | 1690 |
| 70..76 | -15018240 | -15016551 | 1689 | 14 | 4 | 1685 |
| 71..77 | -15018117 | -15016161 | 1956 | 16 | 4 | 1952 |

Exactly **5 candidate pairs**; **none** with 7 or more gaps. The union of the five integer day intervals contains **4,778 distinct days**; all **10** previously completed negative target days are in that union (six old radius64 and four radius96); **4,768 distinct days remain untested**. Per-row untested counts MUST NOT be summed because intervals overlap.

Six old negative days: `-15033432, -15032867, -15034166, -15033568, -15034351, -15033701`.
Four newer negative days: `-15017677, -15017114, -15017465, -15016813`.

Canonical candidate list: ordered by `(a,b)`, JSON UTF-8, `ensure_ascii=False, sort_keys=True, separators=(',', ':')`, one newline at EOF; SHA-256 `caceb13133cbe12d6ec2ab3dc23d42769a8b386e8049c5b1579481099be481ce`. Local independent script SHA-256 `e4db049e89105c79b02711c0e3669af61f762ea97e694e323d55630b469c5276`; local JSON output SHA-256 `ee7de29f768e6fc3ed96efb1482287a3ff67e6ecc321eca93f541cfa1877ae99`. Five deliberate mutation tests were rejected (altered gate index, window index, short-window count, duplicate target sample and non-monotone gate day).

## Decision and boundaries

`POTENTIAL_GEOMETRIC_ONLY`. The five finite short intervals are *necessary geometric possibilities*, not proof of a year selected by the normative `year5000` function, nor proof of selected-month or state-bound admissibility. Four Native samples seeded from the two newer windows selected longer years and failed the 16-month cap; previous six samples likewise were finite negatives. The remaining 4,768 days **do not constitute a justified new Native test plan** without an independent selection-specific rationale. Do not repeat any of the ten completed probes solely because another day in the same geometric window is unsampled.

Gates: independent integer geometry and finite sample coverage **PASS**; new-target Native **NOT_RUN**; selected-year differential **NOT_VERIFIED**; composition **NOT_INVOKED**; full-date **NOT_RUN**; stage-wide acceptance **NOT_CLAIMED**. No user-side OS execution required for this static audit, no Pending_User_Execution cleanup triggered.

**NEXT:** If further progress on the same path is warranted, design a bounded *independent selection-discrimination* analysis to distinguish candidate windows from the year actually selected. Define a falsifiable target-selection criterion and prohibit a new Native dispatch unless it excludes the ten accepted negatives and provides information not already determined by geometric membership. Keep the working branch open/READY; do not infer a production or Stage56 gate.