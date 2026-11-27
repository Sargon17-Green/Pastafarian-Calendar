# Stadio 45 / DISCOVERY 41 — pruvo de Gate A kaj Gate B (Gate C atendata)

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO  
Branĉo: Gleam+Esperanto. Kontrakto: [STAGE45_DISCOVERY41_CONTRACT.md](STAGE45_DISCOVERY41_CONTRACT.md).
LAST_COMPLETED_STAGE=44 ĝis propra akcepto de Gate D.

## Gate A — akceptita (antaŭe registritaj pruvoj)

Kontrakta SHA: f7d7956842c9284b4e0256ce1d126ab24f107cb6.
- Native [45948570370](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45948570370), job 140338847385: 502/502; format/source integrity PASS.
- Names [45948570356](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45948570356), job 140338847235: success.
- Artifact 15176385617, antaŭe kontrolita ZIP SHA-256 74f26705b95e0feef07ea6e923d5166af015ca9dc3f9511bdc88f623b3a07f27; verification.log SHA-256 49ea6f48cd0a7025b52e915fca23529f94794dbe9413c599dd1d7320ce6dc325.
- La matematika antaŭkontrolo 202735/202735 estas abstrakta kardinaleca kontrolo, ne Native aŭ translingva differential.

## Gate B — akceptita sur preciza koda SHA

Komenca SHA a9d2b408955d91c055f20129d250d8cf6df22648: Native 45954421158 malsukcesis ĉe formatter antaŭ testoj; Names 45954421300 success. La antaŭe kontrolita artifact 15177589319 havis ZIP SHA-256 12ec3508a7ec2107fac4163e8cc77e0b96df7bf6bdab746a28abd609302c7c2c.
Post preciza formatter-korekto, SHA 76586227cdfadd1a8f7115b1ab43791a24d53218; la aktuala branĉo estis identical, ahead=0, behind=0. Komparo kun la komenca SHA montras unu commit kaj nur du modifitajn dosierojn.

- Produkto: [discovery_41_joint_directional_deficit.gleam](src/pastafari/discovery_41_joint_directional_deficit.gleam), blob 952519ff78c8525909af16430b0c6bc136de5eb2.
- Testoj: [discovery_41_test.gleam](test/discovery_41_test.gleam), blob 06d2c67fe793834cdfd378fa0d6ded2df64cbce1; 12 unikaj publikaj testfunkcioj.
- Q=(1-CL)(1-CR), reduktita entjera frakcio; vakua flanko donas 0/1. La produkto vokas Stage40 unufoje, konservas previous kaj Error, kontrolas kardinalecojn, kovrojn, limojn kaj identecojn Q=1-2M+J kaj Q=(1-M)^2-S^2/4. Neniu produkta fenestra enumerado aŭ nova dependeco.
- La kontrakta test-orakolo uzas Stage21-gapojn, rektan indeksan fenestran enumeradon kontraŭ originalaj bandoj, ordigitajn parojn kaj minimum-denominatoran serĉon sen produkta gcd. Ĉi tio estas samlingva sendependa test-orakolo, ne translingva differential.

Native [45965017222](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45965017222), job 140391523077, push attempt 1, completed/success:
- Preciza HEAD en checkout, log kaj artifact; Gleam 1.18.1, OTP 28 / ERTS 16.4.0.8.
- 514 passed, no failures; read-only format, tracked/staged/untracked-source kaj HEAD-integrity kontroloj pasis.
- Artifact [15182303942](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45965017222/artifacts/15182303942), 579 bytes, elŝutita ZIP SHA-256 e3a9edf11c6d15ad2ab11c5ae55225b32ee4063868d65c438ef1e8411ae54bea egalas al GitHub digest; ZIP CRC OK.
- verification.log SHA-256 e283e564c352e6e5d7de18d2d0b654d842d29bcddddca40588e106e798983a6e konfirmas saman SHA kaj 514/514.
- Names [45965016984](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45965016984), job 140391522004, push attempt 1, completed/success sur sama SHA; checkout kaj lock-kontrolo en log.
- Unu nebloka antaŭekzistanta averto: unused gleam/list import en discovery_13_next_bowl.gleam:3.

## Gate C — dokumenta fermo, ankoraŭ ne akceptita

Ĉi tiu dokumento kaj DEVELOPMENT_STAGE.md estas dokumenta ŝanĝo nur. Necesas propra sam-SHA Native 514/514, read-only format/source integrity, Names success, job/log kaj elŝutita artifact/digest. Neniu duobla dispatch.

## Gate D — ne komencita

Nur post Gate C: aparta fina metadata-markilo, propra sam-SHA Native 514/514 kaj Names kun kontrolita artifact. LAST_COMPLETED_STAGE restas 44 ĝis Gate D akcepto. Neniu Stage46, main, merge, publikigo, plena datkonverto aŭ politika ŝanĝo.
