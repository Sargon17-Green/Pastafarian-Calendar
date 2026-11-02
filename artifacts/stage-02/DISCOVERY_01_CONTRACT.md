# Stage 2 — DISCOVERY 01: modulo-limiti (nova sendependa laboro)

## Deveno e limito
La uzanto la 2026-11-02 permis nova sendependa implemento anstataus
la ne-trovebla `logo-ido-stage02-discovery01-delta.zip` de 2026-08-29.
Ca laboro **ne** esas autentika restauro di la antea arkivo.
Stage 1 restas kompletigita e ne modifikita.

## Inputo e outputo
Nova pura production-proceduro `monster.stage02.normalize :value`:
inputo esas signizita ekzakt-entjero en la Stage-1 `bi` formo;
outputo esas ekzakt-entjero en la inkluziva intervalo [1, M],
ube `M = nr.M` (konstanto de Appendix A).

Normala regulo: `1 + ((value - 1) mod M)`, kun euklida resta modulo.
La production-vojo uzas **altra formulo**: `r = value mod M`;
se `r = 0`, outputar `M`; altrakaze outputar `r`.
Production ne vokas `nr.save` nek `test/normative_reference.logo`.

## Discovery-kazi e oracle
16 explicita limito-fixturi inkluzas 0, 1, M-1, M, M+1,
2M-1, 2M, 2M+1, 3M-1, 3M, 3M+1, -1, -M, -M+1,
-M-1, -2M. Omna fixture havas du compari:
(1) explicita algebra atendajo; (2) independanta
test-only `nr.save` formula `1+((x-1) mod M)`.
6 periodala inputi uzas `normalize(x+M)=normalize(x)=normalize(x-M)`.
Entute 44 asserti, sen floating point, kun negativa e nulala limiti.

La historiala rakonto nomizis `EXPECTED_RED` por M, 2M, 3M e M+1.
To esas hipotezo pri perdita historiala kodo, ne verifikita defekto.
**Nula expected-red estas deklarita sen native reproducajo.**

## Akcepto
- `Logo+Ido` branch nur; nula main/merge.
- `test/stage01_tests.logo` e frozen katalogo ne modifikita.
- Native UCBLogo 6.2.5 headless per fiksa upstream commit.
- Native smoke + 44 asserti, `STAGE_2_DISCOVERY_01_PASIS`,
  sen `STAGE_2_TESTO_FALIIS`, exit 0.
- Stage 1 original Native e verify sur sama nova SHA completed SUCCESS.
- Sen native completed, statuso esas PENDING, ne PASS.

Stage 2-DISCOVERY 01 ne esas la kompleta kvin-komponenta kalendarala produkto.

## Kontrolita native evidenco

- Logo Stage 2 Discovery 01 Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41522957906
- Logo Stage 1 Native Regression: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41522957076
- Canonical Names Lock / verify: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41522957044
- Entute 44/44 asserti; omna tri CI jobi completed SUCCESS sur `f0498eeb99eea99038e080d300f26ff0615ce564`.
