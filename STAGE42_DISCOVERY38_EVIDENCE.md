# Stadio 42 / DISCOVERY 38 — pruvo de Gate A kaj Gate B (Gate C atendata)

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto.
Kontrakto: [STAGE42_DISCOVERY38_CONTRACT.md](STAGE42_DISCOVERY38_CONTRACT.md).
Akceptita antaŭa stadio: Stage41 / DISCOVERY37, 41/55.
LAST_COMPLETED_STAGE restas **41** ĝis la Stage42 Gate D pasas sian propran sam-SHA Native kaj Names Lock.

## Stage41 fina bazo

Fina Stage41 SHA: \`9fbcc96c6f35cda9aaabb9f9f0eb1b7519f7f0e5\`.
- Native run 45690395716, job \`139474000233\): completed/success, 466/466; Gleam1.18.1, OTP28 / ERTS16.4.0.8; format/source integrity PASS.
- Artifact \`15057704112\), elŝutita ZIP SHA-256 \`0351bed85d68453cfed4e7c3a133d952ea6d741d79c6c06eb04c7a953e625d02\), egala al GitHub digest; verification.log konfirmis la saman HEAD kaj 466/466.
- Names Lock run 45690395728, job \`139474000555\): completed/success sur la sama SHA.
Stage41 estas plene akceptita 41/55.

## Gate A — Stage42 kontrakto, akceptita

Kontrakta SHA: \`32d0aa3e0764f8b193ed8ea2923ad6abe04d73e5\`.
- Native [run 45691221318](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45691221318), job \`139476877452\): completed/success, 466/466, Gleam1.18.1 / OTP28 / ERTS16.4.0.8; read-only formatter kaj fontintegreco PASS.
- Artifact \`15057969068\), elŝutita ZIP SHA-256 \`10baa31f8ccfb1104596700706f13050887aa867582416d0154a28262555ff16\`, egala al GitHub digest; verification.log enhavas la saman HEAD kaj 466/466.
- Names Lock [run 45691221303](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45691221303), job \`139476876770\): completed/success; log kontrolas la saman checkout SHA.

## Gate B — kodo kaj testoj, akceptita

Fina koda SHA: \`dce94e2c6d0a62d5be262eccd0cb0dabe7957fd4\`.

- Produkta modulo: \`src/pastafari/discovery_38_mean_directional_coverage.gleam\`.
- Testdosiero: \`test/discovery_38_test.gleam\`.
- Ekzakte 12 unikaj publikaj \`discovery_38_*_test\)-funkcioj.
- La produkta modulo vokas Stage37 precize unufoje kun la samaj argumentoj, repropagas Error senŝanĝe, konservas la antaŭan rezulton kaj uzas nur entjeran aritmetikon kaj lokan Eŭklidan gcd. Ĝi ne vokas Stage21, ne enumeras fenestrojn kaj ne aldonas dependecojn.
- La test-orakolo ricevas Stage21-gapojn sed rekte enumeras indeksajn fenestrojn, kalkulas sumojn kaj membrecon kontraŭ la originalaj bandoj, kaj serĉas minimumajn denominatorojn sen uzi la produktan gcd. Ĝi kontrolas la heredajn Stage36/37-kampojn kaj la rekonstruajn identecojn CL=M+S/2 kaj CR=M-S/2.
- Native [run 45692508849](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45692508849), job \`139481355171\): completed/success, **478 pasis, 0 malsukcesis**. Checkout-log konfirmas \`HEAD=dce94e2c6d0a62d5be262eccd0cb0dabe7957fd4\`; Gleam1.18.1, OTP28 / ERTS16.4.0.8. Read-only \`gleam format --check src test\` pasis; kompilo kaj ĉiuj testoj pasis; post-testaj git-diff, staged-diff, untracked-source kaj HEAD-integrity kontroloj pasis.
- Artifact \`15059232593\), elŝutita ZIP SHA-256 \`050b61b9adcb2f2d5ece1b2ad192b0455f98541ac73a6c6e597299a032429142\`, egala al GitHub digest. verification.log konfirmas la saman HEAD kaj \`478 passed, no failures\`.
- Names Lock [run 45692509156](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45692509156), job \`139481356694\): completed/success; log konfirmas la saman checkout SHA kaj sukcesan CANONICAL_NAMES_LOCK kontrolon.
- Tio estas Native unit-test/format/source-integrity PASS kaj Names Lock PASS. Aparta translingva differential-test ne estis farita kaj ne estas asertata.

## Riparhistorio — neniu malsukcesa SHA rerulita

1. SHA \`a56f3188644eff7e583ff552137ddf749788f497\): Native [45691806209](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45691806209), job \`139478912431\), malsukcesis ĉe read-only formatter antaŭ kompilo kaj testoj. La formatter montris du source-hunk-ojn kaj test-orakolan esprimoĉenon; testoj ne komenciĝis. Artifact \`15059296528\), SHA-256 \`b9bebb25cb382c9727a17c4ab67264704d7d7284059e836ff907ec7c7066bc8d\`, elŝutita kaj digest-kongrua. Names Lock [45691806295](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45691806295) sukcesis.
2. SHA \`ff4b48d3d01a6b28d08d9fef9f513ddfe447c25c\): Native [45692210182](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45692210182), job \`139480312016\), malsukcesis ĉe unu restanta formatter-hunk en \`reconstructed_denominator\`; testoj ne komenciĝis. Artifact \`15060005111\), SHA-256 \`318cdaa6ba3d87dd47aedba636e949b407a23ac9087aae3325ffa2c6e2bf1658\`, elŝutita kaj digest-kongrua. Names Lock [45692210212](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45692210212) sukcesis.
3. SHA \`dce94e2c6d0a62d5be262eccd0cb0dabe7957fd4\): korektis la solan restantan formatter-hunk-on. Native 478/478 kaj Names Lock sukcesis sur ĉi tiu sama SHA. Neniu malsukcesa SHA estis rerulita.

## Ekstera matematika antaŭkontrolo — ne Native

Python-entjera aritmetiko sendependa de Gleam kaj de la produkta modulo ekzamenis 202735 realigeblajn kardinalecajn statojn por k=0..12. La redukto de M per gcd kongruis kun sendependa minimum-denominatora serĉo en 202735/202735 statoj; samtempe kontrolitaj la vakua konvencio, intervalo [0,1] kaj rekonstrueco de ambaŭ direktaj kovroj el M kaj S. Neniu malkongruo; maksimuma reduktita denominatoro 11704. Tio estas matematika antaŭkontrolo, NE Gleam/CI/Native/differential PASS.

## Gate C — ĉi tiu dokumenta fermo, atendata

Ĉi tiu dokumento kaj \`DEVELOPMENT_STAGE.md\` fermas la dokumentan pruvon de Gate A kaj Gate B. Ili bezonas propran saman-SHA Native **478/478**, read-only formatter/fontintegreco, artifact + verification.log + ZIP digest, kaj Canonical Names Lock completed/success. Ĝis tiuj pruvoj estas kompletaj, Gate C estas PENDING.

## Gate D — fina metadata-markilo, ne komencita

Nur post Gate C, aparta fina metadata-markilo povas ŝanĝi \`LAST_COMPLETED_STAGE\` al 42. Tiu nova SHA bezonas propran Native 478/478 kaj Names Lock kun artifact/digest. Ĝis Gate D, la oficiala stato restas **LAST_COMPLETED_STAGE=41**.

Neniu Stage43, main, merge, publikigo, plena datkonverto aŭ ŝanĝo de politiko.
