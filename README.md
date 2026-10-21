# Pastafarian Calendar ASIC — SystemVerilog + Kalaallisut

## Siunertaq

Una suliniut Pastafarian Calendar-ip naatsorsorneqarneranut ASIC-imik ineriartortitsinissamut tunngavoq. Naatsorsuutit **SystemVerilog** atorlugu naammassineqassapput; oqaatsit atorneqartussat tassaapput **Kalaallisut**.

`P(c,t)` ullut marluk tunngavigalugit naatsorsorneqassaaq. Inernera tallimanik immikkoortortaqarpoq:

```text
(yearNumber, cutletCanonicalIndex, dayInCutlet,
 monthCanonicalIndex, dayInMonth)
```

`canonicalIndex` naatsorsuinermi atorneqassaaq. Atit oqaatsit tunngavigalugit tulleriiaarneqassanngillat.

## Killiffik

```text
TOTAL_STAGES=55
CURRENT_STAGE=1
SOURCE_LANGUAGE_CATALOG_FROZEN=NO
HARDWARE_IMPLEMENTATION_STARTED=YES_STAGE1_BOOTSTRAP_ONLY
SPAGHETTI_MONSTER_IMPLEMENTATION_COMPLETE=NO
SILICON_TAPEOUT=NO
```

Una allakkiaq pilersaarusiornermut tunngavoq. Kalaallisut allanneqarnera aamma atit 64-it suli oqaasilerisumit misissorneqassapput.

## Najoqqutassaq

Normative source: [main README](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/main/README.md), pinned during planning at commit `56bc4173aae4975ded019ef5ab5a36249f1424df`.

```text
M = 2^127 - 1
SAVE(x) = 1 + ((x-1) mod M)
Foundation = -15055671
```

## Ineriartortitsineq

Stage 1: Kalaallisut-imi 17 cutlet atit aamma 47 month atit, tamarmik uppernarsarneqartussat; SystemVerilog oracle nammineq. Stages 2–53: 26 DISCOVERY/PATCH pairs. Stage 54: integration. Stage 55: final audit. ASIC S00–S20 gate-it tamarmik immikkut naammassineqassapput, 55 stage-inik taarserneqarsinnaanngillat.

Production-imi oracle atorneqassanngilaq. Kukkunerit pisoqqat misissorneqarsinnaassapput, aaqqiissutilli kisimik inernernut atuutissapput. `main` allanngortinneqassanngilaq; merge inerteqqutaavoq.

## Oqaatsit

Oqaatsit Kalaallisut-imi misissorneqarnissaannut [Oqaasileriffik](https://oqaasileriffik.gl/en/resources/) atorneqassaaq. 64-it atit suli aalajangersarneqanngillat; taaguutit eqqortumik akuersissutigineqareerpata kisimi `SourceLanguageCatalog` matuneqassaaq.

**SOURCE_LANGUAGE_QA=PENDING; STAGE_1_IN_PROGRESS; STAGE_1_PASS=NO.**

## Sullissineq misilittaanerlu

`rtl/pcal_stage1_bootstrap.sv` tassaavoq Stage 1-imi request-it
nalunaarsorneqarnissaannut atortorissaarut. Ullorsiutit ulluanik
suli naatsorsuisinnaanngilaq, taamaattumillu `date_valid=0`-iuvoq.

`tests/pcal_stage1_oracle_pkg.sv` aamma
`tests/tb_sauce_foundation.sv` misiliinermut taamaallaat
atorneqassapput. `Foundation`-imi paasissutissat akornanni
najoqqutassanut naleqqiussineq suli SystemVerilog-simulatorimi
ingerlanneqanngilaq.

```sh
bash scripts/verify_stage1.sh
```

`docs/STAGE01_ACCEPTANCE_MATRIX.md` naapertorlugu Stage 1
naammassineqanngilaq. `main` allanngortinneqassanngilaq.
