# Spagetikoletise arengulugu

## Etapp 1 — alglaadimine

### Mida arvati

Esimeses etapis ei ole veel ühtegi ajaloolist eksiarvamust lubatud. Eesmärk on luua ainult neutraalne alus, mille peale hilisemad ekslikud legacy-teed ja paranduskihid saavad ükshaaval tekkida.

### Mida avastati

Selles etapis ei ole avastusetappi. Semantiline allikas on manustatud normatiivne kirjeldus ning test-only oracle ehitatakse sellest Raku keeles uuesti.

### Millest mööda mindi

Mitte millestki. Ühtegi tulevast parandust ega legacy-teed ei ole ette lisatud.

### Miks seis on normatiivselt ohutu

Tootmistee ei kasuta oracle'it ja ei tagasta veel lõplikku kalendriviisikut. Neutraalne infrastruktuur ainult valideerib väljakutse identiteeti, hoiab ühe väljakutse konteksti ning kogub semantikaväliseid mõõdikuid.

### Lisatud koletisekiht

Lisatud on väike, üldine `MonsterContext`, `MonsterDispatcher`, `MonsterManager`, valideerija ja mõõdikukest. Need ei sisalda ühegi tulevase vea spetsiifilist lippu ega parandust.

### Miks kiht ei muuda semantikat

Mõõdikuid, logisid ega harujälge ei loeta ühegi normatiivse otsuse sisendiks. Iga väljakutse saab eraldi konteksti ning kinnitamata semantilist olekut ei jagata väljakutsete vahel.
