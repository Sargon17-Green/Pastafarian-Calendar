# Stadio 44 — DISCOVERY 40: komuna direkta kovro

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto. Programo: 55 stadioj.
Baza akceptita HEAD: 7d33da68d47b8f031cce5221c546e455d2d16c86; LAST_COMPLETED_STAGE=43.
Rajtigo: la daŭra uzanta regulo de 2026-11-22, GitHub Issue #36, komento 7085562104: neniu aparta rajtigo necesas por transiri inter stadioj en ĉi tiu sama ekzistanta branĉprogramo. Tio rajtigas ĉi tiun planitan Stage44-kontrakton; ĝi ne rajtigas main, merge, protektitajn branĉojn, publikigon, malfortigon de orakoloj, translingvajn fiksaĵojn aŭ plenan datkonverton.

## Akceptita bazo — Stage43

Stage43 / DISCOVERY39 estas akceptita 43/55 ĉe la fina metadata-markilo SHA 7d33da68d47b8f031cce5221c546e455d2d16c86.
- Native run 45696349938, job 139494640936: completed/success, 490/490, Gleam 1.18.1, OTP 28 / ERTS 16.4.0.8; read-only `gleam format --check src test`, tracked/staged diff, untracked-source kaj HEAD-integrity kontroloj sukcesis.
- Artifact 15060647940: elŝutita ZIP SHA-256 `d94cf4e5a1071cb59f8a3e545afd617506fe9f788ce515707e272eddd8f6a91d`, egala al GitHub digest. `verification.log` enhavas la saman HEAD kaj `490 passed, no failures`; SHA-256 de la eltirita log: `61cbdbf846788a130e84cd3479bf21f13ed4a5465d79be9ca87e3b1da9e3109d`.
- Canonical Names Lock run 45696347863, job 139494634200: completed/success; log konfirmas checkout de la sama SHA kaj sukcesan CANONICAL_NAMES_LOCK-kontrolon.
- Branch HEAD komparita kun la markilo SHA: identical, ahead=0, behind=0.
- Unu nebloka kompilila averto restas en `src/pastafari/discovery_13_next_bowl.gleam:3` (unused import `gleam/list`); ĝi ne influis la 490 testojn aŭ la fontintegrecajn kontrolojn.

Ĉi tiuj estas Stage43 Gate D-akceptaj pruvoj; ili NE estas Stage44 Gate A.

## Kontrakto — komuna direkta kovro

La antaŭaj stadioj jam liveras du direktajn kovrojn:
- (C_L = I/L), kun la eksplicita Stage36 vakua konvencio (C_L=1) kiam (L=0).
- (C_R = I/R), kun (C_R=1) kiam (R=0).

Stage44 aldonas unu simetrian multiplikan mezuron:
[
J = C_L \cdot C_R.
]

Por (L>0) kaj (R>0):
[
J = \frac{I^2}{L\,R}.
]

La mezuro estas la produkto de la du reciprokaj kovroproporcioj. Ĝi estas sendimensia, simetria sub interŝanĝo de A kaj B, kaj konservas la efikon de ambaŭ direktoj samtempe. Ĝi ne estas probablo-aserto.

### Vakua kaj nula konvencio

- (L=0, R=0): (C_L=C_R=1), do (J=1/1).
- Ĝuste unu el (L,R) estas nulo: unu kovro estas 1 kaj la alia 0, do (J=0/1).
- (L>0, R>0, I=0): ambaŭ kovroj estas 0, do (J=0/1).
- (L>0, R>0, I>0): (J=I^2/(LR)), reduktita.

La publika rezulto estas frakcio (p/q), kun (q>0), (0\le p\le q), kaj (gcd(p,q)=1). Neniu glitkomo.

### Algebraj identecoj kaj invariantoj

Kun la heredaj Stage37 signita diferenco (S=C_L-C_R), Stage38 meza kovro (M=(C_L+C_R)/2), kaj Stage39 relativa signita malsimetrio (A=S/M) kiam (M>0):
[
J=C_L C_R=M^2-\frac{S^2}{4}
 =M^2\left(1-\frac{A^2}{4}\right).
]
La identecoj estas kontrolataj per krucomultipliko. Kiam (M=0), Stage39-konvencio donas (S=A=0), kaj (J=0); kiam ambaŭ flankoj estas malplenaj, (M=1,S=A=0,J=1).

