# Stadio 16 — DISCOVERY 12: dek du postaj miksadoj

**Stato 2026-10-31:** koda etapo konfirmita GREEN ĉe `30c590f13376a33c2239accd4c72fa6a3977fc51`: 166/166 testoj, Gleam 1.18.1/OTP28, format kaj source integrity PASS; Native run 41222191573/job 124598906618, artefakto 13050721420 SHA256 `f99ec9c5c70d22e6dbee3a31bf2085a6774621cf54a373d5a4a53839a7fd9e4a`. Names Lock run 41222191012/job 124598905186 SUCCESS. Fina dokumenta HEAD devas esti kontrolita aparte.

## Deveno kaj pordo

Stage15 koda HEAD `a0733dce8b4a1cd6613156042381fba10b2771a0`: Native `41216294550`, job `124581411544`, Gleam 1.18.1 / OTP 28, formatter PASS, source integrity PASS, **154/154** testoj, artefakto `13047852680` SHA256 `bd6510af4a496339e9aab4f17968a4d5e04bae034e90c9361bb13de4a1685b2a`. Names Lock `41216294568`, job `124581411516` SUCCESS. Stage15 posta dokumenta HEAD devos esti revalidigita aparte antaŭ Stage16 koda akcepto.

## API kaj algoritmo

Sendepende krei `src/pastafari/discovery_12_post_stir.gleam` kun `post_stir_for_days(calculation_day: Int, target_day: Int) -> #(List(Int), List(Int))` kaj `dispatch_discovery_12(context: bootstrap.MonsterContext) -> Result(Discovery12Output,bootstrap.BootstrapError)`. Komenca stato estas Stage15 `#(B^(46), order_at_drop_46)`, kaj la dua eliga listo **restu ĝuste la ordo de guto 46**, ne ordo de postmiksado. La unua listo enhavu la ses finajn bovlojn laŭ identigilo 1..6.

Por `t=1..12`, la malnova ses-elementa listo estas `B`. Difinu `Q=save(sum(B)+149*t)`, `rank=1+mod(Q-1,720)`, `O=permutation_unrank1(rank,[1..6])` (ekvivalente, propra Stage11 malkodilo por Q). Por identigilo `j=1..6`: `p=position_of(O,j)`, `prev=O[wrap1(p-1,6)]`, `next=O[wrap1(p+1,6)]`; `S=B[j]+3*B[prev]+5*B[next]+Q+t+p²`; `B'[j]=save(S²+7*B[prev]*B[next])`. Ĉiuj B'-oj uzu la **saman antaŭan B** (sinkrona paŝo). Uzu arbitre precizajn entjerojn, `M=170141183460469231731687303715884105727`, kaj `save(x)=1+mod(x-1,M)` kun ne-negativa restaĵo. Neniuj novaj datokomponentoj; neniu demando/answer-stream aŭ plena datkonverto.

## Testoj, orakolo, limoj

La nura testa orakolo estu `test/reference/sauce.gleam::post_stir_12` aplikita al la referencaj bovloj post 46 gutoj per la referencaj sauce/core-funkcioj. Ordo ĉe guto 46 kompariĝu aparte. Produktkodo neniam importu test/reference, nek reuzu fremdlingvan branĉon.

Plani **12** novajn funkciojn en `test/discovery_12_test.gleam`: (1) ses finaj bovloj, (2) fina ordo konservita de Stage15, (3) fundamento/orakolo, (4) antaŭen, (5) inverso, (6) alia sama tago, (7) fundamenta limo ambaŭdirekte, (8) BigInt ambaŭdirekte, (9) ĉiuj valoroj inter 1 kaj M, (10) determinismo kaj unu-miksa sinkrona sentinelo kun sendepende kalkulitaj nombroj, (11) du validaj interplektitaj kuntekstoj kun diagnoza konservado, (12) retry/recovery-erara prioritato. Ĉiu antaŭa **154** testoj restu; 166/166 estas nur **prognozo**, ne jam mezurita Native.

Pordegoj: `gleam format --check src test`, `gleam test`, source integrity, GH Actions Native completed/success kun preciza SHA/job/artefakto+digest, kaj Names Lock completed/success ĉe sama SHA; distingenda koda HEAD kaj fina dokumenta HEAD. Ne modifi main, ne merge, ne publikigi.
