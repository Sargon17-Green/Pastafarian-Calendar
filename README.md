# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin birinci aşamasıdır. Bu çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Birinci aşamanın sınırı

Bu aşamada yalnızca şu öğeler vardır:

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında tarafsız `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç girişi.
- Birinci aşamaya özgü testler.

Yirmi altı tarihsel kusurun ve bunların yamalarının hiçbiri bu aşamada üretim yoluna eklenmemiştir.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan İbranice kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri ise sabit bir harf eşlemesiyle çevriyazılmıştır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Testler:

```text
python -m unittest discover -s tests -v
```

Üretim başlangıç girişi bu aşamada bilinçli olarak tam tarih döndürmez. Tam üretim yolu yalnızca tarihsel aşamalar tamamlandıktan sonra birleştirilecektir.
