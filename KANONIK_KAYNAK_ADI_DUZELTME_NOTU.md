# Kanonik kaynak adı düzeltmesi

Tarih: 2026-09-13
Dal: `Python+Türkçe`
Başlangıç HEAD: `8828adc31fec9d1c27c4f6845a98e598c130d930`
Üstün kanonik kaynak: https://the-scroll-of-the-appointed-times.blogspot.com/

Bu düzeltme Türkçe kaynak dil kataloğundaki kanonik kimliklere bağlı sunum adlarını düzeltir.
Matematiksel algoritma, `canonicalIndex` değerleri, köfte/ay sırası ve seçim semantiği değiştirilmemiştir.

## Düzeltilen adlar

### Köfteler

- 4: `Melez ağacı` → `Lagaş`
- 6: `Dokuzda dört` → `Dokuz parçadan dördü`
- 8: `Papirüs` → `Papirüs bitkisi`
- 17: `Boş testi` → `Boş kavanoz`

### Aylar

- 7: `Beşte üç` → `Beş parçadan üçü`
- 8: `Karşumab` → `Karşumav`
- 11: `Sis` → `Pus`
- 31: `Mum` → `Lamba`
- 36: `Zambak` → `Susa`

Katalog sürümü `1.3.1` → `1.3.2` olarak yükseltilmiştir.

## Doğrulama

- Python sözdizimi: PASS
- Katalog sürümü, 17 köfte, 47 ay ve kanonik indis sürekliliği: PASS
- Düzeltilen adların beklenen kanonik indislerde olduğu kontrolü: PASS
- Belge eşleşmesi: PASS
- Depo genelinde eski katalog biçimleri için negatif arama: PASS
- `git diff --check`: PASS
- `test_stage_*.py`: temiz HEAD ile karşılaştırıldı; düzeltme yeni failure/error üretmedi (baseline eşdeğerliği doğrulandı)
- Stage 54 entegrasyon testi: temiz HEAD baseline ile karşılaştırıldı; yeni regresyon yok
- Stage 55 audit: temiz HEAD baseline ile karşılaştırıldı; yeni regresyon yok
- Stage 56 saved-sum düzeltme testi: temiz HEAD baseline ile karşılaştırıldı; yeni regresyon yok
- Hızlandırma yamaları 27-33 regresyon testleri: temiz HEAD baseline ile karşılaştırıldı; yeni regresyon yok