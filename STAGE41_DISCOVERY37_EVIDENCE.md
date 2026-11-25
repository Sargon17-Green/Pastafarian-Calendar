# Stadio 41 / DISCOVERY 37 — dokumenta fermo de Gate B (Gate C atendata)

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto; amplekso: nur ĉi tiu ekzistanta branĉo.
Kontrakto: [STAGE41_DISCOVERY37_CONTRACT.md](STAGE41_DISCOVERY37_CONTRACT.md).
LAST_COMPLETED_STAGE restas **40/55**. Stage41 ne estas akceptita ĝis la aparta Gate D (fina metadata-markilo) pasas sian propran sam-SHA Native kaj Names Lock.

## Gate A — kontrakto, akceptita

- Kontrakta SHA: \`39f1b4f39c884b27868aedbffec452eb3c08f10c\`.
- Native [run 45683412752](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45683412752), job \`139449582151\`, completed/success: **454/454**, Gleam 1.18.1 / OTP 28 / ERTS 16.4.0.8; read-only format kaj fontintegreco PASS.
- Artifact \`15054603912\`; elŝutita ZIP SHA-256 \`54747b9b9e167c20e5eb9adc81250329bb43be50042b916044f35b9666ab9ba6\`, egala al GitHub digest; interna verification.log konfirmis la precizan HEAD kaj 454/454.
- Canonical Names Lock [run 45683412868](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45683412868), job \`139449582312\`, completed/success sur la sama SHA.

## Gate B — kodo kaj testoj, akceptita

Fina koda SHA: \`8a8bd171e1c43bbac0a86e782bed2d6928cc722d\`.

- Produkta modulo: \`src/pastafari/discovery_37_signed_coverage_difference.gleam\`; blob \`80005e5b3605d9963367137277f25c0dbf972ec4\`.
- Testdosiero: \`test/discovery_37_test.gleam\`; blob \`badc50f67aeedc5fa3b62c055f0a7af94cbeb945\`.
- Ekzakte 12 unikaj publikaj \`discovery_37_*_test\)-funkcioj. La orakolo uzas Stage21-gapojn sed mem rekte enumeras ĉiujn indeksajn fenestrojn, sumigas ilin, kontrolas membrecon kontraŭ la originalaj bandoj kaj serĉas la minimuman pozitivan denominatoron sen produkta gcd. La testoj ankaŭ rekalkulas la hereditajn Stage36-nombrilojn kaj frakciojn; matrica kontrolo iras ĝis k=12.
- Produkta modulo vokas Stage36 precize unufoje; ne vokas Stage21, ne enumeras fenestrojn kaj ne aldonas dependecojn.
- Native [run 45689253907](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45689253907), job \`139470011983\`, completed/success: **466 pasis, 0 malsukcesis**. Checkout-log konfirmas \`HEAD=8a8bd171e1c43bbac0a86e782bed2d6928cc722d\`; Gleam 1.18.1, OTP 28, ERTS 16.4.0.8. Read-only \`gleam format --check src test\) pasis; kompilo pasis; ĉiuj 466 testoj pasis; la post-testaj git-diff, staged-diff, untracked-source kaj HEAD-integrity kontroloj pasis.
- Artifact \`15057054094\): elŝutita ZIP; SHA-256 \`5d83fb9e51a7f68e281af7c95ff6991c0ba3ded8ca3112118de186bc918d0a19\`, egala al GitHub digest. Interna \`verification.log\) enhavas la saman HEAD kaj \`466 passed, no failures\`.
- Canonical Names Lock [run 45689253823](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45689253823), job \`139470011232\), completed/success. La log kontrolas ĉiun eniron de \`CANONICAL_NAMES_LOCK.sha256\` kontraŭ la bloboj en la sama checkout SHA.
- Ĉi tiu estas Native unit-test/format/source-integrity PASS kaj Names Lock PASS. Aparta translingva differential-test ne estis farita kaj ne estas asertata.

## Riparhistorio — neniu malsukcesa SHA rerulita

1. Koda SHA \`e627473492bdaa5de01d1bf4acc3bf350f542800\): Native [45684614993](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45684614993), job \`139453794806\), malsukcesis antaŭ testoj pro sintaksaj eraroj (Gleam-grupigaj krampoj kaj test-signaturo). Artifact \`15055169548\`, digest \`85ff2f03577ab1df5401dce91f8862e996aea69c90e98287c345dbd5b11c768d\). Names Lock [45684615038](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45684615038) sukcesis.
2. SHA \`89c1e849ebb0d847a651a9426dd85d982e0caeeb\): Native [45684754389](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45684754389), job \`139454278347\), konfirmis pliajn nedeciditajn grupigajn krampojn en la produkta modulo kaj sendependa orakolo; testoj ne komenciĝis. Artifact \`15056101952\), digest \`3a32e86c71fada9c964b75e044b9e31d441e8958b7f00bd61c6610c0b7cf9680\). Names Lock [45684754594](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45684754594) sukcesis.
3. SHA \`406ff9ea7c82c249a69bafd17219c94fcb7ace98\): Native [45685007648](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45685007648), job \`139455162329\), malsukcesis nur ĉe read-only formatter-kontrolo; testoj ne komenciĝis. Tri precizaj formatter-hunk-oj estis aplikitaj sen semantika ŝanĝo. Artifact \`15054379694\), elŝutita ZIP SHA-256 \`a84508bef09a22ed329bb348a3223fdcb2b54eddf88054d1135a2274b280d752\), kongruis kun GitHub digest. Names Lock [45685007649](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45685007649) sukcesis.
4. Fina SHA \`8a8bd171e1c43bbac0a86e782bed2d6928cc722d\): nur la tri precizaj formatter-diferencoj estis korektitaj; neniu algoritmo, atendata rezulto aŭ testnomoj ŝanĝiĝis. La sama-SHA Native kaj Names pruvoj supre estas verdaj.

## Gate C — ĉi tiu dokumenta commit, ankoraŭ atendata

Ĉi tiu dokumento kaj \`DEVELOPMENT_STAGE.md\) estas la dokumenta fermo post la akceptita Gate B. Ili bezonas propran saman-SHA Native **466/466**, read-only formatter/fontintegreco, artifact + verification.log + ZIP digest, kaj Canonical Names Lock completed/success. Ĝis tiuj pruvoj estas kompletaj, Gate C estas PENDING.

## Gate D — fina markilo, ankoraŭ ne komencita

Nur post Gate C, aparta fina metadata-markilo povas ŝanĝi \`LAST_COMPLETED_STAGE\) al 41. Tiu nova SHA bezonas propran Native 466/466 kaj Names Lock kun artefakto kaj digest. Ĝis Gate D, la oficiala stato restas **LAST_COMPLETED_STAGE=40**.

Neniu mana duobla dispatch, neniu Stage42, neniu main/merge/publikigo, neniu plena datkonverto kaj neniu ŝanĝo de politiko.
