# Stadio 44 / DISCOVERY 40 — pruvo de Gate A kaj Gate B (Gate C atendata)

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO  
Branĉo: `Gleam+Esperanto`.  
Kontrakto: [STAGE44_DISCOVERY40_CONTRACT.md](STAGE44_DISCOVERY40_CONTRACT.md).  
Akceptita antaŭa stadio: Stage43 / DISCOVERY39, 43/55.  
`LAST_COMPLETED_STAGE` restas **43** ĝis Gate D ricevas sian propran sam-SHA Native kaj Names Lock.

## Stage43 fina bazo

Fina Stage43 SHA: `7d33da68d47b8f031cce5221c546e455d2d16c86`.
- Native [run 45696349938](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45696349938), job `139494640936`: completed/success, 490/490; Gleam 1.18.1, OTP 28 / ERTS 16.4.0.8; read-only format kaj source-integrity PASS.
- Artifact `15060647940`, elŝutita ZIP SHA-256 `d94cf4e5a1071cb59f8a3e545afd617506fe9f788ce515707e272eddd8f6a91d`, egala al GitHub digest.
- Names Lock [run 45696347863](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45696347863), job `139494634200`: completed/success.
Stage43 estas akceptita 43/55.

## Gate A — Stage44-kontrakto, akceptita

Kontrakta SHA: `b7f33c7dc241f45b277a22409cc8057c206eaafb`.
- Native [run 45698951667](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45698951667), job `139503664660`: completed/success, **490/490**; Gleam 1.18.1, OTP 28 / ERTS 16.4.0.8; format/source-integrity PASS.
- Artifact `15062154116`, elŝutita ZIP SHA-256 `5f930ba9ed94ec96cf8f11062ba743e030f07c531b27b0cdc9fbe942167a394c`, egala al GitHub digest.
- Names Lock [run 45698951686](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45698951686), job `139503664483`: completed/success sur la sama SHA.
Gate A estas akceptita. La ekstera matematika antaŭkontrolo 202735/202735 kun maksimuma denominatoro 5929 restas nur antaŭkontrolo, ne Native.

## Gate B — produkto kaj testoj, akceptita

La fina koda SHA estas `91528ab1ae3aa66fd00e83c8eb816decaaed50db`.

Commit-ĉeno:
- `89723562aa6dda49825019d69ba1893df7dcd614`: unua koda kaj testa commit.
- `c9bc26dcf45df3f311596a9a4834f74cefed87e5`: unua formatter-korekto.
- `91528ab1ae3aa66fd00e83c8eb816decaaed50db`: fina formatter-korekto kaj akceptita koda SHA.

Liveraĵoj:
- Produkta modulo: `src/pastafari/discovery_40_joint_directional_coverage.gleam`.
- Testdosiero: `test/discovery_40_test.gleam`.
- Ekzakte 12 unikaj publikaj `discovery_40_*_test)-funkcioj; totala Native-kalkulo: 502.
- La produkta modulo vokas `dispatch_discovery_39` precize unufoje kun la samaj argumentoj, repropagas ĉiun Error senŝanĝe kaj konservas la Stage39-rezulton sen modifo. Ĝi uzas lokan Eŭklidan gcd kaj precizan entjeran aritmetikon; ĝi ne vokas Stage21, ne enumeras fenestrojn, ne kanonigas bandojn kaj ne aldonas dependecojn.
- La test-orakolo ricevas nur la gapojn de Stage21, poste rekte enumeras ĉiujn fenestrojn per indeksaj limoj (0 \le a < b \le k). Membreco estas kalkulata kontraŭ la originalaj bandoj. La atendata J estas rekalkulata per minimum-denominatora serĉo, sen produkta gcd. La testoj kontrolas ankaŭ la hereditajn Stage36–39-kampojn, simetrion, intervalon kaj la du algebrajn identecojn per krucomultipliko.

Native [run 45776998281](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45776998281), job `139762956006`:
- completed/success; **502 passed, no failures**.
- Checkout kaj verification.log konfirmas `HEAD=91528ab1ae3aa66fd00e83c8eb816decaaed50db`.
- Gleam 1.18.1; Erlang/OTP 28; ERTS 16.4.0.8.
- Read-only `gleam format --check src test` pasis.
- `gleam test` pasis; post-testaj `git diff --exit-code`, `git diff --cached --exit-code`, kontrolo pri mankantaj/untracked source/test-moduloj kaj duobla HEAD-kontrolo pasis.
- Artifact `15096507711`, elŝutita ZIP SHA-256 `c20bb0a76df4e0a9b580f8ec84034bfa52d154e78010abc42b8800f632d59067`, egala al GitHub digest. SHA-256 de eltirita `verification.log`: `e752edeb5d3f355db8753388bfb531b45675ccd49297ccb9e629da61c4381cea`.
- Names Lock [run 45776998044](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45776998044), job `139762954493`: completed/success sur la sama SHA.
- Unu nebloka antaŭekzistanta kompilila averto restas en `src/pastafari/discovery_13_next_bowl.gleam:3`: unused import `gleam/list`. Ĝi ne influis format, kompilon, fontintegrecon aŭ la 502 testojn.

### Formatter-provoj antaŭ la fina akceptita SHA

1. Native [run 45776670976](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45776670976), SHA `89723562aa6dda49825019d69ba1893df7dcd614`, malsukcesis nur ĉe read-only formatter; testoj ne komenciĝis. Artifact `15095938152`, ZIP digest `53f4558809bd242c786913b022ce9924e4cf01514ffbd235c83d0bb1dc34f9df`, elŝutita kaj kontrolita.
2. Native [run 45776891200](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45776891200), SHA `c9bc26dcf45df3f311596a9a4834f74cefed87e5`, montris unu restantan formatter-hunk-on en la test-orakolo; testoj ne komenciĝis. Artifact `15095999534`, ZIP digest `0728258bb8850a11d2284de6b14e6ff323587f41c9592153813e8c5e54f806b6`, elŝutita kaj kontrolita.
3. Ambaŭ korektoj estis faritaj en postaj SHA-oj. Neniu malsukcesa SHA estis rerulita. Nur la fina SHA `91528ab1...` estas akceptita por Gate B.

## Gate C — ĉi tiu dokumenta fermo, CI atendata

Ĉi tiu dokumento kaj la ĝisdatigo de `DEVELOPMENT_STAGE.md` fermas la pruvon de Gate A kaj Gate B. La dokumenta commit bezonas sian propran sam-SHA Native **502/502**, read-only format/source-integrity PASS, artifact + verification.log + ZIP digest, kaj Canonical Names Lock completed/success. Ĝis tiuj rezultoj estas konfirmitaj, Gate C restas PENDING.

## Gate D — fina metadata-markilo, ne komencita

Nur post Gate C povas esti kreita la fina metadata-markilo. Tiu SHA bezonas propran Native 502/502 kaj Names Lock kun kontrolita artifact/digest. Nur post Gate D oni povas ŝanĝi `LAST_COMPLETED_STAGE` al 44.

Neniu Stage45, main, merge, publikigo, plena datkonverto aŭ ŝanĝo de politiko.
