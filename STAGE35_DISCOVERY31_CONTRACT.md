# Stadio 35 — DISCOVERY 31: komunaj fenestroj en A kaj B

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO. Programo de 55 stadioj. Ĉi tiu komito enhavas NUR la kontrakton kaj metadatajn korektojn; neniu Stage35-kodo aŭ Gleam-testo estas verkita. Neniu plena datkonverto.

## Konfirmita antaŭkondiĉo

Stage34 fina HEAD \`7a72aed0ca56504d32746ab242b01722981d92de\`: Native run 44828156810, job 136605943808, completed/success, Gleam 1.18.1 / OTP28, 382 passed, no failures, formatter kaj fontintegreco PASS, artefakto 14675022147 sha256:c2184ea605009735c96a9356ee90dec67c739d7aea3e389c357ec29827e25a30. Canonical Names Lock run 44828156832, job 136605943603, completed/success ĉe la sama SHA. Nur Stage34/DISCOVERY30 estas akceptita.

## Matematika kontrakto

Enigo: \`MonsterContext\`, ordigita eksplicita \`List(Int)\` de k bovlo-identigiloj kun eventualaj ripetoj, kaj du listoj A/B de fermitaj entjeraj \`SumBand(lower,upper)\`. Stage21 donas k pozitivajn interspacojn g[i] en [42,963] aŭ originalan eraron. Ne-malplena indeksa fenestro estas (a,b), 0<=a<b<=k, s(a,b)=sum(g[a:b]), T=k(k+1)/2. UA estas la aro de fenestroj kies sumo estas en almenaŭ unu VALIDA intervalo de A; UB analoge. Kalkulu I=|UA∩UB| per la produktidenteco I=|UA|-|UA\UB| (uzante la akceptitan Stage34). Kontrolidenteco: I=|UA|+|UB|-|UA∪UB|.

Malplena A aŭ B donas I=0. Inversa intervalo lower>upper estas malplena, ne eraro. Fermitaj limoj estas inkluzivaj; negativaj kaj ekstremaj BEAM-int valoroj, duplikatoj, interkovroj, apudeco kaj nestoj estas permesitaj. Ripetitaj identigiloj restas malsamaj indeksaj fenestroj (neniu deduplikigo). Invariantoj: 0<=I<=min(|UA|,|UB|)<=T, 0<=|UA\UB|<=|UA|.

## Preciza API kaj vokordo

Nova dosiero: \`src/pastafari/discovery_31_intersection_bands.gleam\`. Nova testdosiero: \`test/discovery_31_test.gleam\`.

~~~gleam
pub type IntersectionWindowCount {
  IntersectionWindowCount(
    canonical_left_bands: List(discovery_27_sum_bands.SumBand),
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_right_bands: List(discovery_27_sum_bands.SumBand),
    left_windows: Int,
    right_windows: Int,
    combined_windows: Int,
    difference_windows: Int,
    intersection_windows: Int,
    total_windows: Int,
  )
}
pub fn dispatch_discovery_31(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(IntersectionWindowCount, discovery_19_interval_value.Discovery19Error)
~~~

1. Voku \`discovery_28_union_bands.dispatch_discovery_28(context,ids,A)\` unufoje. Se Error, redonu tiun saman eraron, sen pluaj vokoj.
2. Nur post Ok voku \`discovery_30_difference_bands.dispatch_discovery_30(context,ids,A,B)\` unufoje. Ĝi interne vokas Stage32 dufoje. En kazo de Error, redonu ĝin sen ŝanĝo. Ne saltu validigadon ĉe malplenaj bandlistoj aŭ ids=[].
3. Prenu Acount=left.qualifying_windows, Bcount=difference.excluded_windows, U=difference.combined_windows, D=difference.difference_windows, I=Acount-D, T=k(k+1)/2. Akceptu nur se \`0<=D<=Acount<=U<=T\`, \`0<=Bcount<=U\`, \`0<=I<=Bcount\` kaj \`I=Acount+Bcount-U\`; alie \`Error(InvalidStream)\`. Redonu la precizajn tri jam-kanonigitajn listojn de Stage32 kaj Stage34, ne rekanonigu.
4. Produktkodo NE vokas Stage21, test/reference, alian lingvan branĉon aŭ plenan datkonverton. Ne ŝanĝu antaŭajn modulojn. Proksimume tri Stage32-vokoj entute; ekstra memoro nur rezulto/listreferencoj, ne fenestra enumerado.

## Sendependa TESTA orakolo

Nur en testoj akiru la interspacojn per Stage21 \`dispatch_discovery_21\`. Per du nestitaj traversoj enumu ĉiun (a,b), kalkulu sumon rekte kaj testu membrecon en la ORIGINALAJ, nekanonigitaj A/B; kalkulu Acount, Bcount, U, I, T rekte. Neniam uzu Stage32..34, produktan subtrahidentemon aŭ produkton por atendataj rezultoj. Kanonaj listoj havas proprajn eksplicitajn fiksaĵojn. 12 planitaj unikaj publikaj gleeunit-testoj (NE jam kreitaj):
1. Malplenaj ids kaj ambaŭ bandlistoj; 2. malplenaj ids kun neuzata malvalida kunteksto; 3. unu gap ĉe inkluzivaj limoj; 4. unu gap nur en A/nur en B; 5. pluraj gapoj kun ekzhausta orakolo; 6. A=[] aŭ B=[]; 7. nur disaj aŭ inversaj intervaloj; 8. duplikataj/nestitaj/interkovrantaj bandoj; 9. apudaj intervaloj kaj tri kanonaj listoj; 10. ripetitaj idoj sen deduplikigo; 11. nevalida uzata kunteksto aŭ ID kun originala erarpropago; 12. ekstremaj pozitivaj/negativaj limoj, komuteco I(A,B)=I(B,A) kaj monotoneco ĉe aldono al A aŭ B.

## Sendependa matematika antaŭkontrolo — NE Gleam Native

Python 3: 12,100 fiksaĵoj (gap-longoj 0..4, valoroj 42/43/963, 10×10 bandfamilioj), plus 12,000 determinismaj kazoj (seed 20261121, 0..8 gapoj, entjeraj limoj inkl. ±10^70): entute 24,100/24,100 egalaj kalkuloj inter rekta du-nesta origina A/B-membreco kaj aparta kanonigo/entjer-intervala binarserĉo de A−(A∪B−B). Nul malkongruoj en la FINA korektita antaŭkontrolo. Dum preparado la sendependa Python-kontrolilo mem havis randan eraron (\`bisect_right\` anstataŭ \`bisect_left\` ĉe fermita supra limo); ĝi estis korektita ANTAŬ la cititaj 24,100/24,100. Ĉi tio NE estas Gleam-kompilo aŭ produktatesto.

## Devigaj akceptopordegoj

A. Ĉi tiu kontrakta SHA (nur DEVELOPMENT_STAGE.md kaj ĉi tiu dosiero) bezonas Native completed/success kun precize **382/382**, read-only \`gleam format --check src test\`, fontintegreco kaj Canonical Names Lock completed/success **ĉe la sama SHA**. Queued/in_progress ne estas PASS nek bloko; ne duobligu CI.
B. Nur post akceptita A, aldonu apartan produktmodulon kaj 12 unikajn publikajn sendepend-orakolajn Gleam-testojn. 394 estas PROGNOZO, ne mezurita Native. Aparta koda SHA bezonas 394/394 Native + Names Lock.
C. Nur post B, apartaj dokumenta fermo kaj fina metadata-komito; ĉiu nova SHA bezonas sian saman-SHA Native 394/394 + Names Lock. \`LAST_COMPLETED_STAGE=35\` nur post ĉiuj pordegoj.
D. Neniu Stage36, main, merge, publikigo, interlingva fixture aŭ plena datkonverto. Konservu Stage34-pruvojn.

## Aparta dokumenta fermo post la koda pordego (2026-11-21; propra CI ankoraŭ nekonfirmita)

La supra enkonduko priskribas la **historian kontraktan komiton**, ne la hodiaŭan kodan staton. La kontrakta SHA `602534d9faf03b03e299a901156e03f92feabfec` estis akceptita per Native [44876536028](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44876536028), job 136762359730, `completed/success`: 382/382 testoj, read-only format kaj fontintegreco PASS; artefakto 14696348225 kun `sha256:a5778c36d5ef3b7fe92e4b2b74a006bbf02ce28e6034345e0ae9c0cad6a1bc95`. Canonical Names Lock [44876536044](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44876536044), job 136762359673, ankaŭ sukcesis ĉe tiu SHA.

La aparta komenca koda SHA [a455a301](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/a455a301d2a752406c5f18ff7e1240a91ee0ae1b) aldonis la modulon `src/pastafari/discovery_31_intersection_bands.gleam` kaj 12 unikajn publikajn testojn en `test/discovery_31_test.gleam`. Native [44884354885](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44884354885), job 136786293819, malsukcesis **nur ĉe formatter antaŭ la testoj**, do neniu testo estis ekzekutita ĉe tiu originala SHA. Artefakto 14698724882 konservas la tiaman pruvon. Names Lock [44884354822](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44884354822) sukcesis.

La preciza nur-formata du-dosiera flikaĵo [9bcc8617](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/9bcc8617d2b3e795091b07ff5f97035e80bb3929), sen ŝanĝo de algoritmo aŭ testaj asertoj, pasis Native [44884456841](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44884456841), job 136786595836: `completed/success`, Gleam 1.18.1 / OTP 28 / ERTS 16.4.0.7, read-only formatter kaj fontintegreco PASS, **394 passed, no failures**. Artefakto [14698834857](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44884456841/artifacts/14698834857), `sha256:4f7586397b3a6c330d9ed95e60cba71812fdbdca595a4f49590825946ec444e3`, havas `head_sha=9bcc8617d2b3e795091b07ff5f97035e80bb3929`. Canonical Names Lock [44884456918](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44884456918), job 136786595966, estas `completed/success`. La unuo-testdosiero enhavas precize 12 apartajn publikajn `*_test` funkciojn kun rekta Stage21-orakolo, sen Stage32–34 en atendataj kalkuloj. **Nur la Stage35-koda pordego estas nun akceptita.**

Ĉi tiu dokumenta fermo ŝanĝas nur `STAGE35_DISCOVERY31_CONTRACT.md` kaj `DEVELOPMENT_STAGE.md`. `LAST_COMPLETED_STAGE=34` ne ŝanĝiĝas. La nuna dokumenta SHA mem devas atingi `completed/success` Native **394/394** (format kaj fontintegreco) KAJ Names Lock ĉe precize la sama SHA. Nur tiam aparta fina metadata-komito rajtas marki `LAST_COMPLETED_STAGE=35`; ankaŭ ties propra SHA devas sukcese trairi ambaŭ samajn pordegojn. Neniu Stage36, full date, main, merge aŭ publikigo.
