# Magilos laikų kalendorius — Racket ir lietuvių kalba

Šis katalogas yra nepriklausomo įgyvendinimo kelio pradžia. Jis sukurtas nuo nulio pagal į užduotį įterptą normatyvinę nuorodą ir nėra perkeltas iš kitos programavimo kalbos įgyvendinimo.

## Dabartinė būsena

Tai yra 1 etapo „Bootstrap“ tarpinė perdavimo būsena. Šaltinio failai parengti, tačiau šiame perdavime vietinis Racket vykdymas dar nebuvo atliktas. Dėl to būsena negali būti vadinama patvirtinta `GREEN` būsena.

Parengta:

- tikslioji sveikųjų skaičių aritmetika, remiantis natūraliais Racket tiksliųjų sveikųjų skaičių mechanizmais;
- normatyvinio etalono modulis testams;
- 17 kotletų ir 47 mėnesių lietuviškas šaltinio kalbos katalogas su nekintamais `canonicalIndex`;
- mažos, nepriklausomai patikrinamos pradinės fikstūros;
- Racket testų karkasas;
- neutrali bazinė `MonsterContext`, validavimo riba, stebimumo būsena ir semantinės būsenos `snapshot -> validate -> commit` karkasas;
- 1 etapo perdavimo ir būsenos dokumentai.

Sąmoningai dar nėra nė vieno 2–53 etapų `legacy` defekto ar jo pataisos. Tolesnė istorinė architektūra negali būti įtraukta iki atitinkamo etapo.

## Vykdymas

Kai Racket yra įdiegtas, iš projekto šaknies vykdyti:

```text
raco test tests/stage01-tests.rkt
```

Papildomas paleidimo failas:

```text
racket run-stage01-tests.rkt
```

Tik po sėkmingo vykdymo galima pakeisti 1 etapo būseną į užbaigtą `GREEN`.

## Šaltinio kalbos taisyklė

Semantikoje naudojami tik kanoniniai indeksai. Lietuviškos eilutės gaunamos tik pateikimo sluoksnyje ir nedalyvauja rikiavime, rango skaičiavime, rango atvėrime, pasirinkime ar semantinio podėlio rakte.
