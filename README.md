# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin on yedinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 17/55, `PATCH 08` durumundadır.

Tarihsel 0-based helper fiziksel olarak değişmez:

```text
oldPermutationUnrank0(rank0)
```

Discovery 08'in yanlış caller'ı da scar olarak kodda kalır.

Authoritative patch chain tam olarak:

```text
oneBased = regularMod(drop-1,720)+1
legacyRank0 = oneBased-1
order = oldPermutationUnrank0(legacyRank0)
```

biçimindedir.

`PermutationRankPatchWrapper` önce yanlış caller'ı gerçekten çalıştırır ve yanlış order veya `oneBased=720` hata scar'ını invocation-local bağlamda tutar. Sonra patched chain sonucunu semantic order olarak döndürür.

Aşama 16'nın normatif permutation-rank regresyonu değiştirilmeden yeşile dönmüştür. 46 görünür drop order'ının tamamı test-only normatif bowl order ile eşleşir.

Stage 15'in kalıcı sentinel row'u korunur. Pours ve `bowlAlias` henüz eklenmemiştir. Gelecekteki 09–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam on yedinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 16'da kırmızı olan `i=1`, `i=2` ve `i=46` permutation-order alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir.
