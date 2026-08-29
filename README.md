# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin on dokuzuncu aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 19/55, `PATCH 09` durumundadır.

Discovery 09'un yanlış fixed-bowl helper'ı fiziksel olarak korunur:

```text
position 1 -> fixed bowl 1
position 2 -> fixed bowl 2
position 3 -> fixed bowl 3
```

Düzeltme ayrı alias katmanındadır:

```text
bowlAlias[position] = order[position]
```

ve bütün corrected pour bowl read'leri:

```text
bowlByLegacyPosition(oldBowls, bowlAlias, position)
```

üzerinden geçer.

`BowlAliasPatchWrapper`, yanlış helper'ı gerçekten çalıştırıp raw fixed-bowl pour scar'ını invocation bağlamında tutar; semantic sonuç olarak yalnızca alias üzerinden hesaplanan corrected pour tuple'ını döndürür.

Aşama 18'in normatif pour regresyonu değiştirilmeden yeşile dönmüştür. Ayrıca 46 visible drop için isolated pour tuple'larının tamamı test-only normatif position-based formülle eşleşir.

Bowl stir/update henüz başlatılmaz. `vaultOld`, `pending` ve Patch 10 kodu yoktur.

Stage 15 kalıcı sentinel row ve Stage 17 permutation patch korunur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam on dokuzuncu aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 18'de kırmızı olan `i=1`, `i=2` ve `i=3` pour alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir.
