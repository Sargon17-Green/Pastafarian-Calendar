# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin kırk birinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 41/55, `PATCH 20` durumundadır.

Stage 40 `oldStructureSauce(cDay,originalTargetDay)` helper gövdesi aynen korunur ve her structure call'da gerçekten çalışır.

Old result artık ghost state'te saklanır ve selector'a verilmez.

`originalTargetDay != year_first_day` olduğunda `StructureSaucePatchWrapper` current Python implementation ile:

```text
sauceWithCurrentScars(cDay,year_first_day)
```

sonucunu yeniden hesaplar.

`LegacyStructureSelectorAdapter` yalnız bu semantic year-first-day sauce sonucunu görür.

İki target eşitse old result zaten authoritative olduğu için ekstra recomputation yapılmaz.

Aşama 40 normatif regression gövdesi değiştirilmeden yeşile dönmüştür.

Patch 21 cutlet partition prefix-gate filter kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam kırk birinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 40'ta kırmızı olan üç original-target-versus-year-first-day selector alt örneği aynı normatif regression gövdesiyle yeşile dönmelidir.