Devigaj ecoj:
- (0\le J\le1); denominatoro pozitiva; frakcio plene reduktita.
- Interŝanĝi A kaj B ne ŝanĝas J.
- (J=1) kiam ambaŭ flankoj estas malplenaj aŭ kiam la du fenestraroj estas identaj kaj ne-malplenaj.
- (J=0) kiam unu flanko estas malplena aŭ kiam la intersekco estas malplena.
- Por pozitivaj L,R, la rekta kardinaleca formulo (pLR=I^2q) devas kongrui.
- La produkta frakcio devas egali la produkton de la du hereditaj kovrofrakcioj.
- La antaŭa Stage39-rezulto devas esti konservita sen modifo.

## API kaj produkta disciplino

Nova produkto: `src/pastafari/discovery_40_joint_directional_coverage.gleam`.
Nova testdosiero: `test/discovery_40_test.gleam`.

Publika tipo:
```gleam
JointDirectionalCoverage(
  previous: discovery_39_relative_directional_asymmetry.RelativeDirectionalCoverageAsymmetry,
  joint_coverage_numerator: Int,
  joint_coverage_denominator: Int,
)
```

Publika funkcio:
```gleam
dispatch_discovery_40(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(JointDirectionalCoverage, discovery_19_interval_value.Discovery19Error)
```

La nova produktmodulo devas:
1. Voki precize unufoje `discovery_39_relative_directional_asymmetry.dispatch_discovery_39` kun la samaj argumentoj, ankaŭ por malplenaj enigoj.
2. Repropagi ĉiun `Error` senŝanĝe kaj konservi la `previous` Stage39-valoron sen modifo.
3. Legi la heredajn (L,R,I), la du kovrofrakciojn, (S), (M) kaj (A) el la Stage39-rezulto.
4. Kontroli pozitivajn denominatorojn, redukton kaj intervalo-validon de la du kovrofrakcioj; por nula kardinaleco uzi ĝuste la supre difinitan vakuan konvencion.
5. Formi (n_0=C_{L,n}C_{R,n}) kaj (d_0=C_{L,d}C_{R,d}); postuli (d_0>0).
6. Redukti (n_0/d_0) per loka Eŭklida gcd; (gcd(0,d_0)=d_0).
7. Kontroli (q>0), (0\le p\le q), (gcd(p,q)=1), kaj (p d_0=n_0 q).
8. Kontroli la kardinalecan formulon por ĉiuj kvar kazoj: ambaŭ malplenaj, ĝuste unu malplena, ambaŭ ne-malplenaj sed disaj, kaj pozitiva intersekco.
9. Kontroli per krucomultipliko (J=M^2-S^2/4) kaj (J=M^2(1-A^2/4)); malkongruo redonas `InvalidStream`.
10. Ne voki Stage21, ne enumeri fenestrojn, ne kanonigi aŭ kunfandi bandojn, ne aldoni dependecojn kaj ne importi alian lingvon.

Kosto super Stage39: O(log(max(1,d0))) Eŭklidaj paŝoj kaj O(1) pliaj entjeraj valoroj; neniu konstanta bitkosta aserto por grandaj entjeroj. Ĉiuj kalkuloj estas preciza entjera aritmetiko.

## Sendependa test-orakolo kaj precize 12 testoj

Nur en `test/discovery_40_test.gleam`:
- Ricevi gapojn per Stage21 kaj rekte enumeri ĉiujn indeksajn fenestrojn (0\le a<b\le k); ripetitaj ID-oj restas apartaj laŭ indekso.
- Kalkuli (L,R,I) per rekta membreco kontraŭ la ORIGINALAJ A kaj B-bandoj; ne uzi la produktajn nombrilojn de Stage36–40 por konstrui atendatajn rezultojn.
- Rekalkuli (J) el la kardinalecoj per eksplicitaj nul-kazoj; por (L,R>0), serĉi la plej malgrandan pozitivan denominatoron por (I^2/(LR)). Ne uzi produktan gcd.
- Sendepende kontroli la hereditajn Stage36/37/38/39-kampojn kontraŭ la rekta fenestra orakolo.
- Kontroli simetrion, intervalon, minimuman denominatoron, (J=C_LC_R), kaj la du algebrajn identecojn per krucomultipliko.

