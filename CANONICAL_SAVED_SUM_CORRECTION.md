# Kanonik saved-sum düzeltmesi — 2026-09-11

Bu dosya, daha eski kaynak/dokümanlarda geçen `rawBowlSum`, `raw bowl sum`, `K½` veya “Düzeltici Aşama 56” ifadelerinin güncel durumunu tek yerde tanımlar.

## Yetkili kural

Her `r = 1..12` final post-stir turunda:

```text
old = tek altı-kâselik snapshot
S = sum(old)
R = SAVE(S + 149*r)
rank = 1 + ((R - 1) mod 720)
order = lexicographic permutation(rank)

u = old[B] + 3*old[P] + 5*old[N] + R + r + position^2
new[B] = SAVE(u^2 + 7*old[P]*old[N])
```

Altı `new[B]` aynı `old` snapshot'ını okur ve birlikte commit edilir.

## Yasak mutant

```text
u = ... + S + r + position^2
```

Bu raw-sum varyantı kanonik değildir. Yalnız `post_stir_bowlsum_detour.py` içinde açıkça işaretli regresyon mutantı olarak kalır.

## Tarihsel adlar

`corrective56_raw_bowlsum`, `sauce_corrective56` ve benzeri adlar eski corrective-56 tarihinden kalmıştır. Adın varlığı raw-sum semantiğinin aktif olduğu anlamına gelmez. Güncel üretim yolu saved-sum kullanır; `sauce_corrective56` test oracle adı da kanonik `sauce` ile aynı sonucu verir.

Eski corrective-56 raporları ve witness'ları raw-sum semantiğini belgeledikleri için `HISTORICAL — SUPERSEDED` olarak saklanır; kanonik expected-output kaynağı değildir.
