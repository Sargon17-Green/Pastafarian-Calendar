# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirmi birinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 21/55, `PATCH 10` durumundadır.

Discovery 10'un wrong in-place helper'ı fiziksel olarak korunur ve wrapper içinde gerçekten çalıştırılır.

Corrected bowl update yolu:

```text
vaultOld = clone(B)
pending = ayrı write buffer
all six position reads -> vaultOld
all six position writes -> pending
commit -> only after all six positions
```

biçimindedir.

`BowlMutationPatchWrapper`, contaminated legacy sonucu invocation-local scar olarak saklar; ardından snapshot/write-buffer yolunu çalıştırır ve yalnızca committed `pending` tuple'ını semantic sonuç olarak döndürür.

Aşama 20'nin normatif bowl-update regresyonu değiştirilmeden yeşile dönmüştür.

Henüz 46-drop full bowl pass, order-at-46 latch veya post-stir eklenmemiştir; Patch 11 başlamamıştır.

Stage 15 sentinel, Stage 17 permutation patch ve Stage 19 bowlAlias patch korunur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirmi birinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 20'de kırmızı olan position 2, 3 ve 6 alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir.
