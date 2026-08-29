# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirmi dokuzuncu aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 29/55, `PATCH 14` durumundadır.

Discovery 14 short-only scar'ı korunur ve `N>M_OLD` için eski short adapter diagnostic olarak gerçekten çağrılır.

Semantic dispatcher:

```text
N<=M_OLD -> Stage 27 short path
N>M_OLD  -> wideDetour
```

şeklindedir.

Wide path minimal `places` ve `space=M_OLD^places` kurar, `digits[j]=answerAtRing(j)-1` değerlerini yalnız bir kez alır ve:

```text
wide = 1 + Σ digits[j]*M_OLD^j
```

oluşturur.

Rejection bundan sonra yalnız combined `wide` üzerinde `direction_step` ile ilerler. Yeni digit üretilmez.

Aşama 28 normatif wide-selection regresyonu değiştirilmeden yeşile dönmüştür.

Patch 15 negative-gate kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirmi dokuzuncu aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 28'de kırmızı olan `M_OLD+1`, `M_OLD^2` ve `M_OLD^3` wide-selection alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir.
