# Python+Türkçe — kanonik saved-sum düzeltme deltası

Bu paket `Sargon17-Green/Pastafarian-Calendar` deposundaki `Python+Türkçe` dalına,
`cdb1033ac19f78acf16aedc769efba81052f2c5c` tabanı üzerine uygulanmak üzere hazırlanmıştır.
Gözlenen HEAD, beklenen HEAD ile aynıdır.

## Sonuç

Düzeltme gereklidir. Dalın temel post-stir yordamı `postStirRoundExact` zaten doğru
saved-sum kuralını uyguluyordu; ancak güncel üretim entegrasyonu tarihsel
`corrective56_raw_bowlsum=True` yolunu etkinleştirerek sonucu noncanonical raw-sum
varyantına çeviriyordu. Bu delta, üretim ve normative/reference yollarını yeniden
kanonik saved-sum semantiğine bağlar ve raw-sum yordamını yalnız açıkça işaretli
regresyon mutantı olarak bırakır.

Kanonik tur:

```text
S = sum(oldBowls)
R = SAVE(S + 149*r)
rank = 1 + ((R - 1) mod 720)
u = old[B] + 3*old[P] + 5*old[N] + R + r + position^2
new[B] = SAVE(u^2 + 7*old[P]*old[N])
```

Altı `new[B]` aynı `oldBowls` snapshot'ını okur ve birlikte commit edilir.

## Discriminator kanıtı

Gerçekten çalıştırılan hedefli örnek:

- old bowls: `(0, 11, 13, 17, 19, 23, 29)`
- `r = 1`
- `S = 112`
- `R = 261`
- permutation rank: `261`
- permutation: `(3, 1, 6, 4, 2, 5)`
- kanonik/üretim sonucu: `(0, 227180, 225843, 164987, 204240, 199572, 184647)`
- raw-sum mutant sonucu: `(0, 108427, 107388, 66796, 92639, 89163, 79304)`

Böylece `S != R`, permutation aynı `R` üzerinden seçilir ve fark yalnız yanlış
raw `S` teriminin `u` içine sokulmasıyla ortaya çıkar. Mutant öldürülür.

## Yerel doğrulama

Gerçekten çalıştırılan kontroller ve sonuçları `artifacts/canonical-saved-sum/LOCAL_EXECUTION_LOG.txt`
içinde ayrıntılıdır. Özet:

- değiştirilen Python dosyaları için `py_compile`: PASS;
- gerçek `postStirRoundExact` üzerinde hedefli saved-sum/raw-sum discriminator: PASS;
- dört deterministik oracle uyumluluk vakası: PASS;
- drop 46 sonrası bowls + 12 turun her biri için bağımsız intermediate witness üretimi: PASS;
- production raw-flag/import izolasyon taraması: PASS;
- semantic-cache fingerprint değişikliği denetimi: PASS;
- dal ağacında browser/JS/service-worker/public-site yolu bulunmadığının denetimi: PASS.

Tam native repository suite bu paket hazırlanırken çalıştırılmadı. Tam checkout üzerinde
çalıştırılmak üzere güncellenmiş GitHub Actions işi; historical regressions, Stage 54,
Stage 55, saved-sum discriminator ve acceleration/cache testlerini içerir. Çalıştırılmamış
kontroller manifestte açıkça `prepared_but_not_run` altında listelenmiştir; hiçbiri PASS
olarak sunulmaz.

## Tarihsel materyal

Eski corrective-56 raw-sum raporu ve witness dosyaları silinmez; başlarına/açıklamalarına
`HISTORICAL — SUPERSEDED` / `HISTORICAL_SUPERSEDED=YES` işaretleri eklenmiştir.
Raw-sum kodu yalnız `post_stir_bowlsum_detour.py` içinde kasıtlı test mutantı olarak tutulur.

## Uygulama

ZIP içeriğini depo köküne göre overlay olarak açın. Silinmesi gereken yol yoktur; bu nedenle
`DELETE_PATHS.txt` kasıtlı olarak yoktur. `.git`, build cache, editor dosyaları ve hiçbir
`HANDOFF_*` dosyası pakete dahil değildir.
