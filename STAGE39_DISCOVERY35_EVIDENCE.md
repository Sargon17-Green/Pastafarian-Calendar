# Stadio 39 / DISCOVERY 35 — atestaro de la ekzakta interkovra koeficiento

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto
Pritrakto: nur ĉi tiu rajtigita branĉo; neniu main/merge/publikigo.
Kontrakto: [STAGE39_DISCOVERY35_CONTRACT.md](STAGE39_DISCOVERY35_CONTRACT.md).
LAST_COMPLETED_STAGE restas **38/55** ĝis la aparta fina markilo pasos sian propran sam-SHA CI.

## Pordego A — kontrakto, akceptita

Kontrakta HEAD: `48db7d895380940ca16e03e58fc01e6ec1b67420`.
Native [run 45087049704](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087049704), job `137407954602`, completed/success: **430 pasis, neniu malsukceso**; Gleam 1.18.1 / OTP 28; nurlega `gleam format --check src test`, fontintegreco PASS.
Names [run 45087049712](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087049712), job `137407954407`, completed/success sur identa SHA.
Artefakto `14780295478`: [Native artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087049704/artifacts/14780295478); elŝutita ZIP SHA-256 = `4fcb42fedbef32167eb1808dd94165ddd7a0cfc72ab4cbe742668b4cc02ac474`, sama kiel GitHub `digest`. Interna `verification.log` enhavas la saman HEAD kaj 430/430.

## Pordego B — kodo, akceptita

Produktaj dosieroj: `src/pastafari/discovery_35_overlap_bands.gleam` kaj `test/discovery_35_test.gleam`. La produkta modulo vokas Stage38 **precize unufoje**, retenas la hereditajn listojn, nombrilojn, Jaccard- kaj Dice-frakciojn, kontrolas invariantajn rilatojn kaj redonas reduktitan Szymkiewicz–Simpson-frakcion. Ne uzas Stage21 aŭ fenestro-enumeradon en produktado.

La 12 unikaj publikaj testoj uzas originalajn Stage21-gapojn kaj sendependan rektan indeksfenestran enumeradon, original-bandajn membrokontrolojn kaj la plej-malgrandan-pozitivan-denominatoran serĉon sen produkta gcd. Ili kontrolas malplenajn flankojn, unu- kaj plur-gapojn, 1/2, 2/3, 3/4, veran subaron, duplikatojn, inversajn/apudajn kaj ±10^70-limojn, ripetajn ID-ojn, erarprioritaton kaj simetrion/O≥D≥J ĝis k=12. Tio estas sendependa Gleam-test-orakolo laŭ la kontrakto, ne translingva diferenciala testo.

Origina koda commit `58448d90978900ac9c4356f4c3e1a791a5919c87`: [Native 45133633619](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45133633619) malsukcesis **nur je nurlega formata kontrolo, antaŭ testoj**. [Names 45133633597](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45133633597) sukcesis. Naŭ precizaj formata-diff-sekcioj (2 en produkto, 7 en testoj) aplikitaj sen ŝanĝi logikon aŭ testnomojn.

Fina koda SHA: `4a66380900be53382f4bf493af91f3679ebf4040`.
[Native 45133811131](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45133811131), job `137555170287`, completed/success: **442/442 pasis**, neniu malsukceso, Gleam 1.18.1 / OTP28, read-only formatter kaj fontintegreco PASS.
[Canonical Names 45133811142](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45133811142), job `137555170154`, completed/success sur sama SHA.
[Artifact 14798309281](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45133811131/artifacts/14798309281) elŝutita, `SHA-256=1bc6ae4ee6d8c09e1a03716ad8318c96fc5397a0cfd49e81123ab7edaa50b3b6` kalkulita sendepende, sama kiel GitHub digest; interna `verification.log` konfirmas HEAD kaj 442/442.

## Ankoraŭ necesaj pordegoj

C. Ĉi tiu dokumenta commit kaj `DEVELOPMENT_STAGE.md` bezonas propran **sam-SHA Native442/442 + Names SUCCESS + artefakton/logon/digest**.
D. Nur post C, aparta unu-dosiera fina metadatmarkilo povas ŝanĝi `LAST_COMPLETED_STAGE` al 39, provisore; akcepto 39/55 post ties propra sam-SHA Native442/442 + Names SUCCESS + artefakto.
Neniu mano-duobligita CI, main/merge/publikigo aŭ plena datkonverto.
