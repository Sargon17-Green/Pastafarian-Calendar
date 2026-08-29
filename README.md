# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin kırk beşinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 45/55, `PATCH 22` durumundadır.

Aşama 44 raw `LegacyRepeatedNameGenerator.call_with_ring` scar'ı aynen kalır ve önce gerçekten `bad` candidate üretir.

Yeni `fallingFactorialDistinct` ve `partialPermutationUnrank` distinct canonicalIndex partial-permutation family'yi exact lexicographic olarak temsil eder.

`RepeatedNamePatchWrapper` aynı bowl 5 / seal 22 answer ring ile correct rank ve correct candidate hesaplar.

`bad==correct` ise bad aynen döner; farklıysa correct semantic result döner.

Raw repeated candidate diagnostic state'te kalır, semantic ad indices corrected result olur.

Patch 23 `VirtualLegacyList` kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam kırk beşinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 44'te kırmızı olan üç repeated-name witness corrected partial-permutation semantic result ile yeşile dönmelidir.
