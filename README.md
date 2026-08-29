# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin beşinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 5/55, `PATCH 02` durumundadır. İkinci tarihsel kusur kodda korunur:

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION_DAY_OLD)
```

Düzeltme onun üstündeki `dayTagWithFoundationScar` ve `DayTagPatchWrapper` katmanındadır:

```text
n = oldDayTag(day)
if day >= FOUNDATION_DAY_OLD:
    n += 1
if day == FOUNDATION_DAY_OLD and n != 1:
    n = 1
```

`LegacyDayTagAdapter` gerçek çağrı yolunda bu yamadan geçer. Ham eski değer ve düzeltilmiş değer çağrıya ait `MonsterContext` içinde ayrı tutulur.

Aşama 4'teki normatif regresyon değiştirilmeden artık yeşildir. `oldDayTag` yardımcısının yanlış formülü ayrıca testte korunur. Birinci tarihsel yara ve Yama 01 de aynen kalır. Gelecekteki 03–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam beşinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 4'te kırmızı olan gün etiketi normatif regresyonu aynı gövdeyle yeşile dönmelidir; `oldDayTag` kusurunu doğrudan koruyan testler ise eski yanlış değerleri doğrulamaya devam eder.
