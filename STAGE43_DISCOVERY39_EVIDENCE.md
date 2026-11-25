# Stadio 43 / DISCOVERY 39 — pruvo de Gate A kaj Gate B (Gate C atendata)

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto.
Kontrakto: [STAGE43_DISCOVERY39_CONTRACT.md](STAGE43_DISCOVERY39_CONTRACT.md).
Akceptita antaŭa stadio: Stage42 / DISCOVERY38, 42/55.
LAST_COMPLETED_STAGE restas **42** ĝis Stage43 Gate D pasas sian propran sam-SHA Native kaj Names Lock.

## Stage42 fina bazo

Fina Stage42 SHA: \`74be256d54a4eba7fd6c367dcd33829c22a3a3e5\`.
- Native run 45693484956, job \`139484724124\): completed/success, 478/478; Gleam1.18.1, OTP28 / ERTS16.4.0.8; format/source integrity PASS.
- Artifact \`15059907058\), elŝutita ZIP SHA-256 \`e7695fef6573b8353063a06739eee7c186614e8dab172a50fa3998425b484490\`, egala al GitHub digest; verification.log konfirmis la saman HEAD kaj 478/478.
- Names Lock run 45693484898, job \`139484725841\): completed/success sur la sama SHA.
Stage42 estas plene akceptita 42/55.

## Gate A — Stage43 kontrakto, akceptita

Kontrakta SHA: \`9e98de64d79c976f1fab3f8ecf24f9f7bb92042b\`.
- Native [run 45694012385](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45694012385), job \`139486560697\): completed/success, 478/478, Gleam1.18.1 / OTP28 / ERTS16.4.0.8; read-only formatter kaj fontintegreco PASS.
- Artifact \`15060351207\), elŝutita ZIP SHA-256 \`bfec1f3e13aaccacdb7903436b94d4e2f14d80b9970b0f8a6c90c88e4d1c5a8b\`, egala al GitHub digest; verification.log enhavas la saman HEAD kaj 478/478.
- Names Lock [run 45694012504](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45694012504), job \`139486561119\): completed/success; log kontrolas la saman checkout SHA.

## Gate B — kodo kaj testoj, akceptita

Fina koda SHA: \`ccb18a9c7fc7b81a6cda405f4a062e6fe18b1f47\`.

- Produkta modulo: \`src/pastafari/discovery_39_relative_directional_asymmetry.gleam\`.
- Testdosiero: \`test/discovery_39_test.gleam\).
- Ekzakte 12 unikaj publikaj \`discovery_39_*_test\)-funkcioj.
- La produkta modulo vokas Stage38 precize unufoje kun la samaj argumentoj, repropagas Error senŝanĝe, konservas la antaŭan rezulton kaj uzas nur entjeran aritmetikon kaj lokan Eŭklidan gcd. Ĝi ne vokas Stage21, ne enumeras fenestrojn kaj ne aldonas dependecojn.
- La test-orakolo ricevas Stage21-gapojn sed rekte enumeras indeksajn fenestrojn, sumigas ilin kaj kontrolas membrecon kontraŭ la originalaj bandoj. Ĝi sendepende rekalkulas CL, CR, S, M kaj A per minimum-denominatora serĉo, kontrolas la heredajn Stage36/37/38 kampojn kaj rekonstruas CL/CR el M kaj A per krucomultipliko.
- Native [run 45695125917](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45695125917), job \`139490415261\): completed/success, **490 pasis, 0 malsukcesis**. Checkout-log konfirmas \`HEAD=ccb18a9c7fc7b81a6cda405f4a062e6fe18b1f47\`; Gleam1.18.1, OTP28 / ERTS16.4.0.8. Read-only \`gleam format --check src test\` pasis; kompilo kaj ĉiuj testoj pasis; post-testaj git-diff, staged-diff, untracked-source kaj HEAD-integrity kontroloj pasis.
- Artifact \`15060701972\), elŝutita ZIP SHA-256 \`219c7016ba7d2e47b31e071814f432e0420776310ab0d2d88a7992f46e01941d\`, egala al GitHub digest. verification.log konfirmas la saman HEAD kaj \`490 passed, no failures\`.
- Names Lock [run 45695125673](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45695125673), job \`139490414619\): completed/success; log konfirmas la saman checkout SHA kaj sukcesan CANONICAL_NAMES_LOCK kontrolon.
- Tio estas Native unit-test/format/source-integrity PASS kaj Names Lock PASS. Aparta translingva differential-test ne estis farita kaj ne estas asertata.

## Riparhistorio — neniu malsukcesa SHA rerulita

1. SHA \`a2d41fa9a1bfe77115157b61dfb4a682822d6839\): Native [45694600146](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45694600146), job \`139488585338\), malsukcesis antaŭ kompilo kaj testoj pro unu malĝusta ferm-delimitilo en la test-funkcia signaturo. Artifact \`15060206230\), SHA-256 \`11fb49e111bb07df0dd95c3060ad9a0fb8bb52873a367e4e1a51bf70ed41e60b\`, elŝutita kaj digest-kongrua. Names Lock [45694600192](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45694600192) sukcesis.
2. SHA \`c25758243e212fbc0928ab6a0f22379cbfea1987\): Native [45694819129](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45694819129), job \`139489341497\), malsukcesis nur ĉe read-only formatter; testoj ne komenciĝis. La formatter montris la precizajn aritmetikajn kaj pipeline-layout-hunk-ojn en la du novaj dosieroj. Artifact \`15059369813\), SHA-256 \`cc6005ad4e9c46855b44017c905e817cd315c7d98189fecd6d642081a18ef45c\`, elŝutita kaj digest-kongrua. Names Lock [45694819313](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45694819313) sukcesis.
3. SHA \`ccb18a9c7fc7b81a6cda405f4a062e6fe18b1f47\): la malĝusta signaturo kaj ĉiuj precizaj formatter-hunk-oj estis korektitaj sen ŝanĝo de la matematika kontrakto aŭ atendataj rezultoj. Native 490/490 kaj Names Lock sukcesis sur ĉi tiu sama SHA. Neniu malsukcesa SHA estis rerulita.

## Ekstera matematika antaŭkontrolo — ne Native

Python-entjera aritmetiko sendependa de Gleam kaj de la produkta modulo ekzamenis 202735 realigeblajn kardinalecajn statojn por k=0..12. La redukto de A per gcd kongruis kun sendependa minimum-denominatora serĉo en 202735/202735 statoj; samtempe kontrolitaj vakua/nula konvencio, intervalo [-2,2] kaj rekonstruo de CL/CR el M kaj A. Neniu malkongruo; maksimuma reduktita denominatoro 155. Tio estas matematika antaŭkontrolo, NE Gleam/CI/Native/differential PASS.

## Gate C — ĉi tiu dokumenta fermo, atendata

Ĉi tiu dokumento kaj \`DEVELOPMENT_STAGE.md\` fermas la dokumentan pruvon de Gate A kaj Gate B. Ili bezonas propran saman-SHA Native **490/490**, read-only formatter/fontintegreco, artifact + verification.log + ZIP digest, kaj Canonical Names Lock completed/success. Ĝis tiuj pruvoj estas kompletaj, Gate C estas PENDING.

## Gate D — fina metadata-markilo, ne komencita

Nur post Gate C, aparta fina metadata-markilo povas ŝanĝi \`LAST_COMPLETED_STAGE\` al 43. Tiu nova SHA bezonas propran Native 490/490 kaj Names Lock kun artifact/digest. Ĝis Gate D, la oficiala stato restas **LAST_COMPLETED_STAGE=42**.

Neniu Stage44, main, merge, publikigo, plena datkonverto aŭ ŝanĝo de politiko.
