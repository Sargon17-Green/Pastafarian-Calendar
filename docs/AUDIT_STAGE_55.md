# Cam 55 — PATCH 27: un-seiliedig rank1 yn mynegai sero-seiliedig

## Statws: PENDING_NATIVE_CI

Mae `Year5000RankIndexPatchWrapper.patch` yn galw
`LegacyYear5000RankAsIndexAdapter.oldChoose` **unwaith yn union**,
gan gadw'r `wrongChosen` a `wrongIndex0` fel tystiolaeth o'r
graith arbrofol Cam 54. Yna mae'n cyfrifo
`index0 = (rank1 - 1)`, yn dewis yr ymgeisydd cywir
o'r rhestr sydd eisoes wedi'i hidlo a'i threfnu,
ac yn cofnodi a gafwyd cywiriad.
Nid yw'r addasydd Cam 54 yn cael ei newid.

Mae `Year5000RankIndexPatchManager` yn dilysu cyn
creu'r cyd-destun, yn cadw `BOOT → PATCH_27`, yn
cynyddu metrigau ar alwadau llwyddiannus yn unig ac
yn gwrthod replay. Nid yw'r cynhyrchu yn mewnforio
`NormativeCore` nac `NormativeCalendar`.

## Meini prawf derbyn

Mae `run-stage55-tests.sh` yn galw holl brofion
Camau 1–54, gan gynnwys strict RED Cam 54.
Yna mae'n gwirio'r canlynol ar yr oracl gwreiddiol:

- 231 pâr giât gwirioneddol: 43 ymgeisydd cymwys,
  43 cywiriad GREEN a 43 hen wahaniaeth RED.
- 64 rhestr synthetig dau ymgeisydd:
  128 cywiriad a 128 hen wahaniaeth;
  64 rhestr sengl yn MATCH damweiniol cywir.
- 128 triphlyg gyda `ExactInt` enfawr:
  384 cywiriad, 384 hen RED, 128 lapio olaf.
- 64 pâr â hyd cyfartal: 128 dewis rank
  ar ôl trefnu ar hyd yna diwrnod agor esgynnol.
- Hyd 252 a 5778, gwiriadau mewnbwn,
  perchnogaeth cyd-destun, metrigau, BOOT a replay.

**Peidiwch â newid `LAST_COMPLETED_STAGE=54` hyd nes PASS
gwirioneddol yn y swydd Kotlin CI.**

## Soak ar ôl Cam 55 — GORFODOL

Mae'r cynllun 55 cam yn ffin datblygu, **nid** yn dystysgrif
cwblhau'r gangen. Wedi i Cam 55 basio, rhaid
cyflawni soak cynrychiadol a pharhaus gyda
gweithrediad ANNIBYNNOL o'r calendr, gan gymharu
pob un o bum maes semantig:
blwyddyn, mynegai cytled, diwrnod mewn cytled,
mynegai mis, diwrnod mewn mis.

Rhaid i'r tyst gynnwys gwrthdaro ar derfynau,
cyfnodau pell, parau (c,t) anghyfartal, pob
math o amgáu blwyddyn, a phrofi eglurder
indecsau canonaidd yn hytrach na thestun
Cymraeg neu destun lleoledig. Nid yw cymharu
yn erbyn `NormativeCalendar` ar ei ben ei hun
yn bodloni prawf gweithrediad annibynnol.
Cadwch gofnodion, had a rheolau samplu, a
gwirio ym mhob anghysondeb cyn unrhyw ardystiad.

**Ni fydd llwyddiant y profion Cam 55 yn troi
`SPAGHETTI_MONSTER_IMPLEMENTATION_COMPLETE` yn YES.**