Precize 12 unikaj publikaj `*_test`:
1. `discovery_40_both_empty_test` — (L=R=I=0); (J=1/1).
2. `discovery_40_left_empty_test` — (L=0<R); (J=0/1).
3. `discovery_40_right_empty_test` — (R=0<L); (J=0/1).
4. `discovery_40_disjoint_nonempty_test` — (L,R>0,I=0); (J=0/1).
5. `discovery_40_equal_nonempty_test` — identaj ne-malplenaj fenestraroj; (J=1/1).
6. `discovery_40_left_subset_test` — atestanto (L=3,R=7,I=3); (J=3/7).
7. `discovery_40_right_subset_test` — interŝanĝita atestanto; (J=3/7).
8. `discovery_40_partial_overlap_test` — (L=5,R=3,I=2); (J=4/15).
9. `discovery_40_asymmetric_overlap_test` — (L=7,R=5,I=3); (J=9/35).
10. `discovery_40_index_multiplicity_and_duplicate_bands_test` — ripetitaj ID-oj kaj duplikataj bandoj; kontrolu ke indeksa obleco ne perdiĝas.
11. `discovery_40_wide_inverted_and_error_priority_test` — limoj ĝis (10^{70}), inversaj bandoj, InvalidBowlId kaj InvalidContext kun ĝusta prioritato.
12. `discovery_40_matrix_test` — determinisma matrico (k\le12); rekta orakolo, interŝanĝa simetrio, diagonala valoro 1, intervaloj, reduktita denominatoro kaj algebraj identecoj.

## Ekstera matematika antaŭkontrolo — ne Native

Python-entjera aritmetiko, sendependa de Gleam kaj de la produkta modulo, ekzamenis ĉiujn realigeblajn kardinalecajn statojn por (k=0..12): (T=k(k+1)/2), (0\le L,R\le T), (0\le I\le\min(L,R)), (L+R-I\le T). Entute 202735 statoj.
Por ĉiu stato, la frakcio (J) per entjera produkto estis komparita kun aparta minimum-denominatora serĉo; samtempe kontrolitaj (J=C_LC_R), (J=M^2-S^2/4), (J=M^2(1-A^2/4)), la vakua konvencio kaj (0\le J\le1). Rezulto: 202735/202735 kongruis, neniu malkongruo; maksimuma reduktita denominatoro 5929. Tio estas nur matematika antaŭkontrolo, NE Gleam, CI, Native aŭ differential PASS.

## Devigaj SHA-pordegoj

A. Kontrakto: nur ĉi tiu kontrakto kaj minimumaj ŝanĝoj en `DEVELOPMENT_STAGE.md`. Akcepto post sama-SHA Native 490/490, read-only format/source integrity PASS, Gleam 1.18.1/OTP28, Canonical Names Lock completed/success, job/log/artifact/head_sha/digest kaj verification.log.
B. Nur post A: unu nova produkta modulo kaj precize 12 unikaj publikaj testoj. 502/502 estas antaŭdiro, ne rezulto. Akcepto post propra sama-SHA Native 502/502 + Names, kun job/log/artifact/digest.
C. Nur post B: dokumenta fermo kun propra sama-SHA Native 502/502 + Names.
D. Nur post C: fina metadata-markilo kun propra sama-SHA Native 502/502 + Names. Nur tiam LAST_COMPLETED_STAGE=44.
Ĝis D, LAST_COMPLETED_STAGE=43. queued/in_progress ne estas PASS nek bloko; ne lanĉi rerun duoblan. Neniu Stage45, main, merge, publikigo, plena datkonverto aŭ ŝanĝo de politiko.
