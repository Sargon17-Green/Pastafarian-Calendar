# Cam 54 — DISCOVERY 27: rank1 wedi'i ddefnyddio fel index0

**Statws: PENDING_NATIVE_CI.** Nid yw Cam 54 wedi'i ardystio.

## Rhagdybiaeth hanesyddol (arbrofol)

Mae dewiswr blwyddyn 5000 yn derbyn rhestr ymgeiswyr sydd eisoes
wedi'i hidlo a'i threfnu yn ôl hyd esgynnol, wedyn diwrnod agor esgynnol.
Mae'r safon yn dewis `candidates[rank1-1]` ar gyfer `rank1` rhwng 1 ac N.

Mae `LegacyYear5000RankAsIndexAdapter.oldChoose` yn defnyddio
`candidates[rank1 % N]` yn lle hynny: yr elfennau'n cael eu symud
un safle ymlaen gyda lapio o'r olaf i'r cyntaf. Mae'r diffyg hwn
**wedi'i gyflwyno'n fwriadol fel arbrawf**; nid yw'n ddiffyg a
ddarganfuwyd yn y cod cynhyrchu. Mae'r un-elw ar gyfer N=1 yn
MATCH damweiniol ac ni ddylid ei guddio.

## Profion newydd

- 231 pâr giât gwirioneddol o'r oracl `NormativeCalendar.GateTable`;
  cymhwyso'r holl rengau cymwys a chymharu â dewis cywir o'r rhestr.
- 64 rhestr synthetig o ddau ymgeisydd: 128 EXPECTED_RED.
- 64 rhestr sengl: 64 MATCH damweiniol.
- 128 triphlyg gydag `ExactInt` enfawr: 384 EXPECTED_RED,
  128 lapio cylchol ar y rheng olaf.
- Dilysu'r mewnbwn cyn newid cyflwr, perchnogaeth y cyd-destun
  `BOOT → DISCOVERY_27`, counters 128, gwrthod replay, dim effaith
  ar fetrigau mewnbwn annilys.
- `Stage54StrictRedTests` yn methu'n fwriadol gyda'r union god
  `E_DISCOVERY27_STRICT_RANK_AS_INDEX_RED`; rhaid i'r runner
  gadarnhau'r methiant hwn a phasio holl Gamau 1–53.

Mae `src/test/kotlin/pastafari/NormativeCore.kt` a
`NormativeCalendar.kt` yn aros yn oracl prawf-yn-unig.
Nid yw'r hen lwybrau arbrofol yn cael eu cywiro yma; bydd
Cam 55 — PATCH 27 yn gwneud y cywiriad heb ddileu'r graith.

**Rheol cwblhau:** nid yw hyd yn oed Cam 55 yn ddigon:
rhaid cynnal soak sylweddol yn erbyn gweithrediad annibynnol arall
a datrys pob anghysondeb cyn datgan bod y gangen wedi'i chwblhau.
