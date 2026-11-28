# Stadio 47 / DISCOVERY 43 — pruvo de Gate A kaj Gate B

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto.
Kontrakto: [STAGE47_DISCOVERY43_CONTRACT.md](STAGE47_DISCOVERY43_CONTRACT.md).
LAST_COMPLETED_STAGE=46 ĝis propra akcepto de Gate D.
Scope: nur DISCOVERY 43; neniu Stage48, plena datkonverto, main, merge aŭ publikigo.

## Gate A — akceptita

Kontrakta commit SHA: daf54f98a39c73a8ab7c7d1699873b9e0a919da8.
Native [46140294213](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46140294213), job 140964503433: completed/success, 526/526; Gleam 1.18.1, OTP 28 / ERTS 16.4.0.8; read-only format kaj source integrity PASS.
Names [46140294196](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46140294196), job 140964503569: completed/success, sama SHA.
Artifact [15261418238](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46140294213/artifacts/15261418238): ZIP SHA-256 b7df149cbf23dd30f2a584c280957d68e04fcdabb4ff4dacec1fe6f1bcc2d4f5; verification.log SHA-256 ada12806f5594b0758f98aac82afcfc0930b3ee30d1005adb638a595ee68a9af. La antaŭkontrolo 202735/202735 estas abstrakta kardinaleco, ne Native aŭ translingva differential.

## Gate B — akceptita

Komenca koda commit [79df93d698a5a4df6e05e6e45ac6c2c16c75b395](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/79df93d698a5a4df6e05e6e45ac6c2c16c75b395), parent Gate A. Aldonis nur:
- `src/pastafari/discovery_43_conditional_concordant_coverage.gleam`, blob 4e34c9b4606c3745e6bfdb97efc0e9c547cfb83e.
- `test/discovery_43_test.gleam`, komenca blob 0665933b1626ad102e0ef785f67d2bb32b3c17aa.

Komenca Native [46147272395](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147272395), job 140985983224: completed/failure nur ĉe `gleam format --check`; la sola malkongruo estis kvar formatigaj vokoj en la testdosiero. Kompilado kaj testoj NE ruliĝis. Artifact 15264083677: ZIP SHA-256 4c21d930d9be05e2d6f765c9949cbb30d610b158490ebee8ab322348c582066e, kongrua kun GitHub digest; CRC OK; verification.log SHA-256 f5d37737d6844952f11398c302a60376826829c71e0777e59d6efafec7ba7fc3. Names [46147272402](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147272402), job 140985983589: completed/success sur la sama komenca SHA.

La korekto [9b288001722a47b6587d05ac9e0b1142ea19b26d](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/9b288001722a47b6587d05ac9e0b1142ea19b26d) estas unu komito post la komenca koda SHA; ĝi modifis nur `test/discovery_43_test.gleam` per kvar formatter-konformaj ŝanĝoj (+4/-24), sen semantika aŭ produkta ŝanĝo. Branĉo kaj file readback estis kontrolitaj; la produkta blob restis 4e34c9b4606c3745e6bfdb97efc0e9c547cfb83e, fina test blob 49f6cadd1fa832ffc81ceeba61b59c6609db18ba. La kompara stato estis ahead 1 / behind 0.

La testdosiero enhavas 12 unikajn publikajn testojn: both_empty, left_empty, right_empty, disjoint_nonempty, equal_nonempty, left_subset, right_subset, partial_overlap, asymmetric_overlap, repeated_ids_duplicate_bands, wide_inverted_and_error_priority, matrix. La test-orakolo sendepende enumeras indeksajn fenestrojn el Stage21-gapoj, kontrolas membrecon kontraŭ la originalaj bandoj, enumeras ordigitajn buleajn parojn kaj serĉas minimuman denominatoron. Produkta kodo ne enumeras fenestrojn kaj konservas la unuopan Stage42-vokon, `previous` kaj erarojn. Tio estas samlingva sendependa oracle, ne translingva differential.

Fina Native [46150833174](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46150833174), job 140996902780: completed/success sur preciza HEAD 9b288001722a47b6587d05ac9e0b1142ea19b26d; Gleam 1.18.1, OTP 28 / ERTS 16.4.0.8; 538 passed, no failures; read-only formatter kaj tracked/untracked source-integrity kontroloj sukcesis.
Names [46150833115](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46150833115), job 140996902653: completed/success sur la sama SHA; checkout kaj Canonical Names Lock kontrolitaj.
Artifact [15265367222](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46150833174/artifacts/15265367222): 581 bytes; elŝutita ZIP SHA-256 7800f8895498ce4d9e6a010829b1ab4ea8a1378a56da4fcd344550e742d2d395 egalas al GitHub digest; CRC OK; verification.log SHA-256 968c3084574875029b1c7d18da8abfd32696686850dce221edfca03e968bd3ec konfirmas precizan HEAD kaj 538/538.
Nebloka averto: antaŭekzistanta unused `gleam/list` import en `src/pastafari/discovery_13_next_bowl.gleam`.

## Gate C — dokumenta fermo, CI atendata

Ĉi tiu dokumento kaj `DEVELOPMENT_STAGE.md` estas la tuta amplekso de Gate C. Necesas propra sama-SHA Native 538/538, read-only format/source integrity, Names Lock success, kaj kontrolita job/log/artifact/digest. Ĝis tiu akcepto Gate C restas atendanta; LAST_COMPLETED_STAGE restas 46.

## Gate D — ne komencita

Nur post akcepto de Gate C: aparta fina metadata-markilo kaj propra sama-SHA Native 538/538 + Names + kontrolita artifact. LAST_COMPLETED_STAGE=46 ĝis D. Neniu Stage48, main, merge, publikigo aŭ plena datkonverto.
