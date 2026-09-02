# Staðlað úttekt Stage 1

## Umfang

Úttektin ber sjálfstæðu Elm-viðmiðunarvélina saman við innbyggða staðlaða viðmiðið sem Stage 1 var byggt úr. Engin önnur útfærsla, úttak hennar, prófunargögn, skyndiminni, rekjanir eða gátreikningar voru notuð.

## Nákvæmir heiltölur

`Pastafari.ExactInt` heldur formerki og grunntölustöfum í Elm-gildum og framkvæmir samlagningu, frádrátt, margföldun, veldi, gólfdeilingu og euklíðska leif án fleytitölu. Stóri teljarinn er myndaður sem `2^127-1`, ekki sem of stórt Elm-`Int` bókstafsgildi. `SAVE` er skilgreint sem `1 + regularMod(x-1,M)`.

Við framhaldsúttekt var fjarlægð önnur falin stærðartakmörkun: algerar hliðavísitölur í `GateState` og `Year` eru nú `BigInt`, geymdar í orðabók með kanónískum tugastreng vísitölunnar sem lykli. Röð orðabókarinnar hefur því engin staðlað áhrif. Staðbundinn fjöldi hliðabila innan árs er aðeins breyttur í `Int` eftir að ársreglan hefur takmarkað lengdina við 5778 daga; þar sem hvert bil er að minnsta kosti 42 dagar er þessi staðbundni fjöldi alltaf lítill.

Teljari höfnunarskrefa í stutta valinu notar einnig `BigInt`. Því getur langur svarhringur ekki breytt merkingu vegna yfirflæðis í Elm-`Int`.

## Sósan

Úttektin staðfestir eftirfarandi röð: dagatalningar; 46 steinaraðir með sameiginlegri gamalli mynd fyrir alla fimm nýja steina; sjö faldar dropar; 46 sýnilegir dropar með réttum 1/3/7 forverum; röðun sex skála; hellingar á fyrstu þrjú sætin í röðinni; samtímis skálauppfærsla úr einni gamalli mynd; varðveisla raðar dropa 46; og tólf eftirhrærslur.

A1 er útfært nákvæmlega sem `savedBowlSum = SAVE(sum(oldBowls) + 149 * stir)` og sama vistaða gildi er lagt við blöndu hvers skálar í þeirri hrærslu.

## Spurningar og val

Næsti skál er fundinn í varðveittri röð dropa 46. Stefna svarhrings er ákveðin einu sinni. Stutt val notar höfnunarmörkin `floor(M/N)*N` og heldur áfram í sama svarhring. Vítt val myndar eina breiða tölu úr föstum svarstöfum og, eftir höfnun, færist um eitt skref í breiða hringnum án þess að afla nýrra stafa.

## Hlið og ár

Jákvæð hlið spyr um `FOUNDATION+n` og neikvæð hlið um `FOUNDATION-n`. Hliðabil eru 42..963 dagar. Árslengd er 252..5778 dagar; 5779 og hærra komast ekki í gildan árskost. Ár 5000 er valið úr pörum sem innihalda verknaðardaginn á bilinu `(open,close]`, fyrst eftir lengd og síðan eftir fyrra opnunarhliði við jafna lengd. Ferð til markárs er ár fyrir ár. Opnunarhliðið tilheyrir fyrra ári vegna skilyrðisins `targetDay <= openGateDay` í afturleit.

## Kótilettur og mánuðir

Fjöldi kótiletta er takmarkaður við 6..17 og ekki meiri en fjöldi hliðabila ársins. Skipting kótiletta er nákvæm lexíkógrafísk talning/opnun; ef verknaðardagurinn er innra hlið verður það millimark skiptingarinnar. Nöfn eru valin sem hlutumraðanir án endurtekningar og innri merkingin er `canonicalIndex`.

Mánaðafjöldi fylgir mörkunum 4..123 dagar og að hámarki 47 mánuðir. Mánaðalengdir eru taldar og opnaðar með nákvæmu DP án þess að efnisgera alla fjölskylduna. Vefurinn er valinn sem ein heild með DP sem varðveitir bæði röð fyrstu og síðustu birtingar. `dayInMonth` er fjöldi birtinga valins mánaðar frá upphafi árs til og með markdegi.

## Lokaniðurstaða og aðskilnaður

`calendarDateCanonical` skilar nákvæmlega fimm merkingarsviðum. `calendarDate` leysir aðeins kótilettu- og mánaðarvísitölur yfir í fryst íslensk heiti. Ekkert í `src/` flytur inn `NormativeOracle`, þannig að framleiðsluskelin getur ekki notað viðmiðunarvélina sem varaleið eða leiðréttingu.

Við úttektina fannst Elm-sértæk þýðingarvilla í eldri drögum: fjögurra og fimm staka tuple-gildi höfðu verið notuð í stuðlatöflum og í innra vali kótilettuskiptingar. Elm leyfir ekki slík tuple. Þau voru skipt út fyrir nafngreind record-gildi án merkingarbreytingar. Engin fjögurra eða fleiri staka tuple er eftir í Elm-kóðanum.

## Staða

Enginn þekktur merkingarlegur, eignarhaldslegur eða Elm-sértækur byggingargalli er eftir í Stage 1 eftir þessa kyrrstöðuúttekt. Þetta er ekki staðgengill fyrir þýðingu. Raunveruleg Elm 0.19.1 þýðing og keyrsla allra vitna er enn nauðsynleg áður en `LAST_COMPLETED_STAGE` má verða 1.
