# HISTORICAL — SUPERSEDED: Düzeltici Aşama 56 raw bowlSum raporu

> **UYARI — 2026-09-11:** Bu raporun eski sonucu kanonik değildir. Güncel Scroll'a göre final post-stir içindeki `u` terimi raw `sum(oldBowls)` değil, `R = SAVE(sum(oldBowls) + 149*r)` kullanır. Aşağıdaki raw-sum yaklaşımı yalnız tarihsel hata/mutant kaydıdır.

## Eski iddia

Tarihsel corrective-56 çalışması şu ayrımı “authoritative” kabul etmişti:

```text
rawBowlSum = sum(oldBowls)
orderNumber = SAVE(rawBowlSum + 149 * stir)
permutation = permutation(orderNumber)
u += rawBowlSum
```

Bu yorum **yanlıştır** ve SUPERSEDED'dir.

## Güncel kanonik hüküm

```text
S = sum(oldBowls)
R = SAVE(S + 149 * stir)
permutation = permutation(1 + ((R - 1) mod 720))
u += R
```

Her turda bütün altı `new[B]` aynı `oldBowls` snapshot'ından hesaplanır ve birlikte commit edilir.

## Kod durumu

- `legacy_order_memory.postStirRoundExact`: kanonik saved-sum yoludur.
- Üretim adapter'ı raw-sum detour'u çağırmaz.
- `post_stir_bowlsum_detour.rawSumMutantPostStir`: yalnız kasıtlı mutant/regresyon malzemesidir.
- Tarihsel `corrective56_raw_bowlsum` bayrağı compatibility telemetry alanı olarak kalabilir; semantik seçim yapmaz.
- `tests/normative_reference.sauce_corrective56` tarihsel API adı olarak korunur ancak artık kanonik `sauce` ile aynıdır.
- Raw mutant ayrı `sauce_raw_sum_mutant` adı altında yalnız discriminator için tutulur.

## Eski kanıtların durumu

Eski 6/6 corrective-56 sonucu, 402 toplamı ve eski external witness tuple'ları raw-sum semantiğini doğruladıkları için **kanonik doğrulama sayılmaz**. İlgili artifact dosyaları silinmemiş, `HISTORICAL_SUPERSEDED=YES` ile işaretlenmiştir.

Yeni hedefli discriminator ve intermediate witness'lar `artifacts/canonical-saved-sum/` altında yeniden üretildi.
