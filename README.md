# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin on beşinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 15/55, `PATCH 07` durumundadır.

Legacy grind indexing aynen korunur:

```text
legacyGrindRow(table, grind)
    -> table[grind]
```

Düzeltme tablo hizasındadır. `LEGACY_VISIBLE_GRIND_TABLE` 11 gerçek satırı eski zero-based 0..10 biçimiyle fiziksel scar olarak tutmaya devam eder.

Üstünde kalıcı patch tablosu vardır:

```text
GRIND_TABLE_WITH_SENTINEL[0] = SENTINEL_GRIND_ROW
GRIND_TABLE_WITH_SENTINEL[1..11] = gerçek grind row 1..11
```

Görünür drop builder bu sentinel tablosunu kullanır. Normal `grind=1..11` loop sentinel row'u okumaz; sentinel yalnızca 1-based legacy indexing'i fiziksel olarak hizalar.

Aşama 14'ün normatif visible-drop regresyonu değiştirilmeden yeşile dönmüştür. 46 görünür damlanın tamamı test-only normatif builder ile eşleşir.

Sentinel gelecekte silinmemelidir. Gelecekteki 08–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam on beşinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 14'te kırmızı olan görünür damla `i=1`, `i=2` ve `i=46` alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir; legacy `table[grind]` indexing ve index 0 sentinel fiziksel olarak korunur.
