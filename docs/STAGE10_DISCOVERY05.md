# ደረጃ 10/55 — DISCOVERY 05 (COMPLETE / EXPECTED_RED)

## የማይቀየር ታሪካዊ አስተዳደር

ስውር ጠብታዎች `hidden1` (ቅርብ) እስከ `hidden7` (ሩቅ) ሆነው ይሰላሉ። ታሪካዊ የማከማቻ ሰንጠረዥ ግን `hidden7, hidden6, hidden5, hidden4, hidden3, hidden2, hidden1` ነው። `old_hidden_slot(backward,k)` የ`backward[k-1]` አካላዊ ሰልፍን እንደ ሎጂካዊ ቅርበት ያነባል፣ `calendar_hidden_by_nearness` በደረጃ 10 አሁንም ይህን የተሳሳተ ንባብ ይጠቀማል።

## የመፍጠሪያ ሂሳብ

የተገላቢጦሽ ኮኤፊሺየንት ሰንጠረዥ እንደዚህ ይጠበቃል፦

```text
[15,22,30,32], [13,19,26,28], [11,16,22,24], [9,13,18,20],
[7,10,14,16], [5,7,10,12], [3,4,6,8]
```

የተጠገኑትን `action`, `target`, `distance`, `connection`, `direction` ቆጣሪዎች ይጠቀማል። የጠብታ k መጀመሪያ የቆጣሪዎቹን ክብደት እና የድንጋይ k አምስት አባላትን ይደምራል፣ `SAVE` ያደርጋል፣ ከዚያም ሰባት ማሰላሰሎችን ያከናውናል። በእያንዳንዱ ማሰላሰል `SAVE(x*x+3*x+stone[k][kind]+g)` ይጠቀማል፤ `kind=[w,b,s,m,r,w,b]` ነው።

## የሚጠበቀው RED ሁኔታ

| ሎጂካዊ መጠይቅ | አካላዊ የተሳሳተ ምላሽ | ትክክለኛ ምላሽ |
|---|---|---|
| 1 | hidden7 | hidden1 |
| 2 | hidden6 | hidden2 |
| 3 | hidden5 | hidden3 |
| 7 | hidden1 | hidden7 |

`hidden4` በራሱ ላይ ስለሚገኝ የGREEN መቆጣጠሪያ ነው። ሰባቱም የተለያዩ የሂሳብ ውጤቶች በአካላዊ ማከማቻ እንዳሉ በ`discovery05_witness_test.v` ይረጋገጣሉ።

## የV ማረጋገጫ

```text
v fmt -verify ./pastafari
v test ./pastafari/normative_oracle_test.v
v test ./pastafari/discovery05_witness_test.v
v -check ./pastafari/discovery05_expected_red_test.v
v test ./pastafari/discovery05_expected_red_test.v
```

የመጨረሻው የRED ሙከራ ፋይል ብቻ መውደቅ አለበት። 14 የቀድሞ እና አዲስ የታሪካዊ ፈተና ፋይሎች GREEN እንዲሆኑ አስፈላጊ ነው። `PATCH 05` በደረጃ 11 ብቻ ይገባል፤ በደረጃ 10 አይጨመርም።

## የV 0.5.2 የተረጋገጠ መዝጊያ

- የተፈተነ commit፦ `e1487442a3a2e93d0477584301a855e977f4fe50`
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38165059747
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38165059747/artifacts/11711703085
- `V 0.5.2 7647ce1`፣ `v fmt -verify` PASS፣ 14 GREEN ፋይሎች PASS፣ 4 የታሰቡ RED assertions በተናጠል ተረጋግጠዋል።
- `calendar_hidden_by_nearness` አሁንም የታሪካዊውን `old_hidden_slot` ይጠራል።
- `PATCH 05` አልተጨመረም፤ ቀጣዩ ደረጃ 11 — `PATCH 05` ነው።

**ደረጃ 10 COMPLETE / EXPECTED_RED።**
