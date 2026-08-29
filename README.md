# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin ikinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 3/55, `PATCH 01` durumundadır. `oldRemainder(x)` tarihsel kusuruyla birlikte korunur ve büyük sayacın tam katlarında hâlâ `0` döndürür.

Düzeltme onun üstündeki `savePatch(x)` ve `SavePatchWrapper` katmanına eklenmiştir. Gerçek `LegacyRemainderAdapter` yolu bu yamadan geçer; `M`, `2M`, `3M` ve `M+1` için Aşama 2'de eklenen normatif regresyon değiştirilmeden artık yeşildir.

Gözlem durumu yamaya semantik girdi değildir ve yama durumu yalnızca çağrıya ait `MonsterContext` içinde tutulur. Gelecekteki 02–26 yamalarından hiçbiri eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam üçüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 2'de kırmızı olan normatif kalan regresyonu aynı gövdeyle yeşile dönmelidir; `oldRemainder` kusurunu koruyan test ise hâlâ `0` sonucunu bekler.
