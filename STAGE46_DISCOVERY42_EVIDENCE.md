# Stadio 46 / DISCOVERY 42 — pruvo de Gate A kaj Gate B

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto. Kontrakto: [STAGE46_DISCOVERY42_CONTRACT.md](STAGE46_DISCOVERY42_CONTRACT.md).
LAST_COMPLETED_STAGE=45 ĝis propra akcepto de Gate D.

## Gate A — antaŭe akceptita
Kontrakta SHA 61739f59683f795bc9b6a8815509cb495b8605c5.
Native [46048356733](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46048356733), job 140673160647: 514/514, format/source integrity PASS.
Names [46048356837](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46048356837), job 140673161203: success.
Artifact 15222044462: antaŭe kontrolita ZIP SHA-256 587a98615b5b732d8c303b669e7a4c464e694644bf447ea58d9c6cd6dce91eff; verification.log SHA-256 84ed2edeb00ca18af09ccb1eb272ee1bf84512de4f8dcdf65eb7899d969f3aa4.
La antaŭkontrolo 202735/202735 estas abstrakta kardinaleco, ne Native aŭ translingva differential.

## Gate B — akceptita
Komenca SHA 66f26e24f040d16e3e81d4acf593cb06de740183: Native 46053836523 formatter-only failure, testoj NOT_RUN; Names 46053836395 success.
Formatter-korekto 93011c21546c4f3d7ea715c25be09e7287bd41a5: Native 46059970487 compile failure (tri malĝustaj testvokoj); Names 46059970459 success; testoj NOT_RUN.
Korektita SHA 89285d738847495cf6413088b4d5d772b8f8712d: precize tri testvokoj al dispatch_discovery_42; neniu produkta ŝanĝo. Branĉkomparo identical 0/0.
Produkto: [discovery_42_mixed_directional_coverage.gleam](src/pastafari/discovery_42_mixed_directional_coverage.gleam), blob 57c4465330b6230d3737fa484da3cbc15d4e3675.
Testoj: [discovery_42_test.gleam](test/discovery_42_test.gleam), blob f507adb893d06a1ccd21c0446fecaa54ba749808; 12 unikaj publikaj testfunkcioj.
X=CL(1-CR)+(1-CL)CR, reduktita entjera frakcio; unu Stage41-voko, previous kaj Error konservitaj; kontroloj de kardinalecoj, vakuaj konvencioj, J+Q+X=1 kaj X=2M-2J. La kontrakta samlingva orakolo uzas indeksajn fenestrojn, ordigitajn buleajn XOR-parojn kaj minimuman denominatoron. Ne translingva differential.

Native [46072022484](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46072022484), job 140750977448: completed/success; preciza checkout HEAD, Gleam 1.18.1, OTP 28 / ERTS 16.4.0.8; 526 passed, no failures; read-only format kaj source integrity PASS.
Names [46072022472](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46072022472), job 140750977459: completed/success, sama checkout SHA kaj lock-kontrolo.
Artifact [15233411197](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46072022484/artifacts/15233411197): 582 bytes; elŝutita ZIP SHA-256 e0fc548ea701cd7f77d122dfdc284ae75dba2f0a46ee95e80c27212730d3cceb egalas al GitHub digest; CRC OK; verification.log SHA-256 9fb38664847594882b3f917220b736589b8485d25bc8a9f4a5db700f34514ebb konfirmas precizan SHA kaj 526/526.
Neblokaj avertoj: antaŭekzistanta unused gleam/list import en discovery_13_next_bowl.gleam; Node20-deprecation de checkout.

## Gate C — dokumenta fermo, ankoraŭ ne akceptita
Nur ĉi tiu dokumento kaj DEVELOPMENT_STAGE.md. Necesas propra sam-SHA Native 526/526, read-only format/source integrity, Names success, job/log kaj elŝutita artifact/digest.

## Gate D — ne komencita
Nur post Gate C: aparta metadata-markilo kaj propra sam-SHA Native 526/526 + Names + kontrolita artifact. LAST_COMPLETED_STAGE=45 ĝis D. Neniu duobla dispatch, Stage47, main, merge, publikigo, plena datkonverto aŭ politika ŝanĝo.
