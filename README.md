# Pastafari kalender — Raku ja eesti lähtekeel

See puu on sõltumatu `Raku + eesti` teostusliini esimese etapi algseis. Puu on loodud nullist ainult manustatud normatiivse kirjelduse põhjal. Ühtegi teise programmeerimiskeele kalendriteostust, selle väljundit, testi, fikstuuri, tabelit, logi ega räsi ei kasutata semantilise allikana.

## Etapi 1 ulatus

Esimene etapp sisaldab ainult ajalooliselt neutraalset alust:

- ühe väljakutse omandis olev põhikontekst;
- põhitaseme dispetšer, valideerija ja mõõdikukiht;
- külmutatav eesti lähtekeele kataloog 17 kotleti- ja 47 kuunimega;
- testide poolel puhas normatiivne oracle;
- samas Raku liinis loodud väikesed sõltumatud fikstuurid;
- Raku testikäivitaja.

Ühtegi 26 tulevasest legacy-veast ega nende parandusest ei ole tootmiskoodis ette loodud. `calendar-date-spaghetti` on selles etapis teadlikult ainult avaliku tootmistee kest ja keeldub kalendritulemust tagastamast, sest lõplik autoriteetne tootmistee tekib ajalooliselt alles hilisemates etappides. Test-only oracle ei ole tootmisteest imporditav.

## Täisarvud

Rakudo/Raku `Int` on suvalise täpsusega. Seetõttu ei ole vaja võõrkeelset FFI-d, sidumist ega eraldi täisarvuteeki. Normatiivne aritmeetika kasutab ainult täpseid täisarve; ujukomaaritmeetikat ei kasutata.

## Testimine

Käivita projekti juures:

```text
raku -Ilib -It/lib t/01-stage01.t
```

või:

```text
raku bin/run-stage01-tests.raku
```

Test-only oracle asub `t/lib/Pastafari/Normative/Oracle.rakumod`. Tootmiskood ei impordi seda moodulit.

## Oluline ajalooline piirang

Etapis 1 ei tohi olla `old...`, `legacy...`, patch-lippe ega hilisemate etappide vigaseid teid. Need lisatakse ainult vastavas DISCOVERY etapis. Selline ajastus on osa teostuse semantikavälisest, kuid kohustuslikust arheoloogiast.
