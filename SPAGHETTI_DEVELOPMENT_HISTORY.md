# Spagečių monstro kūrimo istorija

## 1 etapas — Bootstrap

### Kas padaryta

Sukurtas visiškai naujas Racket ir lietuvių kalbos įgyvendinimo kelias. Parengtas testams skirtas normatyvinis etalonas, šaltinio kalbos katalogas, pradinės fikstūros ir neutrali bazinė monstro infrastruktūra.

### Ką šiuo metu manėme

Pradiniame etape dar nėra istorinės klaidingos prielaidos. Šio etapo paskirtis — sukurti vietinį etaloną ir saugų bendrą karkasą, kuris vėliau galės būti apsunkinamas tik istorine tvarka.

### Kas aptikta

Joks 1 etapo semantinis neatitikimas dar negali būti laikomas patikrintu ar paneigtu, nes šiame tarpiniame perdavime Racket testai dar nebuvo paleisti.

### Koks apėjimas pridėtas

Joks istorinis apėjimas nepridėtas. 01–26 pataisų kodas šiame etape draudžiamas.

### Monstro sluoksnis

Pridėta tik neutrali bazė: vienos iškvietos kontekstas, bazinė validavimo riba, stebimumo registravimas ir semantinės būsenos transakcinio patvirtinimo karkasas. Šios dalys dar neįgyvendina jokio būsimo `legacy` defekto.

### Kodėl sluoksnis nekeičia semantikos

Bazinis karkasas neteikia kalendoriaus rezultato ir nenaudoja žurnalų ar metrikų kaip semantinių įvesčių. Laukianti semantinė būsena gali tapti patvirtinta tik po aiškaus validatoriaus patvirtinimo.
