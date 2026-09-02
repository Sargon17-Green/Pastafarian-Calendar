# Bootstrap-testane provar den reine referansen, eksakt heiltalsrekning, kjeldekatalogen og den nøytrale grunnmuren.

function fail(name,expected,actual) {
    TEST_FAIL++
    printf("FEIL | %s | venta=%s | faktisk=%s\n",name,expected,actual)
}
function pass(name) { TEST_PASS++; printf("OK | %s\n",name) }
function check_bi(name,actual,expected) { if (bi_eq(actual,expected)) pass(name); else fail(name,expected,actual) }
function check_native(name,actual,expected) { if (actual==expected) pass(name); else fail(name,expected,actual) }
function check_text(name,actual,expected) { if ((actual "x")== (expected "x")) pass(name); else fail(name,expected,actual) }

BEGIN {
    catalog_init(); oracle_init(); fixtures_init()
    TEST_PASS=0; TEST_FAIL=0

    check_bi("M er korrekt",M,FX_M)
    check_bi("M pluss ein",bi_add(M,"1"),FX_M_PLUS_1)
    check_bi("to gonger M",bi_mul_small(M,2),FX_2M)
    check_bi("deling er eksakt",bi_div_floor(FX_2M,M),"2")
    check_bi("euklidsk rest for minus ein",bi_mod_euclid("-1",M),FX_M_MINUS_1)

    check_bi("SAVE av ein",save_big("1"),"1")
    check_bi("SAVE av M minus ein",save_big(FX_M_MINUS_1),FX_M_MINUS_1)
    check_bi("SAVE av M",save_big(M),M)
    check_bi("SAVE av M pluss ein",save_big(FX_M_PLUS_1),"1")
    check_bi("SAVE av to M",save_big(FX_2M),M)

    check_bi("dagteljing før grunnlegginga",day_count(FOUNDATION_DAY-1),"2")
    check_bi("dagteljing på grunnlegginga",day_count(FOUNDATION_DAY),"1")
    check_bi("dagteljing etter grunnlegginga",day_count(FOUNDATION_DAY+1),"3")
    work_counts(FOUNDATION_DAY-1,FOUNDATION_DAY+1)
    check_bi("kronologisk avstand",COUNT_DISTANCE,"3")
    check_bi("sambandstal",COUNT_CONNECTION,"5")
    check_native("retning framover",COUNT_DIRECTION,3)

    check_bi("andre stein kveite",stone_get(2,WHEAT),"378")
    check_bi("andre stein bygg",stone_get(2,BARLEY),"1073")
    check_bi("andre stein salt",stone_get(2,SALT),"2375")
    check_bi("andre stein bitter",stone_get(2,BITTER),"6195")
    check_bi("andre stein raud",stone_get(2,RED),"10493")

    bowl_order_from_number(1)
    check_text("første skålrekkje",ORDER[1] "," ORDER[2] "," ORDER[3] "," ORDER[4] "," ORDER[5] "," ORDER[6],"1,2,3,4,5,6")
    bowl_order_from_number(720)
    check_text("siste skålrekkje",ORDER[1] "," ORDER[2] "," ORDER[3] "," ORDER[4] "," ORDER[5] "," ORDER[6],"6,5,4,3,2,1")

    bc_prepare(10,2,4,6)
    check_bi("tal på små avgrensa samansetjingar",bc_count(10,2),"3")
    bc_unrank(10,2,"2")
    check_text("rang to i avgrensa samansetjing",COMP[1] "," COMP[2],"5,5")

    cp_prepare(6,3,3)
    check_bi("filtrert kottletfamilie",cp_count(6,3,0,0),"4")
    cp_unrank(6,3,"3")
    check_text("rang tre i filtrert kottletfamilie",CUTLET_PART[1] "," CUTLET_PART[2] "," CUTLET_PART[3],"3,1,2")

    MONTH_LENGTH[1]=2; MONTH_LENGTH[2]=2
    weave_prepare(2)
    check_bi("tal på små lovlege vevar",weave_count(),"2")
    weave_prepare(2); weave_unrank("1")
    check_text("første lovlege vev",WEAVE[1] WEAVE[2] WEAVE[3] WEAVE[4],"1122")
    weave_prepare(2); weave_unrank("2")
    check_text("andre lovlege vev",WEAVE[1] WEAVE[2] WEAVE[3] WEAVE[4],"1212")

    unrank_distinct(3,2,"1")
    check_text("første delvise permutasjon",NAME_INDEX[1] "," NAME_INDEX[2],"1,2")
    unrank_distinct(3,2,"6")
    check_text("siste delvise permutasjon",NAME_INDEX[1] "," NAME_INDEX[2],"3,2")

    STREAM_FIRST="922"; STREAM_STEP=1; choose_rank("922")
    check_bi("kort val med rang 922",CHOSEN_RANK,"922")
    STREAM_FIRST="1"; STREAM_STEP=1; choose_rank(bi_add(M,"1"))
    check_bi("breitt val over M",CHOSEN_RANK,bi_add(M,"1"))

    count=0; for (i=1;i<=17;i++) if (catalog_cutlet(i)!="") count++
    check_native("sytten kottletnamn",count,17)
    count=0; for (i=1;i<=47;i++) if (catalog_month(i)!="") count++
    check_native("førtisju månadsnamn",count,47)
    dup=0; for (i=1;i<=17;i++) for (j=i+1;j<=17;j++) if ((catalog_cutlet(i) "x")== (catalog_cutlet(j) "x")) dup++
    check_native("ingen doble kottletnamn",dup,0)
    dup=0; for (i=1;i<=47;i++) for (j=i+1;j<=47;j++) if ((catalog_month(i) "x")== (catalog_month(j) "x")) dup++
    check_native("ingen doble månadsnamn",dup,0)
    check_text("bronse ved canonicalIndex 1",catalog_cutlet(1),"bronse")
    check_text("Lagash ved canonicalIndex 4",catalog_cutlet(4),"Lagash")
    check_text("leopard ved canonicalIndex 9 for månader",catalog_month(9),"leopard")
    check_text("kveite ved canonicalIndex 12",catalog_cutlet(12),"kveite")
    check_text("kopar ved canonicalIndex 19",catalog_month(19),"kopar")
    check_text("mjøl ved canonicalIndex 39",catalog_month(39),"mjøl")
    check_text("katalogen er frosen",CATALOG_FROZEN,"YES")

    sauce(FOUNDATION_DAY,FOUNDATION_DAY)
    for (i=1;i<=6;i++) check_bi("saus-skål " i,SAUCE_BOWL[i],FX_SAUCE_BOWL[i])
    for (i=1;i<=6;i++) check_native("rekkje ved drope 46 posisjon " i,SAUCE_ORDER46[i],FX_ORDER46[i])
    ask_bowl(1,10)
    check_bi("spørsmål ved segl 10",STREAM_FIRST,FX_ASK10_FIRST)
    check_native("spørsmålsretning ved segl 10",STREAM_STEP,FX_ASK10_STEP)

    monster_metrics_reset(); monster_logs_reset()
    check_native("grunn-dispatch",monster_base_dispatch(FOUNDATION_DAY,FOUNDATION_DAY),1)
    check_text("semantisk eigar",MONSTER_CTX["semanticOwner"],"INVOCATION")
    ctxFields=0; for (ctxKey in MONSTER_CTX) ctxFields++; check_native("berre nøytrale bootstrap-felt i konteksten",ctxFields,14)
    check_native("produksjonsbanen er ikkje førtidig implementert",calendarDateSpaghetti(FOUNDATION_DAY,FOUNDATION_DAY),0)
    check_text("bootstrap-status for produksjonsbanen",MONSTER_CTX["status"],"NOT_IMPLEMENTED_BEFORE_INTEGRATION")

    printf("SAMANDRAG | bestått=%d | feil=%d\n",TEST_PASS,TEST_FAIL)
    exit(TEST_FAIL==0?0:1)
}
