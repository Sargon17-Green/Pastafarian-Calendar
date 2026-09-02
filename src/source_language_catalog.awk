# Kjeldekatalogen er normativ berre gjennom canonicalIndex; tekstane er presentasjon på nynorsk.

function catalog_init(    i) {
    delete CUTLET_TEXT; delete MONTH_TEXT

    CUTLET_TEXT[1]="bronse"
    CUTLET_TEXT[2]="rev"
    CUTLET_TEXT[3]="nyre"
    CUTLET_TEXT[4]="Lagash"
    CUTLET_TEXT[5]="tanke"
    CUTLET_TEXT[6]="fire delar av ni"
    CUTLET_TEXT[7]="Palgurash"
    CUTLET_TEXT[8]="papyrus"
    CUTLET_TEXT[9]="klase"
    CUTLET_TEXT[10]="skorpion"
    CUTLET_TEXT[11]="oske"
    CUTLET_TEXT[12]="kveite"
    CUTLET_TEXT[13]="elv"
    CUTLET_TEXT[14]="latter"
    CUTLET_TEXT[15]="Akkad"
    CUTLET_TEXT[16]="horn"
    CUTLET_TEXT[17]="den tomme krukka"

    MONTH_TEXT[1]="leire"
    MONTH_TEXT[2]="granateple"
    MONTH_TEXT[3]="olboge"
    MONTH_TEXT[4]="misunning"
    MONTH_TEXT[5]="Eridu"
    MONTH_TEXT[6]="tannkrem"
    MONTH_TEXT[7]="tre delar av fem"
    MONTH_TEXT[8]="Karshumab"
    MONTH_TEXT[9]="leopard"
    MONTH_TEXT[10]="tinn"
    MONTH_TEXT[11]="tåke"
    MONTH_TEXT[12]="virak"
    MONTH_TEXT[13]="handtein"
    MONTH_TEXT[14]="ribbein"
    MONTH_TEXT[15]="johannesbrød"
    MONTH_TEXT[16]="Uruk"
    MONTH_TEXT[17]="skam"
    MONTH_TEXT[18]="kamel"
    MONTH_TEXT[19]="kopar"
    MONTH_TEXT[20]="brønn"
    MONTH_TEXT[21]="eggeplomme"
    MONTH_TEXT[22]="stjerne"
    MONTH_TEXT[23]="honning"
    MONTH_TEXT[24]="milt"
    MONTH_TEXT[25]="kalkstein"
    MONTH_TEXT[26]="glede"
    MONTH_TEXT[27]="fiken"
    MONTH_TEXT[28]="Ninive"
    MONTH_TEXT[29]="frosk"
    MONTH_TEXT[30]="tjøre"
    MONTH_TEXT[31]="lys"
    MONTH_TEXT[32]="den stengde døra"
    MONTH_TEXT[33]="sesam"
    MONTH_TEXT[34]="nakke"
    MONTH_TEXT[35]="sølv"
    MONTH_TEXT[36]="lilje"
    MONTH_TEXT[37]="storm"
    MONTH_TEXT[38]="esel"
    MONTH_TEXT[39]="mjøl"
    MONTH_TEXT[40]="anger"
    MONTH_TEXT[41]="Babylon"
    MONTH_TEXT[42]="tunge"
    MONTH_TEXT[43]="lin"
    MONTH_TEXT[44]="salt"
    MONTH_TEXT[45]="pære"
    MONTH_TEXT[46]="boge"
    MONTH_TEXT[47]="sand"

    CATALOG_VERSION="1.0.0"
    CATALOG_FROZEN="YES"
}

function catalog_cutlet(idx) {
    if (!(idx in CUTLET_TEXT)) return ""
    return CUTLET_TEXT[idx]
}

function catalog_month(idx) {
    if (!(idx in MONTH_TEXT)) return ""
    return MONTH_TEXT[idx]
}
