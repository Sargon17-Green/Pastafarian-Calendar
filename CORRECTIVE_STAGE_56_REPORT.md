# Düzeltici Aşama 56 raporu

## Amaç

Tamamlanmış Python + Türkçe motorundaki post-stir operand ayrımını spaghetti detour
ile düzeltmek ve özgün 55 aşamalı scar zincirini fiziksel olarak korumak.

## Kanıtlanan root cause

İlk ayrışma 46. görünür damladan sonra, birinci post-stir içinde oluşur.

46. damla sonundaki bowls ve permutation aynı semantiktedir. Bowl ID gösterimi iki
motorda 1..6 ve 0..5 olduğu için yalnız gösterim farkı vardır.

Tarihsel A1 yolu:

```text
savedOrderNumber = SAVE(sum(oldBowls) + 149 * stir)
permutation = permutation(savedOrderNumber)
u += savedOrderNumber
```

Düzeltici authoritative yol:

```text
rawBowlSum = sum(oldBowls)
orderNumber = SAVE(rawBowlSum + 149 * stir)
permutation = permutation(orderNumber)
u += rawBowlSum
```

## Spaghetti koruması

`postStirRoundExact` kaldırılmamış ve doğrudan doğruya düzeltilmemiştir.

Her post-stir'de önce eski A1 fonksiyonu gerçekten çalışır. Eski sonucu
`corrective56_post_stir_last_legacy_wrong_result` alanında ghost olarak tutulur.

Yalnız authoritative final sauce bağlamında `rawBowlSumPostStirDetour` çalışır.
Detour eski orderNumber ve permutationın yeni hesapla aynı olduğunu guard ile
doğrular. Sonra `u` operandını ham bowl toplamıyla yeniden hesaplar.

Historical 1–55 yürüyüşünde corrective flag varsayılan `False` kaldığı için önceki
365 scar regressionı aynı davranışı görür.

## Final integration guard

Stage 54 integration'ın eski context sauce'u yeniden kullanabildiği bir köşe durum
vardı: `original_target_day == year.first_day`.

Düzeltici Aşama 56 bu değeri ghost olarak korur fakat final structure sauce'u her
durumda `sauceWithScars(..., corrective56_raw_bowlsum=True)` üzerinden yeniden
hesaplar.

## Test oracle ayrımı

Historical `tests/normative_reference.py:sauce` A1 semantics ile bırakılmıştır.

Düzeltici doğrulama için ayrı:

```text
post_stir12_corrective56
sauce_corrective56
```

eklenmiştir. `GateTable` ve `NormativeCalendar` optional sauce injection alır; default
eski sauce'tur. Stage 54/55 final-semantic testleri corrective sauce'u açıkça seçer.

## Doğrulama sonucu

```text
Historical regressions: 365/365 PASS
Aşama 54 integration: 10/10 PASS
Aşama 55 final audit: 21/21 PASS
Düzeltici Aşama 56: 6/6 PASS
Failure: 0
Error: 0
Toplam: 402 PASS
```

Stage 55 audit ağır end-to-end vakaları kaynak izolasyonu nedeniyle ayrı Python
process'lerinde doğrulanmıştır.

## External alignment witness

Reference commit:

```text
d5cfe77ef7950a9a67ff0e6814833a3eedacae8a
```

Canonical tuple witness'ları:

```text
Foundation:
(5000, 4, 762, 12, 105)

c=t=-15048173:
(5000, 12, 21, 47, 57)

c=-15048173, t=-15048172:
(5000, 12, 22, 18, 58)

c=-15048173, t=-15048174:
(5000, 12, 20, 7, 58)
```

Düzeltme sonrası dört tuple 4/4 eşleşmiştir.

Foundation ve `c=t=-15048173` direct final sauce bowls da forensic reference
evidence ile bire bir eşleşmiştir.

Bu witness'lar production içinde import edilmez, fallback değildir ve çalışma zamanı
semantic kaynağı değildir.

## Değişmeyenler

- `SourceLanguageCatalog` değişmez.
- 26 historical legacy scar temizlenmez.
- 26 historical patch/detour kaldırılmaz.
- `postStirRoundExact` A1 scar olarak kalır.
- Production test-only oracle import etmez.
- Git history bu paket hazırlanırken değiştirilmez.
