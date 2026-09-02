# Eignarhald merkingarástands — Stage 1

## Niðurstaða

Eignarhald merkingarástands í Stage 1 er staðfest með sérstakri yfirferð á öllum inngöngum, líkansræsingu, áhrifamörkum, endurnýtingu myndaðra gagna og röð prófana. Niðurstaðan byggist ekki aðeins á óbreytanleika Elm: hver möguleg tengileið var skoðuð sérstaklega. Engin sameiginleg breytanleg merkingargögn eru til í framleiðsluskelinni eða viðmiðunarvélinni.

## Framleiðslusamhengi

`Pastafari.MonsterBase.newContext` býr til nýtt `BaseContext` fyrir hvert kall. Samhengið inniheldur aðeins inntaksdagana, lífsferilsstöðu, framkvæmdarslóð, mælingar og greiningargögn. `dispatch` og `recordMetric` skila nýju samhengi; ekkert annað samhengi er lesið eða skrifað. Engin sameiginleg skrá, skyndiminni, áhrifagátt eða önnur breytanleg geymsla er til í `src/` á Stage 1.

Mælingar og greiningargögn eru athugunarástand. Þau eru ekki lesin af reikniritinu sem mótar inntaksdagana eða staðlaða viðmiðunarniðurstöðu. `Pastafari.Spaghetti` tekur aðeins tvo daga og býr sjálft til samhengi fyrir kallið.

## Ræsing líkans

`Stage01Harness.Model` er einingargildið `()`. `init` býr því ekki til, varðveitir né endurnýtir merkingarástand milli keyrslna. Inntaksflögg eru einnig `()`. `update` skilar sama einingargildi og `subscriptions` er alltaf `Sub.none`.

## Áhrif og gáttir

Hrein prófunarrökfræði er í venjulegu Elm-einingunni `Stage01Checks`; hún hefur engar gáttir og engin áhrif. Eina gáttin í verkefninu er útleiðin `report : String -> Cmd msg` í þunna `Stage01Harness` millilaginu. Hún flytur aðeins fullgerðan prófunartexta út úr Elm. Ekkert inntaksport er skilgreint og engin ytri áhrif geta gefið viðmiðunarvélinni, framleiðsluskel eða `BaseContext` merkingarlegt inntak. Framleiðslueiningarnar undir `src/` eru ekki gáttareiningar.

## Endurnýting myndaðra gagna

`NormativeOracle.buildStones` er óbreytanlegt Elm-gildi. `Array.set`, `Array.push`, `Dict.insert` og allar listaaðgerðir í viðmiðunarvélinni skila nýjum gildum; eldri útgáfa er áfram sérstakt gildi. Hliðarástandið `GateState` er alltaf tekið sem fallainntak og skilað sem fallaniðurstaða. Enginn falinn hliðaskyndiminni eða byggingarskyndiminni er til á Stage 1.

Hliðavísitölur eru `BigInt`; orðabókin notar eingöngu kanónískan tugastreng vísitölunnar sem aðgangslykil. Röðun færslna í `Dict` er aldrei lesin til að ákvarða hlið, ár eða aðra staðlaða röð.

`Stage01Checks` inniheldur sérstakan vitnisburð sem reiknar sömu sósu, reiknar aðra sósu á milli og reiknar síðan fyrri sósuna aftur. Niðurstöður fyrra inntaks verða að vera nákvæmlega eins fyrir og eftir millikallið. Þannig er endurnýting steinatöflunnar og annarra óbreytanlegra gilda prófuð gegn söguháðri mengun.

## Röð prófana og kalla

`Stage01Checks` byggir tvö óháð `BaseContext` bæði í A→B og B→A röð og krefst sömu lokagilda. Hann breytir mælingum og lífsferilsstigi í einu samhengi og staðfestir að hitt samhengi sé enn nákvæmlega nýtt samhengi. Samanburðurinn ber sviðin saman beint og notar `Dict.toList` aðeins fyrir athugunarmælingar; engin record-jöfnun á földu fallgildi er notuð.

Prófin nota engin sameiginleg breytanleg gildi, ekkert handahófsfræ, enga klukku og ekkert umhverfisgildi. `checks` er hreint Elm-gildi og hver vitnisburður fæst aðeins úr föstum gögnum eða hreinum föllum. Gáttarmillilagið sér aðeins `Stage01Checks.summary` eftir að hreini útreikningurinn er fullgerður.

## Aðskilnaður viðmiðunarvélar og framleiðslukóða

`NormativeOracle` er aðeins undir `tests/` og ekkert í `src/` flytur það inn. `Pastafari.Spaghetti` getur því hvorki lesið oracle-niðurstöðu né notað viðmiðunarvélina sem varaleið. Viðmiðunarvélin deilir heldur engu samhengi með framleiðslukallinu.

## Keyrslustaða

Byggingarlega er atriðið `SEMANTIC_STATE_OWNER_VALIDATED` lokað og er því sett á `YES`. Keyrsluvitnin fyrir milliköll og röðaróháð samhengi eru hluti af `Stage01Checks`. Raunveruleg Elm 0.19.1 keyrsla er enn nauðsynleg til að staðfesta að vitnin standist í verkfærakeðjunni; það breytir ekki niðurstöðu eignarhaldsúttektarinnar, en kemur í veg fyrir að Stage 1 sé merkt lokið.
