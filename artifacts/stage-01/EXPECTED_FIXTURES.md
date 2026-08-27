# Očekivane vrijednosti — etapa 1

Ove su vrijednosti izvedene izravno iz ugrađenoga normativnog dodatka zadatka. Nisu preuzete ni uspoređene s drugim implementacijama.

- `M = 170141183460469231731687303715884105727`.
- `TABLETS_DAY = -278522`.
- `FOUNDATION_DAY = -15055671`.
- `TABLETS_DAY - FOUNDATION_DAY = 14777149`.
- `SAVE(1)=1`, `SAVE(M-1)=M-1`, `SAVE(M)=M`, `SAVE(M+1)=1`, `SAVE(2M)=M`.
- `dayCount(FOUNDATION)=1`, jedan dan prije daje `2`, jedan dan poslije daje `3`, dva dana prije daju `4`, dva dana poslije daju `5`.
- Za `calculationDay = targetDay = FOUNDATION`: `action=1`, `target=1`, `distance=1`, `connection=2`, `direction=2`.
- Drugi red kamena iz početnoga reda `[17,29,43,71,101]` jest `[378,1073,2375,6195,10493]`.
- Prva permutacija šest zdjela jest `[1,2,3,4,5,6]`, a 720. jest `[6,5,4,3,2,1]`.
- Za različite indekse `N=3`, `K=2`, rangovi 1, 2 i 6 daju redom `[1,2]`, `[1,3]`, `[3,2]`.
- Omeđene kompozicije ukupnoga zbroja 6 u dva dijela između 1 i 5 imaju 5 članova; prvi je `[1,5]`, srednji `[3,3]`, posljednji `[5,1]`.
- Pozitivne kompozicije 6 u tri dijela imaju 10 članova. Uz obveznu granicu na prefiksnom zbroju 2 ostaju točno 4: prvi je `[1,1,4]`, posljednji `[2,3,1]`.
- Za duljine mjeseci `[2,2]` postoje točno dva zakonita tkanja u leksikografskom poretku: `[1,1,2,2]` i `[1,2,1,2]`.
- Za duljine `[1,1,1]` postoji točno jedno zakonito tkanje: `[1,2,3]`.
