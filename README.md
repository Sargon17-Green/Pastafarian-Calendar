# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin on sekizinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 18/55, `DISCOVERY 09` durumundadır.

Exact initial bowl factory eklenmiştir. Yeni tarihsel kusur pour read katmanındadır:

```text
pour position 1 -> sabit bowl 1
pour position 2 -> sabit bowl 2
pour position 3 -> sabit bowl 3
```

Legacy kod current permutation order'ını hangi gerçek bowl ID'nin position 1,2,3'te olduğunu belirlemek için kullanmaz.

`LegacyPourAdapter`, bu fixed-bowl yolu exact visible drops ve exact permutation order tablosunun üstünde gerçek `calendar_date_spaghetti` state-machine zincirine bağlar.

Yeni normatif regresyon `i=1`, `i=2` ve `i=3` için legacy pour tuple'ını test-only normatif position-based bowl reads ile karşılaştırır ve bilinçli olarak kırmızıdır.

Henüz `PATCH 09` yoktur: `bowlAlias[position]=order[position]` ve alias üzerinden bowl read eklenmemiştir.

Bowl stir/update da henüz başlatılmaz; dolayısıyla `vaultOld`/`pending` Patch 10 kodu yoktur.

Stage 15 kalıcı sentinel row ve Stage 17 permutation patch korunur. Önceki Aşama 1–17 regresyonlarının tamamı yeşildir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam on sekizinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–17 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni fixed-bowl pour normatif regresyonunun `i=1`, `i=2` ve `i=3` alt örnekleri başarısız olur.
